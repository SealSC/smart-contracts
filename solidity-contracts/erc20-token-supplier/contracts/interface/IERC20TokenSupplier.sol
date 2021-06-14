// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6.0;

enum SupplyMode {
    Transfer,
    Mineable
}

struct TokenInfo {
    address    token;
    SupplyMode supplyMode;
}

interface IERC20TokenSupplier {


    function tokenCount() external view returns(uint256);
    function getTokenSupply(address _token) external view returns(uint256);
    function mint(address _token, address _to, uint256 _amount) external returns(uint256);
}
