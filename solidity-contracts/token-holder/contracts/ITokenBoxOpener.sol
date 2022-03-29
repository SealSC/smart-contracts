pragma solidity ^0.6.4;

interface ITokenBoxOpener {
    function boxContractConnect(
        address _boxContract,
        bytes calldata _sig,
        uint256 _feeCategory,
        address _feeSupplier) external;
}
