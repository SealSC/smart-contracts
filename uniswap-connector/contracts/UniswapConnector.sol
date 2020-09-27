pragma solidity ^0.5.9;

import "../../contract-libs/open-zeppelin/Ownable.sol";
import "../../contract-libs/open-zeppelin/SafeMath.sol";
import "../../contract-libs/open-zeppelin/Address.sol";
import "../../contract-libs/uniswap/IUniswapV2Router02.sol";
import "../../mining-pools/contracts/interface/IMiningPools.sol";
import "../../contract-libs/open-zeppelin/SafeERC20.sol";
import "./UniswapConnectorAdmin.sol";
import "./UniswapConnectorViews.sol";

contract UniswapConnector is UniswapConnectorAdmin, UniswapConnectorViews {
    using SafeMath for uint256;
    using Address for address payable;
    using SafeERC20 for IERC20;

    modifier validLP(address _lp) {
        require(supportedPair[_lp].length == 2, "not supported pair");
        _;
    }

    constructor(address _owner, address _pools, address _router) public Ownable(_owner) {
        feeBasisPoint = feePrecision.div(10000).mul(400);
        miningPools = IMiningPools(_pools);
        router = IUniswapV2Router02(_router);
    }

    function flashRemoveLP(address _lp, address _to, uint256 _amount) public validLP(_lp) {
        address tokenA = supportedPair[_lp][0];
        address tokenB = supportedPair[_lp][1];

        IERC20(_lp).safeTransferFrom(msg.sender, address(this), _amount);
        _removeLiquidity(tokenA, tokenB, _amount, _to);
    }

    function flashRemoveLPForOneToken(address _lp, address _outToken, address payable _to, uint256 _amount) external validLP(_lp) {
        address tokenA = supportedPair[_lp][0];
        address tokenB = supportedPair[_lp][1];

        (uint256 amountABefore, uint256 amountBBefore) = _amountOfTokens(tokenA, tokenB);
        flashRemoveLP(_lp, address(this), _amount);
        (uint256 amountAAfter, uint256 amountBAfter) = _amountOfTokens(tokenA, tokenB);

        uint256 finalOutAmount = 0;
        uint256 outBefore = 0;

        if(_outToken != tokenA && _outToken  != tokenB) {
            _swapLPReturnedToAnotherToken();
        } else {
            address inToken = tokenA;
            uint256 inAmount = amountAAfter.sub(amountABefore);
            outBefore = amountBBefore;

            if(_outToken == tokenA) {
                inToken = tokenB;
                inAmount = amountBAfter.sub(amountBBefore);
                outBefore = amountABefore;
            }

            finalOutAmount = _swapLPReturnedForOneToken(inToken, _outToken, inAmount);
            finalOutAmount = finalOutAmount.sub(outBefore);
        }

        if(_outToken == ZERO_ADDRESS) {
            _to.sendValue(finalOutAmount);
        } else {
            IERC20(_outToken).safeTransfer(_to, finalOutAmount);
        }
    }

    function flashGetLP(address _lp, address _inToken, uint256 _amount, address _outToken) public validLP(_lp) returns(uint256)  {
        if(_inToken == ZERO_ADDRESS) {
            address thisAddr = address(this);
            (uint256 swapBack, uint256 swapVal) = _prepareToken(_lp, ZERO_ADDRESS, _outToken, 0, thisAddr);
            return _getLP(_lp, ZERO_ADDRESS, _outToken, swapVal, swapBack, thisAddr);
        } else {
            address thisAddr = address(this);
            (uint256 swapBack, uint256 swapVal) = _prepareToken(_lp, _inToken, _outToken, _amount, thisAddr);
            return _getLP(_lp, _inToken, _outToken, swapVal, swapBack, thisAddr);
        }
    }

    function flashStakingToken(address _lp, address _inToken, uint256 _amount, address _outToken, uint256 _pid) external {
        address stakingToken = miningPools.getPoolStakingToken(_pid);
        require(stakingToken == _lp, "not the right staking pool");

        uint256 lpAmount = flashGetLP(_lp, _inToken, _amount, _outToken);
        miningPools.depositByContract(_pid, lpAmount, msg.sender);
    }

    function flashStakingETH(address _lp, address _outToken, uint256 _pid) external payable validLP(_lp) {
        address stakingToken = miningPools.getPoolStakingToken(_pid);
        require(stakingToken == _lp, "not the right staking pool");

        uint256 lpAmount = flashGetLP(_lp, ZERO_ADDRESS, 0, _outToken);
        miningPools.depositByContract(_pid, lpAmount, msg.sender);
    }

    function () external payable {}
}
