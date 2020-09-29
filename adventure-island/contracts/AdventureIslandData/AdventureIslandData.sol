pragma solidity ^0.5.6;

import "../interface/IAdventureIsland.sol";
import "../../../contract-libs/seal-sc/Constants.sol";
import "../../../erc20-token-supplier/contracts/interface/IERC20TokenSupplier.sol";

contract AdventureIslandData is IAdventureIsland, Constants {
    PoolInfo[] public pools;
    mapping (uint256=>mapping(address=>UserInfo)) public users;

    address public mainRewardToken;
    IERC20TokenSupplier public rewardSupplier;

    uint256 public rewardPerBlock;
    uint256 public minRewardPerBlock;

    uint256 public rewardCap;
    uint256 public collectedReward;

    uint256 public precision = 1e18;

    address public team;
    uint256 public lastTotalSupplyWithoutTeam;
    uint256 public teamRewarded;
    bool public teamRewardPermanentlyDisabled = false;

    bool public globalOpen = true;
    uint256 public globalStartBlock  = ~uint256(0);

    bool public rewardDecreasable;
    uint256 public rewardDecreaseBegin;
    uint256 public rewardDecreaseStep;
    uint256 public rewardDecreaseUnit;
}
