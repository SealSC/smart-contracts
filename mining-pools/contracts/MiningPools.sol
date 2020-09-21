pragma solidity ^0.5.9;

import "./SafeMath.sol";
import "./IMigrator.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./IMineableToken.sol";
import "./MiningPoolsAdmin.sol";
import "./MiningPoolsMigratable.sol";
import "./MiningPoolsViews.sol";

contract MiningPools is Ownable, MiningPoolsAdmin, MiningPoolsMigratable, MiningPoolsViews {
    using SafeMath for uint256;
    using Address for address payable;

    constructor(
        address _owner,
        address _admin,
        address _token,
        uint256 _rewardPerBlock,
        bool _checkRewardDecimals,
        uint256 _rewardIntegerPart)
    public Ownable(_owner) {

        rewardToken = IMineableToken(_token);
        rewardPerBlock = _rewardPerBlock;

        if(_checkRewardDecimals) {
            uint256 noDecimalsReward = _rewardPerBlock.div(10 ** uint256(rewardToken.decimals()));
            require(noDecimalsReward == _rewardIntegerPart, "invalid decimals for reward setting");
        }
        administrators[_admin] = _admin;
    }

    function deposit(uint256 _pid, uint256 _amount) public payable {
        PoolInfo storage pool = pools[_pid];
        UserInfo storage user = users[_pid][msg.sender];

        require(pool.billingCycle > 0, "no such pool");
        require(!pool.closed, "closed pool");
        require(address(pool.stakingToken) != INIT_ADDRESS, "stake token not set");

        if(address(0) == address(pool.stakingToken)) {
            _amount = msg.value;
        }

        (bool valid, string memory errInfo) = _canDeposit(pool, _amount);
        require(valid, errInfo);

        if(address(0) != address(pool.stakingToken)) {
            pool.stakingToken.transferFrom(msg.sender, address(this), _amount);
        }

        _updatePool(pool);
        if (user.stakeIn > 0) {
            uint256 willCollect = user.stakeIn.mul(pool.rewardPerShare).div(precision).sub(user.rewardDebt);
            user.willCollect = user.willCollect.add(willCollect);
        }
        pool.staked = pool.staked.add(_amount);
        user.stakeIn = user.stakeIn.add(_amount);
        user.rewardDebt = user.stakeIn.mul(pool.rewardPerShare).div(precision);
    }

    function collect(uint256 _pid, uint256 _withdrawAmount) public {
        PoolInfo storage pool = pools[_pid];
        UserInfo storage user = users[_pid][msg.sender];

        require(pool.billingCycle > 0, "no such pool");
        require(user.stakeIn > 0, "not deposit");
        require(user.stakeIn >= _withdrawAmount, "over withdraw");


        (bool valid, string memory info) = _canCollect(pool, user);
        require(valid, info);

        _tryWithdraw(pool, user, _withdrawAmount);

        user.lastCollectPosition = block.number.sub(block.number.mod(pool.billingCycle));

        _updatePool(pool);
        uint256 userReward  = user.willCollect;
        uint256 stillNeed = user.stakeIn.mul(pool.rewardPerShare).div(precision).sub(user.rewardDebt);
        userReward = userReward.add(stillNeed);
        rewardToken.mint(msg.sender, userReward);

        user.willCollect = 0;
        user.stakeIn = user.stakeIn.sub(_withdrawAmount);
        user.rewardDebt = user.stakeIn.mul(pool.rewardPerShare).div(precision);

        pool.staked = pool.staked.sub(_withdrawAmount);
    }

    function signature() external pure returns (string memory) {
        return "provided by Seal-SC / www.sealsc.com";
    }

    function() external {
        revert("refuse to directly transfer ETH");
    }
}
