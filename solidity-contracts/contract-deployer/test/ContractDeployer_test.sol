pragma solidity ^0.6.0;

import "remix_tests.sol"; // injected by remix-tests
import "remix_accounts.sol";
import "../../contract-libs/seal-sc/Utils.sol";
import "../../contract-libs/open-zeppelin/Create2.sol";
import "../../contract-libs/open-zeppelin/Address.sol";
import "../contracts/ContractDeployer.sol";

contract DeployerTest {
    ContractDeployer deployer;
    using Address for address;

    //salt1 for preset test
    bytes32 constant testSalt1 = 0x0c0918d4c66e14d6de8c251fc9be7fdc17c40e3e512ab202c33bc4b5e5beb4a4;

    //salt2 for deploy contract directly
    bytes32 constant testSalt2 = 0x724e4abea5b0fa1ec78d0cdf4b94dc7fb1da42a8d9508c1cf57058b72684c460;

    bytes constant testByteCode = hex"60c0604052600e60808190526d189b185b9ac818dbdb9d1c9858dd60921b60a090815261002f9160009190610042565b5034801561003c57600080fd5b506100dd565b828054600181600116156101000203166002900490600052602060002090601f016020900481019282601f1061008357805160ff19168380011785556100b0565b828001600101855582156100b0579182015b828111156100b0578251825591602001919060010190610095565b506100bc9291506100c0565b5090565b6100da91905b808211156100bc57600081556001016100c6565b90565b6101a6806100ec6000396000f3fe608060405234801561001057600080fd5b50600436106100365760003560e01c8063c15bae841461003b578063f2fde38b146100b8575b600080fd5b6100436100e0565b6040805160208082528351818301528351919283929083019185019080838360005b8381101561007d578181015183820152602001610065565b50505050905090810190601f1680156100aa5780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b6100de600480360360208110156100ce57600080fd5b50356001600160a01b031661016e565b005b6000805460408051602060026001851615610100026000190190941693909304601f810184900484028201840190925281815292918301828280156101665780601f1061013b57610100808354040283529160200191610166565b820191906000526020600020905b81548152906001019060200180831161014957829003601f168201915b505050505081565b5056fea265627a7a72315820d9a91649bacb0ff2595a3597ca3b7b1c2fa3c979697026dc7d3548b5a485bf2f64736f6c63430005110032";
    bytes constant deployedByteCode = hex"608060405234801561001057600080fd5b50600436106100365760003560e01c8063c15bae841461003b578063f2fde38b146100b8575b600080fd5b6100436100e0565b6040805160208082528351818301528351919283929083019185019080838360005b8381101561007d578181015183820152602001610065565b50505050905090810190601f1680156100aa5780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b6100de600480360360208110156100ce57600080fd5b50356001600160a01b031661016e565b005b6000805460408051602060026001851615610100026000190190941693909304601f810184900484028201840190925281815292918301828280156101665780601f1061013b57610100808354040283529160200191610166565b820191906000526020600020905b81548152906001019060200180831161014957829003601f168201915b505050505081565b5056fea265627a7a72315820d9a91649bacb0ff2595a3597ca3b7b1c2fa3c979697026dc7d3548b5a485bf2f64736f6c63430005110032";
    bytes32 testCodeHash = 0x0000000000000000000000000000000000000000000000000000000000000000;
    bytes32 testDeployedCodeHash = 0x0000000000000000000000000000000000000000000000000000000000000000;

    address testApprover = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;

    uint256 constant testPresetIdx = 0;

    function beforeAll() public {
        deployer = new ContractDeployer(address(this));
        testCodeHash = keccak256(testByteCode);
        testDeployedCodeHash = keccak256(deployedByteCode);
    }

    function test_setDeployApprover() public returns (bool) {
        deployer.setDeployApprover(testApprover);
        return Assert.equal(deployer.deployApprover(), testApprover, "set deployer failed");
    }

    function test_deployContract() public payable {
        address requireAddress = Create2.computeAddress(testSalt2, testCodeHash, address(deployer));

        Assert.ok(!requireAddress.isContract(), "already deployed");
        address deployedContract = deployer.deployContract(testSalt2, testByteCode);
        Assert.ok(requireAddress.isContract(), "deploy failed: no code");
        Assert.equal(deployedContract, requireAddress, "deploy failed: address not equal");

        bytes32 tempHash = 0x0;
        assembly {
            tempHash := extcodehash(deployedContract)
        }

        Assert.equal(tempHash, testDeployedCodeHash, "deploy failed: address not equal");
    }

    function test_addPresetContract() public {
        uint256 presetCountBefore = deployer.presetContractCount();

        deployer.addPresetContract(1 ether, testDeployedCodeHash, "test contract", true);

        uint256 presetCountAfter = deployer.presetContractCount();

        Assert.equal(presetCountAfter-1, presetCountBefore, "set failed: not add to list");

        (string memory name, bytes32 codeHash, uint256 fee, bool disabled) = deployer.presets(presetCountBefore);

        Assert.equal(fee, 1 ether, "set failed: fee not equal");
        Assert.equal(name, "test contract", "set failed: name not equal");
        Assert.equal(codeHash, testDeployedCodeHash, "set failed: code hash not equal");
        Assert.equal(disabled, true, "set failed: disable flag not tue");
    }

    function test_setPresetContractDisableFlag() public {
        (string memory name, bytes32 codeHash, uint256 fee, bool disabled) = deployer.presets(testPresetIdx);
        Assert.equal(disabled, true, "failed: testing must start with state of preset contract was disabled");

        deployer.setPresetContractDisableFlag(testPresetIdx, false);
        (name, codeHash, fee,  disabled) = deployer.presets(testPresetIdx);
        Assert.equal(disabled, false, "failed: disable contract failed");

        deployer.setPresetContractDisableFlag(testPresetIdx, true);
        (name, codeHash, fee,  disabled) = deployer.presets(testPresetIdx);
        Assert.equal(disabled, true, "failed: enable contract failed");

        deployer.setPresetContractDisableFlag(testPresetIdx, false);
    }

    function test_updatePresetContractName() public {
        string memory testName = "name for test";
        (string memory name, bytes32 codeHash, uint256 fee, bool disabled) = deployer.presets(testPresetIdx);

        Assert.notEqual(testName, name, "failed: test name must different from current name");

        deployer.updatePresetContractName(testPresetIdx, testName);
        (name, codeHash, fee,  disabled) = deployer.presets(testPresetIdx);
        Assert.equal(testName, name, "failed: test name must equal the setting name");
    }

    function test_updatePresetContractFee() external {
        uint256 testFee = 0.1 ether;
        (string memory name, bytes32 codeHash, uint256 fee, bool disabled) = deployer.presets(testPresetIdx);

        Assert.notEqual(testFee, fee, "failed: test fee must different from current fee");

        deployer.updatePresetContractFee(testPresetIdx, testFee);
        (name, codeHash, fee,  disabled) = deployer.presets(testPresetIdx);
        Assert.equal(testFee, fee, "failed: fee must equal the setting fee");
    }

    /// #sender: account-0
    /// #value: 10000000000000000000
    function test_deployPresetContract() public payable {
        uint256 presetIdx = 0;
        bytes memory testCodeSig = hex"52ccfd24d0a0016a5f923ed9d0e5e9dfb1f739fb9c4bb03208f69a91acdf7a2575855fdd2ddc55ad5e220aebe18b9adaff348ddfe8ec5bdcb31ed2fd3d98ec5e1c";
        bytes memory testDeploySig = hex"c48898fb1ed3fe735ed21c41cd450704c19e336576eb1ad873e2db4290d87e546a231561a1f2ea150d98bd9fcc0cede1a0da2139951d5b5adcbea423659dd68c1c";

        (string memory name, bytes32 codeHash, uint256 fee, bool disabled) = deployer.presets(presetIdx);
        address newContract = deployer.deployPresetContract.value(fee)(presetIdx, testCodeSig, testDeploySig, testSalt1, testByteCode);

        bytes32 deployedHash = 0x0;

        assembly {
            deployedHash := extcodehash(newContract)
        }
        Assert.equal(deployedHash, codeHash, "deploy preset contract failed: hash not equal");
    }

    function test_presetContractCount() public {
        uint256 presetCount = deployer.presetContractCount();
        Assert.equal(presetCount, 1, "failed: must equal 1 due to we test deploy preset contract before this testing");
    }
}
