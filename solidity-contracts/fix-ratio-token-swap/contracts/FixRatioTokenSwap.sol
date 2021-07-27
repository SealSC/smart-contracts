// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.6.0;

import "../../contract-libs/seal-sc/Simple3Role.sol";
import "../../contract-libs/seal-sc/SimpleSealSCSignature.sol";
import "../../contract-libs/seal-sc/Utils.sol";
import "../../contract-libs/open-zeppelin/SafeERC20.sol";
import "../../contract-libs/seal-sc/RejectDirectETH.sol";

interface IFixRatioTokenSwap {
    struct SwapConfig {
        IERC20 pricingCurrency;
        IERC20 swapCurrency;

        uint256 ratio;

        uint256 startTime;
        uint256 duration;

        uint256 supplyCap;

        uint256 minInAmount;
        uint256 maxInAmount;
    }

    struct SwapInfo {
        uint256 swapIn;
        uint256 swapOut;
        bool exists;
        bool claimed;
    }

    function setConfigure(
        IERC20 _pricingCurrency,
        IERC20 _swapCurrency,
        uint256 _ratio,
        uint256 _startTime,
        uint256 _duration,
        uint256 _supplyCap,
        uint256 _minInAmount,
        uint256 _maxInAmount
    ) external;

    function setProjectAddress(address _projectAdmin) external;
    function setContractAdmin(address _admin) external;
    function switchToPrivate() external;
}

contract FixRatioTokenSwap is IFixRatioTokenSwap, Simple3Role, Mutex, SimpleSealSCSignature, RejectDirectETH {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address payable;

    uint256 constant public RATIO_BASE_POINT = 1e6;
    address public projectAdmin;
    bool public confirmed = false;
    bool public isPrivate = false;
    bool public complete = false;

    uint256 public willSwap;

    mapping(address=>bool) public whitelist;

    mapping(address=>SwapInfo) swapList;

    address[] swapUserList;

    modifier onlyProjectAdmin() {
        require(msg.sender == projectAdmin, "not administrator of this project");
        _;
    }

    modifier running() {
        require(confirmed, "not confirmed");
        require(config.startTime <= block.timestamp, "not start");
        require(config.startTime.add(config.duration) > block.timestamp, "already ended");

        _;
    }

    modifier ended() {
        require(confirmed, "not confirmed");
        require(config.startTime.add(config.duration) < block.timestamp, "not ended");

        _;
    }

    event Claimed(address user, uint256 amount, uint256 blockNum, uint256 timestamp);
    event Created(address admin);
    event Confirmed(address admin, uint256 blockNum, uint256 timestamp);
    event Complete(uint256 blockNum);

    SwapConfig public config;

    constructor() public Simple3Role(msg.sender) {}

    function setProjectAddress(address _projectAdmin) override external onlyOwner {
        projectAdmin = _projectAdmin;
    }

    function setContractAdmin(address _admin) override external onlyOwner {
        addAdministrator(_admin);
    }

    function switchToPrivate() override external onlyOwner {
        isPrivate = true;
    }

    function setConfigure(
        IERC20 _pricingCurrency,
        IERC20 _swapCurrency,
        uint256 _ratio,
        uint256 _startTime,
        uint256 _duration,
        uint256 _supplyCap,
        uint256 _minInAmount,
        uint256 _maxInAmount
    ) override external onlyAdmin {
        require(!confirmed, "can not set config to a confirmed swap");
        require(address (_swapCurrency) != address (0), "swap token is address 0");
        require(_startTime.add(_duration) > block.timestamp, "already end, check the configs related to time");
        require(_ratio != 0, "ratio is 0");

        config = SwapConfig({
            pricingCurrency: _pricingCurrency,
            swapCurrency: _swapCurrency,
            ratio: _ratio,
            startTime: _startTime,
            duration: _duration,
            supplyCap: _supplyCap,
            minInAmount: _minInAmount,
            maxInAmount: _maxInAmount
        });

        emit Created(projectAdmin);
    }

    function confirm() external onlyProjectAdmin {
        if(confirmed) {
            return;
        }
        config.swapCurrency.safeTransferFrom(msg.sender, address(this), config.supplyCap);
        confirmed = true;

        emit Confirmed(projectAdmin, block.number, block.timestamp);
    }

    function addUserToWhitelist(address _user) external onlyProjectAdmin {
        whitelist[_user] = true;
    }

    function _recordSwapInfo(uint256 _amountIn, uint256 _amountOut, address _to) internal {
        if(!swapList[_to].exists) {
            swapList[_to] = SwapInfo({
                swapIn: _amountIn,
                swapOut: _amountOut,
                exists: true,
                claimed: false
            });

            swapUserList.push(_to);
            return;
        }

        swapList[_to].swapIn = swapList[_to].swapIn.add(_amountIn);
        swapList[_to].swapOut = swapList[_to].swapOut.add(_amountOut);
    }

    function _refund(uint256 _refundAmount, address payable _to) internal {
        if(address (config.pricingCurrency) == address(0)) {
            _to.sendValue(_refundAmount);
        } else {
            config.pricingCurrency.safeTransfer(_to, _refundAmount);
        }
    }

    function purchase(uint256 _inAmount) running payable external {
        require(willSwap < config.supplyCap, "supply cap touched");

        if(isPrivate) {
            require(whitelist[msg.sender], "private project only for users in whitelist");
        }

        if(address(config.pricingCurrency) != address(0)) {
            config.pricingCurrency.safeTransferFrom(msg.sender, address(this), _inAmount);
        } else {
            _inAmount = msg.value;
        }

        require(_inAmount >= config.minInAmount, "purchase amount is too small");

        if(config.maxInAmount > 0) {
            require(_inAmount <= config.maxInAmount, "purchase amount is too big");
        }

        uint256 dAmount = _inAmount.mul(config.ratio).div(RATIO_BASE_POINT);
        require(dAmount > 0, "swap amount too small");

        uint256 refundAmount = 0;
        if(willSwap.add(dAmount) > config.supplyCap) {
            uint256 exceedAmount = willSwap.add(dAmount).sub(config.supplyCap);

            dAmount = config.supplyCap.sub(willSwap);
            complete = true;
            refundAmount = exceedAmount.mul(RATIO_BASE_POINT).div(config.ratio);

            emit Complete(block.number);
        }

        willSwap = willSwap.add(dAmount);
        _recordSwapInfo(_inAmount.sub(refundAmount), dAmount, msg.sender);

        if(refundAmount > 0) {
            require(refundAmount < _inAmount, "revert for refund");
            _refund(refundAmount, msg.sender);
        }
    }

    function claim() ended external {
        SwapInfo storage si = swapList[msg.sender];
        require(!si.claimed, "already claimed");
        require(si.swapOut > 0, "no swap out amount for this address");

        uint256 amount = si.swapOut;
        config.swapCurrency.safeTransfer(msg.sender, amount);

        emit Claimed(msg.sender, amount, block.number, block.timestamp);

        si.claimed = true;
    }

    function getProgress() external view returns(uint256 progress, uint256 userCount){
        return (willSwap.mul(RATIO_BASE_POINT).div(config.supplyCap), swapUserList.length);
    }
}
