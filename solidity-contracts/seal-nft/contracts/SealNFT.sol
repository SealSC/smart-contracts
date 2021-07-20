// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.6.0;

import "../../contract-libs/open-zeppelin/ERC721/ERC721.sol";
import "../../contract-libs/seal-sc/Simple3Role.sol";
import "../../contract-libs/seal-sc/SimpleSealSCSignature.sol";
import "./SealNFTPeriphery.sol";

contract SealNFT is ERC721, Simple3Role, RejectDirectETH, SimpleSealSCSignature {
    using SafeMath for uint256;

    bool public sequentialID;
    uint256 public nextID;

    SealNFTPeriphery public sealNFTPeriphery;

    event Deployed(address nftContract, address theOwner, string nftName, string nftSymbol);
    constructor(
        address _owner,
        string memory _name,
        string memory _symbol,
        address payable _periphery,
        bool _sequentialID) public Simple3Role(_owner) ERC721(_name, _symbol) {
        sealNFTPeriphery = SealNFTPeriphery(_periphery);
        sequentialID = _sequentialID;

        emit Deployed(address(this), _owner, _name, _symbol);
    }

    function setBaseURI(string calldata _newURI) external onlyAdmin {
        _setBaseURI(_newURI);
    }

    function tokenURI(uint256 _id) override view public returns(string memory uri) {
        if(bytes(baseURI()).length != 0) {
            return super.tokenURI(_id);
        } else {
            return sealNFTPeriphery.uriOf(address(this), _id);
        }
    }

    function getID(string memory _metadata) internal returns(uint256 id) {
        if(sequentialID) {
            id = nextID;
            nextID = nextID.add(1);
        } else {
            id = uint256(keccak256(abi.encodePacked(_metadata)));
        }

        return id;
    }

    function mintWithoutSig(address _to, string calldata _metadata) external onlyAdmin {
        uint256 id = getID(_metadata);
        (, bool stored) = sealNFTPeriphery.store(id);

        require(stored, "not stored");
        _mint(_to, id);
    }

    function mintWithSig(address _to, string calldata _metadata, bytes calldata _sig, uint256 _feeCategory, address _feeSupplier) external onlyExecutor {
        uint256 id = getID(_metadata);
        (, bool stored) = sealNFTPeriphery.storeWithVerify(id, _sig, _feeCategory, _feeSupplier);

        require(stored, "invalid signature");
        _mint(_to, id);
    }

    function burn(uint256 _id) external {
        require(ownerOf(_id) == msg.sender, "not token owner");
        _burn(_id);
    }

    function getSealNFTURI(uint256 _id) external view returns(string memory sealURI) {
        if(ownerOf(_id) == address(0)) {
            return "";
        }

        return sealNFTPeriphery.uriOf(address(this), _id);
    }

    function getStoredInfo(uint256 _id) external view
        returns(address recorder, uint256 key, uint256 blk, bytes memory sig) {
        return sealNFTPeriphery.getStored(address(this), _id);
    }
}