pragma solidity ^0.5.9;

import "../../../contract-libs/open-zeppelin/Ownable.sol";
import "../../../contract-libs/open-zeppelin/SafeMath.sol";
import "../../../contract-libs/seal-sc/Calculation.sol";
import "./AdventureIslandRoleManager.sol";

contract AdventureIslandTeamManager is AdventureIslandRoleManager {
    using SafeMath for uint256;
    using Calculation for uint256;

    address public team;
    uint256 public teamRewardBP  = 100; // 100 Basis Point == 1%

    bool public teamRewardPermanentlyDisabled = false;

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
}
