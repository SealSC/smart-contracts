// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6.0;

import "../../contract-libs/open-zeppelin/SafeMath.sol";
import "../../contract-libs/open-zeppelin/Ownable.sol";
import "../../contract-libs/open-zeppelin/Address.sol";
import "../../contract-libs/seal-sc/Utils.sol";
import "./AdventureIslandViews.sol";
import "./AdventureIslandAdmin/AdventureIslandAdmin.sol";

contract AdventureIsland is Ownable, Mutex, AdventureIslandAdmin, AdventureIslandViews {
    using SafeMath for uint256;
    using Address for address payable;
    using Calculation for uint256;

    constructor(
        address _owner,
        address _admin,
        address _mainRewardToken,
        address _rewardSupplier,
        uint256 _rewardPerBlock,
        bool _checkRewardDecimals,
        uint256 _rewardIntegerPart,
        bool _startNow)
    public Ownable(_owner) {

        mainRewardToken = _mainRewardToken;
        rewardSupplier = IERC20TokenSupplier(_rewardSupplier);
        rewardPerBlock = _rewardPerBlock;

        if(_startNow) {
            globalStartBlock = block.number;
        }

        if(_checkRewardDecimals) {
            IERC20 mainToken = IERC20(_mainRewardToken);
            uint256 noDecimalsReward = _rewardPerBlock.div(10 ** uint256(mainToken.decimals()));
            require(noDecimalsReward == _rewardIntegerPart, "invalid decimals for reward setting");
        }
        admins[_admin] = _admin;
    }

    function stakingByContract(uint256 _pid, uint256 _amount, address payable _forUser) external noReentrancy {
        require(msg.sender.isContract(), "this interface only for contract call");
        require(!_forUser.isContract(), "reward user must not be a contract");

        UserInfo storage user = users[_pid][_forUser];
        _staking(_pid, user, _amount, false);
    }

    function staking(uint256 _pid, uint256 _amount) external noReentrancy {
        require(!msg.sender.isContract(), "this interface only for EOA call");
        UserInfo storage user = users[_pid][msg.sender];
        _staking(_pid, user, _amount, false);
    }

    function collect(
        uint256 _pid,
        uint256 _withdrawAmount,
        bool _flashUnstaking,
        bool _forOneToken,
        address _outToken
    ) public noReentrancy {

        PoolInfo storage pool = allPools[_pid];
        UserInfo storage user = users[_pid][msg.sender];

        require(pool.billingCycle > 0, "no such pool");
        require(user.stakeIn > 0, "not deposit");
        require(user.stakeIn >= _withdrawAmount, "over withdraw");

        (bool valid, string memory info) = _canCollect(pool, user);
        require(valid, info);

        if(_flashUnstaking) {
            _tryFlashUnstaking(pool, user, _forOneToken, _outToken, _withdrawAmount);
        } else {
            _tryWithdraw(pool, user, _withdrawAmount);
        }

        user.lastCollectPosition = block.number.sub(block.number.mod(pool.billingCycle));

        _updatePool(pool);
        uint256 userReward  = user.willCollect;
        uint256 stillNeed = user.stakeIn.mul(pool.rewardPerShare).div(COMMON_PRECISION).sub(user.rewardDebt);
        userReward = userReward.add(stillNeed);

        _mintReward(mainRewardToken, msg.sender, userReward);

        user.willCollect = 0;
        user.stakeIn = user.stakeIn.sub(_withdrawAmount);
        user.rewardDebt = user.stakeIn.mul(pool.rewardPerShare).div(COMMON_PRECISION);

        pool.staked = pool.staked.sub(_withdrawAmount);

        _mintTeamReward(userReward);
    }

    function flashStakingLP(uint256 _pid, uint256 _amount, address _inToken, address _outToken) external payable noReentrancy {
        PoolInfo memory pool = allPools[_pid];
        uint256 fee = _amount.percentageMul(platformFeeBP, BASIS_POINT_PRECISION);
        uint256 inAmount = _amount.sub(fee);
        address lp = address(pool.stakingToken);
        uint256 lpAmount = 0;
        uint256 rewardAmount = 0;
        address rewardBaseToken = _inToken;

        _approveFlashStaking(IERC20(_inToken), IERC20(_outToken), pool.stakingToken);

        if(_inToken == ZERO_ADDRESS) {
            fee = msg.value.percentageMul(platformFeeBP, BASIS_POINT_PRECISION);
            inAmount = msg.value.sub(fee);
            lpAmount = uniConnector.flashGetLP.value(inAmount)(lp, _inToken, inAmount, _outToken);

            rewardBaseToken = address(WETH);

            platformFeeCollected[ZERO_ADDRESS] = platformFeeCollected[ZERO_ADDRESS].add(fee);
        } else {
            IERC20(_inToken).safeTransferFrom(msg.sender, address(this), _amount);
            lpAmount = uniConnector.flashGetLP(lp, _inToken, inAmount, _outToken);
            platformFeeCollected[_inToken] = platformFeeCollected[_inToken].add(fee);
        }

        rewardAmount = _flashStakingReward(rewardBaseToken, inAmount, _getTokenPrice(rewardBaseToken));
        _mintReward(mainRewardToken, msg.sender, rewardAmount);
        UserInfo storage user = users[_pid][msg.sender];
        _staking(_pid, user, lpAmount, true);
    }

    function emergencyWithdrawal(uint256 _pid) external noReentrancy {
        PoolInfo storage pool = allPools[_pid];
        UserInfo storage user = users[_pid][msg.sender];

        require(pool.billingCycle > 0, "no such pool");
        require(user.stakeIn > 0, "not deposit");

        _tryWithdraw(pool, user, user.stakeIn);

        _updatePool(pool);

        user.willCollect = 0;
        pool.staked = pool.staked.sub(user.stakeIn);
        user.stakeIn = 0;
        user.rewardDebt = 0;
        user.lastCollectPosition = block.number;
    }

    function signature() external pure returns (string memory) {
        return "provided by Seal-SC / www.sealsc.com";
    }

    receive() external payable {
        if(!ethPayer[msg.sender]) {
            revert("not from valid payer");
        }
    }
}
