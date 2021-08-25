// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.6.0;

import "../../contract-libs/seal-sc/Simple3Role.sol";
import "../../contract-libs/seal-sc/SimpleSealSCSignature.sol";
import "../../contract-libs/seal-sc/Utils.sol";
import "../../contract-libs/open-zeppelin/SafeERC20.sol";
import "../../contract-libs/open-zeppelin/ERC721/IERC721.sol";
import "../../contract-libs/seal-sc/RejectDirectETH.sol";
import "../../contract-libs/seal-sc/Constants.sol";

interface IERC20DistributionInShares {
    struct DistributionConfig {
        IERC20 pricingCurrency;
        IERC20 qualificationCurrency;
        IERC20 swapOutCurrency;

        uint256 price;
        uint256 qualificationRatio;
        uint256 totalSupply;

        uint256 startTime;
        uint256 duration;

        uint256 investCap;
    }

    struct InvestInfo {
        uint256 amount;
        bool exists;
        bool claimed;
    }

    function setConfigure(
        IERC20 _pricingCurrency,
        IERC20 _qualificationCurrency,
        IERC20 _swapOutCurrency,
        uint256 _price,
        uint256 _qualificationRatio,
        uint256 _totalSupply,
        uint256 _startTime,
        uint256 _duration
    ) external;

    function switchToPrivate() external;
    function setPeriphery(address _projectAdmin, address _accItem) external;
}

contract ERC20DistributionInShares is IERC20DistributionInShares, Constants, Simple3Role, Mutex, SimpleSealSCSignature, RejectDirectETH {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address payable;

    IERC721 public accelerationItem;
    mapping(address=>bool) public acceleratedUser;

    uint256 constant public RATIO_BASE_POINT = 1e18;
    address public projectAdmin;
    bool public confirmed = false;
    bool public isPrivate = false;
    bool public complete = false;
    bool public investWasSent = false;

    uint256 public totalInvested;

    mapping(address=>bool) public whitelist;

    mapping(address=>InvestInfo) public shareList;

    address[] public swapUserList;

    modifier onlyProjectAdmin() {
        require(msg.sender == projectAdmin, "not admin");
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
    event Configured(address byAdmin);
    event Confirmed(address admin, uint256 blockNum, uint256 timestamp);
    event Complete(uint256 blockNum);
    event UserAccelerated(address user);
    event PeripherySet(address projectAdmin, address accItem);
    event InvestWasSent(address reciever, uint256 amount);

    DistributionConfig public config;

    constructor() public Simple3Role(msg.sender) {}

    function switchToPrivate() override external onlyAdmin {
        isPrivate = true;
    }

    function setPeriphery(address _projectAdmin, address _accItem) override external onlyAdmin {
        projectAdmin = _projectAdmin;
        accelerationItem = IERC721(_accItem);

        emit PeripherySet(_projectAdmin, _accItem);
    }

    function getInvest(address _to) external ended onlyAdmin {
        require(_to != ZERO_ADDRESS, "receiver is zero");
        require(!investWasSent, "already sent");

        uint256 investedAmount = totalInvested;
        if(totalInvested > config.investCap) {
            investedAmount = config.investCap;
        }

        config.pricingCurrency.safeTransfer(_to, investedAmount);
        investWasSent = true;

        emit InvestWasSent(_to, investedAmount);
    }

    function emergencyWithdrawERC20(address _token, address _to) external onlyOwner {
        if(_to == ZERO_ADDRESS) {
            _to = owner();
        }

        IERC20(_token).safeTransfer(_to, IERC20(_token).balanceOf(address(this)));
    }

    function emergencyWithdrawETH(address payable _to) external onlyOwner {
        if(_to == ZERO_ADDRESS) {
            _to = msg.sender;
        }

        _to.sendValue(address(this).balance);
    }

    function setConfigure(
        IERC20 _pricingCurrency,
        IERC20 _qualificationCurrency,
        IERC20 _swapOutCurrency,
        uint256 _price,
        uint256 _qualificationRatio,
        uint256 _totalSupply,
        uint256 _startTime,
        uint256 _duration
    ) override external onlyAdmin {
        require(!confirmed, "already confirmed");
        require(address (_swapOutCurrency) != address (0), "invalid out token");
        require(_startTime.add(_duration) > block.timestamp, "already ended");
        require(_price != 0, "ratio is 0");

        config = DistributionConfig({
            pricingCurrency: _pricingCurrency,
            swapOutCurrency: _swapOutCurrency,
            qualificationCurrency: _qualificationCurrency,
            price: _price,
            qualificationRatio: _qualificationRatio,
            totalSupply: _totalSupply,
            startTime: _startTime,
            duration: _duration,
            investCap: _totalSupply.mul(_price).div(10 ** uint256(_swapOutCurrency.decimals()))
        });

        emit Configured(projectAdmin);
    }

    function confirm() external onlyProjectAdmin {
        if(confirmed) {
            return;
        }
        require(config.startTime > block.timestamp, "already started");
        config.swapOutCurrency.safeTransferFrom(msg.sender, address(this), config.totalSupply);
        confirmed = true;

        emit Confirmed(projectAdmin, block.number, block.timestamp);
    }

    function addUserToWhitelist(address _user) external onlyProjectAdmin {
        whitelist[_user] = true;
    }

    function _recordInvestInfo(uint256 _amount, address _to) internal {
        if(acceleratedUser[_to]) {
            _amount = _amount.mul(2);
        }

        if(!shareList[_to].exists) {
            shareList[_to] = InvestInfo({
                amount: _amount,
                exists: true,
                claimed: false
            });

            totalInvested = totalInvested.add(_amount);
            swapUserList.push(_to);
            return;
        }

        totalInvested = totalInvested.add(_amount);
        shareList[_to].amount = shareList[_to].amount.add(_amount);
    }

    function _refund(uint256 _refundAmount, address payable _to) internal {
        if(address (config.pricingCurrency) == ZERO_ADDRESS) {
            _to.sendValue(_refundAmount);
        } else {
            config.pricingCurrency.safeTransfer(_to, _refundAmount);
        }
    }

    function purchase(uint256 _amount) running payable external {
        if(isPrivate) {
            require(whitelist[msg.sender], "not in whitelist");
        }

        if(address(config.pricingCurrency) != ZERO_ADDRESS) {
            config.pricingCurrency.safeTransferFrom(msg.sender, address(this), _amount);
        }

        if(address(config.qualificationCurrency) != ZERO_ADDRESS) {
            config.qualificationCurrency.safeTransferFrom(msg.sender, DUMMY_ADDRESS, _amount.mul(config.qualificationRatio).div(RATIO_BASE_POINT));
        }

        _recordInvestInfo(_amount, msg.sender);
    }

    function claim() ended external {
        InvestInfo storage si = shareList[msg.sender];
        require(!si.claimed, "already claimed");
        require(si.amount > 0, "out amount is 0");

        (uint256 amount, uint256 refund) = calcSharesOf(msg.sender);
        config.swapOutCurrency.safeTransfer(msg.sender, amount);
        config.pricingCurrency.safeTransfer(msg.sender, refund);

        emit Claimed(msg.sender, amount, block.number, block.timestamp);

        si.claimed = true;
    }

    function accelerate(uint256 _itemID) running external {
        address user = msg.sender;
        if(acceleratedUser[user]) {
            return;
        }

        acceleratedUser[user] = true;
        accelerationItem.safeTransferFrom(msg.sender, DUMMY_ADDRESS, _itemID);

        totalInvested = totalInvested.add(shareList[user].amount);
        shareList[user].amount =  shareList[user].amount.mul(2);

        emit UserAccelerated(user);
    }

    function calcSharesOf(address _user) public view returns(uint256 shares, uint256 refund) {
        shares = shareList[_user].amount.mul(10 ** uint256(config.swapOutCurrency.decimals())).div(config.price);
        refund = 0;

        if(totalInvested > config.investCap) {
            uint256 actualShares = shareList[_user].amount.mul(config.totalSupply).div(totalInvested);
            uint256 actualInvest = actualShares.mul(RATIO_BASE_POINT).mul(shareList[_user].amount).div(shares).div(RATIO_BASE_POINT);

            refund = shareList[_user].amount.sub(actualInvest);
            shares = actualShares;
        }

        return (shares, refund);
    }

    function getUserInfo(address _user) external view
        returns(
            uint256 invested,
            bool accelerated,
            bool exits,
            bool claimed,
            uint256 shares,
            uint256 refund) {
        (shares, refund) = calcSharesOf(_user);
        return (
            shareList[_user].amount,
            acceleratedUser[_user],
            shareList[_user].exists,
            shareList[_user].claimed,
            shares, refund
        );
    }

    function getProgress() external view
        returns (
            uint256 progress,
            uint256 total,
            uint256 totalSupply,
            uint256 price,
            uint256 qualificationRatio,
            uint256 endTime,
            uint256 userCount,
            bool isRunning) {
        return (
            totalInvested.mul(RATIO_BASE_POINT).div(config.investCap),
            totalInvested,
            config.totalSupply,
            config.price,
            config.qualificationRatio,
            config.startTime.add(config.duration),
            swapUserList.length,
            confirmed && config.startTime <= block.timestamp
        );
    }
}
