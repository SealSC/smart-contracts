pragma solidity ^0.5.9;

import "../../contract-libs/open-zeppelin/IERC20.sol";

interface IMigrator {
    function migrate(IERC20 token) external returns (IERC20);
}
