pragma solidity ^0.5.9;

import "../../contract-libs/open-zeppelin/Ownable.sol";
import "../../contract-libs/open-zeppelin/SafeMath.sol";
import "../../contract-libs/open-zeppelin/IERC20.sol";
import "../../mineable-erc20/contracts/interface/IMineableERC20.sol";
import "./interface/IERC20TokenSupplier.sol";
import "../../contract-libs/seal-sc/Constants.sol";
import "../../contract-libs/open-zeppelin/SafeERC20.sol";
import "../../contract-libs/seal-sc/RejectDirectETH.sol";
import "../../contract-libs/seal-sc/Utils.sol";

contract ERC20TokenSupplier is Ownable, Mutex, IERC20TokenSupplier, Constants, RejectDirectETH {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    mapping(address=>TokenInfo) public tokens;
    address[] public tokenArray;

    mapping(address=>bool) public consumers;
    modifier onlyConsumer() {
        require(consumers[msg.sender], "not consumer");
        _;
    }

    constructor(address _owner) public Ownable(_owner) {}

    function tokenCount() external view returns(uint256) {
        return tokenArray.length;
    }

    function getTokenSupply(address _token) external view returns(uint256) {
        require(tokens[_token].token != ZERO_ADDRESS, "not supported yet");

        TokenInfo memory ti = tokens[_token];
        return (SupplyMode.Transfer == ti.supplyMode)  ?
                    IMineableERC20(ti.token).balanceOf(address(this)) : IERC20(ti.token).totalSupply();
    }

    function addConsumer(address _consumer) external onlyOwner {
        consumers[_consumer] = true;
    }

    function removeConsumer(address _consumer) external onlyOwner {
        delete consumers[_consumer];
    }

    function addToken(address _token, uint256 mode) external onlyOwner{
        TokenInfo memory ti = TokenInfo({
            token: _token,
            supplyMode: SupplyMode(mode)
        });

        tokens[_token] = ti;
    }

    function _supplyByTransfer(TokenInfo memory ti, address to, uint256 amount) internal returns(uint256) {
        IERC20 token = IERC20(ti.token);
        uint256 supplyBeforeMint = token.balanceOf(address(this));

        if(supplyBeforeMint < amount) {
            amount = supplyBeforeMint;
        }
        token.safeTransfer(to, amount);

        uint256 supplyAfterMint = token.balanceOf(address(this));
        return supplyBeforeMint.sub(supplyAfterMint);
    }

    function _supplyByMint(TokenInfo memory ti, address to, uint256 amount) internal returns(uint256) {
        IMineableERC20 token = IMineableERC20(ti.token);
        uint256 supplyBeforeMint = token.balanceOf(to);

        token.mint(to, amount);

        uint256 supplyAfterMint = token.balanceOf(to);
        return supplyAfterMint.sub(supplyBeforeMint);
    }

    function mint(address _token, address _to, uint256 _amount) external onlyConsumer noReentrancy returns(uint256) {
        TokenInfo memory ti = tokens[_token];
        require(ti.token != ZERO_ADDRESS, "no such token");

        return (SupplyMode.Transfer == ti.supplyMode) ?
                    _supplyByTransfer(ti, _to, _amount) : _supplyByMint(ti, _to, _amount);
    }
}
