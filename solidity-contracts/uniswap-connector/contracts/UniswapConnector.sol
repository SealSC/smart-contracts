// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6.0;

import "../../contract-libs/open-zeppelin/Ownable.sol";
import "../../contract-libs/open-zeppelin/SafeMath.sol";
import "../../contract-libs/open-zeppelin/Address.sol";
import "../../contract-libs/uniswap/IUniswapV2Router02.sol";
import "../../contract-libs/open-zeppelin/SafeERC20.sol";
import "./UniswapConnectorAdmin.sol";
import "./UniswapConnectorViews.sol";
import "../../contract-libs/seal-sc/Calculation.sol";
import "./interface/IUniswapConnector.sol";

contract UniswapConnector is UniswapConnectorAdmin, UniswapConnectorViews {
    using SafeMath for uint256;
    using Address for address payable;
    using SafeERC20 for IERC20;
    using Calculation for uint256;

    modifier validLP(address _lp) {
        require(supportedPair[_lp].length == 2, "not supported pair");
        _;
    }

    constructor(address _owner, address _newRouter, address _newFactory, address _weth) public Ownable(_owner) {
        router = IUniswapV2Router02(_newRouter);
        factory = IUniswapV2Factory(_newFactory);
        weth = IERC20(_weth);

        weth.safeApprove(address(router), ~uint256(0));
    }

    function flashRemoveLP(
        address _lp,
        address payable _to,
        uint256 _amount,
        bool _externalCall) public validLP(_lp) returns(uint256,  uint256) {

        address tokenA = supportedPair[_lp][0];
        address tokenB = supportedPair[_lp][1];

        IERC20(_lp).safeTransferFrom(msg.sender, address(this), _amount);
        _removeLiquidity(tokenA, tokenB, _amount);
        (uint256 amountA, uint256 amountB) = _amountOfTokens(tokenA, tokenB);

        if(_externalCall) {
            if(tokenA == ZERO_ADDRESS) {
                if(amountA > address(this).balance) {
                    amountA = address(this).balance;
                }
                _to.sendValue(amountA);
            } else {
                if(amountA > IERC20(tokenA).balanceOf(address(this))) {
                    amountA = IERC20(tokenA).balanceOf(address(this));
                }
                IERC20(tokenA).safeTransfer(_to, amountA);
            }

            if(amountB > IERC20(tokenB).balanceOf(address(this))) {
                amountB = IERC20(tokenB).balanceOf(address(this));
            }
            IERC20(tokenB).safeTransfer(_to, amountB);
        }

        return (amountA, amountB);
    }

    function flashRemoveLPForOneToken(address _lp, address _outToken, address payable _to, uint256 _amount) external validLP(_lp) returns(uint256) {
        address tokenA = supportedPair[_lp][0];
        address tokenB = supportedPair[_lp][1];

        (uint256 amountABefore, uint256 amountBBefore) = _amountOfTokens(tokenA, tokenB);
        (uint256 amountAAfter, uint256 amountBAfter) = flashRemoveLP(_lp, address(this), _amount, false);

        uint256 finalOutAmount = 0;
        uint256 outBefore = 0;

        {
            address inToken = tokenA;
            amountAAfter = amountAAfter.sub(amountABefore);
            outBefore = amountBBefore;

            if(_outToken == tokenA) {
                inToken = tokenB;
                amountAAfter = amountBAfter.sub(amountBBefore);
                outBefore = amountABefore;
            }

            finalOutAmount = _swapLPReturnedForOneToken(inToken, _outToken, amountAAfter);
            finalOutAmount = finalOutAmount.sub(outBefore);
        }

        if(_outToken == ZERO_ADDRESS) {
            if(finalOutAmount > address(this).balance) {
                finalOutAmount = address(this).balance;
            }
            _to.sendValue(finalOutAmount);
        } else {
            if(finalOutAmount > IERC20(_outToken).balanceOf(address(this))) {
                finalOutAmount = IERC20(_outToken).balanceOf(address(this));
            }
            IERC20(_outToken).safeTransfer(_to, finalOutAmount);
        }

        return finalOutAmount;
    }

    function flashGetLP(
        address _lp,
        address _inToken,
        uint256 _amount,
        address _outToken) external payable validLP(_lp) returns(uint256)  {

        if(_inToken != ZERO_ADDRESS && _outToken != ZERO_ADDRESS) {
            require(msg.value == 0, "not accept eth in token2token swap");
        }

        address thisAddr = address(this);
        (uint256 swapBack, uint256 swapVal) = _prepareToken(_lp, _inToken, _outToken, _amount, thisAddr);
        return _getLP(_lp, _inToken, _outToken, _amount.sub(swapVal), swapBack, msg.sender);
    }

    function lpToPair(address _lp) view external returns(address, address) {
        if(supportedPair[_lp].length == 0) {
            return (DUMMY_ADDRESS, DUMMY_ADDRESS);
        }

        return (supportedPair[_lp][0], supportedPair[_lp][1]);
    }

    receive () external payable {}
}
