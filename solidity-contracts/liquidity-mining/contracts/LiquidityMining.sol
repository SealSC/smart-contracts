// SPDX-License-Identifier: Apache-2.0
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.0;

import "../../contract-libs/seal-sc/Simple3Role.sol";
import "../../contract-libs/open-zeppelin/SafeERC20.sol";
import "../../parameterized-erc20/contracts/IParameterizedERC20.sol";
import "../../contract-libs/open-zeppelin/SafeMath.sol";
import "./LiquidityMiningInternal.sol";
import "./LiquidityMiningViews.sol";

contract LiquidityMining is Simple3Role, LiquidityMiningInternal, LiquidityMiningViews {
    using SafeMath for uint256;

    bool public proxyMode;
    mapping(address=>bool) public stakingProxy;

    modifier proxyCheck() {
        if(!proxyMode) {
            _;
        } else {
            require(stakingProxy[msg.sender], "not from proxy");
            _;
        }
    }

    constructor(
        address _owner,
        address _rewardToken,
        uint256 _rewardPerBlock,
        bool _startNow
    ) public Simple3Role(_owner) {
        mainRewardToken = IParameterizedERC20(_rewardToken);
        rewardPerBlock = _rewardPerBlock;

        if(_startNow) {
            globalStartBlock = block.number;
        }

        selfAddr = address(this);
    }

    function setProxyMode(bool _enable) external onlyAdmin {
        proxyMode = _enable;
    }

    function setProxy(address _proxy, bool _enable) external onlyAdmin {
        stakingProxy[_proxy] = _enable;
    }

    function stake(uint256 _pid, uint256 _amount) external proxyCheck {
        _stake(_pid, _amount, msg.sender, msg.sender);
    }

    function proxyStaking(uint256 _pid, uint256 _amount, address _user) external proxyCheck {
        if(!proxyMode) {
            revert("only valid in proxy mode");
        }
        _stake(_pid, _amount, msg.sender, _user);
    }

    function stakeForUser(uint256 _pid, uint256 _amount, address _user) external proxyCheck {
        if(proxyMode) {
            revert("stakeForUser not support proxy mode!");
        }
        _stake(_pid, _amount, _user, msg.sender);
    }

    function withdraw(uint256 _pid, uint256 _amount) external proxyCheck {
        _collect(_pid, msg.sender);
        _withdraw(_pid, msg.sender, _amount);
    }

    function collect(uint256 _pid) external proxyCheck {
        _collect(_pid, msg.sender);
    }

    function addPool(
        IERC20 _stakeToken,
        uint256 _weight,
        uint256 _startBlock,
        uint256 _endBlock
    ) external onlyAdmin {
        if(_startBlock == 0) {
            _startBlock = block.number;
        } else {
            require(_startBlock >= block.number, "start must after or on the tx block");
        }

        require(_startBlock >= globalStartBlock, "must after or at pools start block");

        _updateAllPools();

        PoolInfo memory pool = PoolInfo({
            pid: poolCount,
            stakingToken: _stakeToken,
            startBlock: _startBlock,
            endBlock: _endBlock,
            weight: _weight,
            staked: 0,
            lastRewardBlock: _startBlock,
            rewardPerShare: 0,
            closed: false
        });

        _appendPool(pool);

        totalWeight = totalWeight.add(_weight);
    }

    function closePool(uint256 _pid) external onlyAdmin {
        PoolInfo storage pool = poolList[_pid];
        require(address(pool.stakingToken) != address(0), "no such pool");
        if(pool.closed) {
            return;
        }

        _updateAllPools();

        pool.weight = 0;
        pool.closed = true;
        pool.lastRewardBlock = block.number;
        pool.endBlock = block.number;

        validPool[_pid] = false;
        totalWeight = totalWeight.sub(pool.weight);
    }

    function changePoolsWeight(uint256[] calldata _pids, uint256[] calldata _newWeights) external onlyAdmin{
        uint256 newWeightCnt = _pids.length;
        _updateAllPools();
        for(uint256 i=0; i<newWeightCnt; i++) {
            uint256 pid = _pids[i];
            uint256 newWeight = _newWeights[i];

            if(poolList[pid].closed) {
                continue;
            }

            totalWeight = totalWeight.sub(poolList[pid].weight).add(newWeight);
        }
    }
}
