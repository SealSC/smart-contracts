// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6.0;

contract RejectDirectETH {
    receive() external payable {
        revert("refuse to directly transfer ETH in");
    }
}
