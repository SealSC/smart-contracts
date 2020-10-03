pragma solidity ^0.5.9;

import "./UniswapConnectorData.sol";
import "../../contract-libs/open-zeppelin/SafeMath.sol";
import "../../contract-libs/open-zeppelin/SafeERC20.sol";

contract UniswapConnectorInternal is UniswapConnectorData {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    function _swapDeadline() view internal returns(uint) {
        return block.timestamp + 300;
    }

    function _addLiquidity(address _a, address _b, uint _aAmount, uint _bAmount, address _to) internal {
        router.addLiquidity(_a, _b, _aAmount, _bAmount, 0, 0, _to, _swapDeadline());
    }

    function _addLiquidityETH(uint256 _ethMin,  address _token, uint256 _tokenAmount, address _to) internal {
        router.addLiquidityETH.value(_ethMin)(_token, _tokenAmount, 0, 0, _to, _swapDeadline());
    }

    function _removeLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _liquidity) internal returns(uint256 amountA, uint256 amountB) {

        if(_tokenA == ZERO_ADDRESS) {
            //token A is eth and uniswap router will return eth value @ second slot
            (amountB, amountA) = router.removeLiquidityETH(_tokenB, _liquidity, 0, 0, address(this), _swapDeadline());
        } else {
            (amountA, amountB) = router.removeLiquidity(_tokenA, _tokenB, _liquidity, 0, 0,  address(this), _swapDeadline());
        }

        return (amountA, amountB);
    }

    function _swapInVal(uint256 _inAmount, address _inToken, address _pair) internal view returns(uint256) {
        uint256 _uinInBalance = IERC20(_inToken).balanceOf(_pair);
        return  _uinInBalance.mul(_inAmount).add(_uinInBalance.mul(_uinInBalance)).sqrt().sub(_uinInBalance);
    }

    function _swapToken(
        address _pair,
        address _inToken,
        address _outToken,
        uint256 _inAmount,
        address _thisAddr) internal returns(uint256, uint256) {

        uint256 beforeSwap = IERC20(_outToken).balanceOf(_thisAddr);
        uint256 swapVal = _swapInVal(_inAmount, _inToken, _pair);

        address[] memory path = new address[](2);
        path[0] = _inToken;
        path[1] = _outToken;

        router.swapExactTokensForTokens(swapVal, 0, path, _thisAddr, _swapDeadline());

        uint256 afterSwap = IERC20(_outToken).balanceOf(_thisAddr);
        uint256 swapBack = afterSwap.sub(beforeSwap);

        return (swapBack, swapVal);
    }

    function _swapETHForToken(address _pair, address _outToken, address _thisAddr) internal returns(uint256, uint256) {
        uint256 beforeSwap = IERC20(_outToken).balanceOf(_thisAddr);

        uint256 swapVal = _swapInVal(msg.value, address(weth), _pair);

        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] =  _outToken;

        router.swapExactETHForTokens.value(swapVal)(0, path, _thisAddr, _swapDeadline());

        uint256 afterSwap = IERC20(_outToken).balanceOf(_thisAddr);
        uint256 swapBack = afterSwap.sub(beforeSwap);

        return (swapBack, swapVal);
    }

    function _swapTokenForETH(address _pair, address _inToken, uint256 _inAmount, address _thisAddr) internal returns(uint256, uint256) {
        uint256 beforeSwap = address(this).balance;

        uint256 swapVal = _swapInVal(_inAmount, _inToken, _pair);

        address[] memory path = new address[](2);
        path[0] =  _inToken;
        path[1] =  address(weth);

        uint256[] memory amounts = router.getAmountsOut(swapVal, path);
        router.swapTokensForExactETH(amounts[amounts.length - 1], swapVal, path, _thisAddr, _swapDeadline());

        uint256 afterSwap = address(this).balance;
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

        if(_inToken != ZERO_ADDRESS  && _outToken != ZERO_ADDRESS) {
            IERC20(_inToken).safeTransferFrom(msg.sender, _thisAddr, _amount);
            return _swapToken(_lp, _inToken, _outToken, _amount, _thisAddr);
        } else if(_inToken == ZERO_ADDRESS && _outToken != ZERO_ADDRESS) {
            return _swapETHForToken(_lp, _outToken, _thisAddr);
        } else if(_inToken != ZERO_ADDRESS && _outToken == ZERO_ADDRESS) {
            IERC20(_inToken).safeTransferFrom(msg.sender, _thisAddr, _amount);
            return _swapTokenForETH(_lp, _inToken, _amount, _thisAddr);
        } else {
            revert("eth swap eth not supported");
        }
    }

    function _getLP(
        address _lp,
        address _inToken,
        address _outToken,
        uint256 _inVal,
        uint256 _swapBack,
        address _to) internal returns (uint256) {

        IERC20 lpToken = IERC20(_lp);

        uint256 beforeAddLPAmount = lpToken.balanceOf(_to);

        if(_inToken != ZERO_ADDRESS && _outToken != ZERO_ADDRESS) {
            _addLiquidity(_inToken, _outToken, _inVal, _swapBack, _to);
        } else if(_inToken == ZERO_ADDRESS && _outToken != ZERO_ADDRESS) {
            _addLiquidityETH(_inVal, _outToken, _swapBack, _to);
        } else if(_inToken != ZERO_ADDRESS && _outToken == ZERO_ADDRESS){
            _addLiquidityETH(_swapBack, _inToken, _inVal, _to);
        } else {
            revert("eth for eth not support");
        }

        uint256 afterAddLPAmount = lpToken.balanceOf(_to);

        return afterAddLPAmount.sub(beforeAddLPAmount);
    }


    function _amountOfTokens(address _tokenA, address _tokenB) internal view returns (uint256 amountA, uint256 amountB) {
        if(_tokenA == ZERO_ADDRESS) {
            amountA = address(this).balance;
        } else {
            amountA = IERC20(_tokenA).balanceOf(address(this));
        }

        amountB = IERC20(_tokenB).balanceOf(address(this));

        return (amountA, amountB);
    }

    function _swapLPReturnedToAnotherToken() internal pure {
        revert("not supported yet");
    }

    function _swapLPReturnETHForToken(uint256 _inAmount, address _outToken) internal returns(uint256) {
        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = _outToken;

        router.swapExactETHForTokens.value(_inAmount)(0, path, address(this), _swapDeadline());

        return IERC20(_outToken).balanceOf(address(this));
    }

    function _swapLPReturnTokenForToken(address _inToken, uint256 _inAmount, address _outToken) internal returns(uint256) {
        address[] memory path = new address[](2);
        path[0] = _inToken;
        path[1] = _outToken;

        router.swapExactTokensForTokens(_inAmount, 0, path, address(this), _swapDeadline());
        return IERC20(_outToken).balanceOf(address(this));
    }

    function _swapLPReturnTokenForETH(address _inToken, uint256 _inAmount) internal returns(uint256) {
        address[] memory path = new address[](2);
        path[0] = _inToken;
        path[1] = address(weth);

        router.swapExactTokensForETH(_inAmount, 0, path, address(this), _swapDeadline());
        return address(this).balance;
    }

    function _swapLPReturnedForOneToken(address _inToken, address _outToken, uint256 _inAmount) internal returns(uint256) {

        if(_inToken == ZERO_ADDRESS) {
            return _swapLPReturnETHForToken(_inAmount, _outToken);
        } else {
            if(_outToken == ZERO_ADDRESS) {
                return _swapLPReturnTokenForETH(_inToken, _inAmount);
            } else {
                return _swapLPReturnTokenForToken(_inToken, _inAmount, _outToken);
            }
        }
    }
}
