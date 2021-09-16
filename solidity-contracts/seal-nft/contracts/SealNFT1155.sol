pragma solidity ^0.6.2;

import "../../contract-libs/open-zeppelin/ERC1155/ERC1155.sol";
import "../../contract-libs/seal-sc/Simple3Role.sol";
import "../../contract-libs/seal-sc/Utils.sol";
import "../../contract-libs/seal-sc/SimpleSealSCSignature.sol";
import "../../contract-libs/seal-sc/RejectDirectETH.sol";
import "../../contract-libs/open-zeppelin/IERC20.sol";
import "../../contract-libs/open-zeppelin/Strings.sol";

contract SealNFT1155 is ERC1155, Simple3Role, SimpleSealSCSignature, RejectDirectETH {
    using SafeMath for uint256;
    using ECDSA for bytes32;

    event CapSet(address admin, uint256 id, uint256 cap, uint256 currentSupply);
    event Minted(address to, uint256 id, uint256 amount, uint256 currentSupply);
    event MintedWithApprove(address apporver, address to, uint256 id, uint256 amount, uint256 currentSupply);
    event Burned(address from, uint256 id, uint256 amount, uint256 currentSupply);

    constructor(address _owner, string memory _name, string memory _symbol)
        public Simple3Role(_owner) ERC1155("") {

        name = _name;
        symbol = _symbol;
    }

    mapping(uint256=>uint256) public supplyCaps;
    mapping(uint256=>uint256) public currentSupply;

    string public name;
    string public symbol;

    function setTokenSupplyCap(uint256 _id, uint256 _newCap) public onlyAdmin {
        require(_newCap > currentSupply[_id], "cap too small");
        supplyCaps[_id] = _newCap;
        emit CapSet(msg.sender, _id, _newCap, currentSupply[_id]);
    }

    function mintWithCap(address _to, uint256 _id, uint256 _cap, uint256 _amount) external onlyAdmin {
        setTokenSupplyCap(_id, _cap);
        _mint(_to, _id, _amount);
    }

    function setURI(string calldata _newURI) external onlyAdmin {
        _setURI(_newURI);
    }

    function uri(uint256 _id) override view external returns(string memory tokenURI) {
        return string(abi.encodePacked(_uri, "/", Strings.toString(_id)));
    }

    function _mint(address _to, uint256 _id, uint256 _amount) internal {
        require(currentSupply[_id].add(_amount) <=  supplyCaps[_id], "exceed cap");
        _mint(_to, _id, _amount, bytes(""));
        currentSupply[_id] = currentSupply[_id].add(_amount);
    }

    function mint(address _to, uint256 _id, uint256 _amount) external onlyExecutor {
        _mint(_to, _id, _amount);
        emit Minted(_to, _id, _amount, currentSupply[_id]);
    }

    function claim(address _to, uint256 _id, uint256 _amount, bytes calldata _sig) external {
        bytes32 signedHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n213:",
                SealUtils.toLowerCaseHex(address(this)),
                SealUtils.toLowerCaseHex(_to),
                SealUtils.toLowerCaseHex(_id),
                SealUtils.toLowerCaseHex(_amount)
            ));

        address approver = signedHash.recover(_sig);

        if(!administrator[approver]) {
            revert("invalid signature");
        }

        _mint(_to, _id, _amount);
        emit MintedWithApprove(approver, _to, _id, _amount, currentSupply[_id]);
    }

    function burn(uint256 _id, uint256 _amount) external {
        _burn(msg.sender, _id, _amount);
        currentSupply[_id] = currentSupply[_id].sub(_amount);
        emit Burned(msg.sender, _id, _amount, currentSupply[_id]);
    }
}
