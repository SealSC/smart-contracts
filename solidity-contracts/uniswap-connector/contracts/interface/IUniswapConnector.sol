// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6.0;

interface IUniswapConnector {

    function flashRemoveLP(address _lp, address payable _to, uint256 _amount, bool _externalCall) external returns(uint256,  uint256);
    function flashRemoveLPForOneToken(address _lp, address _outToken, address payable _to, uint256 _amount) external returns(uint256);
    function flashGetLP(address _lp, address _inToken, uint256 _amount, address _outToken) external payable returns(uint256);
    function lpToPair(address _lp) view external returns(address, address);

}
