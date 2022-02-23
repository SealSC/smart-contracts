// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6.0;

import "../../../contract-libs/open-zeppelin/SafeMath.sol";
import "../../../contract-libs/open-zeppelin/Address.sol";
import "../../../contract-libs/open-zeppelin/SafeERC20.sol";
import "../AdventureIslandData/AdventureIslandData.sol";
import "../../../contract-libs/seal-sc/Calculation.sol";

contract AdventureIslandStakingOperations is AdventureIslandData {
    using SafeMath for uint256;
    using Address for address payable;
    using SafeERC20 for IERC20;
    using Calculation for uint256;

    function _mintReward(address _token, address _to, uint256 _amount) internal {
        if(address (rewardSupplier) == ZERO_ADDRESS) {
            IERC20(_token).safeTransfer(_to, _amount);
        } else {
            rewardSupplier.mint(mainRewardToken, msg.sender, _amount);
        }
    }

    function _chargeFlashUnstakingFee(
        address _tokenA,
        uint256 _amountA,
        address _tokenB,
        uint256 _amountB) internal returns(uint256 amountA, uint256 amountB) {
        uint256 feeBP = platformFeeBP;
        if(_amountB != 0) {
            feeBP = feeBP.div(2);
        }

        uint256 feeA = _amountA.percentageMul(platformFeeBP, BASIS_POINT_PRECISION);
        uint256 feeB = _amountB.percentageMul(platformFeeBP, BASIS_POINT_PRECISION);

        platformFeeCollected[_tokenA] = platformFeeCollected[_tokenA].add(feeA);
        platformFeeCollected[_tokenB] = platformFeeCollected[_tokenA].add(feeB);

        amountA = _amountA.sub(feeA);
        amountB = _amountB.sub(feeB);

        return (amountA, amountB);
    }

    function _getWETHPrice() view internal returns(uint256) {
        address[] memory path = new address[](2);
        path[0] = address(WETH);
        path[1] = address(USDT);

        uint256 oneToken = COMMON_PRECISION;

        uint256[] memory price = UNI_V2_ROUTER.getAmountsOut(oneToken, path);
        return price[1];
    }

    function _getTokenPrice(address _token) view internal returns(uint256) {
        if(_token == address(USDT)) {
            return USDT_PRECISION;
        }

        if(_token == address(WETH)) {
            return _getWETHPrice();
        }

        address[] memory path = new address[](3);
        path[0] = address(_token);
        path[1] = address(WETH);
        path[2] = address(USDT);

        uint256 oneToken = 1 * (10 ** uint256(IERC20(_token).decimals()));

        uint256[] memory price = UNI_V2_ROUTER.getAmountsOut(oneToken, path);
        return price[2];
    }

    function _flashStakingReward(address _forToken, uint256 _amount, uint256 _price) view internal returns(uint256) {
        uint256 tokenDecimals = 10 ** uint256(IERC20(_forToken).decimals());
        uint256 rewardTokenDecimals = 10 ** uint256(IERC20(mainRewardToken).decimals());
        if(tokenDecimals > rewardTokenDecimals) {
            _amount = _amount.mul(tokenDecimals.div(rewardTokenDecimals));
        } else if(tokenDecimals < rewardTokenDecimals) {
            _amount = _amount.mul(rewardTokenDecimals.div(tokenDecimals));
        }

        return _price.mul(_amount).percentageMul(flashStakingRewardBP, BASIS_POINT_PRECISION).div(USDT_PRECISION);
    }

    function _safeApprove(IERC20 _token, address _spender) internal {
        if(address(_token) == ZERO_ADDRESS) {
            _token = WETH;
        }

        uint256 approved = _token.allowance(address(this), _spender);
        if(approved == 0) {
            _token.safeApprove(_spender, MAX_UINT256);
        }
    }

    function _approveFlashStaking(IERC20 _tokeA, IERC20 _tokenB, IERC20 _stakingToken) internal {
        address conn = address(uniConnector);
        _safeApprove(_tokeA, conn);
        _safeApprove(_tokenB, conn);
        _safeApprove(_stakingToken, conn);
    }

    function _tryFlashUnstaking(
        PoolInfo storage pool,
        UserInfo storage user,
        bool _forOneToken,
        address _outToken,
        uint256 _amount) internal returns(uint256) {

        if(user.stakeIn < _amount) {
            return 0;
        }

        if(_amount == 0) {
            return 0;
        }

        (address tokenA, address tokenB) = uniConnector.lpToPair(address(pool.stakingToken));
        if(tokenA == DUMMY_ADDRESS) {
            return 0;
        }

        _approveFlashStaking(IERC20(tokenA), IERC20(tokenB), pool.stakingToken);

        uint256 amountA;
        uint256 amountB;

        uint256 rewardAmount = 0;
        if(_forOneToken)  {
            amountA = uniConnector.flashRemoveLPForOneToken(address(pool.stakingToken), _outToken, address(uint160(address(this))), _amount);

            //make sure amountB using for token amount
            if(_outToken != ZERO_ADDRESS) {
                amountB = amountA;
                amountA = 0;
            }
        } else {
            (amountA, amountB) = uniConnector.flashRemoveLP(address(pool.stakingToken), address(uint160(address(this))), _amount, true);
        }

        (amountA, amountB) = _chargeFlashUnstakingFee(tokenA, amountA, tokenB, amountB);

        if(!_forOneToken) {
            if(amountA > 0) {
                if(tokenA == ZERO_ADDRESS) {
                    msg.sender.sendValue(amountA);
                    rewardAmount = _flashStakingReward(address(WETH), amountA, _getTokenPrice(address(WETH)));
                } else {
                    IERC20(tokenA).safeTransfer(msg.sender, amountA);
                    rewardAmount = _flashStakingReward(tokenA, amountA, _getTokenPrice(tokenA));
                }
            }

            if(amountB > 0) {
                IERC20(tokenB).safeTransfer(msg.sender, amountB);
                uint256 rewardOfB = _flashStakingReward(tokenB, amountB, _getTokenPrice(tokenB));
                rewardAmount = rewardAmount.add(rewardOfB);
            }
        } else {
            if(_outToken == ZERO_ADDRESS) {
                msg.sender.sendValue(amountA);
                rewardAmount = _flashStakingReward(address(WETH), amountA, _getTokenPrice(address(WETH)));
            } else {
                IERC20(_outToken).safeTransfer(msg.sender, amountB);
                uint256 rewardOfB = _flashStakingReward(_outToken, amountB, _getTokenPrice(_outToken));
                rewardAmount = rewardAmount.add(rewardOfB);
            }
        }

        _mintReward(mainRewardToken, msg.sender, rewardAmount);
        return rewardAmount;
    }
}
