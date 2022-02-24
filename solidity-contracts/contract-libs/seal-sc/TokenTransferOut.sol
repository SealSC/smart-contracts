pragma solidity ^0.6.0;

import "../open-zeppelin/SafeERC20.sol";
import "../open-zeppelin/ERC1155/IERC1155.sol";
import "../open-zeppelin/ERC721/IERC721.sol";

library TokenTransferOut {
    using SafeERC20 for IERC20;

    function transferOutERC20(IERC20 _token, address _to, uint256 _amount) internal {
        _token.safeTransfer(_to, _amount);
    }

    function transferOutERC1155(IERC1155 _token, address _to, uint256 _id, uint256 _amount) internal {
        _token.safeTransferFrom(address(this), _to, _id, _amount, bytes(""));
    }

    function transferOutERC721(IERC721 _token, address _to, uint256 _id) internal {
        _token.safeTransferFrom(address(this), _to, _id);
    }
}
