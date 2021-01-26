// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6.0;

import "../open-zeppelin/IERC20.sol";
import "../uniswap/IUniswapV2Factory.sol";
import "../uniswap/IUniswapV2Router02.sol";

contract Constants {
    address constant internal ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;
    address constant internal MAX_ADDRESS = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;
    address constant internal DUMMY_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    IERC20 constant internal USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    uint256 constant internal USDT_PRECISION = 1e6;

    IERC20 constant internal WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    IUniswapV2Factory constant internal UNI_V2_FACTORY = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    IUniswapV2Router02  constant internal UNI_V2_ROUTER = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    uint256 constant internal BASIS_POINT_PRECISION = 1e18;
    uint256 constant internal COMMON_PRECISION = 1e18;
    uint256 constant internal MAX_UINT256 = ~uint256(0);
}
