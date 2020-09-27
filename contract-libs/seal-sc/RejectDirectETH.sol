pragma solidity ^0.5.9;

contract RejectDirectETH {
    function() external {
        revert("refuse to directly transfer ETH in");
    }
}
