pragma solidity ^0.6.0;

import "../open-zeppelin/SafeERC20.sol";
import "./RejectDirectETH.sol";
import "./Calculation.sol";

contract Cashier is RejectDirectETH {
    using SafeERC20 for IERC20;
    using Calculation for uint256;
    using Address for address payable;

    uint256 constant public feeRatioBase = 1e18;

    enum FEE_CHARGE_METHOD {
        ByAmount,
        ByRatio,
        END
    }

    struct FeeInfo {
        address currency;
        uint256 amount;
        uint256 ratio;
        address payable beneficiary;
        FEE_CHARGE_METHOD chargeMethod;
        bool exists;
    }

    mapping(uint256=>FeeInfo) public supportedFee;

    event Received(address currency, address from, address to, uint256 amount);

    function _setFeeInfo(
        uint256 _category,
        address _currency,
        uint256 _amount,
        uint256 _ratio,
        address payable _beneficiary,
        FEE_CHARGE_METHOD _method) internal {
        require(_beneficiary != address(0), "beneficiary must not zero address");

        supportedFee[_category] = FeeInfo({
            currency: _currency,
            amount: _amount,
            ratio: _ratio,
            beneficiary: _beneficiary,
            chargeMethod: _method,
            exists: true
        });
    }

    function _changeBeneficiary(uint256 _category, address payable _newBeneficiary) internal {
        require(_newBeneficiary != address(0), "beneficiary must not zero address");
        require(supportedFee[_category].exists, "not supported fee");

        supportedFee[_category].beneficiary = _newBeneficiary;
    }

    function _changeFeeSetting(uint256 _category, FEE_CHARGE_METHOD _method, uint256 _newAmount, uint256 _newRatio) internal {
        require(supportedFee[_category].exists, "not supported fee");

        supportedFee[_category].chargeMethod = _method;
        supportedFee[_category].amount = _newAmount;
        supportedFee[_category].ratio = _newRatio;
    }

    function _removeFeeInfo(uint256 _category) internal {
        supportedFee[_category].exists = false;
        delete supportedFee[_category];
    }

    function _chargeFee(FeeInfo memory _fi, uint256 _amount, address supplier) private returns(uint256 feeCharged) {
        require(_fi.beneficiary != address(this), "cashier can't be beneficiary");

        if(_amount != 0) {
            if(_fi.currency == address(0)) {
                _fi.beneficiary.sendValue(_amount);
            } else {
                IERC20(_fi.currency).safeTransferFrom(supplier, _fi.beneficiary, _amount);
            }
        }

        emit Received(_fi.currency, supplier, _fi.beneficiary, _amount);

        return _amount;
    }

    function _charge(uint256 _category, address _supplier, uint256 _totalSupply) internal returns(uint256 feeCharged) {
        FeeInfo memory fi = supportedFee[_category];
        uint256 feeAmount = fi.amount;
        if(fi.chargeMethod == FEE_CHARGE_METHOD.ByRatio) {
            feeAmount = _totalSupply.percentageMul(fi.ratio, feeRatioBase);
        }

        return _chargeFee(fi, feeAmount, _supplier);
    }
}
