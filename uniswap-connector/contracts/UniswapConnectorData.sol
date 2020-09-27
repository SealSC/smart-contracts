pragma solidity ^0.5.9;

import "../../contract-libs/seal-sc/Constants.sol";
import "../../mining-pools/contracts/interface/IMiningPools.sol";

contract UniswapConnectorData is Constants {
    IERC20 public weth = WETH;
    IUniswapV2Router02 public router = UNI_V2_ROUTER;
    IUniswapV2Factory public factory = UNI_V2_FACTORY;

    IMiningPools public miningPools;

    uint256 public feePrecision = 1e12;
    uint256 public feeBasisPoint = 0;

    mapping(address=>address[]) public supportedPair;
    address[] public supportedList;
}
