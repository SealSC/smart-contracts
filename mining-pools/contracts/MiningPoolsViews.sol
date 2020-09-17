pragma solidity ^0.5.9;

import "./MiningPoolsInternal.sol";

contract MiningPoolsViews is MiningPoolsInternal {
    function poolsCount() public view returns(uint256) {
        return pools.length;
    }

    function poolsEnabled() public view returns(bool) {
        return _poolsEnabled();
    }

    function totalMined() public view returns(uint256) {
        return _poolsOutput(0, block.number);
    }

    function poolWeight(uint256 _pid) public view returns(uint256) {
        PoolInfo storage pool = pools[_pid];

        return pool.weight.mul(precision).div(_poolsTotalWeight());
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
        uint256 rewardPerShare = pool.rewardPerShare.add(teBeCollect.mul(precision).div(pool.staked));

        uint256 userReward  = user.willCollect;
        uint256 stillNeed = user.stakeIn.mul(rewardPerShare).div(precision).sub(user.rewardDebt);
        userReward = userReward.add(stillNeed);

        return userReward;
    }
}
