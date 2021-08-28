pragma solidity ^0.6.0;

import "../open-zeppelin/SafeERC20.sol";
import "./RejectDirectETH.sol";
import "./Calculation.sol";

contract Cashier is RejectDirectETH {
    using SafeERC20 for IERC20;
    using Calculation for uint256;
    using Address for address payable;

    uint256 constant public feeRatioBase = 1e18;

    struct FeeInfo {
        address currency;
        uint256 amount;
        uint256 ratio;
        address payable beneficiary;
        bool exists;
    }

    mapping(uint256=>FeeInfo) public supportedFee;

    event Received(address currency, address from, address to, uint256 amount);

    function _setFeeInfo(uint256 _category, address _currency, uint256 _amount, uint256 _ratio, address payable _beneficiary) internal {
        require(_beneficiary != address(0), "beneficiary must not zero address");

        supportedFee[_category] = FeeInfo({
            currency: _currency,
            amount: _amount,
            ratio: _ratio,
            beneficiary: _beneficiary,
            exists: true
        });
    }

    function _changeBeneficiary(uint256 _category, address payable _newBeneficiary) internal {
        require(_newBeneficiary != address(0), "beneficiary must not zero address");
        require(supportedFee[_category].exists, "not supported fee");

        supportedFee[_category].beneficiary = _newBeneficiary;
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

    function _chargeFeeByAmount(uint256 _category, address _supplier) internal returns(uint256 feeCharged) {
        FeeInfo memory fi = supportedFee[_category];
        return _chargeFee(fi, fi.amount, _supplier);
    }

    function _chargeFeeByRatio(uint256 _category, uint256 _totalSupply, address _supplier) internal returns(uint256 feeCharged) {
        FeeInfo memory fi = supportedFee[_category];
        uint256 feeAmount = _totalSupply.percentageMul(fi.ratio, feeRatioBase);
        return _chargeFee(fi, feeAmount, _supplier);
    }

}
