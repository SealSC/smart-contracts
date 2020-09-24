pragma solidity ^0.5.9;

import "../../contract-libs/open-zeppelin/IERC20.sol";

interface IMiningPools {
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

    function depositByContract(uint256 _pid, uint256 _amount, address payable _forUser) external payable;
    function deposit(uint256 _pid, uint256 _amount) external payable;
    function collect(uint256 _pid, uint256 _withdrawAmount) external;

    function getPoolStakingToken(uint256 _pid) view external returns(address);
}
