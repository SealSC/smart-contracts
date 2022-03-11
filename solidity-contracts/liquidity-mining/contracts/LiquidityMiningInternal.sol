// SPDX-License-Identifier: Apache-2.0
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.0;

import "../../contract-libs/seal-sc/Simple3Role.sol";
import "../../contract-libs/open-zeppelin/SafeERC20.sol";
import "../../parameterized-erc20/contracts/IParameterizedERC20.sol";
import "../../contract-libs/open-zeppelin/SafeMath.sol";
import "./LiquidityMiningCalculator.sol";

contract LiquidityMiningInternal is LiquidityMiningCalculator {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    function _collect(uint256 _pid, address _user) internal {
        UserInfo storage user = users[_pid][_user];
        PoolInfo storage pool = poolList[_pid];

        _updatePool(pool);

        uint256 amount = _rewardOf(pool, _user);
        if(amount == 0) {
            return;
        }

        user.willCollect = 0;
        user.rewardDebt = user.stakeIn.mul(pool.rewardPerShare).div(COMMON_PRECISION);
        user.lastCollectPosition = block.number;

        mainRewardToken.mint(_user, amount);
    }

    function _withdraw(uint256 _pid, address _user, uint256 _amount) internal {
        UserInfo storage user = users[_pid][_user];
        PoolInfo storage pool = poolList[_pid];

        if(user.stakeIn == 0) {
            revert("withdraw: not staked");
        }

        if(user.stakeIn < _amount) {
            revert("withdraw: too greed");
        }

        pool.stakingToken.safeTransfer(_user, _amount);
        pool.staked = pool.staked.sub(_amount);
        user.stakeIn = user.stakeIn.sub(_amount);
    }

    function _stake(uint256 _pid, uint256 _amount, address _user, address _payer) internal {
        UserInfo storage user = users[_pid][_user];
        PoolInfo storage pool = poolList[_pid];

        _updatePool(pool);
        pool.stakingToken.safeTransferFrom(_payer, selfAddr, _amount);

        if (user.stakeIn > 0) {
            uint256 willCollect = user.stakeIn.mul(pool.rewardPerShare).div(COMMON_PRECISION).sub(user.rewardDebt);
            user.willCollect = user.willCollect.add(willCollect);
        }

        if(user.lastCollectPosition == 0) {
            user.lastCollectPosition = block.number;
        }

        pool.staked = pool.staked.add(_amount);
        user.stakeIn = user.stakeIn.add(_amount);
        user.willCollect = user.willCollect.add(_rewardOf(pool, _user));
        user.rewardDebt = user.stakeIn.mul(pool.rewardPerShare).div(COMMON_PRECISION);
    }
}
