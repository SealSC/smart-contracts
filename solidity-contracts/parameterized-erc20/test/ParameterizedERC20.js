const ParameterizedERC20 = artifacts.require("ParameterizedERC20");

const tokenName = "test token";
const tokenSymbol = "tt";
const testDecimals = "4";
const initSupply = "1000000000";
const mintEnabled = true;
const BASIS_POINT = "1000000000000000000"; //this is the factor base point
const HALF_BASIS_POINT = "500000000000000000"; //this is half of the factor base point

let testToken = null
let noneMinalbeToken = null

contract("ParameterizedERC20", async accounts => {
  before('deploy the contract', async () => {
    testToken = await ParameterizedERC20.new(accounts[0], tokenName, tokenSymbol, testDecimals, mintEnabled, initSupply)
      .catch(_=>{
        return null
      })

    noneMinalbeToken = await ParameterizedERC20.new(accounts[0], tokenName, tokenSymbol, testDecimals, false, initSupply)
    assert.isNotNull(testToken, `deploy failed: ${testToken}`);
  });

  it(`test issue to address zero should be failed`, async ()=>{
    let nullToken = await ParameterizedERC20.new('0x0000000000000000000000000000000000000000', tokenName, tokenSymbol, testDecimals, mintEnabled, initSupply)
      .catch(_=>{
        return null
      })

    assert.equal(nullToken, null, `deploy not failed: ${testToken}`);
  })

  it(`test mint enable switch`, async ()=>{
    let enabled = await testToken.mintEnabled.call()
    assert.equal(enabled, true, "failed: must start testing in enable state");

    await testToken.setMintEnableStatus(false, {from: accounts[0]})
    enabled = await testToken.mintEnabled.call();
    assert.equal(enabled, false, "failed: mintEnabled's value must be false");

    await testToken.setMintEnableStatus(true, {from: accounts[0]})
    enabled = await testToken.mintEnabled.call();
    assert.equal(enabled, true, "failed: mintEnabled's value must be true");
  })

  it(`add minter test`, async ()=>{
    let minter = await testToken.minters.call(accounts[0])
    assert.equal(minter.minter, "0x0000000000000000000000000000000000000000", "failed: minter must been not set");

    await testToken.addMinter(accounts[0], "0");
    minter = await testToken.minters.call(accounts[0])
    assert.equal(minter.minter, accounts[0], "failed: minter must been set");
    assert.equal(minter.factor.toString(), BASIS_POINT, `failed: factor must be ${BASIS_POINT}`);

    let tx = await testToken.addMinter(accounts[0], "0").catch(_=>{return null});
    assert.equal(tx, null, `failed: tx must be failed due to minter already added`);
  })

  it(`remove minter test`, async ()=>{
    let minter = await testToken.minters.call(accounts[0])
    assert.equal(minter.minter, accounts[0], "failed: minter must been set before testing");

    await testToken.removeMinter(accounts[0]);
    minter = await testToken.minters.call(accounts[0])
    assert.equal(minter.minter, "0x0000000000000000000000000000000000000000", "failed: minter must been set");
    assert.equal(minter.factor.toString(), "0", "failed: factor must be 0");
  })

  it(`update minter's factor`, async ()=>{
    await testToken.addMinter(accounts[0], HALF_BASIS_POINT);
    let minter = await testToken.minters.call(accounts[0])
    assert.equal(minter.minter, accounts[0], "failed: minter must been set before testing");
    assert.equal(minter.factor, HALF_BASIS_POINT, "failed: minter's factor must been set to half of base point");

    testToken.updateMinterFactor([accounts[0], accounts[1]], [BASIS_POINT, BASIS_POINT]);

    minter = await testToken.minters.call(accounts[0])
    assert.equal(minter.factor.toString(), BASIS_POINT, "failed: minter's factor must been set to half of base point");
  })

  it(`test update minter's factor should failed`, async ()=>{
    let tx = await testToken.updateMinterFactor([accounts[0]], [BASIS_POINT, BASIS_POINT]).catch(_=>{return null});
    assert.equal(tx, null, "failed: tx must be failed due to accounts length not equal factor length");
  })

  it(`none minable token test`, async()=>{
    await noneMinalbeToken.addMinter(accounts[0], HALF_BASIS_POINT);

    let tx = await noneMinalbeToken.mint(accounts[1], "100").catch(e=>{return null});
    assert.equal(tx, null, `failed: tx must be failed due to this it's a none minable token`)
  })

  it(`minte token`, async ()=>{
    await testToken.updateMinterFactor([accounts[0]], [HALF_BASIS_POINT]);
    let minter = await testToken.minters.call(accounts[0])
    assert.equal(minter.minter, accounts[0], "failed: minter must been set before testing");
    assert.equal(minter.factor, HALF_BASIS_POINT, "failed: minter's factor must been set to half of base point");

    let account1BalanceBeforeMint = await testToken.balanceOf.call(accounts[1]);

    await testToken.setMintEnableStatus(false, {from: accounts[0]})

    let tx = await testToken.mint(accounts[1], "100").catch(e=>{return null});
    assert.equal(tx, null, `failed: tx must be failed due to the mint disabled`)

    await testToken.setMintEnableStatus(true, {from: accounts[0]})
    tx = await testToken.mint("0x0000000000000000000000000000000000000000", "100").catch(e=>{return null});
    assert.equal(tx, null, `failed: tx must be failed due to receiver is address zero`)

    tx = await testToken.mint("0x0000000000000000000000000000000000000000", "100", {from: accounts[1]}).catch(e=>{return null});
    assert.equal(tx, null, `failed: tx must be failed due to  sender not minter`)

    testToken.mint(accounts[1], "100");
    let account1BalanceAfterMint = await testToken.balanceOf.call(accounts[1]);

    assert.equal(
      account1BalanceAfterMint.toNumber(),
      account1BalanceBeforeMint.toNumber() + 50,
      "failed: the balance after mint must be equal balance before mint plus 50 due to the factor was half BP")
  })

  it(`test blacklist`, async ()=>{
    const blackListTestingAddr = accounts[3]
    let blocked = await testToken.blackList.call(blackListTestingAddr)
    assert.equal(blocked, false, "failed: must not in black list before testing");

    await testToken.addToBlackList(blackListTestingAddr);
    blocked = await testToken.blackList.call(blackListTestingAddr)
    assert.equal(blocked, true, "failed: must in black list");

    await testToken.removeFromBlackList(blackListTestingAddr);
    blocked = await testToken.blackList.call(blackListTestingAddr)
    assert.equal(blocked, false, "failed: must not in black list due to removed");

    await testToken.transfer(blackListTestingAddr, "100")
    let blockedBalance = await testToken.balanceOf.call(blackListTestingAddr)
    blockedBalance = blockedBalance.toNumber()
    assert.equal(blockedBalance, 100, "failed: transfer must be success due to receiver not in blacklist for now");

    await testToken.addToBlackList(blackListTestingAddr);

    let tx = await testToken.transfer(blackListTestingAddr, "100").catch(_=>{return null})
    assert.equal(tx, null, `failed: tx must failed due to receiver was in blacklist`)

    tx = await testToken.transfer(accounts[4], "1", {from: blackListTestingAddr}).catch(_=>{return null})
    assert.equal(tx, null, `failed: tx must failed due to sender was in blacklist`)

  })
  //    function test_addToBlackList() public {
//        bool blocked = testToken.blackList(blackListTestingAddr);
//        Assert.equal(blocked, false, "failed: must not in black list before testing");
//
//        testToken.addToBlackList(blackListTestingAddr);
//        blocked = testToken.blackList(blackListTestingAddr);
//
//        Assert.equal(blocked, true, "failed: must in black list before testing");
//
//    }
});