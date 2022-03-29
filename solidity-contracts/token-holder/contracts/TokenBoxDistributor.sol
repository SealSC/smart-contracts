pragma solidity ^0.6.4;

import "../../contract-libs/seal-sc/Simple3Role.sol";
import "../../contract-libs/seal-sc/SimpleSealSCSignature.sol";
import "./ITokenBoxDistributor.sol";
import "./ITokenBox.sol";

contract TokenBoxDistributor is ITokenBoxDistributor, Simple3Role, SimpleSealSCSignature {

    address public openerContract;
    mapping(address=>mapping(bytes32=>address)) public boxOwners;
    mapping(address=>mapping(bytes32=>bool)) public openedBoxes;
    mapping(address=>bool) public connectedList;

    modifier connected(address _boxContract) {
        require(connectedList[_boxContract], "not connected");
        _;
    }

    modifier transferable(address _boxContract) {
        require(ITokenBox(_boxContract).getBoxRoot() != 0, "not mixed");
        require(Simple3Role(_boxContract).isExecutor(msg.sender), "not executor");
        _;
    }

    event Airdropped(address boxContract, uint256 count);
    event AirdroppedForOne(address boxContract, uint256 count, address user);
    event AirdroppedSingle(address boxContract, bytes32 sn, address user);
    event BoxTransferTo(address boxContract, bytes32 sn, address from, address to);

    constructor(address _owner) public Simple3Role(_owner) {}

    function getOwnerOf(address _boxContract, bytes32 _sn) override external view returns(address) {
        return boxOwners[_boxContract][_sn];
    }

    function setOpener(address _opener) external onlyOwner {
        openerContract = _opener;
    }

    function setConnectedContract(address _boxContract) override external {
        require(msg.sender == openerContract, "not opener call");
        connectedList[_boxContract] = true;
    }

    function airdropBoxes(
        address _boxContract,
        bytes32[] calldata _snList,
        address[] calldata _owners) external connected(_boxContract) transferable(_boxContract) {

        require(_snList.length == _owners.length, "length not match");

        for(uint256 i=0; i<_snList.length; i++) {
            require(boxOwners[_boxContract][_snList[i]] == address(0), "airdropped");
            boxOwners[_boxContract][_snList[i]] = _owners[i];
        }

        emit Airdropped(_boxContract, _snList.length);
    }

    function airdropBoxesForOne(
        address _boxContract,
        bytes32[] calldata _snList,
        address _theOwner) external connected(_boxContract) transferable(_boxContract) {

        for(uint256 i=0; i<_snList.length; i++) {
            require(boxOwners[_boxContract][_snList[i]] == address(0), "airdropped");
            boxOwners[_boxContract][_snList[i]] = _theOwner;
        }

        emit AirdroppedForOne(_boxContract, _snList.length, _theOwner);
    }

    function airdropBoxesSingle(
        address _boxContract,
        bytes32 _sn,
        address _theOwner) external connected(_boxContract) transferable(_boxContract) {

        require(boxOwners[_boxContract][_sn] == address(0), "airdropped");
        boxOwners[_boxContract][_sn] = _theOwner;

        emit AirdroppedSingle(_boxContract, _sn, _theOwner);
    }

    function setBoxOpened(address _boxContract, bytes32 _sn) override external {
        require(msg.sender == openerContract, "not opener call");
        openedBoxes[_boxContract][_sn] = true;
    }

    function boxTransfer(
        address _boxContract,
        bytes32 _sn,
        address _to) external {

        require(msg.sender == boxOwners[_boxContract][_sn], "not box owner");
        require(!openedBoxes[_boxContract][_sn], "box opened already");

        boxOwners[_boxContract][_sn] = _to;

        emit BoxTransferTo(_boxContract, _sn, msg.sender, _to);
    }
}
