pragma solidity ^0.5.9;

import "./IERC20.sol";

interface IMigrator {
    function migrate(IERC20 token) external returns (IERC20);
}
