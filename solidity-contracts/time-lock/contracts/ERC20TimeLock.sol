pragma experimental ABIEncoderV2;
pragma solidity ^0.6.0;

import "../../contract-libs/open-zeppelin/SafeERC20.sol";
import "../../contract-libs/open-zeppelin/Ownable.sol";

contract ERC20TimeLock is Ownable {
   using SafeERC20 for IERC20;
   using SafeMath for uint256;

   uint256 public minLockedTime = 365 * 24 * 3600;

   struct userLockedInfo {
      uint256 amount;
      uint256 unlockedTime;
      IERC20 token;
      bool withdrawn;
   }

   mapping (address=>userLockedInfo[]) public lockList;
   mapping (address=>bool) public supportedToken;

   event AddLockedInfo(address indexed user, address indexed token, uint256 amount, uint256 unlockedTime, uint256 idx);
   event AddLockedAmount(address indexed user,  address indexed token, uint256 idx,uint256 amount);
   event SubLockedAmount(address indexed user,  address indexed token, uint256 idx,uint256 amount);
   event SetNewUnlockedTime(address indexed user,  uint256 idx, uint256 unlockedTime);
   event RemoveLockedInfo(address indexed user, address indexed token, uint256 indexed idx, uint256 amount);
   event Withdrawn(address indexed user, address indexed token, uint256 indexed idx, uint256 amount);
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

   function lock(address _forUser, uint256 _amount, uint256 _unlockedTime, address _token) external {
      require(supportedToken[_token], "not supported token");
      require(_unlockedTime > block.timestamp + minLockedTime, "unlocked time too small");

      IERC20 token = IERC20(_token);

      token.safeTransferFrom(msg.sender, address(this), _amount);
      userLockedInfo[] storage uList = lockList[_forUser];
      emit AddLockedInfo(_user, _token, _amount, _unlockedTime, uList.length);

      uList.push(userLockedInfo({
         amount: _amount,
         unlockedTime: _unlockedTime,
         token: token,
         withdrawn: false
      }));
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

   function subUserUnlockAmount(address _user, uint256 _idx, uint256 _amount) external onlyOwner {
      userLockedInfo storage uli = _getUserLockedInfo(_user, _idx);
      require(!uli.withdrawn, "token has been withdrawn");

      uli.token.safeTransfer(msg.sender, _amount);
      uli.amount = uli.amount.sub(_amount);

      emit SubLockedAmount(_user, address(uli.token), _idx, _amount);
   }

   function addUserUnlockAmount(address _user, uint256 _idx, uint256 _amount) external onlyOwner {
      userLockedInfo storage uli = _getUserLockedInfo(_user, _idx);
      require(!uli.withdrawn, "token has been withdrawn");

      uli.token.safeTransferFrom(msg.sender, address(this), _amount);
      uli.amount = uli.amount.add(_amount);

      emit AddLockedAmount(_user, address(uli.token), _idx, _amount);
   }

   function setNewMinLockedTime(uint256 _newMinLockedTime) external onlyOwner {
      minLockedTime = _newMinLockedTime;
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
