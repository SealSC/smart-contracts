pragma solidity ^0.5.9;

import "./Ownable.sol";
import "./MiningPoolsInternal.sol";

contract MiningPoolsAdmin is Ownable, MiningPoolsInternal {
    using SafeMath for uint256;

    mapping(address=>address) public administrators;

    modifier onlyAdmin() {
        require(address(0) != administrators[msg.sender], "caller is not the administrator");
        _;
    }

    modifier onlyTeam() {
        require(msg.sender == team, "caller is not the team");
        _;
    }

    function addAdministrator(address _admin) public onlyAdmin {
        administrators[_admin] = _admin;
    }

    function removeAdministrator(address _admin) public onlyAdmin {
        delete administrators[_admin];
    }

    function isAdmin(address _admin) public view returns(bool) {
        return (address(0) != administrators[_admin]);
    }

    function setPoolsCap(uint256 cap) public onlyAdmin {
        require(cap > rewardCap);
        rewardCap = cap;
    }

    function addPool(
        address _stakeToken,
        uint256 _weight,
        uint256 _billingCycle,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _minStakeIn,
        uint256 _maxStakeIn) public onlyAdmin {
        require(_startBlock >= globalStartBlock, "must after or at pools start block");
        require(_billingCycle > 0, "pool billing cycle must not be zero");

        if(_startBlock == 0) {
            _startBlock = block.number;
        } else {
            require(_startBlock >= block.number, "start must after or on the tx block");
        }

        if(_endBlock > 0) {
            require(_endBlock > _startBlock);
        }

        _updatePools();

        PoolInfo memory newPool = PoolInfo({
            stakingToken: IERC20(_stakeToken),
            startBlock: _startBlock,
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
        require(address(pool.stakingToken) == INIT_ADDRESS, "address already set");

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

    function setPoolWeight(uint256[] memory _pids, uint256[] memory _newWeights) public onlyAdmin {
        uint256 _pidLen = _pids.length;
        uint256 _newWeightLen = _newWeights.length;

        _updatePools();

        require(_pidLen == _newWeightLen, "invalid parameter");
        for(uint256 i=0; i<_pidLen; i++) {
            PoolInfo storage pool = pools[_pids[i]];
            require(pool.billingCycle != 0, "no such pool");
            require(!pool.closed, "pool already closed");

            pool.weight = _newWeights[i];
        }
    }

    function setTeam(address _team) public onlyAdmin {
        team = _team;
    }

    function mintToTeam() public {
        require (msg.sender == team || isAdmin(msg.sender), "not team or admin");

        uint256 totalAmount = rewardToken.totalSupply();
        uint256 thisSupplyWithoutTeam = totalAmount.sub(teamRewarded);
        uint256 rewardToCollect = thisSupplyWithoutTeam.sub(lastTotalSupplyWithoutTeam).div(10);

        rewardToken.mint(team, rewardToCollect);
        lastTotalSupplyWithoutTeam = thisSupplyWithoutTeam;
        teamRewarded = teamRewarded.add(rewardToCollect);
    }

    function setGlobalStartBlock(uint256 _newStart) public onlyAdmin {
        require(globalStartBlock > _newStart, "new start must less than current start");
        globalStartBlock = _newStart;
    }

    function changeEnableState(bool _enabled) public onlyAdmin {
        globalOpen = _enabled;
    }

    function setRewardDecreased(uint256 _begin, uint256 _step, uint256 _unit, uint256 _minReward) public onlyAdmin {
        require(_begin > block.number && _begin >= globalStartBlock);
        require(_step > 0);
        require(_unit > 0);
        require(_minReward < rewardPerBlock);

        rewardDecreasable = true;
        rewardDecreaseBegin = _begin;
        rewardDecreaseStep = _step;
        rewardDecreaseUnit = _unit;
        minRewardPerBlock = _minReward;
    }
}
