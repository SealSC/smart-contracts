pragma solidity ^0.5.9;

import "../../../contract-libs/open-zeppelin/SafeMath.sol";
import "../../../contract-libs/open-zeppelin/Address.sol";
import "../../../contract-libs/open-zeppelin/SafeERC20.sol";
import "../AdventureIslandData/AdventureIslandData.sol";
import "../../../contract-libs/seal-sc/Calculation.sol";

contract AdventureIslandInternal is AdventureIslandData {
    using SafeMath for uint256;
    using Address for address payable;
    using SafeERC20 for IERC20;
    using Calculation for uint256;

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

            if(pool.staked == 0) {
                continue;
            }

            totalWeight = totalWeight.add(pool.weight);
        }

        return totalWeight;
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

    function _chargeFlashUnstakingFee(
        address _tokenA,
        uint256 _amountA,
        address _tokenB,
        uint256 _amountB) internal returns(uint256 amountA, uint256 amountB) {
        uint256 feeBP = platformFeeBP;
        if(_amountB != 0) {
            feeBP = feeBP.div(2);
        }

        uint256 feeA = _amountA.percentageMul(platformFeeBP, BASIS_POINT_PRECISION);
        uint256 feeB = _amountB.percentageMul(platformFeeBP, BASIS_POINT_PRECISION);

        platformFeeCollected[_tokenA] = platformFeeCollected[_tokenA].add(feeA);
        platformFeeCollected[_tokenB] = platformFeeCollected[_tokenA].add(feeB);

        amountA = _amountA.sub(feeA);
        amountB = _amountB.sub(feeB);

        return (amountA, amountB);
    }

    function _getTokenPrice(address _token) view public returns(uint256) {
        if(_token == address(USDT)) {
            return USDT_PRECISION;
        }
        address[] memory path = new address[](2);
        path[0] = address(_token);
        path[1] = address(USDT);

        uint256 oneToken = 1 * (10 ** uint256(IERC20(_token).decimals()));

        uint256[] memory price = UNI_V2_ROUTER.getAmountsOut(oneToken, path);
        return price[1];
    }

    function _flashStakingReward(address _forToken, uint256 _amount, uint256 _price) view internal returns(uint256) {
        uint256 tokenDecimals = 10 ** uint256(IERC20(_forToken).decimals());
        uint256 rewardTokenDecimals = 10 ** uint256(IERC20(mainRewardToken).decimals());
        if(tokenDecimals > rewardTokenDecimals) {
            _amount = _amount.mul(tokenDecimals.div(rewardTokenDecimals));
        } else if(tokenDecimals < rewardTokenDecimals) {
            _amount = _amount.mul(rewardTokenDecimals.div(tokenDecimals));
        }

        return _price.mul(_amount).percentageMul(flashStakingRewardBP, BASIS_POINT_PRECISION).div(USDT_PRECISION);
    }

    function _approveConnector(IERC20 _lp) internal {
        uint256 approved = _lp.allowance(address(this), address(uniConnector));
        if(approved == 0) {
            _lp.approve(address(uniConnector), MAX_UINT256);
        }
    }

    function _tryFlashUnstaking(
        PoolInfo storage pool,
        UserInfo storage user,
        bool _forOneToken,
        address _outToken,
        uint256 _amount) internal returns(uint256) {

        if(user.stakeIn < _amount) {
            return 0;
        }

        if(_amount == 0) {
            return 0;
        }

        (address tokenA, address tokenB) = uniConnector.lpToPair(address(pool.stakingToken));
        if(tokenA == DUMMY_ADDRESS) {
            return 0;
        }

        _approveConnector(pool.stakingToken);

        uint256 amountA;
        uint256 amountB;

        uint256 rewardAmount = 0;
        if(_forOneToken)  {
            amountA = uniConnector.flashRemoveLPForOneToken(address(pool.stakingToken), _outToken, address(uint160(address(this))), _amount);

            //make sure amountB using for token amount
            if(_outToken != ZERO_ADDRESS) {
                amountB = amountA;
                amountA = 0;
            }
        } else {
            (amountA, amountB) = uniConnector.flashRemoveLP(address(pool.stakingToken), address(uint160(address(this))), _amount, true);
        }

        (amountA, amountB) = _chargeFlashUnstakingFee(tokenA, amountA, tokenB, amountB);

        if(amountA > 0) {
            if(tokenA == ZERO_ADDRESS) {
                msg.sender.sendValue(amountA);
                rewardAmount = _flashStakingReward(address(WETH), amountA, _getTokenPrice(address(WETH)));
            } else {
                IERC20(tokenA).safeTransfer(msg.sender, amountA);
                rewardAmount = _flashStakingReward(tokenA, amountA, _getTokenPrice(tokenA));
            }
        }

        if(amountB > 0) {
            IERC20(tokenB).safeTransfer(msg.sender, amountB);
            uint256 rewardOfB = _flashStakingReward(tokenB, amountB, _getTokenPrice(_outToken));
            rewardAmount = rewardAmount.add(rewardOfB);
        }

        rewardSupplier.mint(mainRewardToken, msg.sender, rewardAmount);
        return rewardAmount;
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
        pool.rewardPerShare = pool.rewardPerShare.add(teBeCollect.mul(COMMON_PRECISION).div(pool.staked));
        pool.lastRewardBlock = block.number;
        if(pool.lastRewardBlock > pool.endBlock && pool.endBlock > 0) {
            pool.lastRewardBlock = pool.endBlock;
        }
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

    function _staking(uint256 pid, UserInfo storage user, uint256 amount, bool isFlashStaking) internal {
        PoolInfo storage pool = pools[pid];
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

    function _mintTeamReward(uint256 _amount) internal {
        if(team != ZERO_ADDRESS && !teamRewardPermanentlyDisabled) {
            return;
        }
        rewardSupplier.mint(mainRewardToken, team, _amount.percentageMul(teamRewardBP, BASIS_POINT_PRECISION));
    }
}
