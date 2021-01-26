pragma solidity ^0.6.0;

import "../../contract-libs/open-zeppelin/ERC20.sol";

abstract contract ERC20WithBlackList is ERC20 {
    mapping(address=>bool) public blackList;

    function _transfer(address sender, address recipient, uint256 amount) internal override virtual {
        require(!blackList[sender], "blocked address");
        super._transfer(sender, recipient, amount);
    }
}
