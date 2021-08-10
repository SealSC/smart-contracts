// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.6.0;

import "../../contract-libs/seal-sc/Simple3Role.sol";
import "../../contract-libs/seal-sc/SimpleSealSCSignature.sol";
import "../../contract-libs/seal-sc/RejectDirectETH.sol";
import "../../contract-libs/open-zeppelin/SafeERC20.sol";
import "../../contract-libs/seal-sc/ERC20TransferOut.sol";

contract ERC20Faucet is ERC20TransferOut, Simple3Role, RejectDirectETH, SimpleSealSCSignature {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct FaucetSettings {
        IERC20[] token;
        uint256[] amount;
        uint256 interval;
    }

    FaucetSettings public settings;
    mapping(address=>uint256) public latestClaim;
    mapping(address=>bool) public supportedToken;

    uint256 public supportedTokenCount;
    uint256 public totalClaimed;

    constructor(address _owner, uint256 _interval) public Simple3Role(_owner) {
        settings.interval = _interval;
    }

    function setInterval(uint256 _interval) external onlyAdmin {
        settings.interval = _interval;
    }

    function addToken(address _token, uint256 _amount) external onlyAdmin {
        require(!supportedToken[_token], "already set");
        settings.token.push(IERC20(_token));
        settings.amount.push(_amount);

        supportedToken[_token] = true;
        supportedTokenCount = supportedTokenCount.add(1);
    }

    function setTokenAmount(uint256 _idx, uint256 _amount) external onlyAdmin {
        require(_idx < supportedTokenCount, "idx out of range");
        settings.amount[_idx] = _amount;
    }

    function clear() external onlyAdmin {
        address receiver = owner();
        for(uint256 i=0; i<settings.token.length; i++) {
            settings.token[i].safeTransfer(receiver, settings.token[i].balanceOf(address (this)));
        }
    }

    function transferOutERC20(IERC20 _token, address _to) external onlyOwner {
        _transferERC20Out(_token, _to);
    }

    function claim(address _receiver) external {
        require(validUser(msg.sender), "too greed of sender");
        require(validUser(_receiver), "too greed of receiver");

        for(uint256 i=0; i<settings.token.length; i++) {
            settings.token[i].safeTransfer(_receiver, settings.amount[i]);
        }
        latestClaim[msg.sender] = block.timestamp;
        latestClaim[_receiver] = block.timestamp;
    }

    function getSettings() external view returns(IERC20[] memory token, uint256[] memory amount, uint256 interval) {
        return(settings.token, settings.amount, settings.interval);
    }

    function validUser(address _user) public view returns(bool valid) {
        return (latestClaim[_user].add(settings.interval) < block.timestamp);
    }
}
