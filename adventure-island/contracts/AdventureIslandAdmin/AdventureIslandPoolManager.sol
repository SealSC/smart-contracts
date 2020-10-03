pragma solidity ^0.5.9;

import "../../../contract-libs/open-zeppelin/Ownable.sol";
import "../../../contract-libs/open-zeppelin/SafeMath.sol";
import "../AdventureIslandInternal/AdventureIslandInternal.sol";
import "./AdventureIslandTeamManager.sol";

contract AdventureIslandPoolManager is AdventureIslandTeamManager, AdventureIslandInternal {
    using SafeMath for uint256;

    function addPool(
        address _stakeToken,
        uint256 _weight,
        uint256 _billingCycle,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _minStakeIn,
        uint256 _maxStakeIn
    ) external onlyAdmin {
        require(_startBlock >= globalStartBlock, "must after or at pools start block");
        require(_billingCycle > 0, "pool billing cycle must not be zero");

        uint256 start = _startBlock;

        if(start == 0) {
            start = block.number;
        } else {
            require(start >= block.number, "start must after or on the tx block");
        }

        if(_endBlock > 0) {
            require(_endBlock > _startBlock);
        }

        _updatePools();

        PoolInfo memory newPool = PoolInfo({
        stakingToken: IERC20(_stakeToken),
        startBlock: start,
        endBlock: _endBlock,
        billingCycle: _billingCycle,
        weight: _weight,
        staked: 0,
        minStakeIn: _minStakeIn,
        maxStakeIn: _maxStakeIn,
        lastRewardBlock: _startBlock,
        rewardPerShare: 0,
        closed: false
        });

        pools.push(newPool);
    }

    function setPoolStakeToken(uint256 _pid, address _token) public onlyAdmin {
        PoolInfo storage pool = pools[_pid];
        require(address(pool.stakingToken) == DUMMY_ADDRESS, "address already set");

        pool.stakingToken = IERC20(_token);
    }

    function removePool(uint256 _pid) public onlyAdmin {
        PoolInfo storage pool = pools[_pid];
        require(pool.billingCycle != 0, "no such pool");

        _updatePools();

        pool.weight = 0;
        pool.closed = true;
        pool.lastRewardBlock = block.number;
        pool.endBlock = block.number;
    }

    function setPoolWeight(uint256[] calldata _pids, uint256[] calldata _newWeights) external onlyAdmin {
        uint256 pidLen = _pids.length;
        uint256 newWeightLen = _newWeights.length;

        _updatePools();

        require(pidLen == newWeightLen, "invalid parameter");
        for(uint256 i=0; i<pidLen; i++) {
            PoolInfo storage pool = pools[_pids[i]];
            require(pool.billingCycle != 0, "no such pool");
            require(!pool.closed, "pool already closed");

            pool.weight = _newWeights[i];
        }
    }

    function updateFlashStakingRewardBP(uint256 _newBP) external onlyAdmin {
        require(_newBP <= BASIS_POINT_PRECISION.mul(100), "reward basis point is too big");

        flashStakingRewardBP = _newBP;
    }
}
