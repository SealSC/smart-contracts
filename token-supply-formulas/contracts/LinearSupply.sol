pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../contract-libs/open-zeppelin/SafeMath.sol";
import "./interface/ITokenSupplyFormula.sol";

contract LinearSupply is ITokenSupplyFormula {
    using SafeMath for uint256;

    struct FormulaParam {
        uint256 a;
        uint256 b;
    }

    FormulaParam public formulaParam;
    constructor(uint256 _a, uint256 _b) public {
        formulaParam.a = _a;
        formulaParam.b = _b;
    }

    function CalcSupply(CalcInputParameters calldata _param) external override returns (bool, uint256) {
        uint256 blocks = _param.to.sub(_param.from);

        return (true, formulaParam.a.mul(blocks).mul(_param.base).add(formulaParam.b));
    }
}
