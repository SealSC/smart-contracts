pragma solidity ^0.5.9;

import "../open-zeppelin/SafeMath.sol";

library Calculation {
    using SafeMath for uint256;

    function percentageMul(uint256 a, uint256 weight, uint256 basis) internal pure returns (uint256) {
        return a.mul(weight).div(basis);
    }
}
