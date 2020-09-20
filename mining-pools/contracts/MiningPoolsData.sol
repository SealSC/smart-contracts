pragma solidity ^0.5.6;

import "./IERC20.sol";
import "./IMineableToken.sol";
import "./IMigrator.sol";

contract MiningPoolsData {
    struct PoolInfo {
        IERC20 stakingToken;
        uint256 startBlock;
        uint256 endBlock;
        uint256 billingCycle;
        uint256 weight;
        uint256 staked;
        uint256 lastRewardBlock;
        uint256 rewardPerShare;
        uint256 minStakeIn;
        uint256 maxStakeIn;
        bool closed;
    }

    struct UserInfo {
        uint256 stakeIn;
        uint256 rewardDebt;
        uint256 willCollect;
        uint256 lastCollectPosition;
    }

    PoolInfo[] public pools;
    mapping (uint256=>mapping(address=>UserInfo)) public users;

    IMineableToken public rewardToken;
    uint256 public rewardPerBlock;
    uint256 public minRewardPerBlock;

    uint256 public rewardCap;
    uint256 public collectedReward;

    mapping(uint256=>bool) public closedPool;

    uint256 public precision = 1e18;

    address public team;
    uint256 public lastTotalSupplyWithoutTeam;
    uint256 public teamRewarded;
    bool public teamRewardPermanentlyDisabled = false;

    bool public globalOpen = true;
    uint256 public globalStartBlock  = ~uint256(0);

    bool public rewardDecreasable;
    uint256 public rewardDecreaseBegin;
    uint256 public rewardDecreaseStep;
    uint256 public rewardDecreaseUnit;

    address constant INIT_ADDRESS = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;
}
