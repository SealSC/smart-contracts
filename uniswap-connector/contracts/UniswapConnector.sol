pragma solidity ^0.5.9;

import "../../contract-libs/open-zeppelin/Ownable.sol";
import "../../contract-libs/open-zeppelin/SafeMath.sol";
import "../../contract-libs/open-zeppelin/Address.sol";
import "../../contract-libs/uniswap/IUniswapV2Router02.sol";
import "../../mining-pools/contracts/interface/IMiningPools.sol";
import "../../contract-libs/open-zeppelin/SafeERC20.sol";
import "./UniswapConnectorAdmin.sol";
import "./UniswapConnectorViews.sol";

contract UniswapConnector is UniswapConnectorAdmin, UniswapConnectorViews {
    using SafeMath for uint256;
    using Address for address payable;
    using SafeERC20 for IERC20;

    constructor(address _owner, address _pools, address _router) public Ownable(_owner) {
        feeBasisPoint = feePrecision.div(10000).mul(400);
        miningPools = IMiningPools(_pools);
        router = IUniswapV2Router02(_router);
    }

    function flashStakingToken(address _lp, address _inToken, uint256 _amount, address _outToken, uint256 _pid) external {
        require(supportedPair[_lp].length == 2, "token not supported");
        address stakingToken = miningPools.getPoolStakingToken(_pid);
        require(stakingToken == _lp, "not the right staking pool");

        if(supportedPair[_lp][0] == _inToken) {
            require(supportedPair[_lp][1] == _outToken, "not a pair");
        } else {
            require(supportedPair[_lp][0] == _outToken && supportedPair[_lp][1] == _inToken, "not a pair");
        }

        address thisAddr = address(this);
        IERC20 forToken = IERC20(_outToken);
        IERC20 lpToken = IERC20(_lp);
        IERC20 inToken = IERC20(_inToken);

        inToken.safeTransferFrom(msg.sender, thisAddr, _amount);

        uint256 fee = _amount.mul(feeBasisPoint).div(feePrecision);
        (uint256 swapBack, uint256 swapVal) = _swapToken(_inToken, _outToken, _amount, fee, forToken);

        uint256 beforeAddLPAmount = lpToken.balanceOf(address(this));

        _addLiquidity(_inToken, _outToken, swapVal.add(fee), swapBack, thisAddr);

        uint256 afterAddLPAmount = lpToken.balanceOf(address(this));

        miningPools.depositByContract(_pid, afterAddLPAmount.sub(beforeAddLPAmount), msg.sender);
    }

    function _swapETHForToken(uint256 fee, address _token, IERC20 forToken) internal returns(uint256, uint256) {
        uint256 beforeSwap = forToken.balanceOf(address(this));

        uint256 ethVal = msg.value.sub(fee);
        uint256 swapVal = ethVal.div(2);

        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] =  _token;

        router.swapExactETHForTokens.value(swapVal)(0, path, address(this), block.timestamp + 600);

        uint256 afterSwap = forToken.balanceOf(address(this));
        uint256 swapBackAmount = afterSwap.sub(beforeSwap);

        return (swapBackAmount, swapVal);
    }

    function flashStakingETH(address _lp, address _token, uint256 _pid) external payable {
        require(supportedPair[_lp].length == 2, "token not supported");
        require(supportedPair[_lp][1] == _token, "token not supported");

        address stakingToken = miningPools.getPoolStakingToken(_pid);
        require(stakingToken == _lp, "not the right staking pool");

        IERC20 forToken = IERC20(_token);
        IERC20 lpToken = IERC20(_lp);
        uint256 fee = msg.value.mul(feeBasisPoint).div(feePrecision);
        (uint256 swapBack, uint256 swapVal) = _swapETHForToken(fee, _token, forToken);

        uint256 beforeAddLPAmount = lpToken.balanceOf(address(this));
        _addLiquidityETH(swapVal.add(fee), _token, swapBack, address(this));
        uint256 afterAddLPAmount = lpToken.balanceOf(address(this));

        miningPools.depositByContract(_pid, afterAddLPAmount.sub(beforeAddLPAmount), msg.sender);
    }

    function () external payable {}
}
