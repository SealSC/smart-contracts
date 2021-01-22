pragma solidity ^0.6.0;

import "../../contract-libs/seal-sc/RejectDirectETH.sol";
import "../../contract-libs/open-zeppelin/Create2.sol";
import "../../contract-libs/seal-sc/Simple3Role.sol";
import "../../contract-libs/bytes-utils/BytesLib.sol";
import "../../contract-libs/bytes-utils/BytesLib.sol";


contract ContractDeployer is Simple3Role, RejectDirectETH {

    using BytesLib for bytes;

    struct PresetContract {
        string name;
        bytes32 codeHash;
        uint256 fee;
        bool disabled;
    }

    PresetContract[] public presets;

    constructor(address _owner) public Simple3Role(_owner) {}

    event PresetContractDeployed(address indexed user, address addr, uint256 contractIdx, uint256 value, uint256 fee);
    event ContractDeployed(address indexed user, address indexed addr, uint256 value);

    function deployContract(bytes32 _salt, bytes calldata _bytecode) external payable {
        address newContract = Create2.deploy(msg.value, _salt, _bytecode);
        emit ContractDeployed(msg.sender, newContract, msg.value);
    }

    function deployPresetContract(uint256 _idx, bytes32 _salt, bytes calldata _bytecode, bytes calldata _params) external payable {
        require(presets.length > _idx, "invalid preset contract index");

        PresetContract memory presetInfo = presets[_idx];
        require(!presetInfo.disabled, "preset contract was disabled");

        bytes32 codeHash = keccak256(_bytecode);
        require(codeHash == presetInfo.codeHash, "invalid code hash");

        bytes memory deployCode = _bytecode.concat(_params);
        address newContract = Create2.deploy(msg.value, _salt, deployCode);
        emit PresetContractDeployed(msg.sender, newContract, _idx, msg.value, presetInfo.fee);
    }

    function addPresetContract(uint256 _fee, string calldata _name, bytes32 _codeHash, bool _disabled) external onlyAdmin {
        presets.push(PresetContract({
            name: _name,
            codeHash: _codeHash,
            fee: _fee,
            disabled: _disabled
        }));
    }

    function disablePresetContract(uint256 _idx) external onlyAdmin {
        presets[_idx].disabled = true;
    }

    function enablePresetContract(uint256 _idx) external onlyAdmin {
        presets[_idx].disabled = false;
    }

    function updatePresetContractName(uint256 _idx, string calldata _name) external onlyAdmin {
        presets[_idx].name = _name;
    }

    function updatePresetContractFee(uint256 _idx, uint256 _fee) external onlyAdmin {
        presets[_idx].fee = _fee;
    }

    function computeAddress(bytes32 _salt, bytes32 _bytecodeHash) internal view returns (address addr) {
        return Create2.computeAddress(_salt, _bytecodeHash);
    }

    function presetContractCount() external view returns (uint256 presetCount) {
        return presets.length;
    }

    function getBytecodeHash(bytes calldata _bytecode) external pure returns(bytes32 hash) {
        return keccak256(_bytecode);
    }
}
