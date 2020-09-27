pragma solidity ^0.5.9;

import "./UniswapConnectorData.sol";

contract UniswapConnectorViews is UniswapConnectorData{
    function supportedPairCount() view external returns(uint256) {
        return supportedList.length;
    }
}
