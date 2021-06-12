pragma solidity ^0.6.0;

import "remix_tests.sol"; // injected by remix-tests
import "remix_accounts.sol";
import "../../contract-libs/seal-sc/Utils.sol";
import "../contracts/ParameterizedERC20.sol";

contract DeployerTest {
    ParameterizedERC20 testToken;

    string constant tokenName = "test token";
    string constant tokenSymbol = "tt";
    uint8 constant testDecimals = 4;
    uint256 constant initSupply = 10000 * (10**4);
    bool constant mintEnabled = true;
    uint256 constant BASIS_POINT_PRECISION = 1e18; //this is the factor base point
    address constant blackListTestingAddr = address(1);

    function beforeAll() public {
        testToken = new ParameterizedERC20(address(this), tokenName, tokenSymbol, testDecimals, mintEnabled, initSupply);
    }

    function test_setMintEnableStatus() public {
        bool enabled = testToken.mintEnabled();
        Assert.equal(enabled, true, "failed: must start testing in enable state");

        testToken.setMintEnableStatus(false);
        enabled = testToken.mintEnabled();
        Assert.equal(enabled, false, "failed: mintEnabled's value must be false");

        testToken.setMintEnableStatus(true);
        enabled = testToken.mintEnabled();
        Assert.equal(enabled, true, "failed: mintEnabled's value must be true");
    }

    function test_addMinter() public {
        (address minter, uint256 factor) = testToken.minters(address (this));
        Assert.equal(minter, address(0), "failed: minter must been not set");

        testToken.addMinter(address(this), 123);
        (minter, factor) = testToken.minters(address (this));
        Assert.equal(minter, address(this), "failed: minter must been set");
        Assert.equal(factor, 123, "failed: factor must be 1");
    }

    function test_removeMinter() public {
        (address minter, uint256 factor) = testToken.minters(address (this));
        Assert.equal(minter, address(this), "failed: minter must been set before testing");

        testToken.removeMinter(address(this));
        (minter, factor) = testToken.minters(address (this));
        Assert.equal(minter, address(0), "failed: minter must been removed");
        Assert.equal(factor, 0, "failed: removed minter's factor must be 0");

        testToken.addMinter(address(this), BASIS_POINT_PRECISION);
    }

    function test_updateMinterFactor() public {
        uint256[] memory testFactor = new uint256[](1);
        address [] memory testAddress = new address [](1);

        testFactor[0] = BASIS_POINT_PRECISION / 2;
        testAddress[0] = address (this);

        (address minter, uint256 factor) = testToken.minters(address (this));
        Assert.equal(minter, address(this), "failed: minter must been set before testing");
        Assert.notEqual(factor, testFactor[0], "failed: factor must not equal test value before testing");


        testToken.updateMinterFactor(testAddress, testFactor);
        (minter, factor) = testToken.minters(address (this));
        Assert.equal(factor, testFactor[0], "failed: factor must equal test value");
    }

    function test_mint() public {
        (address minter, uint256 factor) = testToken.minters(address (this));
        Assert.equal(minter, address(this), "failed: minter must been set before testing");
        Assert.equal(factor, BASIS_POINT_PRECISION / 2, "failed: factor must be half of BP");

        uint256 thisBalance = testToken.balanceOf(address (this));
        Assert.equal(thisBalance, initSupply, "failed: this balance must be equal init supply before testing");

        testToken.mint(address(this), 100);
        thisBalance = testToken.balanceOf(address (this));

        Assert.equal(thisBalance, initSupply + 50, "failed: this balance must be equal init supply plus 50 due to the factor was half BP");
    }

    function test_addToBlackList() public {
        bool blocked = testToken.blackList(blackListTestingAddr);
        Assert.equal(blocked, false, "failed: must not in black list before testing");

        testToken.addToBlackList(blackListTestingAddr);
        blocked = testToken.blackList(blackListTestingAddr);

        Assert.equal(blocked, true, "failed: must in black list before testing");

    }

    function test_removeFromBlackList() public {
        bool blocked = testToken.blackList(blackListTestingAddr);
        Assert.equal(blocked, true, "failed: must in black list before testing");

        testToken.removeFromBlackList(blackListTestingAddr);
        blocked = testToken.blackList(blackListTestingAddr);

        Assert.equal(blocked, false, "failed: must not in black list before testing");
    }
}
