// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6.0;

import "../../../contract-libs/open-zeppelin/SafeMath.sol";
import "../../../contract-libs/open-zeppelin/IERC20.sol";

struct PoolInfo {
    IERC20 stakingToken;
    uint256 pid;
    uint256 startBlock;
    uint256 endBlock;
    uint256 billingCycle;
    uint256 weight;
    uint256 staked;
    uint256 lastRewardBlock;
    uint256 rewardPerShare;
    uint256 minStakeIn;
    uint256 maxStakeIn;
    bool closed;
}

contract AdventureIslandPools {
    using SafeMath for uint256;

    mapping (uint256=>PoolInfo) public allPools;
    uint256 public allPoolsCount;
    mapping(uint256=>bool) public validPoolList;

    function appendPool(PoolInfo memory _pool) internal {
        allPools[allPoolsCount] = _pool;
        validPoolList[allPoolsCount] = true;
        allPoolsCount = allPoolsCount.add(1);
    }

    function removePoolFromList(uint256 _pid) internal {
        validPoolList[_pid] = false;
    }
}
