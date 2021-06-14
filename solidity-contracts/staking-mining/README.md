# Summary

This contract implement the simple liquidity mining function with low running cost (compared to sushi protocol).

# constructor
```
constructor(address _owner, address _rewardToken) public Ownable(_owner) 
```

##### parameters

|  name   | type  | description  |
|  ----  | ----  | ---- |
| _owner  | address | Owner of the contract. |
| _rewardToken  | address | the ERC20 token for mining reward. |

# owner interfaces

The methods blow only can be called by owner role.

#### :point_right: createPool
```
function createPool(address _stakingToken, uint256 _rewardFactor) external onlyOwner
```

##### description
>create a mining pool

##### parameters

|  name   | type  | description  |
|  ----  | ----  | ---- |
| _stakingToken | address | ERC20 token required for staking. |
| _rewardFactor | uint256 | reward factor *1. |


>*1 reward amount will conform the formula (basePoint is constant 1e18):  
```(stakingAmount * blockDiff * factor) / basePoint```


#### :point_right: closePool
```
function closePool(uint256 _pid) external onlyOwner
```

##### description
>close a mining pool

##### parameters

|  name   | type  | description  |
|  ----  | ----  | ---- |
| _pid | uint256 | the index of the pool  which will be closed. |


# user interfaces

The methods blow only can be called by anyone.

#### :point_right: stake
```
function stake(uint256 _pid, uint256 _amount) external
```

##### description
>stake token to mine the reward token.

##### parameters

|  name   | type  | description  |
|  ----  | ----  | ---- |
| _pid | uint256 | which pool to stake in. |
| _amount | uint256 | the amount of required tokens to be stake in |


#### :point_right: collect
```
function collect(uint256 _pid, bool _exitFlag) public
```

##### description
>stake token to mine the reward token.

##### parameters

|  name   | type  | description  |
|  ----  | ----  | ---- |
| _pid | uint256 | the pool to collect the reward of. |
| _exitFlag | bool | the flag for determine if user want to get their staking token back |

