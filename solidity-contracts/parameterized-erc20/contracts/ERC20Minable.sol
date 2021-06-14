// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.6.0;

import "../../contract-libs/open-zeppelin/ERC20.sol";
import "../../contract-libs/seal-sc/Constants.sol";
import "../../contract-libs/seal-sc/Calculation.sol";
import "../../contract-libs/seal-sc/Simple3Role.sol";
import "../../token-supply-formulas/contracts/interface/ITokenSupplyFormula.sol";
import "../../contract-libs/open-zeppelin/Address.sol";

abstract contract ERC20Minable is ERC20, Constants, Simple3Role {
    using SafeMath for uint256;
    using Calculation for uint256;
    using Address for address;

    bool public minable;
    bool public mintEnabled = true;
    ITokenSupplyFormula public supplyFormula;

    struct MinterInfo {
        address minter;
        uint256 factor;
    }

    event AddMinter(address minter, uint256 factor, uint256 block);
    event UpdateMinterFactor(address minter, uint256 factor, uint256 block);
    event MinterRemoved(address minter, uint256 factor, uint256 block);
    event MintTo(address minter, address to, uint256 amount);
    event FormulaChanged(address indexed from, address indexed to, address indexed byAdmin);

    mapping(address=>MinterInfo) public minters;

    modifier onlyMinter() {
        require(minters[msg.sender].minter != ZERO_ADDRESS, "not minter");
        _;
    }

    function setMintEnableStatus(bool _enabled) external onlyAdmin {
        mintEnabled = _enabled;
    }

    function addMinter(address _minter, uint256 _factor) external onlyAdmin {
        MinterInfo memory mi = minters[_minter];
        require(mi.minter ==  ZERO_ADDRESS, "minter already set");

        uint256 minterFactor  = _factor;
        if(minterFactor == 0) {
            minterFactor = BASIS_POINT_PRECISION;
        }

        mi.minter = _minter;
        mi.factor = minterFactor;
        minters[_minter] = mi;

        emit AddMinter(_minter, _factor, block.number);
    }

    function updateMinterFactor(address[] calldata _minters, uint256[] calldata _factors) external onlyAdmin {
        require(_minters.length == _factors.length, "parameter's length not match");

        for(uint256 i=0; i<_minters.length; i++) {
            MinterInfo storage mi = minters[_minters[i]];
            if(mi.minter == ZERO_ADDRESS) {
                continue;
            }

            mi.factor = _factors[i];

            emit UpdateMinterFactor(mi.minter, mi.factor, block.number);
        }
    }

    function removeMinter(address _minter) external onlyAdmin {
        MinterInfo memory mi = minters[_minter];
        emit MinterRemoved(mi.minter, mi.factor, block.number);

        delete minters[_minter];
    }

    function setSupplyFormula(address _formula) external onlyAdmin {
        require(_formula.isContract(), "formula must be a contract");

        emit FormulaChanged(address(supplyFormula), _formula, msg.sender);
        supplyFormula = ITokenSupplyFormula(_formula);
    }

    function mintWithFormula(address _to, uint256 _fromBlock, uint256 _toBlock, uint256 _base) external onlyMinter {
        require(address(supplyFormula) != ZERO_ADDRESS, "formula not set");
        (bool valid, uint256 amount) = supplyFormula.CalcSupply(_fromBlock, _toBlock, _base);
        require(valid, "invalid param");

        mint(_to, amount);
    }

    function mint(address to, uint256 amount) public onlyMinter {
        require(minable, "not minable");
        require(mintEnabled, "mint disabled");
        require(to != ZERO_ADDRESS, "can not mint to address 0");

        MinterInfo memory minter = minters[msg.sender];
        uint256 actualAmount = amount.percentageMul(minter.factor, BASIS_POINT_PRECISION);
        emit MintTo(msg.sender, to, actualAmount);
        _mint(to, actualAmount);
    }
}
