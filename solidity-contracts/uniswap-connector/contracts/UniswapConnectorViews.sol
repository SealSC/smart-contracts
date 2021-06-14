// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6.0;

import "./UniswapConnectorData.sol";

contract UniswapConnectorViews is UniswapConnectorData{
    function supportedPairCount() view external returns(uint256) {
        return supportedList.length;
    }
}
