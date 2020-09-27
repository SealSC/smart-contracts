pragma solidity ^0.5.9;

import "./UniswapConnectorData.sol";
import "../../contract-libs/open-zeppelin/SafeMath.sol";
import "../../contract-libs/open-zeppelin/SafeERC20.sol";

contract UniswapConnectorInternal is UniswapConnectorData {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    function _addLiquidity(address _a, address _b, uint _aAmount, uint _bAmount, address to) internal {
        router.addLiquidity(_a, _b, _aAmount, _bAmount, 0, 0, to, block.timestamp);
    }

    function _addLiquidityETH(uint256 _ethMin,  address _token, uint256 _tokenAmount, address _lpTo) internal {
        router.addLiquidityETH.value(_ethMin)(_token, _tokenAmount, 0, 0, _lpTo, block.timestamp);
    }

    function _swapToken(
        address _inToken,
        address _outToken,
        uint256 _inAmount,
        uint256 _fee,
        address _thisAddr) internal returns(uint256, uint256) {

        uint256 beforeSwap = IERC20(_outToken).balanceOf(_thisAddr);
        uint256 swapAmount = _inAmount.sub(_fee);
        uint256 swapVal = swapAmount.div(2);

        address[] memory path = new address[](2);
        path[0] = _inToken;
        path[1] = _outToken;

        router.swapExactTokensForTokens(swapVal, 0, path, _thisAddr, block.timestamp);

        uint256 afterSwap = IERC20(_outToken).balanceOf(_thisAddr);
        uint256 swapBackAmount = afterSwap.sub(beforeSwap);

        return (swapBackAmount, swapVal);
    }

    function _swapETHForToken(uint256 fee, address _outToken, address _thisAddr) internal returns(uint256, uint256) {
        uint256 beforeSwap = IERC20(_outToken).balanceOf(_thisAddr);

        uint256 ethVal = msg.value.sub(fee);
        uint256 swapVal = ethVal.div(2);

        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] =  _outToken;

        router.swapExactETHForTokens.value(swapVal)(0, path, _thisAddr, block.timestamp);

        uint256 afterSwap = IERC20(_outToken).balanceOf(_thisAddr);
        uint256 swapBack = afterSwap.sub(beforeSwap);

        return (swapBack, swapVal);
    }

    function _prepareToken(
        address _lp,
        address _inToken,
        address _outToken,
        uint256 _amount,
        address _thisAddr) internal returns (uint256 swapBack, uint256 swapVal) {

        if(supportedPair[_lp][0] == _inToken) {
            require(supportedPair[_lp][1] == _outToken, "not a pair");
        } else {
            require(supportedPair[_lp][0] == _outToken && supportedPair[_lp][1] == _inToken, "not a pair");
        }

        if(_inToken != ZERO_ADDRESS) {
            IERC20 inToken = IERC20(_inToken);
            inToken.safeTransferFrom(msg.sender, _thisAddr, _amount);
            uint256 fee = _amount.mul(feeBasisPoint).div(feePrecision);
            return _swapToken(_inToken, _outToken, _amount, fee, _thisAddr);
        } else {
            _amount = msg.value;
            uint256 fee = _amount.mul(feeBasisPoint).div(feePrecision);
            return _swapETHForToken(fee, _outToken, _thisAddr);
        }
    }

    function _getLP(
        address _lp,
        address _inToken,
        address _outToken,
        uint256 _swapVal,
        uint256 _swapBack,
        address _thisAddr) internal returns (uint256) {

        IERC20 lpToken = IERC20(_lp);

        uint256 beforeAddLPAmount = lpToken.balanceOf(_thisAddr);

        if(_inToken != ZERO_ADDRESS) {
            _addLiquidity(_inToken, _outToken, _swapVal, _swapBack, _thisAddr);
        } else {
            _addLiquidityETH(_swapVal, _outToken, _swapBack, _thisAddr);
        }

        uint256 afterAddLPAmount = lpToken.balanceOf(_thisAddr);

        return afterAddLPAmount.sub(beforeAddLPAmount);
    }
}
