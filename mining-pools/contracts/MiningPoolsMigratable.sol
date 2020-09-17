pragma solidity ^0.5.9;

import "./IMigrator.sol";
import "./MiningPoolsData.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract MiningPoolsMigratable is Ownable, MiningPoolsData {
    using SafeMath for uint256;

    IMigrator public migrator;

    function setMigrator(IMigrator _migrator) public onlyOwner {
        migrator = _migrator;
    }

    function migrate(uint256 _pid, uint256 _multiple, uint256 _precision) public {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = pools[_pid];
        IERC20 stakingToken = pool.stakingToken;

        uint256 amount = stakingToken.balanceOf(address(this));
        stakingToken.approve(address(migrator), amount);

        IERC20 newStakingToken = migrator.migrate(stakingToken);
        uint256 newBal = newStakingToken.balanceOf(address(this));
        newBal = newBal.mul(_multiple).div(_precision);

        require(amount == newBal, "migrate: failed");
        pool.stakingToken = newStakingToken;
    }
}
