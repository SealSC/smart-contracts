// SPDX-License-Identifier: Apache-2.0
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.0;

import "../../contract-libs/seal-sc/Simple3Role.sol";
import "../../contract-libs/open-zeppelin/SafeERC20.sol";
import "../../parameterized-erc20/contracts/IParameterizedERC20.sol";
import "../../contract-libs/open-zeppelin/SafeMath.sol";

contract LiquidityMiningData {
    address public selfAddr;
    IParameterizedERC20 public mainRewardToken;
    uint256 public rewardPerBlock;
    uint256 public globalStartBlock;
    uint256 public totalWeight;

    struct PoolInfo {
        IERC20 stakingToken;
        uint256 pid;
        uint256 startBlock;
        uint256 endBlock;
        uint256 weight;
        uint256 staked;
        uint256 lastRewardBlock;
        uint256 rewardPerShare;
        bool closed;
    }

    struct UserInfo {
        uint256 stakeIn;
        uint256 rewardDebt;
        uint256 willCollect;
        uint256 lastCollectPosition;
    }

    mapping (uint256=>PoolInfo) public poolList;
    uint256 public poolCount;
    mapping(uint256=>bool) public validPool;

    mapping (uint256=>mapping(address=>UserInfo)) public users;

    uint256 constant internal COMMON_PRECISION = 1e18;
}
