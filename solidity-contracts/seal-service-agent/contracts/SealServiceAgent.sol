pragma solidity ^0.6.0;

import "../../contract-libs/seal-sc/Simple3Role.sol";
import "../../contract-libs/seal-sc/Cashier.sol";
import "../../contract-libs/seal-sc/SimpleSealSCSignature.sol";

contract SealServiceAgent is Cashier, Simple3Role, SimpleSealSCSignature {
    using Address for address;

    constructor(address _owner) Simple3Role(_owner) public {}

    struct ServiceInfo {
        bool registered;
        bool enabled;
        bool free;
    }

    mapping(bytes32=>ServiceInfo) public registeredService;
    mapping(bytes32=>bool) public blockedService;

    modifier registered(bytes32 _key) {
        require(registeredService[_key].registered, "not registered");
        _;
    }

    function _checkKey(bytes32 _key) internal view {
        require(registeredService[_key].registered, "not registered");
        require(registeredService[_key].enabled, "not enabled");
    }

    function registerService(address _contract, bytes4 _service) external onlyExecutor {
        bytes32 key = keccak256(abi.encodePacked(_contract, _service));
        if(!registeredService[key].registered) {
            registeredService[key] = ServiceInfo({
                registered: true,
                enabled: false,
                free: false
            });
        }
    }

    function removeService(bytes32 _key) external onlyAdmin {
        require(registeredService[_key].registered, "not registered");
        delete registeredService[_key];
    }

    function enableServiceForFree(bytes32 _key) external onlyAdmin registered(_key) {
        require(registeredService[_key].registered, "not registered");
        registeredService[_key].free = true;
        if(!registeredService[_key].enabled) {
            registeredService[_key].enabled = true;
        }
    }

    function _calcFeeCategory(bytes32 _key, uint256 _category, FEE_CHARGE_METHOD _chargeType) internal view returns(uint256) {
        uint256 usedCategory = uint256(keccak256(abi.encodePacked(_key, _category)));
        require(supportedFee[usedCategory].exists, "invalid fee category");
        require(_chargeType < FEE_CHARGE_METHOD.END, "invalid charge type");

        return usedCategory;
    }

    function enableServiceWithFee(
        bytes32 _key,
        uint256 _category,
        FEE_CHARGE_METHOD _chargeType,
        address _currency,
        uint256 _amount,
        uint256 _ratio,
        address payable _beneficiary) external onlyAdmin registered(_key)  {

        uint256 usedCategory = _calcFeeCategory(_key, _category, _chargeType);

        registeredService[_key].enabled = true;

        super._setFeeInfo(usedCategory, _currency, _amount, _ratio, _beneficiary, _chargeType);
    }

    function addServiceFeeCategory(
        bytes32 _key,
        FEE_CHARGE_METHOD _chargeType,
        uint256 _category,
        address _currency,
        uint256 _amount,
        uint256 _ratio,
        address payable _beneficiary) external onlyAdmin {

        _checkKey(_key);

        uint256 usedCategory = _calcFeeCategory(_key, _category, _chargeType);
        super._setFeeInfo(usedCategory, _currency, _amount, _ratio, _beneficiary, _chargeType);
    }

    function removeServiceFeeCategory(
        bytes32 _key,
        uint256 _category) external onlyAdmin {

        _checkKey(_key);

        uint256 usedCategory = uint256(keccak256(abi.encodePacked(_key, _category)));
        require(supportedFee[_category].exists, "invalid category");

        super._removeFeeInfo(uint256(usedCategory));
    }

    function setNewFee(uint256 _category, FEE_CHARGE_METHOD _method, uint256 _newAmount, uint256 _newRatio) external onlyAdmin {
        super._changeFeeSetting(_category, _method, _newAmount, _newRatio);
    }

    function changeFeeBeneficiary(uint256 _category, address payable _newBeneficiary) external onlyAdmin {
        super._changeBeneficiary(_category, _newBeneficiary);
    }

    function _prepareCall(
        address _contract,
        bytes4 _service,
        uint256 _category,
        address _feeSupplier,
        uint256 _totalSupply) internal {

        bytes32 key = keccak256(abi.encodePacked(_contract, _service));

        ServiceInfo memory si = registeredService[key];
        if(si.free) {
            return;
        }

        uint256 usedCategory = uint256(keccak256(abi.encodePacked(key, _category)));
        super._charge(usedCategory, _feeSupplier, _totalSupply);
    }

    function callService(
        address _contract,
        bytes4 _service,
        uint256 _category,
        address _feeSupplier,
        uint256 _totalSupply,
        bytes calldata _data) external returns(bytes memory serviceRet) {

        _prepareCall(_contract, _service, _category, _feeSupplier, _totalSupply);
        serviceRet = _contract.functionCall(abi.encodeWithSelector(_service, _data), "call service failed");

        return serviceRet;
    }

    function callPayableService(
        address payable _contract,
        bytes4 _service,
        uint256 _category,
        address _feeSupplier,
        uint256 _totalSupply,
        bytes calldata _data) external payable returns(bytes memory serviceRet) {

        _prepareCall(_contract, _service, _category, _feeSupplier, _totalSupply);
        serviceRet = _contract.functionCallWithValue(abi.encodeWithSelector(_service, _data), msg.value, "call service failed");

        return serviceRet;
    }
}
