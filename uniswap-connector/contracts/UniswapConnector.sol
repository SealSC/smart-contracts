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

    constructor(address _owner, address _pools, address _router) public Ownable(_owner) {
        feeBasisPoint = feePrecision.div(10000).mul(400);
        miningPools = IMiningPools(_pools);
        router = IUniswapV2Router02(_router);
    }

    function flashStakingToken(address _lp, address _inToken, uint256 _amount, address _outToken, uint256 _pid) external {
        require(supportedPair[_lp].length == 2, "token not supported");
        address stakingToken = miningPools.getPoolStakingToken(_pid);
        require(stakingToken == _lp, "not the right staking pool");

        address thisAddr = address(this);
        (uint256 swapBack, uint256 swapVal) = _prepareToken(_lp, _inToken, _outToken, _amount, thisAddr);
        uint256 lpAmount = _getLP(_lp, _inToken, _outToken, swapVal, swapBack, thisAddr);

        miningPools.depositByContract(_pid, lpAmount, msg.sender);
    }

    function flashStakingETH(address _lp, address _outToken, uint256 _pid) external payable {
        require(supportedPair[_lp].length == 2, "token not supported");
        address stakingToken = miningPools.getPoolStakingToken(_pid);
        require(stakingToken == _lp, "not the right staking pool");

        address thisAddr = address(this);
        (uint256 swapBack, uint256 swapVal) = _prepareToken(_lp, ZERO_ADDRESS, _outToken, 0, thisAddr);
        uint256 lpAmount = _getLP(_lp, ZERO_ADDRESS, _outToken, swapVal, swapBack, thisAddr);

        miningPools.depositByContract(_pid, lpAmount, msg.sender);
    }

    function () external payable {}
}
