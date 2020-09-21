pragma solidity ^0.5.9;

import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./IMineableToken.sol";

contract MineableToken is IMineableToken, ERC20, ERC20Detailed, Ownable {
    using SafeMath for uint256;

    constructor(
        address _owner,
        address _minter,
        string memory _name,
        string memory _symbol,
        uint8 _decimals)

    public ERC20Detailed(_name, _symbol, _decimals) Ownable(_owner){
        minters[_minter] = _minter;
    }

    mapping(address=>address) public minters;

    function setMinter(address _minter) public {
        require(isMinter(msg.sender) || isOwner());
        minters[_minter] = _minter;
    }

    function removeMinter(address _minter) public {
        require(isMinter(msg.sender) || isOwner());
        delete minters[_minter];
    }

    function isMinter(address _minter) public view returns(bool) {
        return (address(0) != minters[_minter]);
    }

    function mint(address to, uint256 amount) public {
        require(isMinter(msg.sender), "not minter");
        require(to != address(0), "can not mint to addresss 0");

        _mint(to, amount);
    }

    function signature() external pure returns (string memory) {
        return "provided by Seal-SC / www.sealsc.com";
    }
}
