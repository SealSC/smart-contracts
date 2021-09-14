pragma solidity ^0.6.0;

import "../open-zeppelin/SafeERC20.sol";

contract ERC20TransferOut {
    using SafeERC20 for IERC20;

    function _transferERC20Out(IERC20 _token, address _to) internal {
        uint256 amount = _token.balanceOf(address (this));
        _token.safeTransfer(_to, amount);
    }
}
