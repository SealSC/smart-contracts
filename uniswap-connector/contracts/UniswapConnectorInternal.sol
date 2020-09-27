pragma solidity ^0.5.9;

import "./UniswapConnectorData.sol";
import "../../contract-libs/open-zeppelin/SafeMath.sol";
import "../../contract-libs/open-zeppelin/SafeERC20.sol";

contract UniswapConnectorInternal is UniswapConnectorData {
    using SafeMath for uint256;
    using SafeERC20 for uint256;

    function _addLiquidity(address _a, address _b, uint _aAmount, uint _bAmount, address to) internal {
        router.addLiquidity(_a, _b, _aAmount, _bAmount, 0, 0, to, block.timestamp);
    }

    function _addLiquidityETH(uint256 _ethMin,  address _token, uint256 _tokenAmount, address _lpTo) internal {
        router.addLiquidityETH.value(_ethMin)(_token, _tokenAmount, 0, 0, _lpTo, block.timestamp);
    }

    function _swapToken(address _inToken, address _outToken, uint256 _inAmount, uint256 fee, IERC20 forToken) internal returns(uint256, uint256) {
        uint256 beforeSwap = forToken.balanceOf(address(this));
        uint256 swapAmount = _inAmount.sub(fee);
        uint256 swapVal = swapAmount.div(2);

        address[] memory path = new address[](2);
        path[0] = _inToken;
        path[1] = _outToken;

        router.swapExactTokensForTokens(swapVal, 0, path, address(this), block.timestamp);

        uint256 afterSwap = forToken.balanceOf(address(this));
        uint256 swapBackAmount = afterSwap.sub(beforeSwap);

        return (swapBackAmount, swapVal);
    }
}
