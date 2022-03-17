// SPDX-License-Identifier: Apache-2.0
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.0;

import "../../contract-libs/seal-sc/Simple3Role.sol";
import "../../contract-libs/open-zeppelin/SafeERC20.sol";
import "../../parameterized-erc20/contracts/IParameterizedERC20.sol";
import "../../contract-libs/open-zeppelin/SafeMath.sol";
import "./LiquidityMiningCalculator.sol";

contract LiquidityMiningViews is LiquidityMiningCalculator {
    using SafeMath for uint256;

    function getPoolInfo(uint256 _pid) external view returns(PoolInfo memory pool) {
        return poolList[_pid];
    }

    function toBeCollectedOfUser(address _user, uint256 _pid) external view returns(uint256 amount) {
        return _rewardOf(_pid, _user);
    }

    function toBeCollectedOfPool(uint256 _pid) external view returns(uint256 amount) {
        return _rewardOf(_pid);
    }

    function toBeCollectedOfUser(address _user) external view returns(uint256[] memory amounts) {
        amounts = new uint256[](poolCount);
        for(uint256 i=0; i<poolCount; i++) {
            amounts[i] = _rewardOf(i, _user);
        }

        return amounts;
    }

    function toBeCollectedOfPool() external view returns(uint256[] memory amounts) {
        amounts = new uint256[](poolCount);
        for(uint256 i=0; i<poolCount; i++) {
            amounts[i] = _rewardOf(i);
        }

        return amounts;
    }

    function rewardToken() external view returns(address token) {
        return address(mainRewardToken);
    }
}
