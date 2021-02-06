// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6.0;

import "../../../contract-libs/open-zeppelin/SafeMath.sol";
import "../../../contract-libs/seal-sc/Calculation.sol";
import "./AdventureIslandRoleManager.sol";
import "../AdventureIslandData/AdventureIslandData.sol";
import "../../../contract-libs/open-zeppelin/SafeERC20.sol";

abstract contract AdventureIslandTeamManager is AdventureIslandRoleManager, AdventureIslandData {
    using SafeMath for uint256;
    using Calculation for uint256;
    using SafeERC20 for IERC20;

    modifier onlyTeam() {
        require(msg.sender == team, "caller is not the team");
        _;
    }

    function disableTeamRewardPermanently() public onlyAdmin {
        teamRewardPermanentlyDisabled = true;
    }

    function setTeam(address _team) external onlyAdmin {
        team = _team;
    }

    function updateTeamRewardBasis(uint256 _newBP) external onlyAdmin {
        teamRewardBP = _newBP;
    }

    function _mintTeamReward(uint256 _amount) internal {
        if(team == ZERO_ADDRESS || teamRewardPermanentlyDisabled) {
            return;
        }

        if(address (rewardSupplier) == ZERO_ADDRESS) {
            IERC20(mainRewardToken).safeTransfer(team, _amount.percentageMul(teamRewardBP, BASIS_POINT_PRECISION));
        } else {
            rewardSupplier.mint(mainRewardToken, team, _amount.percentageMul(teamRewardBP, BASIS_POINT_PRECISION));
        }
    }
}
