pragma solidity ^0.6.4;

interface ITokenBoxDistributor {
    function getOwnerOf(address _boxContract, bytes32 _key) external view returns(address);
    function setConnectedContract(address _boxContract) external;
    function setBoxOpened(address _boxContract, bytes32 _sn) external;
}
