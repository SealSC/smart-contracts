// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6.0;

import "../../../contract-libs/open-zeppelin/SafeMath.sol";
import "../AdventureIslandData/AdventureIslandData.sol";
import "./AdventureIslandStakingOperations.sol";

contract AdventureIslandPoolInternalOperations is AdventureIslandStakingOperations {
    using SafeMath for uint256;

    function _poolsEnabled() internal view returns(bool) {
        return globalOpen && block.number >= globalStartBlock;
    }

    function _poolsTotalWeight() internal view returns(uint256) {
        uint256 poolCnt = allPoolsCount;
        uint256 totalWeight = 0;

        if(!_poolsEnabled()) {
            return totalWeight;
        }

        for(uint256 i=0; i<poolCnt; i++) {
            if(!validPoolList[i]) {
                continue;
            }

            PoolInfo memory pool = allPools[i];
            if(pool.closed) {
                continue;
            }

            if(block.number > pool.endBlock &&  pool.endBlock != 0) {
                continue;
            }

            if(pool.startBlock > block.number) {
                continue;
            }

            if(pool.staked == 0) {
                continue;
            }

            totalWeight = totalWeight.add(pool.weight);
        }

        return totalWeight;
    }

    function _toBeCollected(PoolInfo storage pool, uint256 from, uint256 to) internal view returns (uint256) {
        if(!_poolsEnabled()) {
            return 0;
        }

        if(pool.closed) {
            return 0;
        }

        if(block.number < pool.lastRewardBlock) {
            return 0;
        }

        if(to > pool.endBlock && pool.endBlock != 0) {
            to = pool.endBlock;
        }

        if(to > block.number) {
            to = block.number;
        }

        if(from < pool.lastRewardBlock) {
            from = pool.lastRewardBlock;
        }

        if(from >= to) {
            return 0;
        }

        uint256 poolMultiple = pool.weight.mul(COMMON_PRECISION).div(_poolsTotalWeight());

        uint256 poolsOutput = to.sub(from).mul(rewardPerBlock);
        if(poolsOutput == 0) {
            return 0;
        }

        return poolsOutput.mul(poolMultiple).div(COMMON_PRECISION);
    }

    function _poolsStatusCheck() internal view returns(bool, string memory) {
        if(block.number < globalStartBlock) {
            return (false, "mining not started");
        }

        if(!globalOpen) {
            return (false, "pools is temporarily closed");
        }

        return (true, "");
    }

    function _canDeposit(PoolInfo storage pool, uint256 _amount) internal view returns(bool, string memory) {
        (bool status, string memory info) = _poolsStatusCheck();
        if(!status) {
            return (status, info);
        }

        if(block.number < pool.startBlock) {
            return (false, "pool is not started");
        }

        if(pool.closed) {
            return (false, "pool closed");
        }

        if(_amount == 0) {
            return (false, "deposit must not be 0");
        }

        if(pool.maxStakeIn > 0) {
            if(pool.staked.add(_amount) > pool.maxStakeIn) {
                return (false, "hard cap touched");
            }
        }

        if(pool.endBlock > 0) {
            if(block.number < pool.startBlock) {
                return (false, "pool not started");
            }

            if(block.number > pool.endBlock) {
                return (false, "mining end");
            }
        }

        return (true, "");
    }

    function _canCollect(PoolInfo storage pool, UserInfo storage user) internal view returns(bool, string memory) {
        (bool status, string memory info) = _poolsStatusCheck();
        if(!status) {
            return (status, info);
        }

        bool isLimitedPool = (pool.endBlock > 0);

        if(block.number < pool.startBlock) {
            return (false, "mining pool is not open");
        }

        if(block.number < user.lastCollectPosition) {
            return (false, "not in collect round");
        }

        uint256 userLastCollect = user.lastCollectPosition;
        if(userLastCollect == 0) {
            userLastCollect = pool.startBlock;
        }

        uint256 fromLast = block.number.sub(user.lastCollectPosition);
        if(fromLast < pool.billingCycle) {
            if(isLimitedPool) {
                if(block.number > pool.endBlock) {
                    return (true, "");
                }
            }
            return (false, "not in collect round");
        }

        return (true, "");
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

        uint256 toBeCollect = _toBeCollected(pool, pool.lastRewardBlock, block.number);
        pool.rewardPerShare = pool.rewardPerShare.add(toBeCollect.mul(COMMON_PRECISION).div(pool.staked));
        pool.lastRewardBlock = block.number;
        if(pool.lastRewardBlock > pool.endBlock && pool.endBlock > 0) {
            pool.lastRewardBlock = pool.endBlock;
        }
    }

    function _updatePools() internal {
        if(block.number < globalStartBlock) {
            return;
        }

        for(uint256 i=0; i<allPoolsCount; i++) {
            if(!validPoolList[i]) {
                continue;
            }

            PoolInfo storage pool = allPools[i];
            if(pool.closed || block.number < pool.startBlock) {
                continue;
            }

            _updatePool(pool);
        }
    }


    function _staking(uint256 pid, UserInfo storage user, uint256 amount, bool isFlashStaking) internal {
        PoolInfo storage pool = allPools[pid];
        require(pool.billingCycle > 0, "no such pool");
        require(!pool.closed, "closed pool");
        require(address(pool.stakingToken) != DUMMY_ADDRESS, "stake token not set");

        (bool valid, string memory errInfo) = _canDeposit(pool, amount);
        require(valid, errInfo);

        if(ZERO_ADDRESS != address(pool.stakingToken) && !isFlashStaking) {
            pool.stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        }

        _updatePool(pool);
        if (user.stakeIn > 0) {
            uint256 willCollect = user.stakeIn.mul(pool.rewardPerShare).div(COMMON_PRECISION).sub(user.rewardDebt);
            user.willCollect = user.willCollect.add(willCollect);
        }

        if(user.lastCollectPosition == 0) {
            user.lastCollectPosition = block.number;
        }
        pool.staked = pool.staked.add(amount);
        user.stakeIn = user.stakeIn.add(amount);
        user.rewardDebt = user.stakeIn.mul(pool.rewardPerShare).div(COMMON_PRECISION);
    }

    function _tryWithdraw(PoolInfo storage pool, UserInfo storage user, uint256 _amount) internal {
        if(user.stakeIn < _amount) {
            return;
        }

        if(_amount == 0) {
            return;
        }

        if(address(0) == address(pool.stakingToken)) {
            msg.sender.sendValue(_amount);
        } else {
            pool.stakingToken.safeTransfer(msg.sender, _amount);
        }
    }
}
