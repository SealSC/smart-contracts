pragma solidity ^0.6.4;

import "../../contract-libs/seal-sc/SimpleSealSCSignature.sol";
import "../../contract-libs/seal-sc/Simple3Role.sol";
import "../../contract-libs/open-zeppelin/ERC721/IERC721.sol";
import "../../contract-libs/open-zeppelin/ERC721/ERC721Holder.sol";
import "../../contract-libs/open-zeppelin/ERC1155/IERC1155.sol";
import "../../contract-libs/open-zeppelin/ERC1155/ERC1155Receiver.sol";
import "../../contract-libs/open-zeppelin/IERC20.sol";
import "../../contract-libs/seal-sc/Utils.sol";
import "../../contract-libs/open-zeppelin/SafeERC20.sol";
import "./ITokenBox.sol";

contract TokenBox is ITokenBox, ERC721Holder, ERC1155Receiver, Simple3Role, SimpleSealSCSignature, Mutex {
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Address for address;

    uint256 public startTime;
    uint256 public endTime;
    bool public closed;

    uint256 public totalBoxCount = 0;

    bytes32 public boxRoot;
    address public opener;

    enum BoxTypes {
        ERC721,
        ERC1155,
        ERC20
    }

    struct BoxesInfo {
        BoxTypes boxType;
        address token;
        uint256 tokenId;
        uint256 startId;
        uint256 count;
        uint256 amount;
        bool exists;
    }

    mapping(bytes32=>BoxesInfo) public boxList;
    mapping(bytes32=>uint256) public collectedAmount;
    mapping(bytes32=>bool) public claimedList;

    event ERC721Collected(bytes32 key, address token, uint256 id, address from, uint256 boxStartId);
    event ERC1155Collected(bytes32 key, address token, uint256 id, uint256 amountPerBox, uint256 boxCount, address from, uint256 boxStartId);
    event ERC20Collected(bytes32 key, address token, uint256 amountPerBox, uint256 boxCount, address from, uint256 boxStartId);
    event BoxOpened(bytes32 sn, uint256 boxType, address token, address to, bytes32 key, uint256 boxNumber);

    constructor(address _owner, address _opener) public Simple3Role(_owner) {
        require(_opener.isContract(), "presenter must be a contract");
        opener = _opener;
    }

    modifier notStart() {
        require(startTime == 0 || startTime > block.timestamp, "already start");
        _;
    }

    modifier notMixed() {
        require(boxRoot == 0, "mixed already");
        _;
    }

    modifier ended() {
        require(block.timestamp > endTime || endTime == 0, "not ended");
        _;
    }

    function _boxKey(
        uint256 _type,
        address _token,
        uint256 _tokenId,
        uint256 _startId,
        uint256 _count) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(_type, _token, _tokenId, _startId, _count));
    }

    function _collected(address _token, uint256 _id, uint256 _amount) internal {
        bytes32 key = keccak256(abi.encodePacked(_token, _id));
        collectedAmount[key] = collectedAmount[key].add(_amount);
    }

    function _collectedAmount(address _token, uint256 _id) view internal returns(uint256) {
        bytes32 key = keccak256(abi.encodePacked(_token, _id));
        return collectedAmount[key];
    }

    function _claimed(address _token, uint256 _id, uint256 _amount) internal {
        bytes32 key = keccak256(abi.encodePacked(_token, _id));
        collectedAmount[key] = collectedAmount[key].sub(_amount);
    }

    function _createBoxes(
        bytes32 _key,
        address _token,
        uint256 _tokenId,
        BoxTypes _type,
        uint256 _start,
        uint256 _count,
        uint256 _tokenAmount) internal {

        boxList[_key].boxType = _type;
        boxList[_key].token = _token;
        boxList[_key].tokenId = _tokenId;
        boxList[_key].startId = _start;
        boxList[_key].count = _count;
        boxList[_key].amount = _tokenAmount;
        boxList[_key].exists = true;

        _collected(_token, _tokenId, _count.mul(_tokenAmount));
        totalBoxCount = totalBoxCount.add(_count);

        return;
    }

    function setStartTime(uint256 _time) external onlyAdmin notStart {
        require(endTime > startTime || endTime == 0, "invalid end time");
        startTime = _time;
    }

    function setEndTime(uint256 _time) external onlyAdmin {
        require(!closed, "box closed");
        require(endTime > startTime, "invalid end time");
        endTime = _time;
    }

    function closeContract() external onlyOwner {
        closed = true;
    }

    function setBoxesRoot(bytes32 _root) override external notMixed {
        require(opener == msg.sender, "not opener call");
        boxRoot = _root;
    }

    function creatERC721Box(address _token, uint256 _id, address _from) external notStart onlyExecutor notMixed {
        uint256 startId = totalBoxCount.add(1);

        bytes32 key = _boxKey(uint256(BoxTypes.ERC721), _token, _id, startId, 1);
        if(boxList[key].exists) {
            return;
        }

        address theOwner = IERC721(_token).ownerOf(_id);
        if(theOwner == address(this)) {
            _createBoxes(key, _token, _id, BoxTypes.ERC721, startId, 1, 1);
            emit ERC721Collected(key, address(_token), _id, _from, startId);
            return;
        }

        IERC721(_token).safeTransferFrom(_from, address(this), _id);
        _createBoxes(key, _token, _id, BoxTypes.ERC721, startId, 1, 1);

        emit ERC721Collected(key, address(_token), _id, _from, startId);
    }

    function createERC1155Box(
        address _token,
        uint256 _id,
        uint256 _amountPerBox,
        uint256 _boxCount,
        address _from) external noReentrancy notStart onlyExecutor notMixed {

        uint256 startId = totalBoxCount.add(1);

        bytes32 key = _boxKey(uint256(BoxTypes.ERC1155), _token, _id, startId, _boxCount);

        IERC1155(_token).safeTransferFrom(_from, address(this), _id, _amountPerBox.mul(_boxCount), bytes(""));
        _createBoxes(key, _token, _id, BoxTypes.ERC1155, startId, _boxCount, _amountPerBox);

        emit ERC1155Collected(key, address(_token), _id, _amountPerBox, _boxCount, _from, startId);
    }

    function createERC20Box(
        address _token,
        uint256 _amountPerBox,
        uint256 _boxCount,
        address _from) external noReentrancy notStart onlyExecutor notMixed {

        uint256 startId = totalBoxCount.add(1);

        bytes32 key = _boxKey(uint256(BoxTypes.ERC1155), _token, 0, startId, _boxCount);

        IERC20(_token).safeTransferFrom(_from, address(this), _amountPerBox.mul(_boxCount));
        _createBoxes(key, _token, 0, BoxTypes.ERC20, startId, _boxCount, _amountPerBox);

        emit ERC20Collected(key, address(_token), _amountPerBox, _boxCount, _from, startId);
    }

    function openBox(bytes32 _sn, bytes32 _key, uint256 _boxNumber, address _to) external override ended {
        require(msg.sender == address(opener), "not opener");
        require(uint256(boxRoot) != 0, "not mixed");

        BoxesInfo memory bi = boxList[_key];
        if(!bi.exists) {
            revert("invalid key");
        }

        require(!claimedList[_sn], "already claimed");
        claimedList[_sn] = true;

        if(bi.boxType == BoxTypes.ERC721) {
            require(bi.startId == _boxNumber, "invalid box number");
            IERC721(bi.token).safeTransferFrom(address(this), _to, bi.tokenId);
        } else {
            require(bi.startId <= _boxNumber && bi.startId.add(bi.count) > _boxNumber, "invalid box number");
            if(bi.boxType == BoxTypes.ERC1155) {
                IERC1155(bi.token).safeTransferFrom(address(this), _to, bi.tokenId, bi.amount, bytes(''));
            } else {
                IERC20(bi.token).safeTransfer(_to, bi.amount);
            }
        }

        _claimed(bi.token, bi.tokenId, bi.amount);
        emit BoxOpened(_sn, uint256(bi.boxType), bi.token, _to, _key, _boxNumber);
    }

    function transferOutToken(
        uint256 _tokenType,
        address _token,
        uint256 _tokenId,
        uint256 _amount) external onlyOwner {
        uint256 inBoxAmount = _collectedAmount(_token, _tokenId);
        uint256 thisBalance;
        address thisAddr = address(this);

        if(_tokenType == uint256(BoxTypes.ERC721)) {

            require(inBoxAmount == 0 && thisAddr == IERC721(_token).ownerOf(_tokenId), "no such NFT token");
            IERC721(_token).safeTransferFrom(thisAddr, msg.sender, _tokenId);

        } else if(_tokenType == uint256(BoxTypes.ERC1155)) {

            thisBalance = IERC1155(_token).balanceOf(thisAddr, _tokenId);
            require(thisBalance >= inBoxAmount.add(_amount), "no extra NFT tokens");
            IERC1155(_token).safeTransferFrom(thisAddr, msg.sender, _tokenId, _amount, bytes(""));

        } else if(_tokenType == uint256(BoxTypes.ERC20)) {

            thisBalance = IERC20(_token).balanceOf(thisAddr);
            require(thisBalance >= inBoxAmount.add(_amount), "no extra FT tokens");
            IERC20(_token).safeTransfer(msg.sender, _amount);

        } else {
            revert("invalid token type");
        }
    }

    function getBoxRoot() external override returns(bytes32) {
        return boxRoot;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    )
    override
    external
    returns(bytes4) {
        address _tokenAddress = msg.sender;
        require(IERC165(_tokenAddress).supportsInterface(_INTERFACE_ID_ERC1155),
            "onERC1155Received caller needs to implement ERC1155!");
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    )
    override
    external
    returns(bytes4 notSupport) {
        return notSupport;
    }
}
