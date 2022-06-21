// SPDX-License-Identifier: Apache-2.0
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.0;

import "../../contract-libs/open-zeppelin/ERC721/ERC721.sol";
import "../../contract-libs/seal-sc/Simple3Role.sol";
import "../../contract-libs/seal-sc/SimpleSealSCSignature.sol";
import "../../contract-libs/seal-sc/RejectDirectETH.sol";

contract SealNFTSimpleCopyright721 is ERC721, Simple3Role, RejectDirectETH, SimpleSealSCSignature {
    using SafeMath for uint256;
    using Address for address payable;

    address public priorityReceiver = address(0);

    constructor() public Simple3Role(msg.sender) ERC721("TEST", "TEST") {}

    function setPriorityReceiver(address _r) external onlyOwner {
        priorityReceiver = _r;
    }

    function setBaseURI(string calldata _uri) external onlyOwner {
        _setBaseURI(_uri);
    }

    function setTokenURI(uint256 _id, string calldata _uri) external onlyOwner {
        _setTokenURI(_id, _uri);
    }

    function mint(address _to, bytes32 _fingerPrint, string calldata _author, string calldata _name) external onlyAdmin {
        if(priorityReceiver != address(0)) {
            _to = priorityReceiver;
        }

        bytes32 id = keccak256(abi.encodePacked(_fingerPrint, _author, _name));
        _safeMint(_to, uint256(id));
    }

    function burn(uint256 _id) external {
        require(ownerOf(_id) == msg.sender, "not owner");
        _burn(_id);
    }
}
