pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

struct CalcInputParameters {
    uint256 from;
    uint256 to;
    uint256 base;
}

interface ITokenSupplyFormula {
    function CalcSupply(CalcInputParameters calldata _param) external returns(bool, uint256);
}
