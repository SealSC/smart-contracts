pragma solidity ^0.5.9;

import "./SafeMath.sol";
import "./Address.sol";
import "./MiningPoolsData.sol";

contract MiningPoolsInternal is MiningPoolsData {
    using SafeMath for uint256;
    using Address for address payable;

    function _poolsEnabled() internal view returns(bool) {
        return globalOpen && block.number >= globalStartBlock;
    }

    function _poolsTotalWeight() public view returns(uint256) {
        uint256 poolCnt = pools.length;
        uint256 totalWeight = 0;

        if(!_poolsEnabled()) {
            return totalWeight;
        }

        for(uint256 i=0; i<poolCnt; i++) {
            PoolInfo memory pool = pools[i];
            if(pool.closed) {
                continue;
            }

            if(block.number > pool.endBlock &&  pool.endBlock != 0) {
                continue;
            }

            if(pool.startBlock > block.number) {
                continue;
            }

            totalWeight = totalWeight.add(pool.weight);
        }

        return totalWeight;
    }

    function _decreasedRewards(uint256 from, uint256 to) internal view returns(uint256) {
        if(!rewardDecreasable) {
            return 0;
        }

        if(to < rewardDecreaseBegin) {
            return 0;
        }

        if(to <= from) {
            return 0;
        }

        uint256 decreaseBegin = 0;
        uint256 totalDecreased = 0;

        uint256 maxDiff = rewardPerBlock.sub(minRewardPerBlock);
        uint256 maxDecreaseSteps = rewardPerBlock.sub(minRewardPerBlock).div(rewardDecreaseUnit);
        uint256 targetEnd = to.sub(rewardDecreaseBegin).div(rewardDecreaseStep);

        if(from > rewardDecreaseBegin) {
            decreaseBegin = from.sub(rewardDecreaseBegin).div(rewardDecreaseStep);
        }

        if(decreaseBegin >= maxDecreaseSteps) {
            totalDecreased = maxDiff.mul(maxDecreaseSteps.add(1)).div(2);
            return totalDecreased;
        }

        if(targetEnd > maxDecreaseSteps) {
            totalDecreased = maxDiff.mul(targetEnd.sub(maxDecreaseSteps).mul(rewardDecreaseStep));
            targetEnd = maxDecreaseSteps;
        }

        uint256 decreaseCount = targetEnd.sub(decreaseBegin);

        uint256 endReward = decreaseCount.mul(rewardDecreaseUnit);
        uint256 beginReward = decreaseBegin.mul(rewardDecreaseUnit);
        uint256 currentDecreased = endReward.add(beginReward).mul(decreaseCount.add(1)).div(2);

        return totalDecreased.add(currentDecreased);
    }

    function _tryWithdraw(PoolInfo storage pool, UserInfo storage user, uint256 _amount) internal {
        if(user.stakeIn < _amount) {
            return;
        }
        if(_amount > 0) {
            if(address(0) == address(pool.stakingToken)) {
                msg.sender.sendValue(_amount);
            } else {
                pool.stakingToken.transfer(msg.sender, _amount);
            }
        }
    }

    function _poolsOutput(uint256 from, uint256 to) internal view returns(uint256){
        if(from  < globalStartBlock) {
            from = globalStartBlock;
        }

        uint256 averReward = rewardPerBlock;

        uint256 alreadyDecreased = _decreasedRewards(globalStartBlock, from);
        uint256 decreased = _decreasedRewards(from, to);

        uint256 output = to.sub(from).mul(averReward);
        uint256 alreadyOutput = from.sub(globalStartBlock).mul(averReward);

        alreadyOutput = alreadyOutput.sub(alreadyDecreased);
        output = output.sub(decreased);

        if(rewardCap > 0) {
            if(alreadyOutput > rewardCap) {
                return 0;
            }

            if(output.add(alreadyOutput) > rewardCap) {
                output = rewardCap.sub(alreadyOutput);
            }
        }

        return output;
    }

    function _toBeCollected(PoolInfo storage pool, uint256 from, uint256 to) internal view returns (uint256) {
        if(!_poolsEnabled()) {
            return 0;
        }

        if(pool.closed) {
            return 0;
        }

        if(to > pool.endBlock && pool.endBlock != 0) {
            to = pool.endBlock;
        }

        if(block.number < pool.lastRewardBlock) {
            return 0;
        }

        if(to > block.number) {
            return 0;
        }

        if(from < pool.lastRewardBlock) {
            from = pool.lastRewardBlock;
        }

        uint256 poolMultiple = precision;
        poolMultiple = pool.weight.mul(precision).div(_poolsTotalWeight());

        uint256 poolsOutput = _poolsOutput(from, to);
        if(poolsOutput == 0) {
            return 0;
        }

        return poolsOutput.mul(poolMultiple).div(precision);
    }

    function _canDeposit(PoolInfo storage pool, uint256 _amount) internal view returns(bool, string memory) {
        (bool status, string memory info) = _poolsStatusCheck();
        if(!status) {
            return (status, info);
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

    function _poolsStatusCheck() internal view returns(bool, string memory) {
        if(block.number < globalStartBlock) {
            return (false, "mining not started");
        }

        if(!globalOpen) {
            return (false, "pools is temporarily closed");
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

        uint256 teBeCollect = _toBeCollected(pool, pool.lastRewardBlock, block.number);
        pool.rewardPerShare = pool.rewardPerShare.add(teBeCollect.mul(precision).div(pool.staked));
        pool.lastRewardBlock = block.number;
    }

    function _updatePools() internal {
        uint256 poolLen = pools.length;
        if(block.number < globalStartBlock) {
            return;
        }

        for(uint256 i=0; i<poolLen; i++) {
            PoolInfo storage pool = pools[i];
            if(pool.closed || block.number < pool.startBlock) {
                continue;
            }

            _updatePool(pool);
        }
    }

    function _deposit(uint256 pid, UserInfo storage user, uint256 amount) internal {
        PoolInfo storage pool = pools[pid];
        require(pool.billingCycle > 0, "no such pool");
        require(!pool.closed, "closed pool");
        require(address(pool.stakingToken) != INIT_ADDRESS, "stake token not set");

        if(address(0) == address(pool.stakingToken)) {
            amount = msg.value;
        } else {
            require(msg.value != 0, "erc20 token staking not accept ETH in.");
        }

        (bool valid, string memory errInfo) = _canDeposit(pool, amount);
        require(valid, errInfo);

        if(address(0) != address(pool.stakingToken)) {
            pool.stakingToken.transferFrom(msg.sender, address(this), amount);
        }

        _updatePool(pool);
        if (user.stakeIn > 0) {
            uint256 willCollect = user.stakeIn.mul(pool.rewardPerShare).div(precision).sub(user.rewardDebt);
            user.willCollect = user.willCollect.add(willCollect);
        }
        pool.staked = pool.staked.add(amount);
        user.stakeIn = user.stakeIn.add(amount);
        user.rewardDebt = user.stakeIn.mul(pool.rewardPerShare).div(precision);
    }
}
