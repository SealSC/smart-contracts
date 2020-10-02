pragma solidity ^0.5.9;

import "./AdventureIslandInternal/AdventureIslandInternal.sol";

contract AdventureIslandViews is AdventureIslandInternal {
    function poolsCount() public view returns(uint256) {
        return pools.length;
    }

    function poolsEnabled() public view returns(bool) {
        return _poolsEnabled();
    }

    function poolWeight(uint256 _pid) public view returns(uint256) {
        PoolInfo storage pool = pools[_pid];

        return pool.weight.mul(COMMON_PRECISION).div(_poolsTotalWeight());
    }

    function toBeCollectedOfPool(uint256 _pid) public view returns(uint256){
        PoolInfo storage pool = pools[_pid];
        if(pool.billingCycle == 0) {
            return 0;
        }

        return _toBeCollected(pool, pool.lastRewardBlock, block.number);
    }

    function toBeCollectedOf(uint256 _pid, address _user) public view returns(uint256) {
        PoolInfo storage pool = pools[_pid];
        UserInfo storage user = users[_pid][_user];

        if(pool.billingCycle == 0) {
            return 0;
        }

        if(user.stakeIn == 0) {
            return 0;
        }

        if(block.number < pool.startBlock) {
            return 0;
        }

        uint256 teBeCollect = _toBeCollected(pool, pool.lastRewardBlock, block.number);
        uint256 rewardPerShare = pool.rewardPerShare.add(teBeCollect.mul(COMMON_PRECISION).div(pool.staked));

        uint256 userReward  = user.willCollect;
        uint256 stillNeed = user.stakeIn.mul(rewardPerShare).div(COMMON_PRECISION).sub(user.rewardDebt);
        userReward = userReward.add(stillNeed);

        return userReward;
    }

    function getPoolStakingToken(uint256 _pid) view external returns(address) {
        return address(pools[_pid].stakingToken);
    }
}
