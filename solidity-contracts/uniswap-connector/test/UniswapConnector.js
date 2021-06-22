const UniswapConnector = artifacts.require("UniswapConnector");
const uniswapFactory = artifacts.require("@uniswap/v2-core/UniswapV2Factory");
const uniswapRouter = artifacts.require("@uniswap/v2-periphery/UniswapV2Router02");
const weth = artifacts.require("@uniswap/v2-periphery/WETH9");

const ERC20PresetMinterPauser = artifacts.require("@openzeppelin/contracts/ERC20PresetMinterPauser");

const Decimal = require('decimal.js')

const erc20abi = require('./ERC20-ABI.js')

let uniFactory = null
let uniRouter = null

let fakeWETH = null
let tokenA = null
let tokenB = null
let tokenForWithdrawTest = null

let uniPairAandWETH = null
let uniPairBandWETH = null
let uniPairAandB = null

let connector = null

let baseAccount = null
const initSupply = "100000000"

const zeroAddress = "0x0000000000000000000000000000000000000000"
const receiverAddress = "0x0000000000000000000000000000000000000123"
const dummyAddress = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"

Decimal.set({ toExpPos: 256, precision: 100 })

const testETHWithdrawAmount = "100"
const testTokenWithdrawAmount = "123"

contract("UniswapConnector", async accounts => {
  before('prepare the contract', async () => {
    baseAccount = accounts[0]

    fakeWETH = await weth.new('WETH', 'WETH')
    tokenA = await ERC20PresetMinterPauser.new('tokenA', 'tokenA')
    tokenB = await ERC20PresetMinterPauser.new('tokenB', 'tokenB')
    tokenForWithdrawTest = await ERC20PresetMinterPauser.new('tokenForWithdrawTest', 'tokenForWithdrawTest')

    await fakeWETH.deposit({from: baseAccount, value: initSupply})
    await tokenA.mint(baseAccount, initSupply)
    await tokenB.mint(baseAccount, initSupply)

    uniFactory = await uniswapFactory.new(baseAccount)
    uniRouter = await uniswapRouter.new(uniFactory.address, fakeWETH.address)

    await fakeWETH.approve(uniRouter.address, initSupply)
    await tokenA.approve(uniRouter.address, initSupply)
    await tokenB.approve(uniRouter.address, initSupply)

    await uniFactory.createPair(tokenA.address, fakeWETH.address)
    await uniFactory.createPair(tokenB.address, fakeWETH.address)
    await uniFactory.createPair(tokenA.address, tokenB.address)

    uniPairAandWETH = await uniFactory.getPair.call(tokenA.address, fakeWETH.address)
    uniPairBandWETH = await uniFactory.getPair.call(tokenB.address, fakeWETH.address)
    uniPairAandB = await uniFactory.getPair.call(tokenA.address, tokenB.address)

    uniPairAandWETH = new web3.eth.Contract(erc20abi, uniPairAandWETH)
    uniPairBandWETH = new web3.eth.Contract(erc20abi, uniPairBandWETH)
    uniPairAandB = new web3.eth.Contract(erc20abi, uniPairAandB)

    connector = await UniswapConnector.new(baseAccount, uniRouter.address, uniFactory.address, fakeWETH.address)

    await tokenForWithdrawTest.mint(connector.address, testTokenWithdrawAmount)

    await uniRouter.addLiquidity(tokenA.address, fakeWETH.address, "10000000", "10000000", "0", "0", baseAccount, "33166342861")
    await uniRouter.addLiquidity(tokenB.address, fakeWETH.address, "10000000", "10000000", "0", "0", baseAccount, "33166342861")
    await uniRouter.addLiquidity(tokenA.address, tokenB.address, "10000000", "10000000", "0", "0", baseAccount, "33166342861")

    await tokenB.transfer(connector.address, testTokenWithdrawAmount)
    await web3.eth.sendTransaction({from: baseAccount, to: connector.address, value: testETHWithdrawAmount})
  });

  it(`evn check`, async ()=>{
    assert.notEqual(fakeWETH, null, `weth not ready`)
    assert.notEqual(tokenA, null, `tokenA not ready`)
    assert.notEqual(tokenB, null, `tokenB not ready`)
    assert.notEqual(uniFactory, null, `uniFactory not ready`)
    assert.notEqual(uniRouter, null, `uniRouter not ready`)
    assert.notEqual(uniPairAandWETH, null, `uniPairAandWETH not ready`)
    assert.notEqual(uniPairBandWETH, null, `uniPairBandWETH not ready`)
    assert.notEqual(uniPairAandB, null, `uniPairAandB not ready`)
    assert.notEqual(connector, null, `connector not ready`)
  })

  it(`test add supported pair`, async ()=>{
    await connector.addSupportedPair(uniPairAandWETH._address, tokenA.address, fakeWETH.address)

    let token0 = await connector.supportedPair.call(uniPairAandWETH._address, 0)
    let token1 = await connector.supportedPair.call(uniPairAandWETH._address, 1)

    assert.equal(tokenA.address, token0, `failed: token0 should be ${tokenA.address}`)
    assert.equal(fakeWETH.address, token1, `failed: token1 should be ${fakeWETH.address}`)

    await connector.addSupportedPair(uniPairBandWETH._address, zeroAddress, tokenB.address)
    token0 = await connector.supportedPair.call(uniPairBandWETH._address, 0)
    token1 = await connector.supportedPair.call(uniPairBandWETH._address, 1)

    assert.equal(zeroAddress, token0, `failed: token0 should be ${fakeWETH.address}`)
    assert.equal(tokenB.address, token1, `failed: token1 should be ${tokenB.address}`)

    assert.equal(zeroAddress, token0, `failed: token0 should be ${fakeWETH.address}`)
    assert.equal(tokenB.address, token1, `failed: token1 should be ${tokenB.address}`)

    let tx = await connector.addSupportedPair(uniPairAandWETH._address, tokenA.address, fakeWETH.address)
      .catch(_=>{return null})
    assert.equal(tx, null, `failed: tx should be null due to the supported token added already`)

    tx = await connector.addSupportedPair(uniPairAandB._address, tokenA.address, fakeWETH.address)
      .catch(_=>{return null})
    assert.equal(tx, null, `failed: tx should be null due to LP not for token pair`)

    await connector.addSupportedPair(uniPairAandB._address, tokenA.address, tokenB.address)
  })

  it(`test withdraw`, async ()=>{
    let targetAccount = accounts[1]
    let balanceOfETH = await web3.eth.getBalance(connector.address)
    balanceOfETH = new Decimal(balanceOfETH)
    let balanceToken = await tokenForWithdrawTest.balanceOf.call(connector.address)
    balanceToken = new Decimal(balanceToken.toString())

    let baseETH = await web3.eth.getBalance(targetAccount)
    baseETH = new Decimal(baseETH)
    let baseToken = await tokenForWithdrawTest.balanceOf.call(targetAccount)
    baseToken = new Decimal(baseToken.toString())

    await connector.withdrawFee(targetAccount)
    await connector.withdrawToken(tokenForWithdrawTest.address, targetAccount)

    let ethAfterWithdraw = await web3.eth.getBalance(targetAccount)
    ethAfterWithdraw = new Decimal(ethAfterWithdraw)
    let tokenAfterWithdraw = await tokenForWithdrawTest.balanceOf.call(targetAccount)
    tokenAfterWithdraw = new Decimal(tokenAfterWithdraw.toString())

    assert.isTrue(ethAfterWithdraw.eq(baseETH.add(balanceOfETH)), `failed: withdraw eth not equal`)
    assert.isTrue(tokenAfterWithdraw.eq(baseToken.add(balanceToken)), `failed: withdraw token not equal`)
  })

  it(`test remove LP directly`, async ()=>{
    let lpAAmount = await uniPairAandWETH.methods.balanceOf(baseAccount).call()
    lpAAmount = new Decimal(lpAAmount)

    let beforeETH = await web3.eth.getBalance(receiverAddress)
    beforeETH = new Decimal(beforeETH)
    let beforeTokenABalance = await tokenA.balanceOf.call(receiverAddress)
    beforeTokenABalance = new Decimal(beforeTokenABalance.toString())
    let beforeTokenBBalance = await tokenB.balanceOf.call(receiverAddress)
    beforeTokenBBalance = new Decimal(beforeTokenBBalance.toString())
    let beforeWETHBBalance = await fakeWETH.balanceOf.call(receiverAddress)
    beforeWETHBBalance = new Decimal(beforeWETHBBalance.toString())

    const lpAToRemove = lpAAmount.div(10).toDP(0).toString()
    await uniPairAandWETH.methods.approve(connector.address, lpAAmount.toString()).send({from:baseAccount})
    await connector.flashRemoveLP(
      uniPairAandWETH._address,
      receiverAddress,
      lpAToRemove,
      true)

    let lpAAfterRemove = await uniPairAandWETH.methods.balanceOf(baseAccount).call()
    assert.isTrue(lpAAmount.sub(lpAToRemove).eq(lpAAfterRemove), `failed: invalid lp A removed amount`)

    let lpBAmount = await uniPairBandWETH.methods.balanceOf(baseAccount).call()
    lpBAmount = new Decimal(lpBAmount)
    const lpBToRemove = lpBAmount.div(10).toDP(0).toString()
    await uniPairBandWETH.methods.approve(connector.address, lpBAmount.toString()).send({from:baseAccount})
    await connector.flashRemoveLP(
      uniPairBandWETH._address,
      receiverAddress,
      lpBToRemove,
      true)
    let lpBAfterRemove = await uniPairAandWETH.methods.balanceOf(baseAccount).call()
    assert.isTrue(lpBAmount.sub(lpBToRemove).eq(lpBAfterRemove), `failed: invalid lp B removed amount`)

    let tx = await connector.flashRemoveLP(
      connector._address,
      receiverAddress,
      lpBToRemove,
      true).catch(_=>{return null})

    assert.equal(tx, null, `failed: tx should be null due to invalid lp address`)

    let afterETH = await web3.eth.getBalance(receiverAddress)
    afterETH = new Decimal(afterETH)
    let afterTokenABalance = await tokenA.balanceOf.call(receiverAddress)
    afterTokenABalance = new Decimal(afterTokenABalance.toString())
    let afterTokenBBalance = await tokenB.balanceOf.call(receiverAddress)
    afterTokenBBalance = new Decimal(afterTokenBBalance.toString())
    let afterWETHBBalance = await fakeWETH.balanceOf.call(receiverAddress)
    afterWETHBBalance = new Decimal(afterWETHBBalance.toString())

    assert.isTrue(afterETH.gt(beforeETH), `failed: eth not received from LP removing`)
    assert.isTrue(afterTokenABalance.gt(beforeTokenABalance), `failed: token a not received from LP removing`)
    assert.isTrue(afterTokenBBalance.gt(beforeTokenBBalance), `failed: token b not received from LP removing`)
    assert.isTrue(afterWETHBBalance.gt(beforeWETHBBalance), `failed: weth not received from LP removing`)
  })

  it(`test remove lp for one token`, async ()=>{
    let beforeETH = await web3.eth.getBalance(receiverAddress)
    beforeETH = new Decimal(beforeETH)
    let beforeTokenABalance = await tokenA.balanceOf.call(receiverAddress)
    beforeTokenABalance = new Decimal(beforeTokenABalance.toString())
    let beforeTokenBBalance = await tokenB.balanceOf.call(receiverAddress)
    beforeTokenBBalance = new Decimal(beforeTokenBBalance.toString())
    let beforeWETHBBalance = await fakeWETH.balanceOf.call(receiverAddress)
    beforeWETHBBalance = new Decimal(beforeWETHBBalance.toString())

    let lpAAmount = await uniPairAandWETH.methods.balanceOf(baseAccount).call()
    lpAAmount = new Decimal(lpAAmount)

    const lpAToRemove = lpAAmount.div(10).toDP(0).toString()

    await connector.flashRemoveLPForOneToken(
      uniPairAandWETH._address,
      tokenA.address,
      receiverAddress,
      lpAToRemove
    )

    let lpBAmount = await uniPairBandWETH.methods.balanceOf(baseAccount).call()
    lpBAmount = new Decimal(lpBAmount)

    const lpBToRemove = lpBAmount.div(10).toDP(0).toString()

    await connector.flashRemoveLPForOneToken(
      uniPairBandWETH._address,
      tokenB.address,
      receiverAddress,
      lpBToRemove
    )

    await connector.flashRemoveLPForOneToken(
      uniPairBandWETH._address,
      zeroAddress,
      receiverAddress,
      lpBToRemove
    )

    await connector.flashRemoveLPForOneToken(
      uniPairAandWETH._address,
      fakeWETH.address,
      receiverAddress,
      lpBToRemove
    )

    let afterETH = await web3.eth.getBalance(receiverAddress)
    afterETH = new Decimal(afterETH)
    let afterTokenABalance = await tokenA.balanceOf.call(receiverAddress)
    afterTokenABalance = new Decimal(afterTokenABalance.toString())
    let afterTokenBBalance = await tokenB.balanceOf.call(receiverAddress)
    afterTokenBBalance = new Decimal(afterTokenBBalance.toString())
    let afterWETHBBalance = await fakeWETH.balanceOf.call(receiverAddress)
    afterWETHBBalance = new Decimal(afterWETHBBalance.toString())

    assert.isTrue(afterETH.gt(beforeETH), `failed: eth not received from LP removing`)
    assert.isTrue(afterTokenABalance.gt(beforeTokenABalance), `failed: token a not received from LP removing`)
    assert.isTrue(afterTokenBBalance.gt(beforeTokenBBalance), `failed: token b not received from LP removing`)
    assert.isTrue(afterWETHBBalance.gt(beforeWETHBBalance), `failed: weth not received from LP removing`)
  })

  it(`test flash get lp`, async ()=>{
    await tokenA.approve(connector.address, initSupply)
    await tokenB.approve(connector.address, initSupply)
    await fakeWETH.approve(connector.address, initSupply)

    await connector.flashGetLP(
      uniPairAandWETH._address,
      tokenA.address,
      "10000",
      fakeWETH.address
    ).catch(e=>{
      console.log("3", e)
    })

    await connector.flashGetLP(
      uniPairBandWETH._address,
      zeroAddress,
      "10000",
      tokenB.address,
      {value: "10000"}
    )

    await connector.flashGetLP(
      uniPairBandWETH._address,
      tokenB.address,
      "10000",
      zeroAddress
    )

    await connector.flashGetLP(
      uniPairAandB._address,
      tokenA.address,
      "10000",
      tokenB.address
    ).catch(e=>{
      console.log("1")
    })
  })

  it(`test flash get lp should failed`, async ()=>{
    let tx1 = await connector.flashGetLP(
      uniPairAandWETH._address,
      tokenA.address,
      "10000",
      zeroAddress
    ).catch(e=>{
      return null
    })

    let tx2 = await connector.flashGetLP(
      uniPairAandWETH._address,
      zeroAddress,
      "0",
      tokenA.address,
      {value: "10000"}
    ).catch(e=>{
      return null
    })

    let tx3 = await connector.flashGetLP(
      uniPairAandB._address,
      tokenA.address,
      "0",
      tokenB.address,
      {value: "10000"}
    ).catch(e=>{
      return null
    })

    assert.equal(tx1, null, `failed: tx should be null due to address of token b is address zero`)
    assert.equal(tx2, null, `failed: tx should be null due to address of token a is address zero`)
    assert.equal(tx3, null, `failed: tx should be null due to eth should not sent to connector`)
  })

  it(`test view functions`, async ()=>{
    let pairsAAndB = await connector.lpToPair.call(uniPairAandB._address)
    let dummy = await connector.lpToPair.call(connector.address)
    let supportedPair = await connector.supportedPairCount.call()

    assert.equal(pairsAAndB['0'], tokenA.address, `failed: token0 should be token A`)
    assert.equal(pairsAAndB['1'], tokenB.address, `failed: token0 should be token B`)

    assert.equal(dummy['0'], dummyAddress, `failed: token0 should be ${dummyAddress}`)
    assert.equal(dummy['1'], dummyAddress, `failed: token0 should be ${dummyAddress}`)

    assert.equal(supportedPair.toString(), "3", `failed: supported pair should be 3`)
  })
});