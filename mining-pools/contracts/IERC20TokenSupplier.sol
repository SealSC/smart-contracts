pragma solidity ^0.5.9;

interface IERC20TokenSupplier {
    function tokenCount() external view returns(uint256);
    function getTokenSupply(address _token) external view returns(uint256);
    function mint(address _token, address _to, uint256 _amount) external returns(uint256);
}
