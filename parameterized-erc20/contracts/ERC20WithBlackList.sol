pragma solidity ^0.6.0;

import "../../contract-libs/open-zeppelin/ERC20.sol";
import "../../contract-libs/seal-sc/Simple3Role.sol";

abstract contract ERC20WithBlackList is ERC20, Simple3Role {
    mapping(address=>bool) public blackList;

    function addToBlackList(address _user) external onlyAdmin {
        blackList[_user] = true;
    }

    function removeFromBlackList(address _user) external onlyAdmin {
        blackList[_user] = false;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override virtual {
        require(!blackList[sender], "blocked address");
        super._transfer(sender, recipient, amount);
    }
}
