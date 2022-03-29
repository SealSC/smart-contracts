pragma solidity ^0.6.4;

import "../../contract-libs/seal-sc/SimpleSealSCSignature.sol";
import "../../contract-libs/seal-sc/Simple3Role.sol";
import "../../contract-libs/open-zeppelin/IERC20.sol";
import "../../contract-libs/seal-sc/Utils.sol";
import "../../contract-libs/open-zeppelin/SafeERC20.sol";
import "../../contract-libs/open-zeppelin/MerkleProof.sol";
import "../../contract-libs/seal-sc/Cashier.sol";
import "./ITokenBox.sol";
import "./ITokenBoxOpener.sol";
import "./ITokenBoxDistributor.sol";

contract TokenBoxOpener is ITokenBoxOpener, Cashier, Simple3Role, SimpleSealSCSignature, Mutex {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Address for address;

    address public commonSigner;
    ITokenBoxDistributor public distributor;
    mapping(address=>bool) public contractConnected;

    event BoxContractConnected(address boxContract);

    constructor(address _owner, address _commonSigner) public Simple3Role(_owner) {
        commonSigner = _commonSigner;
    }

    function setCommonSigner(address _newSigner) external onlyAdmin {
        commonSigner = _newSigner;
    }

    function setDistributor(address _distributor) external onlyOwner {
        distributor = ITokenBoxDistributor(_distributor);
    }

    function boxContractConnect(
        address _boxContract,
        bytes calldata _sig,
        uint256 _feeCategory,
        address _feeSupplier) external override {

        if(contractConnected[_boxContract]) {
            return;
        }

        require(Simple3Role(_boxContract).owner() == msg.sender, "not owner call");

        bytes memory rawData = abi.encodePacked(_boxContract, msg.sender);
        _verifySig(rawData, _sig, commonSigner, "enable box failed.");
        super._charge(_feeCategory, _feeSupplier, 0);

        contractConnected[_boxContract] = true;
        distributor.setConnectedContract(_boxContract);

        emit BoxContractConnected(_boxContract);
    }

    function _verifySig(
        bytes memory _rawData,
        bytes memory _sig,
        address _signer,
        string memory _errInfo) pure internal returns(bytes32) {

        bytes32 hash = keccak256(_rawData);
        string memory hashStr = SealUtils.toLowerCaseHex(abi.encodePacked(hash));

        SealUtils.verifySignature(_signer, abi.encodePacked(":", hashStr), _sig, _errInfo);

        return hash;
    }

    function setBoxContractBoxesRoot(address _boxContract, bytes32 _root, bytes calldata _sig) external {
        require(contractConnected[_boxContract], "not connect");
        _verifySig(abi.encodePacked(_root), _sig, commonSigner, "invalid box root sig");
        ITokenBox(_boxContract).setBoxesRoot(_root);
    }

    function openBox(
        address _boxContract,
        bytes32 _key,
        uint256 _boxNumber,
        uint256 _snSalt,
        bytes32[] calldata _proof
    ) external noReentrancy {
        bytes32 sn = keccak256(abi.encodePacked(_boxContract, _key, _boxNumber, _snSalt));

        bytes32 leaf = keccak256(abi.encodePacked(sn));
        require(MerkleProof.verify(_proof, ITokenBox(_boxContract).getBoxRoot(), leaf), "invalid box");

        address boxOwner = distributor.getOwnerOf(_boxContract, sn);
        require(boxOwner == msg.sender, "not box owner");

        ITokenBox(_boxContract).openBox(sn, _key, _boxNumber, msg.sender);
        distributor.setBoxOpened(_boxContract, sn);
    }

    function setFeeInfo(uint256 _feeCategory, address _currency, uint256 _amount, address payable _beneficiary) external onlyAdmin {
        super._setFeeInfo(_feeCategory, _currency, _amount, 0, _beneficiary, FEE_CHARGE_METHOD.ByAmount);
    }

    function removeFeeInfo(uint256 _feeCategory) external onlyAdmin {
        super._removeFeeInfo(_feeCategory);
    }
}
