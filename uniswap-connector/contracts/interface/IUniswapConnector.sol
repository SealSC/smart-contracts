pragma solidity ^0.5.9;

interface IUniswapConnector {

    function flashRemoveLP(address _lp, address _to, uint256 _amount) external;
    function flashRemoveLPForOneToken(address _lp, address _outToken, address payable _to, uint256 _amount) external;
    function flashGetLP(address _lp, address _inToken, uint256 _amount, address _outToken) external payable returns(uint256);

}
