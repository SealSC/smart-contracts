// SPDX-License-Identifier: Apache-2.0
pragma experimental ABIEncoderV2;

import "../../contract-libs/open-zeppelin/Ownable.sol";
import "../../contract-libs/open-zeppelin/IERC20.sol";
import "../../contract-libs/open-zeppelin/SafeERC20.sol";
pragma solidity ^0.6.0;

interface stakingEvent {
    event PoolCreated(address indexed stakingToken, uint256 indexed pid, uint256 rewardFactor);
    event PoolClosed(uint256 indexed pid, uint256 indexed timestamp);
    event UserStaked(address indexed user, uint256 indexed pid, uint256 amount);
    event UserCollect(address indexed user, uint256 indexed pid, uint256 amount);
    event UserExit(address indexed user, uint256 indexed pid, uint256 withdrawAmount);

}

contract StakingMining is stakingEvent, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct pool {
        IERC20 stakingToken;
        uint256 rewardFactor;
        uint256 closedBlock;
        bool    closedFlag;
        bool    created;
    }

    struct stakeInfo {
        uint256 stakedAmount;
        uint256 lastCollectBlock;
    }

    IERC20 public rewardToken;

    uint256 public REWARD_BASE_POINT = 1e18;
    pool[] public poolList;
    mapping(address=>mapping(uint256=>stakeInfo)) public userStakeInfo;

    constructor(address _owner, address _rewardToken) public Ownable(_owner) {
        rewardToken = IERC20(_rewardToken);
    }

    function createPool(address _stakingToken, uint256 _rewardFactor) external onlyOwner {
        emit PoolCreated(_stakingToken, poolList.length, _rewardFactor);

        poolList.push(pool({
            stakingToken: IERC20(_stakingToken),
            rewardFactor: _rewardFactor,
            closedBlock: 0,
            closedFlag: false,
            created: true
        }));
    }

    function closePool(uint256 _pid) external onlyOwner {
        require(poolList[_pid].created, "pool not exist");
        require(!poolList[_pid].closedFlag, "closed already");

        poolList[_pid].closedBlock = block.number;
        poolList[_pid].closedFlag = true;

        emit PoolClosed(_pid, block.timestamp);
    }

    function stake(uint256 _pid, uint256 _amount) external {
        require(poolList[_pid].created, "pool not exist");
        require(!poolList[_pid].closedFlag, "closed already");

        stakeInfo storage userStaked = userStakeInfo[msg.sender][_pid];

        collect(_pid, false);

        poolList[_pid].stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        userStaked.stakedAmount = userStaked.stakedAmount + _amount;

        emit UserStaked(msg.sender, _pid, _amount);
    }

    function collect(uint256 _pid, bool _exitFlag) public {
        require(poolList[_pid].created, "pool not created");
        address user = msg.sender;
        stakeInfo storage userStaked = userStakeInfo[user][_pid];

        uint256 lastCollectBlock = userStaked.lastCollectBlock;
        uint256 currentBlock = block.number;

        if(poolList[_pid].closedFlag) {
            if(currentBlock > poolList[_pid].closedBlock) {
                currentBlock = poolList[_pid].closedBlock;
            }
        }

        require(currentBlock > lastCollectBlock, "no reward in time");

        uint256 rewardAmount = userStaked.stakedAmount.mul(currentBlock.sub(lastCollectBlock)).mul(poolList[_pid].rewardFactor).div(REWARD_BASE_POINT);

        rewardToken.safeTransfer(user, rewardAmount);
        emit UserCollect(user, _pid, rewardAmount);

        if(_exitFlag) {
            emit UserExit(user, _pid, userStaked.stakedAmount);

            poolList[_pid].stakingToken.safeTransfer(user, userStaked.stakedAmount);
            userStaked.stakedAmount = 0;
        }

        userStaked.lastCollectBlock = currentBlock;
    }

    function poolCount() view external returns(uint256 count) {
        return poolList.length;
    }
}
