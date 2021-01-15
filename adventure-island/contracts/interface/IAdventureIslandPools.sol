pragma solidity ^0.5.9;

import "../../../contract-libs/open-zeppelin/IERC20.sol";

interface IAdventureIslandPools {
    struct PoolInfo {
        IERC20 stakingToken;
        uint256 pid;
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
}
