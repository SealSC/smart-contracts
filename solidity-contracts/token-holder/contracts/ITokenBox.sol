pragma solidity ^0.6.4;

interface ITokenBox {
    function openBox(bytes32 _sn, bytes32 _key, uint256 _boxNumber, address _to) external;
    function getBoxRoot() external returns(bytes32);
    function setBoxesRoot(bytes32 root) external;
}
