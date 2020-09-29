pragma solidity ^0.5.9;

import "../../contract-libs/open-zeppelin/SafeMath.sol";
import "../../contract-libs/open-zeppelin/Ownable.sol";
import "../../contract-libs/open-zeppelin/Address.sol";
import "../../contract-libs/seal-sc/Utils.sol";
import "../../contract-libs/seal-sc/RejectDirectETH.sol";
import "./AdventureIslandViews.sol";
import "./AdventureIslandAdmin/AdventureIslandAdmin.sol";

contract AdventureIsland is Ownable, Mutex, AdventureIslandAdmin, AdventureIslandViews, RejectDirectETH {
    using SafeMath for uint256;
    using Address for address payable;

    constructor(
        address _owner,
        address _admin,
        address _mainRewardToken,
        address _rewardSupplier,
        uint256 _rewardPerBlock,
        bool _checkRewardDecimals,
        uint256 _rewardIntegerPart)
    public Ownable(_owner) {

        mainRewardToken = _mainRewardToken;
        rewardSupplier = IERC20TokenSupplier(_rewardSupplier);
        rewardPerBlock = _rewardPerBlock;

        if(_checkRewardDecimals) {
            IERC20 mainToken = IERC20(_mainRewardToken);
            uint256 noDecimalsReward = _rewardPerBlock.div(10 ** uint256(mainToken.decimals()));
            require(noDecimalsReward == _rewardIntegerPart, "invalid decimals for reward setting");
        }
        admins[_admin] = _admin;
    }

    function depositByContract(uint256 _pid, uint256 _amount, address payable _forUser) public payable noReentrancy {
        require(msg.sender.isContract(), "this interface only for contract call");
        require(!_forUser.isContract(), "reward user must not be a contract");

        UserInfo storage user = users[_pid][_forUser];
        _deposit(_pid, user, _amount);
    }

    function deposit(uint256 _pid, uint256 _amount) public payable noReentrancy {
        require(!msg.sender.isContract(), "this interface only for EOA call");
        UserInfo storage user = users[_pid][msg.sender];
        _deposit(_pid, user, _amount);
    }

    function collect(uint256 _pid, uint256 _withdrawAmount) public noReentrancy {
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

        rewardSupplier.mint(mainRewardToken, msg.sender, userReward);

        user.willCollect = 0;
        user.stakeIn = user.stakeIn.sub(_withdrawAmount);
        user.rewardDebt = user.stakeIn.mul(pool.rewardPerShare).div(precision);

        pool.staked = pool.staked.sub(_withdrawAmount);
    }

    function emergencyWithdrawal(uint256 _pid) external noReentrancy {
        PoolInfo storage pool = pools[_pid];
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
}
