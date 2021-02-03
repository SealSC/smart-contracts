pragma solidity ^0.6.0;

import "../../contract-libs/open-zeppelin/SafeMath.sol";
import "./interface/ITokenSupplyFormula.sol";
import "../../contract-deployer/build/ContractDeployer.sol";

contract LinearSupply is ITokenSupplyFormula, Ownable {
    using SafeMath for uint256;

    struct FormulaParam {
        uint256 a;
        uint256 b;
    }

    FormulaParam public formulaParam;
    constructor(uint256 _a, uint256 _b, address _owner) public Ownable(_owner) {
        formulaParam.a = _a;
        formulaParam.b = _b;
    }

    function updateFormulaParam(uint256 _a, uint256 _b) external onlyOwner {
        formulaParam.a = _a;
        formulaParam.b = _b;
    }

    function CalcSupply(uint256 _fromBlock, uint256 _toBlock, uint256 _base) external override returns (bool, uint256) {
        uint256 blocks = _toBlock.sub(_fromBlock);

        return (true, formulaParam.a.mul(blocks).mul(_base).add(formulaParam.b));
    }
}
