pragma solidity ^0.5.9;

import "../open-zeppelin/IERC20.sol";
import "../uniswap/IUniswapV2Factory.sol";
import "../uniswap/IUniswapV2Router02.sol";

contract Constants {
    address constant internal ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;
    address constant internal MAX_ADDRESS = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;
    address constant internal DUMMY_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    IERC20 constant internal USDT_ERC20 = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IUniswapV2Factory constant internal UNI_V2_FACTORY = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    IUniswapV2Router02  constant internal UNI_V2_ROUTER = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    uint256 constant internal BASIS_POINT_PRECISION = 1e4;
}
