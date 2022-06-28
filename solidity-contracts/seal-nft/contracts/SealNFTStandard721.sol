// SPDX-License-Identifier: Apache-2.0
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.0;

import "../../contract-libs/open-zeppelin/ERC721/ERC721.sol";
import "../../contract-libs/seal-sc/Simple3Role.sol";
import "../../contract-libs/seal-sc/SimpleSealSCSignature.sol";
import "../../contract-libs/seal-sc/RejectDirectETH.sol";

contract SealNFTStandard721 is ERC721, Simple3Role, RejectDirectETH, SimpleSealSCSignature {
    using SafeMath for uint256;
    using Address for address payable;
    mapping (uint256=>bool) public lockTokenList;
    bool public lockTokenEnabled;
    string public addr;
    string public baseuri;

    constructor(
        address _owner,
        string memory _name,
        string memory _symbol,
        bool _enablelockToken,
        string memory _uri
        ) public Simple3Role(_owner) ERC721(_name, _symbol) {
           lockTokenEnabled = _enablelockToken;
           addr = addressToString(address(this));
           baseuri = string(abi.encodePacked(_uri, addr,'/'));
            _setBaseURI(baseuri);
        }
     
    modifier isTokenOwner(uint256 _id) {
        require(ownerOf(_id) == msg.sender, "not owner");
        _;
    }
    event BaseURISet(string _uri);
    function setBaseURI(string calldata _uri) external onlyAdmin {
        _setBaseURI(_uri);
        emit BaseURISet(_uri);
    }

    event TokenURISet(uint256 _id, string _uri);
    function setTokenURI(uint256 _id, string calldata _uri) external onlyAdmin {
        _setTokenURI(_id, _uri);
        emit TokenURISet(_id, _uri);
    }

    event MintTo(address owner, address _to, uint256 _id);
    function mint(address _to, uint256 _id) external onlyAdmin {
        _safeMint(_to, _id);
        emit MintTo(msg.sender, _to, _id);
    }

    event TokenBurn(address owner, uint256 _id);
    function burn(uint256 _id) external isTokenOwner(_id) {
        require(!lockTokenList[_id],'token is locked');
        _burn(_id);
        emit TokenBurn(msg.sender, _id);
    }

    event LockToken(uint256 _id);
    function lockToken(uint256 _id) external onlyOwner{
        require(lockTokenEnabled,'Token lock is not enabled');
        lockTokenList[_id] = true;
        emit LockToken(_id);
    }

    event UnLockToken(uint256 _id);
    function unlockToken(uint256 _id) external onlyOwner{
        require(lockTokenEnabled,'Token lock is not enabled');
        lockTokenList[_id] = false;
        emit UnLockToken(_id);
    }

    event TransferToken(address from, address to, uint256 tokenId);
    function transfer(address from, address to, uint256 tokenId) external isTokenOwner(tokenId) {
        require(!lockTokenList[tokenId], "token is locked");
        super._transfer(from, to, tokenId);
        emit TransferToken(from, to, tokenId);
    }

    function addressToString(address _addr) public pure returns(string memory) {
        bytes32 value = bytes32(uint256(_addr));
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(51);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint(uint8(value[i + 12] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(value[i + 12] & 0x0f))];
        }
        return string(str);
    }
}