pragma solidity ^0.5.9;

import "../../../contract-libs/open-zeppelin/Ownable.sol";
import "../../../contract-libs/open-zeppelin/SafeMath.sol";
import "../AdventureIslandInternal/AdventureIslandInternal.sol";
import "./AdventureIslandPoolManager.sol";

contract AdventureIslandAdmin is AdventureIslandPoolManager {
    using Address for address payable;
    using SafeERC20 for IERC20;

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

    function changeUniConnector(address _newUniConnector) external onlyAdmin {
        uniConnector = IUniswapConnector(_newUniConnector);
        ethPayer[_newUniConnector] = true;
    }

    function withdrawPlatformETHFeeTo(address payable _to, address _token) external onlyAdmin {
        uint256 feeToWithdraw = platformFeeCollected[_token];
        require(feeToWithdraw > 0, "platform fee is zero");

        uint256 contractBalance = 0;
        if(_token == ZERO_ADDRESS) {
            contractBalance = address(this).balance;
        } else {
            contractBalance = IERC20(_token).balanceOf(address(this));
        }

        if(feeToWithdraw > contractBalance) {
            feeToWithdraw = contractBalance;
        }

        if(_token == ZERO_ADDRESS) {
            _to.sendValue(feeToWithdraw);
        } else {
            IERC20(_token).safeTransfer(_to, feeToWithdraw);
        }

        platformFeeCollected[_token] = 0;
    }
}
