pragma solidity ^0.5.9;

import "../../../contract-libs/open-zeppelin/Ownable.sol";
import "../../../contract-libs/open-zeppelin/SafeMath.sol";
import "../AdventureIslandInternal/AdventureIslandInternal.sol";
import "./AdventureIslandPoolManager.sol";

contract AdventureIslandAdmin is AdventureIslandPoolManager {
    function setGlobalStartBlock(uint256 _newStart) external onlyAdmin {
        require(globalStartBlock > _newStart, "new start must less than current start");
        require(_newStart > block.number, "new start must after current block");

        globalStartBlock = _newStart;
    }

    function changeGlobalEnableState(bool _enabled) external onlyAdmin {
        globalOpen = _enabled;
    }

    function changeRewardPerBlock(uint256 _newReward)  external onlyAdmin {
        _updatePools();
        rewardPerBlock = _newReward;
    }
}
