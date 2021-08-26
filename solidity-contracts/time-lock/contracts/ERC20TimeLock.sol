pragma experimental ABIEncoderV2;
pragma solidity ^0.6.0;

import "../../contract-libs/open-zeppelin/SafeERC20.sol";
import "../../contract-libs/open-zeppelin/Ownable.sol";

contract ERC20TimeLock is Ownable {
   using SafeERC20 for IERC20;
   using SafeMath for uint256;

   struct userLockedInfo {
      uint256 amount;
      uint256 unlockedTime;
      IERC20 token;
      bool withdrawn;
   }

   mapping (address=>userLockedInfo[]) public lockList;
   mapping (address=>bool) public supportedToken;

   event SimpleLocked(address user, address token, uint256 amount, uint256 unlockedTime, uint256 idx);
   event LinearReleaseLocked(address user, address token, uint256 eachRelease, uint256 stageCount, uint256 startTime, uint256 interval, uint256 idx);
   event IncreaseLockedAmount(address user, address token, uint256 idx,uint256 amount);
   event ReduceLockedAmount(address user,  address token, uint256 idx,uint256 amount);
   event SetNewUnlockedTime(address user,  uint256 idx, uint256 unlockedTime);
   event RemoveLockedInfo(address user, address token, uint256 idx, uint256 amount);
   event Withdrawn(address user, address token, uint256 idx, uint256 amount);
   event SupportedTokenAdded(address token);
   event SupportedTokenRemoved(address token);

   constructor(address _owner, address _initToken) public Ownable(_owner) {}

   function removeUser(address _user, uint256 _idx) external onlyOwner {
      userLockedInfo storage uli = _getUserLockedInfo(_user, _idx);

      require(!uli.withdrawn, "token has been withdrawn");
      uli.withdrawn = true;
      uli.token.safeTransfer(msg.sender, uli.amount);
      emit RemoveLockedInfo(_user, address(uli.token), _idx, uli.amount);
      uli.amount = 0;
   }

   function _lock(address _forUser, uint256 _amount, uint256 _unlockedTime, IERC20 _token) internal returns(uint256 idx) {
      userLockedInfo[] storage uList = lockList[_forUser];

      uList.push(userLockedInfo({
         amount: _amount,
         unlockedTime: _unlockedTime,
         token: _token,
         withdrawn: false
      }));

      return uList.length;
   }

   function simpleLock(address _forUser, uint256 _amount, uint256 _unlockedTime, address _token) external {
      require(supportedToken[_token], "not supported token");

      IERC20 token = IERC20(_token);
      token.safeTransferFrom(msg.sender, address(this), _amount);
      uint256 idx = _lock(_forUser, _amount, _unlockedTime, token);

      emit SimpleLocked(_forUser, _token, _amount, _unlockedTime, idx);
   }

   function linearReleaseLock(
      address _forUser,
      uint256 _eachRelease,
      uint256 _stageCount,
      uint256 _startTime,
      uint256 _interval,
      address _token) external {
      require(supportedToken[_token], "not supported token");

      uint256 totalAmount = _eachRelease.mul(_stageCount);
      IERC20 token = IERC20(_token);
      token.safeTransferFrom(msg.sender, address(this), totalAmount);

      uint256 unlockTime = _startTime;
      uint256 idx = 0;
      for(uint256 i=0; i<_stageCount; i++) {
         unlockTime = unlockTime.add(_interval);
         idx = _lock(_forUser, _eachRelease, unlockTime, token);
      }

      emit LinearReleaseLocked(_forUser, _token, _eachRelease, _stageCount, _startTime, _interval, idx);
   }

   function addSupportedToken(address _token) external onlyOwner {
      supportedToken[_token] = true;
      emit SupportedTokenAdded(_token);
   }

   function removeSupportedToken(address _token) external onlyOwner {
      supportedToken[_token] = false;
      emit SupportedTokenRemoved(_token);
   }

   function _getUserLockedInfo(address _user, uint256 _idx) internal view returns(userLockedInfo storage uli) {
      userLockedInfo[] storage ul =  lockList[_user];
      require(ul.length > _idx, "no such locked information");

      return ul[_idx];
   }

   function setUserUnlockedTime(address _user, uint256 _idx, uint256 _newUnlockedTime) external onlyOwner {
      userLockedInfo storage uli = _getUserLockedInfo(_user, _idx);
      uli.unlockedTime = _newUnlockedTime;

      emit SetNewUnlockedTime(_user, _idx, _newUnlockedTime);
   }

   function reduceUserUnlockAmount(address _user, uint256 _idx, uint256 _amount) external onlyOwner {
      userLockedInfo storage uli = _getUserLockedInfo(_user, _idx);
      require(!uli.withdrawn, "token has been withdrawn");

      uli.token.safeTransfer(msg.sender, _amount);
      uli.amount = uli.amount.sub(_amount);

      emit ReduceLockedAmount(_user, address(uli.token), _idx, _amount);
   }

   function increaseUserUnlockAmount(address _user, uint256 _idx, uint256 _amount) external onlyOwner {
      userLockedInfo storage uli = _getUserLockedInfo(_user, _idx);
      require(!uli.withdrawn, "token has been withdrawn");

      uli.token.safeTransferFrom(msg.sender, address(this), _amount);
      uli.amount = uli.amount.add(_amount);

      emit IncreaseLockedAmount(_user, address(uli.token), _idx, _amount);
   }

   function withdraw(uint256 _idx) external {
      address user = msg.sender;
      userLockedInfo storage uli = _getUserLockedInfo(user, _idx);

      require(!uli.withdrawn, "already withdrawn");
      require(uli.unlockedTime < block.timestamp, "still locked");

      uli.withdrawn = true;
      uli.token.safeTransfer(user, uli.amount);
      emit Withdrawn(user, address(uli.token), _idx, uli.amount);
      uli.amount = 0;
   }

   function getLockedListOf(address _user) external view returns(userLockedInfo[] memory list) {
      return lockList[_user];
   }
}
