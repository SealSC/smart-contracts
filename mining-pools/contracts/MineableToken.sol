pragma solidity ^0.5.9;

import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./IMineableToken.sol";

contract MineableToken is IMineableToken, ERC20, ERC20Detailed, Ownable {
    using SafeMath for uint256;

    uint256 public totalSupplyCap;

    constructor(
        address _owner,
        address _minter,
        string memory _name,
        string memory _symbol,
        uint256 _supplyCap,
        uint8 _decimals)

    public ERC20Detailed(_name, _symbol, _decimals) Ownable(_owner){
        minters[_minter] = _minter;
        if(_supplyCap == 0) {
            totalSupplyCap = ~uint256(0);
        } else{
            totalSupplyCap = _supplyCap;
        }
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

    function setTotalSupplyCap(uint256 newCap) public onlyOwner {
        uint256 currentSupply = totalSupply();
        require(newCap > currentSupply);

        totalSupplyCap = newCap;
    }

    function mint(address to, uint256 amount) public {
        require(minters[msg.sender] != address(0), "not minter");

        uint256 currentSupply = totalSupply();
        require(currentSupply < totalSupplyCap, "total supply cap touched");

        uint256 afterMint = currentSupply.add(amount);

        if(afterMint > totalSupplyCap) {
            amount = totalSupplyCap.sub(currentSupply);
        }

        _mint(to, amount);
    }

    function signature() external pure returns (string memory) {
        return "provided by Seal-SC / www.sealsc.com";
    }
}
