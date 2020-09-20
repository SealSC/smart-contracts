pragma solidity ^0.5.9;

import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./IMineableToken.sol";

contract MineableToken is IMineableToken, ERC20, ERC20Detailed, Ownable {
    using SafeMath for uint256;
    address public  supplyAddress = address(42);
    address private admin;

    constructor(
        address _owner,
        address _admin,
        address _minter,
        string memory _name,
        string memory _symbol,
        uint256 _initSupply,
        uint8 _decimals)

    public ERC20Detailed(_name, _symbol, _decimals) Ownable(_owner){
        minters[_minter] = _minter;
        setTotalSupplyCap(_initSupply);
        admin = _admin;
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

    function setTotalSupplyCap(uint256 newCap) public {
        require(isOwner() || msg.sender == admin);

        uint256 currentSupply = totalSupply();
        require(newCap > currentSupply);

        uint256 newTokenCount = newCap.sub(currentSupply);
        _mint(supplyAddress, newTokenCount);
    }

    function mint(address to, uint256 amount) public {
        require(minters[msg.sender] != address(0), "not minter");
        require(to != address(0), "can not mint to addresss 0");

        _balances[supplyAddress] = _balances[supplyAddress].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[to] = _balances[to].add(amount);
        emit Transfer(supplyAddress, to, amount);
    }

    function setAdmin(address _newAdmin) public onlyOwner {
        admin = _newAdmin;
    }

    function signature() external pure returns (string memory) {
        return "provided by Seal-SC / www.sealsc.com";
    }
}
