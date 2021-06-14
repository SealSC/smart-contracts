// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6.0;

import "../../contract-libs/seal-sc/Constants.sol";

contract UniswapConnectorData is Constants {
    IERC20 public weth = WETH;
    IUniswapV2Router02 public router = UNI_V2_ROUTER;
    IUniswapV2Factory public factory = UNI_V2_FACTORY;

    mapping(address=>address[]) public supportedPair;
    address[] public supportedList;
}
