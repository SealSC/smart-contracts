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

    function depositByContract(uint256 _pid, uint256 _amount, address _forUser) public payable {
        require(msg.sender.isContract(), "this interface only for contract call");
        UserInfo storage user = users[_pid][_forUser];
        _deposit(_pid, user, _amount);
    }

    function deposit(uint256 _pid, uint256 _amount) public payable {
        require(!msg.sender.isContract(), "this interface only for EOA call");
        UserInfo storage user = users[_pid][msg.sender];
        _deposit(_pid, user, _amount);
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
