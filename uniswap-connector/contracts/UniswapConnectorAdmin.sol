pragma solidity ^0.5.9;

import "../../contract-libs/open-zeppelin/IERC20.sol";
import "../../contract-libs/open-zeppelin/SafeERC20.sol";
import "../../contract-libs/open-zeppelin/Ownable.sol";
import "./UniswapConnectorInternal.sol";

contract UniswapConnectorAdmin is Ownable, UniswapConnectorInternal {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Address for address payable;

    function approveRouterUseWETH() external onlyOwner {
        weth.safeApprove(address(router), ~uint256(0));
    }

    function addSupportedPair(address _lpToken, address _tokenA, address _tokenB) external onlyOwner {
        address[] storage pair = supportedPair[_lpToken];
        if(pair.length != 0) {
            revert("already added");
        }

        address tokenAAddr = _tokenA;
        if(tokenAAddr ==  ZERO_ADDRESS) {
            tokenAAddr = address(weth);
        }
        address pairAddr = factory.getPair(tokenAAddr, _tokenB);
        require(_lpToken == pairAddr,  "not a uni-pair");

        pair.push(_tokenA);
        pair.push(_tokenB);

        supportedList.push(_lpToken);

        IERC20 lp = IERC20(_lpToken);
        IERC20 tokenA = IERC20(_tokenA);
        IERC20 tokenB = IERC20(_tokenB);

        lp.safeApprove(address(router), ~uint256(0));

        if(_tokenA != ZERO_ADDRESS) {
            if(tokenA.allowance(address(this), address(router)) == 0) {
                tokenA.safeApprove(address(router), ~uint256(0));
            }
        }

        if(tokenB.allowance(address(this), address(router)) == 0) {
            tokenB.safeApprove(address(router), ~uint256(0));
        }
    }

    function withdrawFee(address payable _to) external onlyOwner {
        _to.sendValue(address(this).balance);
    }

    function withdrawToken(address _token, address _to) external onlyOwner {
        IERC20 token = IERC20(_token);
        token.safeTransfer(_to, token.balanceOf(address(this)));
    }

    function setWETHAddress(address _weth) external onlyOwner {
        weth = IERC20(_weth);
    }
}
