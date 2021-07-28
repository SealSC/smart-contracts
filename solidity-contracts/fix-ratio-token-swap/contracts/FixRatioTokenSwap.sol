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
        IERC20 swapOutCurrency;

        uint256 sharePrice;

        uint256 startTime;
        uint256 duration;

        uint256 totalShares;

        uint256 amountPerShare;
        uint256 maxShares;
    }

    struct ShareInfo {
        uint256 count;
        bool exists;
        bool claimed;
    }

    function setConfigure(
        IERC20 _pricingCurrency,
        IERC20 _swapOutCurrency,
        uint256 _sharePrice,
        uint256 _startTime,
        uint256 _duration,
        uint256 _totalShares,
        uint256 _amountPerShare,
        uint256 _maxShares
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

    uint256 public willSwappedShares;

    mapping(address=>bool) public whitelist;

    mapping(address=>ShareInfo) public shareList;

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
        IERC20 _swapOutCurrency,
        uint256 _sharePrice,
        uint256 _startTime,
        uint256 _duration,
        uint256 _totalShares,
        uint256 _amountPerShare,
        uint256 _maxShares
    ) override external onlyAdmin {
        require(!confirmed, "can not set config to a confirmed swap");
        require(address (_swapOutCurrency) != address (0), "swap token is address 0");
        require(_startTime.add(_duration) > block.timestamp, "already end, check the configs related to time");
        require(_sharePrice != 0, "ratio is 0");

        config = SwapConfig({
            pricingCurrency: _pricingCurrency,
            swapOutCurrency: _swapOutCurrency,
            sharePrice: _sharePrice,
            startTime: _startTime,
            duration: _duration,
            totalShares: _totalShares,
            amountPerShare: _amountPerShare,
            maxShares: _maxShares
        });

        emit Created(projectAdmin);
    }

    function confirm() external onlyProjectAdmin {
        if(confirmed) {
            return;
        }
        config.swapOutCurrency.safeTransferFrom(msg.sender, address(this), config.totalShares.mul(config.amountPerShare));
        confirmed = true;

        emit Confirmed(projectAdmin, block.number, block.timestamp);
    }

    function addUserToWhitelist(address _user) external onlyProjectAdmin {
        whitelist[_user] = true;
    }

    function _recordSharesInfo(uint256 _shares, address _to) internal {
        if(!shareList[_to].exists) {
            shareList[_to] = ShareInfo({
                count: _shares,
                exists: true,
                claimed: false
            });

            swapUserList.push(_to);
            return;
        }

        shareList[_to].count = shareList[_to].count.add(_shares);
    }

    function _refund(uint256 _refundAmount, address payable _to) internal {
        if(address (config.pricingCurrency) == address(0)) {
            _to.sendValue(_refundAmount);
        } else {
            config.pricingCurrency.safeTransfer(_to, _refundAmount);
        }
    }

    function purchase(uint256 _shares) running payable external {
        require(willSwappedShares < config.totalShares, "supply cap touched");

        if(isPrivate) {
            require(whitelist[msg.sender], "private project only for users in whitelist");
        }

        uint256 inAmount = _shares.mul(config.sharePrice);
        if(address(config.pricingCurrency) != address(0)) {
            config.pricingCurrency.safeTransferFrom(msg.sender, address(this), inAmount);
        } else {
            require(inAmount == msg.value, "value not equal needs");
        }

        if(config.maxShares > 0) {
            require(_shares.add(shareList[msg.sender].count) <= config.maxShares, "purchase amount is too big");
        }

        willSwappedShares = willSwappedShares.add(_shares);
        _recordSharesInfo(_shares, msg.sender);
    }

    function claim() ended external {
        ShareInfo storage si = shareList[msg.sender];
        require(!si.claimed, "already claimed");
        require(si.count > 0, "no swap out amount for this address");

        uint256 amount = si.count.mul(config.amountPerShare);
        config.swapOutCurrency.safeTransfer(msg.sender, amount);

        emit Claimed(msg.sender, amount, block.number, block.timestamp);

        si.claimed = true;
    }

    function getProgress() external view
        returns (
            uint256 progress,
            uint256 totalSwapOut,
            uint256 supplyCap,
            uint256 endTime,
            bool soldOut,
            uint256 userCount) {
        return (
            willSwappedShares.mul(RATIO_BASE_POINT).div(config.totalShares),
            willSwappedShares,
            config.totalShares,
            config.startTime.add(config.duration),
            complete,
            swapUserList.length
        );
    }
}
