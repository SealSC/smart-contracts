const StakingMining = artifacts.require("StakingMining");
const ERC20PresetMinterPauser = artifacts.require("@openzeppelin/contracts/ERC20PresetMinterPauser");
const Decimal = require('decimal.js')

let stakingToken = null
let rewardToken = null
let pool = null

let rewardBP = null;

Decimal.set({ toExpPos: 256, precision: 100 })

const testPoolIdx = `0`
const notExistPoolIdx = `100`
const rewardSupply = "1000000000000"

let firstStakingBlock = 0

contract("StakingMining", async accounts => {
  before('prepare the contract', async () => {
    stakingToken = await ERC20PresetMinterPauser.new('staking token', 'st')
    rewardToken = await ERC20PresetMinterPauser.new('reward token', 'rt')

    pool = await StakingMining.new(accounts[0], rewardToken.address)
    rewardBP = await pool.REWARD_BASE_POINT.call()
    rewardBP = new Decimal(rewardBP.toString())

    await rewardToken.mint(pool.address, rewardSupply)
  });

  it(`test prepare successfully`, async ()=>{

    assert.notEqual(stakingToken, null, `failed: staking token not deployed`)
    assert.notEqual(rewardToken, null, `failed: rewardToken token not deployed`)
    assert.notEqual(pool, null, `failed: rewardToken token not deployed`)

    let rewardTokenInPool = await rewardToken.balanceOf.call(pool.address)
    rewardTokenInPool = rewardTokenInPool.toString()

    assert.equal(rewardTokenInPool, rewardSupply, `failed: reward token supply not equal reward token in pool`)
  })

  it(`test create pool`, async () => {
    let poolCount = await pool.poolCount.call()
    poolCount = poolCount.toNumber()

    assert.equal(poolCount, 0, "failed: pool list not empty");

    await pool.createPool(stakingToken.address, rewardBP.div(2).toString());

    poolCount = await pool.poolCount.call()
    poolCount = poolCount.toNumber()

    assert.equal(poolCount, 1, "failed: create pool failed");

    let poolInfo = await pool.poolList(testPoolIdx)

    assert.equal(poolInfo.stakingToken, stakingToken.address, "failed: wrong staking token");
    assert.equal(poolInfo.rewardFactor.toString(), rewardBP.div(2).toString(), "failed: wrong factor");
    assert.equal(poolInfo.closedBlock.toNumber(), 0, "failed: already closed");
    assert.equal(poolInfo.closedFlag, false, "failed: already closed");
    assert.equal(poolInfo.created, true, "failed: pool not exist");
  })

  it(`test stake`, async () => {
    let mintAmount = "200"
    let stakeAmount = "100"
    let stakingAccount = accounts[2]
    await stakingToken.mint(stakingAccount, mintAmount)
    await stakingToken.approve(pool.address, mintAmount, {from: stakingAccount})
    await pool.stake(testPoolIdx, stakeAmount, {from: stakingAccount});

    let stakeInfo = await pool.userStakeInfo.call(stakingAccount, testPoolIdx);

    let poolTokenBalance = await stakingToken.balanceOf.call(pool.address)
    poolTokenBalance = poolTokenBalance.toString()

    firstStakingBlock = await web3.eth.getBlockNumber()

    assert.equal(poolTokenBalance, "100", "failed: wrong staking token balance of pool");
    assert.equal(stakeInfo.stakedAmount.toString(), "100", "failed: wrong staked amount");
    assert.equal(stakeInfo.lastCollectBlock.toNumber(), firstStakingBlock, "failed: last collect must be current block");
  })
  it(`test collect`, async ()=>{
    let stakingAccount = accounts[2]
    let stakingInfo = await pool.userStakeInfo.call(stakingAccount, testPoolIdx);
    let poolInfo = await pool.poolList.call(testPoolIdx);

    let rewardAmount = new Decimal(stakingInfo.stakedAmount.toString()).mul(poolInfo.rewardFactor.toString()).div(rewardBP) //(staked * (currentBlock - lastCollect) * factor) / rewardBP;
    let beforeBalance = await rewardToken.balanceOf(stakingAccount);

    await pool.collect(testPoolIdx, true, {from: stakingAccount});

    let afterBalance = await rewardToken.balanceOf(stakingAccount);
    stakingInfo = await pool.userStakeInfo.call(stakingAccount, testPoolIdx);

    let stakingAfterCollect = stakingInfo.stakedAmount.toString()

    assert.equal(afterBalance.toNumber(), beforeBalance.toNumber() + rewardAmount.toNumber(), "failed: last collect must be current block");
    assert.equal(stakingAfterCollect, "0", "failed: staked amount was modified");

    await pool.stake(testPoolIdx, "100", {from: stakingAccount});
  })
<<<<<<< HEAD
=======
//    function test_collect() public {
//        (uint256 staked, uint256 lastCollect) = pool.userStakeInfo(address (this), testPoolIdx);
//        (IERC20 sToken, uint256 factor, uint256 closedBlock, bool closedFlag, bool created) = pool.poolList(testPoolIdx);
//        uint256 currentBlock = block.number;
//
//        uint256 rewardAmount = (staked * (currentBlock - lastCollect) * factor) / rewardBP;
//        uint256 beforeBalance = rewardToken.balanceOf(address(this));
//        pool.collect(testPoolIdx, false);
//        uint256 afterBalance = rewardToken.balanceOf(address(this));
//        (uint256 stakedAfter,) = pool.userStakeInfo(address (this), testPoolIdx);
//
//        Assert.equal(afterBalance, beforeBalance + rewardAmount, "failed: last collect must be current block");
//        Assert.equal(staked, stakedAfter, "failed: staked amount was modified");
//    }
>>>>>>> b5e2a55... using truffle test & solidity-coverage for staking-mining

  it(`test close pool`, async ()=>{
    let poolInfo = await pool.poolList.call(testPoolIdx)
    assert.equal(poolInfo.closedFlag, false, "failed: pool should be not closed for now");

    await pool.closePool(testPoolIdx)

    poolInfo = await pool.poolList.call(testPoolIdx)
    assert.equal(poolInfo.closedFlag, true, "failed: pool should be closed");

    let tx = await pool.closePool(notExistPoolIdx).catch(_=>{return null});
    assert.equal(tx, null, "failed: tx should be failed due to the idx of the pool is not exist");

    tx = await pool.closePool(testPoolIdx).catch(_=>{return null});
    assert.equal(tx, null, "failed: tx should be failed due to the pool was closed already");
  })

  it(`test collect after pool closed`, async ()=>{
    let stakingAccount = accounts[2]
    let stakingInfo = await pool.userStakeInfo.call(stakingAccount, testPoolIdx);
    let poolInfo = await pool.poolList.call(testPoolIdx);

    let rewardAmount = new Decimal(stakingInfo.stakedAmount.toString()).mul(poolInfo.rewardFactor.toString()).div(rewardBP) //(staked * (currentBlock - lastCollect) * factor) / rewardBP;
    let beforeBalance = await rewardToken.balanceOf(stakingAccount);

    await pool.collect(testPoolIdx, true, {from: stakingAccount});
    let tx = await pool.collect(testPoolIdx, true, {from: stakingAccount}).catch(_=>{return null});
    assert.equal(tx, null, "failed: tx should be failed due to user can not collect more then once in one block");

    let afterBalance = await rewardToken.balanceOf(stakingAccount);
    stakingInfo = await pool.userStakeInfo.call(stakingAccount, testPoolIdx);

    let stakingAfterCollect = stakingInfo.stakedAmount.toString()

    assert.equal(afterBalance.toNumber(), beforeBalance.toNumber() + rewardAmount.toNumber(), "failed: last collect must be current block");
    assert.equal(stakingAfterCollect, "0", "failed: staked amount was modified");

  })

  it(`test stake should failed`, async () => {
    let mintAmount = "200"
    let stakeAmount = "100"
    let stakingAccount = accounts[3]
    await stakingToken.mint(stakingAccount, mintAmount)
    await stakingToken.approve(pool.address, stakeAmount, {from: stakingAccount})

    let tx = await pool.stake(notExistPoolIdx, stakeAmount, {from: stakingAccount}).catch(_=>{return null});
    assert.equal(tx, null, "failed: staking should be failed due to the idx of the pool is not exist");

    tx = await pool.stake(testPoolIdx, stakeAmount, {from: stakingAccount}).catch(_=>{return null});
    assert.equal(tx, null, "failed: staking should be failed due to the pool was closed");
  })

  it(`test pool count`, async () => {
    let count = await pool.poolCount.call()

    assert.equal(count.toString(), "1", "failed: should be only one pool");
  })
});