pragma solidity ^0.5.9;

import "../../../contract-libs/open-zeppelin/IERC20.sol";

interface IAdventureIsland {
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

    function stakingByContract(uint256 _pid, uint256 _amount, address payable _forUser) external;
    function staking(uint256 _pid, uint256 _amount) external;
    function collect(uint256 _pid, uint256 _withdrawAmount, bool _flashUnstaking, bool _forOneToken, address _outToken) external;

    function getPoolStakingToken(uint256 _pid) view external returns(address);
}
