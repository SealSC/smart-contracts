pragma solidity ^0.6.0;

import "../../contract-libs/seal-sc/Simple3Role.sol";
import "../../contract-libs/seal-sc/SimpleSealSCSignature.sol";
import "../../contract-libs/open-zeppelin/SafeMath.sol";
import "../../contract-libs/open-zeppelin/ECDSA.sol";
import "./ISealOnchainIdxStore.sol";
import "../../contract-libs/seal-sc/Cashier.sol";

contract SealOnchainIdxStore is ISealOnchainIdxStore, Cashier, Simple3Role, SimpleSealSCSignature {
    using SafeMath for uint256;
    using ECDSA for bytes32;
    uint256 public idxCount;

    mapping(bytes32=>Data) public idxList;
    mapping(address=>bool) internal signers;

    constructor(address _owner) public Simple3Role(_owner) {}

    function getStoreID(address _recorder, uint256 _key) pure internal returns(bytes32) {
        return keccak256(abi.encodePacked(_recorder, _key));
    }

    function storeID(bytes32 _id, uint256 _key, bytes memory _sig) internal returns(bool exists, bool stored) {
        Data memory d = idxList[_id];
        exists = (d.block != 0);

        if(!exists) {
            idxList[_id] = Data({
                key: _key,
                recorder: msg.sender,
                block: block.number,
                sig: _sig
            });

            idxCount = idxCount.add(1);
        }

        return (exists, true);
    }

    function store(uint256 _key) override external returns(bool exists, bool stored) {
        bytes32 id = getStoreID(msg.sender, _key);
        return storeID(id, _key, new bytes(0));
    }

    function storeWithVerify(uint256 _key, bytes calldata _sig, uint256 _feeCategory, address _feeSupplier)
        override payable external returns(bool exists, bool stored) {

        require(supportedFee[_feeCategory].exists, "not supported fee category");

        bytes32 id = getStoreID(msg.sender, _key);
        address signer = id.recover(_sig);

        if(!signers[signer]) {
            return (false, false);
        }

        super._chargeFeeByAmount(_feeCategory, _feeSupplier);

        return storeID(id, _key, _sig);
    }

    function getStored(address _recorder, uint256 _key) override view external
        returns(address recorder, uint256 key, uint256 blk, bytes memory sig) {

        bytes32 id = getStoreID(_recorder, _key);
        Data memory d = idxList[id];
        return (d.recorder, d.key, d.block, d.sig);
    }

    function validSigner(address _signer) override view external returns(bool valid) {
        return signers[_signer];
    }

    function removeSigner(address _signer) external onlyAdmin {
        signers[_signer] = false;
    }

    function setSigner(address _signer) external onlyAdmin {
        signers[_signer] = true;
    }

    function setFeeInfo(uint256 _feeCategory, address _currency, uint256 _amount, address payable _beneficiary) external onlyAdmin {
        super._setFeeInfo(_feeCategory, _currency, _amount, 0, _beneficiary);
    }

    function removeFeeInfo(uint256 _feeCategory) external onlyAdmin {
        super._removeFeeInfo(_feeCategory);
    }
}
