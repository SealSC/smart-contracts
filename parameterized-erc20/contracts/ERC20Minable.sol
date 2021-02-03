// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.6.0;

import "../../contract-libs/open-zeppelin/ERC20.sol";
import "../../contract-libs/seal-sc/Constants.sol";
import "../../contract-libs/seal-sc/Calculation.sol";
import "../../contract-libs/seal-sc/Simple3Role.sol";
import "../../token-supply-formulas/contracts/interface/ITokenSupplyFormula.sol";

abstract contract ERC20Minable is ERC20, Constants, Simple3Role {
    using SafeMath for uint256;
    using Calculation for uint256;

    bool public minable;
    bool public mintEnabled = true;
    ITokenSupplyFormula public supplyFormula;

    struct MinterInfo {
        address minter;
        uint256 weight;
    }

    event AddMinter(address minter, uint256 weight, uint256 block);
    event UpdateMinterWeight(address minter, uint256 weight, uint256 block);
    event MinterRemoved(address minter, uint256 weight, uint256 block);
    event MintTo(address minter, address to, uint256 amount);

    mapping(address=>MinterInfo) public minters;

    modifier onlyMinter() {
        require(minters[msg.sender].minter != ZERO_ADDRESS, "not minter");
        _;
    }

    function setMintEnableStatus(bool _enabled) external onlyAdmin {
        mintEnabled = _enabled;
    }

    function addMinter(address _minter, uint256 _weight) external onlyAdmin {
        MinterInfo memory mi = minters[_minter];
        require(mi.minter ==  ZERO_ADDRESS, "minter already set");

        uint256 minterWeight  = _weight;
        if(minterWeight == 0) {
            minterWeight = BASIS_POINT_PRECISION;
        }

        mi.minter = _minter;
        mi.weight = minterWeight;
        minters[_minter] = mi;

        emit AddMinter(_minter, _weight, block.number);
    }

    function updateMinterWeight(address[] calldata _minters, uint256[] calldata _weights) external onlyAdmin {
        require(_minters.length == _weights.length, "parameter's length not match");

        for(uint256 i=0; i<_minters.length; i++) {
            MinterInfo storage mi = minters[_minters[i]];
            if(mi.minter == ZERO_ADDRESS) {
                continue;
            }

            mi.weight = _weights[i];

            emit UpdateMinterWeight(mi.minter, mi.weight, block.number);
        }
    }

    function removeMinter(address _minter) external onlyAdmin {
        MinterInfo memory mi = minters[_minter];
        emit MinterRemoved(mi.minter, mi.weight, block.number);

        delete minters[_minter];
    }

    function mintWithFormula(address _to, uint256 _fromBlock, uint256 _toBlock, uint256 _base) external onlyMinter {
        (bool valid, uint256 amount) = supplyFormula.CalcSupply(_fromBlock, _toBlock, _base);
        require(valid, "invalid param");

        mint(_to, amount);
    }

    function mint(address to, uint256 amount) public onlyMinter {
        require(minable, "not minable");
        require(mintEnabled, "mint disabled");
        require(to != ZERO_ADDRESS, "can not mint to address 0");

        MinterInfo memory minter = minters[msg.sender];
        uint256 actualAmount = amount.percentageMul(minter.weight, BASIS_POINT_PRECISION);
        emit MintTo(msg.sender, to, actualAmount);
        _mint(to, actualAmount);
    }
}
