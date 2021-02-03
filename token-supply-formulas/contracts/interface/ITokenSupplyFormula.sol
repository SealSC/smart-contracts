pragma solidity ^0.6.0;

interface ITokenSupplyFormula {
    function CalcSupply(uint256 _fromBlock, uint256 _toBlock, uint256 _base) external returns(bool, uint256);
}
