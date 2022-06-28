pragma solidity ^0.6.0;

import "../../contract-libs/seal-sc/Simple3Role.sol";
import "../../contract-libs/seal-sc/SimpleSealSCSignature.sol";
import "../../contract-libs/seal-sc/Utils.sol";
import "../../contract-libs/open-zeppelin/Strings.sol";
import "../../contract-libs/seal-sc/Cashier.sol";


contract SealNFTChargeFee is Cashier, Simple3Role{
    using Strings for uint256;
    using ECDSA for bytes32;
    string public baseURI;
    mapping(address=>bool) internal signers;
    address public signerAddress;

    constructor(address _owner) public Simple3Role(_owner){}

    function uriOf(address _nftContract, uint256 _tokenID) view external returns(string memory uri) {
        return string(abi.encodePacked(baseURI, SealUtils.toLowerCaseHex(_nftContract), '/', _tokenID.toString()));
    }

    function setBaseURI(string calldata _uri) external onlyAdmin {
        baseURI = _uri;
    }

    function setFeeInfo(uint256 _feeCategory, address _currency, uint256 _amount, address payable _beneficiary) external onlyAdmin {
        super._setFeeInfo(_feeCategory, _currency, _amount, 0, _beneficiary, FEE_CHARGE_METHOD.ByAmount);
    }

    function removeFeeInfo(uint256 _feeCategory) external onlyAdmin {
        super._removeFeeInfo(_feeCategory);
    }

    function setSignerAddress(address _signer) external onlyAdmin{
        signerAddress = _signer;
    }

    function changeFee(uint256 _metaDataHash, bytes calldata _sig, uint256 _feeCategory, address _feeSupplier)external{
        require(supportedFee[_feeCategory].exists,'not supported fee category');
        require(signerAddress != address(0),'No signers configured');
        //验签
        bytes32 tempHash = keccak256(abi.encodePacked(_metaDataHash));
        string memory hashStr = SealUtils.toLowerCaseHex(abi.encodePacked(tempHash));
        SealUtils.verifySignature(signerAddress, abi.encodePacked(":", hashStr), _sig, "invalid signature");

        //付费
        super._charge(_feeCategory,_feeSupplier,0);
    }
}
