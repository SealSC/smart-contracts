pragma solidity ^0.5.9;

import "./AdventureIslandInternal/AdventureIslandInternal.sol";

contract AdventureIslandViews is AdventureIslandInternal {
    function poolsCount() public view returns(uint256) {
        return pools.length;
    }

    function poolsEnabled() public view returns(bool) {
        return _poolsEnabled();
    }

    function getAllPoolToBeCollected() view external returns (uint256[] memory) {
        uint256[] memory rets = new uint256[](pools.length);

        for(uint256 i=0; i<pools.length; i++) {
            rets[i] = toBeCollectedOfPool(i);
        }
        return rets;
    }

    function getToBeCollectListOf(address user) view external returns(uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory) {
        uint256[] memory userReward = new uint256[](pools.length);
        uint256[] memory poolReward = new uint256[](pools.length);
        uint256[] memory userStaked = new uint256[](pools.length);
        uint256[] memory poolStaked = new uint256[](pools.length);

        for(uint256 i=0; i<pools.length; i++) {
            (userReward[i], poolReward[i], userStaked[i], poolStaked[i]) = toBeCollectedOf(i, user);
        }
        return (userReward, poolReward, userStaked, poolStaked);
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

    function toBeCollectedOf(uint256 _pid, address _user) public view returns(uint256, uint256, uint256, uint256) {
        PoolInfo storage pool = pools[_pid];
        UserInfo storage user = users[_pid][_user];

        if(pool.billingCycle == 0) {
            return (0, 0, 0, 0);
        }

        if(block.number < pool.startBlock) {
            return (0, 0, 0, 0);
        }

        uint256 toBeCollect = _toBeCollected(pool, pool.lastRewardBlock, block.number);
        if(user.stakeIn == 0) {
            return (0, toBeCollect, 0, pool.staked);
        }

        uint256 rewardPerShare = pool.rewardPerShare.add(toBeCollect.mul(COMMON_PRECISION).div(pool.staked));

        uint256 userReward  = user.willCollect;
        uint256 stillNeed = user.stakeIn.mul(rewardPerShare).div(COMMON_PRECISION).sub(user.rewardDebt);
        userReward = userReward.add(stillNeed);

        return (userReward, toBeCollect, user.stakeIn, pool.staked);
    }

    function getPoolStakingToken(uint256 _pid) view external returns(address) {
        return address(pools[_pid].stakingToken);
    }
}
