// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6.0;

import "../../../contract-libs/open-zeppelin/IERC20.sol";

struct UserInfo {
    uint256 stakeIn;
    uint256 rewardDebt;
    uint256 willCollect;
    uint256 lastCollectPosition;
}

interface IAdventureIsland {
    function stakingByContract(uint256 _pid, uint256 _amount, address payable _forUser) external;
    function staking(uint256 _pid, uint256 _amount) external;
    function collect(uint256 _pid, uint256 _withdrawAmount, bool _flashUnstaking, bool _forOneToken, address _outToken) external;

    function getPoolStakingToken(uint256 _pid) view external returns(address);
}
