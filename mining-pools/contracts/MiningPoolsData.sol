pragma solidity ^0.5.6;

import "./IMineableToken.sol";
import "./IMigrator.sol";
import "./IMiningPools.sol";
import "./IERC20TokenSupplier.sol";

contract MiningPoolsData is IMiningPools {
    PoolInfo[] public pools;
    mapping (uint256=>mapping(address=>UserInfo)) public users;

    IMineableToken public rewardToken;
    IERC20TokenSupplier public rewardSupplier;

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
