pragma solidity ^0.6.0;

import "remix_tests.sol"; // injected by remix-tests
import "remix_accounts.sol";
import "../../parameterized-erc20/contracts/ParameterizedERC20.sol";
import "../contracts/StakingMining.sol";

contract StakingMiningTest {
    ParameterizedERC20 testToken;

    string constant tokenName = "staking token";
    string constant tokenSymbol = "st";
    uint8 constant testDecimals = 4;
    uint256 constant initSupply = 10000 * (10**4);
    bool constant mintEnabled = true;

    IERC20 public stakingToken;
    IERC20 public rewardToken;

    StakingMining public pool;

    uint256 public rewardBP;

    uint256 testPoolIdx = 0;

    function beforeAll() public {
        stakingToken = IERC20(new ParameterizedERC20(address(this), tokenName, tokenSymbol, testDecimals, mintEnabled, initSupply));
        rewardToken =  IERC20(new ParameterizedERC20(address(this), tokenName, tokenSymbol, testDecimals, mintEnabled, initSupply));

        pool = new StakingMining(address(this), address(rewardToken));

        rewardBP = pool.REWARD_BASE_POINT();

        rewardToken.transfer(address(pool), initSupply);

        Assert.equal(rewardToken.balanceOf(address(this)), 0, "failed: reward token of this contract must be zero");
        Assert.equal(rewardToken.balanceOf(address(pool)), initSupply, "failed: reward token of the pool must equal initSupply");
        Assert.equal(address (pool.rewardToken()), address(rewardToken), "failed: reward token is not correct");

        stakingToken.approve(address (pool), uint256(-1));
    }

    function test_createPool() public {
        uint256 poolCount = pool.poolCount();
        Assert.equal(poolCount, 0, "failed: pool list not empty");
        pool.createPool(address(stakingToken), rewardBP/2);

        poolCount = pool.poolCount();
        Assert.equal(poolCount, 1, "failed: create pool failed");

        (IERC20 sToken, uint256 factor, uint256 closedBlock, bool closedFlag, bool created) = pool.poolList(testPoolIdx);

        Assert.equal(address(sToken), address(stakingToken), "failed: wrong staking token");
        Assert.equal(factor, rewardBP/2, "failed: wrong factor");
        Assert.equal(closedBlock, 0, "failed: already closed");
        Assert.equal(closedFlag, false, "failed: already closed");
        Assert.equal(created, true, "failed: pool not exist");
    }

    function test_stake() public {
        uint256 stakeAmount = 100;
        uint256 beforeBalance = stakingToken.balanceOf(address(this));
        pool.stake(testPoolIdx, stakeAmount);
        uint256 afterBalance = stakingToken.balanceOf(address(this));

        (uint256 staked, uint256 lastCollect) = pool.userStakeInfo(address (this), testPoolIdx);

        Assert.equal(afterBalance, beforeBalance - stakeAmount, "failed: wrong staked amount");
        Assert.equal(staked, 100, "failed: wrong staked amount");
        Assert.equal(lastCollect, block.number, "failed: last collect must be current block");
    }

    function test_collect() public {
        (uint256 staked, uint256 lastCollect) = pool.userStakeInfo(address (this), testPoolIdx);
        (IERC20 sToken, uint256 factor, uint256 closedBlock, bool closedFlag, bool created) = pool.poolList(testPoolIdx);
        uint256 currentBlock = block.number;

        uint256 rewardAmount = (staked * (currentBlock - lastCollect) * factor) / rewardBP;
        uint256 beforeBalance = rewardToken.balanceOf(address(this));
        pool.collect(testPoolIdx, false);
        uint256 afterBalance = rewardToken.balanceOf(address(this));
        (uint256 stakedAfter,) = pool.userStakeInfo(address (this), testPoolIdx);

        Assert.equal(afterBalance, beforeBalance + rewardAmount, "failed: last collect must be current block");
        Assert.equal(staked, stakedAfter, "failed: staked amount was modified");
    }

    function test_collectWithExit() public {
        (uint256 staked, uint256 lastCollect) = pool.userStakeInfo(address (this), testPoolIdx);
        (IERC20 sToken, uint256 factor, uint256 closedBlock, bool closedFlag, bool created) = pool.poolList(testPoolIdx);
        uint256 currentBlock = block.number;

        uint256 rewardAmount = (staked * (currentBlock - lastCollect) * factor) / rewardBP;
        uint256 beforeBalance = rewardToken.balanceOf(address(this));
        pool.collect(testPoolIdx, true);
        uint256 afterBalance = rewardToken.balanceOf(address(this));

        (staked, lastCollect) = pool.userStakeInfo(address (this), testPoolIdx);

        Assert.equal(afterBalance, beforeBalance + rewardAmount, "failed: last collect must be current block");
        Assert.equal(staked, 0, "failed: staked amount not zero");
    }

    function test_closePool() public {
        (IERC20 sToken, uint256 factor, uint256 closedBlock, bool closedFlag, bool created) = pool.poolList(testPoolIdx);
        Assert.equal(closedFlag, false, "failed: pool already closed");
        Assert.equal(created, true, "failed: pool not created");

        pool.closePool(testPoolIdx);

        (,,closedBlock,closedFlag,created) = pool.poolList(testPoolIdx);

        Assert.equal(closedBlock, block.number, "failed: not closed in this block");
        Assert.equal(closedFlag, true, "failed: pool not closed");
        Assert.equal(created, true, "failed: pool not created");


    }
}
