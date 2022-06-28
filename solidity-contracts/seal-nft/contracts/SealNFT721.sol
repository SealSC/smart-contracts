// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.6.0;

import "../../contract-libs/open-zeppelin/ERC721/ERC721.sol";
import "../../contract-libs/seal-sc/Simple3Role.sol";
import "../../contract-libs/seal-sc/SimpleSealSCSignature.sol";
import "./SealNFTChargeFee.sol";

contract SealNFT721 is ERC721, Simple3Role, RejectDirectETH, SimpleSealSCSignature {
    using SafeMath for uint256;

    uint256 public nextSequenceID;

    SealNFTChargeFee public sealNFTChargeFee;

    event Deployed(address nftContract, address theOwner, string nftName, string nftSymbol);
    event SequenceNFTMinted(address to, uint256 id);
    event DirectNFTMinted(address to, bytes32 id);
    event MetaNFTMinted(address to, bytes32 metahash);
    event SignedMetaNFTMinted(address to, bytes32 metahash, bytes sig);

    constructor(
        address _owner,
        string memory _name,
        string memory _symbol,
        address payable _chargeFee) public Simple3Role(_owner) ERC721(_name, _symbol) {
        sealNFTChargeFee = SealNFTChargeFee(_chargeFee);

        emit Deployed(address(this), _owner, _name, _symbol);
    }

    function setBaseURI(string calldata _newURI) external onlyAdmin {
        _setBaseURI(_newURI);
    }

    function tokenURI(uint256 _id) override view public returns(string memory uri) {
        if(bytes(baseURI()).length != 0) {
            return super.tokenURI(_id);
        } else {
            return sealNFTChargeFee.uriOf(address(this), _id);
        }
    }

    function mintHashed(address _to, bytes32 _metadataHash) external onlyAdmin {

        _mint(_to, uint256(_metadataHash));

        emit MetaNFTMinted(_to, _metadataHash);
    }

    function mintSequentially(address _to) external onlyExecutor {

        _mint(_to, nextSequenceID);

        emit SequenceNFTMinted(_to, nextSequenceID);

        nextSequenceID = nextSequenceID.add(1);
    }

    function mintSigned(address _to, bytes32 _metadataHash, bytes calldata _sig, uint256 _feeCategory, address _feeSupplier) external onlyExecutor {

        sealNFTChargeFee.changeFee(uint256(_metadataHash), _sig, _feeCategory, _feeSupplier);

        _mint(_to, uint256(_metadataHash));

        emit SignedMetaNFTMinted(_to, _metadataHash, _sig);
    }

    function mintDirect(address _to, uint256 _id) external onlyExecutor {
        _mint(_to, _id);
        emit DirectNFTMinted(_to, bytes32(_id));
    }
    
    function getSealNFTURI(uint256 _id) external view returns(string memory sealURI) {
        if(ownerOf(_id) == address(0)) {
            return "";
        }

        return sealNFTChargeFee.uriOf(address(this), _id);
    }
}