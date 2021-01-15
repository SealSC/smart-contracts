pragma solidity ^0.5.9;

import "../interface/IAdventureIslandPools.sol";
import "../../../contract-libs/open-zeppelin/SafeMath.sol";

contract AdventureIslandPools is IAdventureIslandPools {
    using SafeMath for uint256;

    mapping (uint256=>PoolInfo) public allPools;
    uint256 public allPoolsCount;
    PoolInfo[] public validPoolList;

    function appendPool(PoolInfo memory _pool) internal {
        allPools[allPoolsCount] = _pool;
        validPoolList.push(_pool);
        allPoolsCount = allPoolsCount.add(1);
    }

    function removePoolFromList(uint256 _pid) internal {
        uint256 lastIndex = validPoolList.length - 1;
        for(uint256 i=0; i<lastIndex; i++) {
            if(validPoolList[i].pid == _pid) {
                validPoolList[i] = validPoolList[lastIndex];
                break;
            }
        }

        validPoolList.length--;
    }
}
