const ContractDeployer = artifacts.require("ContractDeployer.sol");
const web3Instance = new (require('web3'))()
const testDataContractABI = require('./TestDataContractABI')

const calculateCreate2 = require('eth-create2-calculator').calculateCreate2

const testByteCode = "0x60c0604052600e60808190526d189b185b9ac818dbdb9d1c9858dd60921b60a090815261002f9160009190610042565b5034801561003c57600080fd5b506100dd565b828054600181600116156101000203166002900490600052602060002090601f016020900481019282601f1061008357805160ff19168380011785556100b0565b828001600101855582156100b0579182015b828111156100b0578251825591602001919060010190610095565b506100bc9291506100c0565b5090565b6100da91905b808211156100bc57600081556001016100c6565b90565b6101a6806100ec6000396000f3fe608060405234801561001057600080fd5b50600436106100365760003560e01c8063c15bae841461003b578063f2fde38b146100b8575b600080fd5b6100436100e0565b6040805160208082528351818301528351919283929083019185019080838360005b8381101561007d578181015183820152602001610065565b50505050905090810190601f1680156100aa5780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b6100de600480360360208110156100ce57600080fd5b50356001600160a01b031661016e565b005b6000805460408051602060026001851615610100026000190190941693909304601f810184900484028201840190925281815292918301828280156101665780601f1061013b57610100808354040283529160200191610166565b820191906000526020600020905b81548152906001019060200180831161014957829003601f168201915b505050505081565b5056fea265627a7a72315820d9a91649bacb0ff2595a3597ca3b7b1c2fa3c979697026dc7d3548b5a485bf2f64736f6c63430005110032"
const invalidByteCode = "0x60806040526040518060400160405280601b81526020017f626c616e6b20636f6e7472616374202d206279746573206469666600000000008152506000908051906020019061004f929190610062565b5034801561005c57600080fd5b50610107565b828054600181600116156101000203166002900490600052602060002090601f016020900481019282601f106100a357805160ff19168380011785556100d1565b828001600101855582156100d1579182015b828111156100d05782518255916020019190600101906100b5565b5b5090506100de91906100e2565b5090565b61010491905b808211156101005760008160009055506001016100e8565b5090565b90565b6101d8806101166000396000f3fe608060405234801561001057600080fd5b50600436106100365760003560e01c8063c15bae841461003b578063f2fde38b146100be575b600080fd5b610043610102565b6040518080602001828103825283818151815260200191508051906020019080838360005b83811015610083578082015181840152602081019050610068565b50505050905090810190601f1680156100b05780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b610100600480360360208110156100d457600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff1690602001909291905050506101a0565b005b60008054600181600116156101000203166002900480601f0160208091040260200160405190810160405280929190818152602001828054600181600116156101000203166002900480156101985780601f1061016d57610100808354040283529160200191610198565b820191906000526020600020905b81548152906001019060200180831161017b57829003601f168201915b505050505081565b5056fea265627a7a7231582076b84ce3f62b7c26d4e74b4795e7f22f03b846b7c297129f37b825956781ac4064736f6c63430005110032"
const testCodeHash = web3Instance.utils.soliditySha3Raw(testByteCode);

const deployedByteCode = "0x608060405234801561001057600080fd5b50600436106100365760003560e01c8063c15bae841461003b578063f2fde38b146100b8575b600080fd5b6100436100e0565b6040805160208082528351818301528351919283929083019185019080838360005b8381101561007d578181015183820152602001610065565b50505050905090810190601f1680156100aa5780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b6100de600480360360208110156100ce57600080fd5b50356001600160a01b031661016e565b005b6000805460408051602060026001851615610100026000190190941693909304601f810184900484028201840190925281815292918301828280156101665780601f1061013b57610100808354040283529160200191610166565b820191906000526020600020905b81548152906001019060200180831161014957829003601f168201915b505050505081565b5056fea265627a7a72315820d9a91649bacb0ff2595a3597ca3b7b1c2fa3c979697026dc7d3548b5a485bf2f64736f6c63430005110032";
const testDeployedCodeHash = web3Instance.utils.soliditySha3Raw(deployedByteCode);

//salt1 for preset test
const testSalt1 = "0x0c0918d4c66e14d6de8c251fc9be7fdc17c40e3e512ab202c33bc4b5e5beb4a4";

//salt2 for deploy contract directly
const testSalt2 = "0x724e4abea5b0fa1ec78d0cdf4b94dc7fb1da42a8d9508c1cf57058b72684c460";

//pk & address were from remix-project's fixed accounts list
const testApproverPK = "503f38a9c967ed597e47fe25643985f032b072db8075426a92110f82df48dfcb";
const testApprover = "0x5b38da6a701c568545dcfcb03fcb875f56beddc4";
let instance = null;

const testPresetIdx = "0";

async function getSign(data) {
  let dataHash = web3Instance.utils.soliditySha3(...data)
  dataHash = `:${dataHash}`
  return web3Instance.eth.accounts.sign(dataHash, testApproverPK).signature
}

contract("ContractDeployer", async accounts => {
  before('should deploy the contract', async () => {
    instance = await ContractDeployer.new(accounts[0])
      .catch(_=>{
        return null
      })

    assert.isNotNull(instance, `deploy failed: ${instance}`);
  });

  it(`set approver to ${testApprover}`, async ()=>{
    await instance.setDeployApprover(testApprover, {from: accounts[0]});

    let newApprover = await instance.deployApprover.call();
    newApprover = newApprover.toLowerCase()
    assert.equal(testApprover, newApprover, `${testApprover} != ${newApprover}`)
  })

  it(`new contract's address should equal pre-calc address`, async ()=>{
    const newContractAddr = calculateCreate2(instance.address, testSalt2, testByteCode);

    await instance.setDeployApprover(testApprover, {from: accounts[0]});

    let deployedContract = await instance.deployContract(testSalt2, testByteCode, {from: accounts[0]})
      .then(receipt=>{
        return receipt.logs[0].args.addr
      });

    assert.equal(newContractAddr, deployedContract, `${newContractAddr} != ${deployedContract}`)
  })

  it(`new preset should added`, async ()=>{
    let presetCountBefore = await instance.presetContractCount.call();
    presetCountBefore = presetCountBefore.toNumber()

    await instance.addPresetContract(web3.utils.toWei("1"), testDeployedCodeHash, "test contract", true);

    let presetCountAfter = await instance.presetContractCount.call();
    presetCountAfter = presetCountAfter.toNumber()

    assert.equal(presetCountAfter, presetCountBefore + 1, "set failed: not add to list");

    let addedInfo = await instance.presets.call(presetCountBefore.toString());

    assert.equal(addedInfo.fee.toString(), web3.utils.toWei("1"), "set failed: fee not equal");
    assert.equal(addedInfo.name, "test contract", "set failed: name not equal");
    assert.equal(addedInfo.codeHash, testDeployedCodeHash, "set failed: code hash not equal");
    assert.equal(addedInfo.disabled, true, "set failed: disable flag not tue");
  })

  it(`testing disable flag switch`, async ()=>{
    let presetInfo = await instance.presets.call(testPresetIdx);
    assert.equal(presetInfo.disabled, true, "failed: testing must start with state of preset contract was disabled");

    await instance.setPresetContractDisableFlag(testPresetIdx, false, {from: accounts[0]});
    presetInfo = await instance.presets.call(testPresetIdx);
    assert.equal(presetInfo.disabled, false, "failed: enable contract failed");

    await instance.setPresetContractDisableFlag(testPresetIdx, true, {from: accounts[0]});
    presetInfo = await instance.presets.call(testPresetIdx);
    assert.equal(presetInfo.disabled, true, "failed: disable contract failed");

    await instance.setPresetContractDisableFlag(testPresetIdx, false, {from: accounts[0]});
  })

  it(`testing name change`, async ()=>{
    const testName = "name for test";
    let presetInfo = await instance.presets.call(testPresetIdx);
    assert.notEqual(testName, presetInfo.name, "failed: test name must different from current name");

    await instance.updatePresetContractName(testPresetIdx, testName, {from: accounts[0]});
    presetInfo = await instance.presets.call(testPresetIdx);
    assert.equal(testName, presetInfo.name,  "failed: name not change");
  })

  it(`preset contract should be deployed`, async ()=>{
    const  testCodeSig = await getSign([
      {t: 'uint256', v: testPresetIdx},
      {t: 'address', v: accounts[0]}
    ]);

    const testDeploySig = await getSign([
      {t: 'uint256', v: testPresetIdx},
      {t: 'bytes32', v: testSalt1},
      {t: 'address', v: accounts[0]}
    ]);

    let tx = await instance.deployPresetContract(
      testPresetIdx, testCodeSig, testDeploySig, testSalt1, invalidByteCode,
      {from: accounts[0], value: web3.utils.toWei("1")}).catch(e=>{
        return null
      });

    assert.equal(tx, null, `tx must be reverted due to bytecode not match`)

    tx = await instance.deployPresetContract(
      "2", testCodeSig, testDeploySig, testSalt1, testByteCode,
      {from: accounts[0], value: web3.utils.toWei("1")}).catch(e=>{return null});

    assert.equal(tx, null, `tx must be reverted due to preset index was out of range`)


    await instance.setPresetContractDisableFlag(testPresetIdx, true, {from: accounts[0]});
    tx = await instance.deployPresetContract(
      testPresetIdx, testCodeSig, testDeploySig, testSalt1, testByteCode,
      {from: accounts[0], value: web3.utils.toWei("1")}).catch(e=>{return null});

    assert.equal(tx, null, `tx must be reverted due to preset contract was disabled`)

    await instance.setPresetContractDisableFlag(testPresetIdx, false, {from: accounts[0]});
    tx = await instance.deployPresetContract(
      testPresetIdx, testCodeSig, testDeploySig, testSalt1, testByteCode,
      {from: accounts[0], value: web3.utils.toWei("1")}).catch(e=>{return e});

    assert.equal(tx.receipt.status, true, `tx failed: ${tx}`)

  })

  it(`testing fee change`, async ()=>{
    const newFee = web3.utils.toWei("2");
    let presetInfo = await instance.presets.call(testPresetIdx);
    assert.notEqual(newFee, presetInfo.fee.toString(), "failed: new fee must different from current fee");

    await instance.updatePresetContractFee(testPresetIdx, newFee, {from: accounts[0]});
    presetInfo = await instance.presets.call(testPresetIdx);
    assert.equal(newFee, presetInfo.fee.toString(),  "failed: fee must equal the setting fee");
  })

  it(`testing pre-set contracts counts`, async ()=>{
    let counts = await instance.presetContractCount.call();
    assert.equal(counts.toNumber(), 1, "failed: must equal 1 due to we test deploy preset contract before this testing");
  })
});