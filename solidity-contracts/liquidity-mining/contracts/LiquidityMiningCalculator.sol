// SPDX-License-Identifier: Apache-2.0
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.0;

import "../../contract-libs/seal-sc/Simple3Role.sol";
import "../../contract-libs/open-zeppelin/SafeERC20.sol";
import "../../parameterized-erc20/contracts/IParameterizedERC20.sol";
import "../../contract-libs/open-zeppelin/SafeMath.sol";
import "./LiquidityMiningData.sol";

contract LiquidityMiningCalculator is LiquidityMiningData {
    using SafeMath for uint256;

    function _rewardOf(uint256 _pid, address _user) internal view returns(uint256) {
        return _rewardOf(poolList[_pid], _user);
    }

    function _rewardPerShareOf(PoolInfo storage _pool) internal view returns(uint256) {
        uint256 poolReward = _rewardOf(_pool, _pool.lastRewardBlock, block.number);
        uint256 rewardPerShare = _pool.rewardPerShare.add(poolReward.mul(COMMON_PRECISION).div(_pool.staked));

        return rewardPerShare;
    }

    function _rewardOf(PoolInfo storage _pool, address _user) internal view returns(uint256) {
        UserInfo memory user = users[_pool.pid][_user];
        if(user.stakeIn == 0) {
            return 0;
        }


        uint256 rewardPerShare = _rewardPerShareOf(_pool);
        uint256 userReward  = user.willCollect;
        uint256 stillNeed = user.stakeIn.mul(rewardPerShare).div(COMMON_PRECISION).sub(user.rewardDebt);
        userReward = userReward.add(stillNeed);

        return userReward;
    }

    function _rewardOf(uint256 _pid) internal view returns(uint256) {
        return _rewardOf(poolList[_pid], poolList[_pid].lastRewardBlock, block.number);
    }

    function _rewardOf(PoolInfo storage _pool, uint256 _start, uint256 _end) internal view returns(uint256) {
        //check global start & reward status
        if(globalStartBlock == 0 || rewardPerBlock == 0) {
            return 0;
        }

        //check pool closed
        if(_pool.closed || _pool.weight == 0) {
            return 0;
        }

        //check pool update
        if(block.number < _pool.lastRewardBlock) {
            return 0;
        }

        //check end block was set
        if(_end > _pool.endBlock && _pool.endBlock != 0) {
            _end = _pool.endBlock;
        }

        //check end block
        if(_end > block.number) {
            _end = block.number;
        }

        //check start block
        if(_start < _pool.lastRewardBlock) {
            _start = _pool.lastRewardBlock;
        }

        //check from to end
        if(_start >= _end) {
            return 0;
        }

        uint256 poolMultiple = _pool.weight.mul(COMMON_PRECISION).div(totalWeight);
        uint256 poolsOutput = _end.sub(_start).mul(rewardPerBlock);

        return poolsOutput.mul(poolMultiple).div(COMMON_PRECISION);
    }

    function _userInfoOf(uint256 _pid, address _user) internal view returns(UserInfo memory user) {
        user = users[_pid][_user];
        return user;
    }

    function _updatePool(PoolInfo storage pool) internal {
        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        if (pool.staked == 0) {
            //enable the following line will reduce the total output of every block when no one stake in this pool
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 toBeCollect = _rewardOf(pool, pool.lastRewardBlock, block.number);
        pool.rewardPerShare = pool.rewardPerShare.add(toBeCollect.mul(COMMON_PRECISION).div(pool.staked));
        pool.lastRewardBlock = block.number;
        if(pool.lastRewardBlock > pool.endBlock && pool.endBlock > 0) {
            pool.lastRewardBlock = pool.endBlock;
        }
    }

    function _updateAllPools() internal {
        for(uint256 i=0; i<poolCount; i++) {
            _updatePool(poolList[i]);
        }
    }

    function _appendPool(PoolInfo memory _pool) internal {
        poolList[poolCount] = _pool;
        validPool[poolCount] = true;
        poolCount = poolCount.add(1);
    }
}
