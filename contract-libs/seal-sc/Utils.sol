// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6.0;

contract Mutex {
    bool internal _utils_mutex_locked;

    //code from solidity document
    modifier noReentrancy() {
        require(
            !_utils_mutex_locked,
            "Reentrant call."
        );
        _utils_mutex_locked = true;
        _;
        _utils_mutex_locked = false;
    }
}
