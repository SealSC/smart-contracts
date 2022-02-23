pragma solidity ^0.6.0;

import "../../contract-libs/seal-sc/Simple3Role.sol";
import "../../contract-libs/seal-sc/SimpleSealSCSignature.sol";
import "../../contract-libs/seal-sc/Utils.sol";
import "../../seal-onchain-idx-store/contracts/SealOnchainIdxStore.sol";
import "../../contract-libs/open-zeppelin/Strings.sol";

contract SealNFTPeriphery is SealOnchainIdxStore {
    using Strings for uint256;
    string public baseURI;

    constructor(address _owner) public SealOnchainIdxStore(_owner) {}

    function uriOf(address _nftContract, uint256 _tokenID) view external returns(string memory uri) {
        return string(abi.encodePacked(baseURI, SealUtils.toLowerCaseHex(_nftContract), '/', _tokenID.toString()));
    }

    function setBaseURI(string calldata _uri) external onlyAdmin {
        baseURI = _uri;
    }
}
