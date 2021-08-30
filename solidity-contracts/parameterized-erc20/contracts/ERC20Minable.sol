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
        uint256 quota;
    }

    event AddMinter(address minter, uint256 factor, uint256 quota, uint256 block);
    event UpdateMinterFactor(address minter, uint256 factor, uint256 block);
    event UpdateMinterQuota(address minter, uint256 quota, uint256 block);
    event MinterRemoved(address minter, uint256 block);
    event MintTo(address minter, address to, uint256 amount);

    mapping(address=>MinterInfo) public minters;

    modifier onlyMinter() {
        require(minters[msg.sender].minter != ZERO_ADDRESS, "not minter");
        _;
    }

    function setMintEnableStatus(bool _enabled) external onlyAdmin {
        mintEnabled = _enabled;
    }

    function addMinter(address _minter, uint256 _factor, uint256 _quota) external onlyAdmin {
        MinterInfo memory mi = minters[_minter];
        require(mi.minter ==  ZERO_ADDRESS, "minter already set");

        uint256 minterFactor  = _factor;
        if(minterFactor == 0) {
            minterFactor = BASIS_POINT_PRECISION;
        }

        mi.minter = _minter;
        mi.factor = minterFactor;
        mi.quota = _quota;
        minters[_minter] = mi;

        emit AddMinter(_minter, _factor, _quota, block.number);
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

    function setMinterQuota(address[] calldata _minters, uint256[] calldata _quotas) external onlyAdmin {
        for(uint256 i=0; i<_minters.length; i++) {
            MinterInfo storage mi = minters[_minters[i]];
            if(mi.minter == ZERO_ADDRESS) {
                continue;
            }

            mi.quota = _quotas[i];

            emit UpdateMinterQuota(mi.minter, mi.quota, block.number);
        }
    }

    function removeMinter(address _minter) external onlyAdmin {
        MinterInfo memory mi = minters[_minter];
        emit MinterRemoved(mi.minter, block.number);

        delete minters[_minter];
    }

    function mint(address _to, uint256 _amount) public onlyMinter {
        require(minable, "not minable");
        require(mintEnabled, "mint disabled");

        MinterInfo memory minter = minters[msg.sender];
        uint256 actualAmount = _amount.percentageMul(minter.factor, BASIS_POINT_PRECISION);

        require(actualAmount >= minter.quota, "out of quota");
        minter.quota = minter.quota.sub(actualAmount);

        emit MintTo(msg.sender, _to, actualAmount);
        _mint(_to, actualAmount);
    }
}
