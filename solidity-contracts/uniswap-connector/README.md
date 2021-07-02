# Summary

UNI V2 protocol connector, allow users using the UNI V2 protocol in a more flexible way.  
For example: provide liquidity using only one token of the swap pair, etc.  

# constructor
```
constructor(address _owner) public Ownable(_owner)
```

##### parameters

|  name   | type  | description  |
|  ----  | ----  | ---- |
| _owner | address | owner of the connector contract. |

# owner interfaces

The methods blow only can be called by owner role.

#### :point_right: approveRouterUseWETH
```
function approveRouterUseWETH() external onlyOwner
```

##### description
>approve UNI V2 router transfer the WETH token belonged to this contract

#### :point_right: addSupportedPair
```
function addSupportedPair(address _lpToken, address _tokenA, address _tokenB) external onlyOwner
```

##### description
>add UNI pair supported by this contract.


##### parameters

|  name   | type  | description  |
|  ----  | ----  | ---- |
| _lpToken | address | UNI-V2 token of the swap pair |
| _tokenA | address | token A of the pair |
| _tokenB | address | token B of the pair |

#### :point_right: setWETHAddress
```
function setWETHAddress(address _weth) external onlyOwner
```

##### description
>set the WETH address to support different evm compatible blockchain

##### parameters

|  name   | type  | description  |
|  ----  | ----  | ---- |
| _weth | address | weth address |


# user interfaces

The methods blow can be called by anyone.

#### :point_right: flashGetLP
```
function flashGetLP(
        address _lp,
        address _inToken,
        uint256 _amount,
        address _outToken) external payable validLP(_lp) returns(uint256 lpAmount)
```

##### description
>provide liquidity and get LP token using only one kind of the token in swap pair

##### parameters

|  name   | type  | description  |
|  ----  | ----  | ---- |
| _lp | address | the lp token address of the swap pair |
| _inToken | address | the token (token A in the swap pair) user provide |
| _amount | uint256 | the token amount user provide |
| _tokenB | address | another token in the swap pair |


##### returns

|  name   | type  | description  |
|  ----  | ----  | ---- |
| lpAmount | uint256 | the amount of lp token minted in this process that will send to user. |


#### :point_right: flashRemoveLP
```
function flashRemoveLP(
        address _lp,
        address payable _to,
        uint256 _amount,
        bool _externalCall) public validLP(_lp) returns(uint256 tokenAAmount,  uint256 tokenBAmount)
```

##### description
>remove liquidity, a wrap of LP remove function of UNI-V2

##### parameters

|  name   | type  | description  |
|  ----  | ----  | ---- |
| _lp | address | the lp token address|
| _to | address | the receiver for token returned by UNI-V2 |
| _amount | uint256 | token amount of the lp token user provide |
| _externalCall | bool | determine if called by external user or contract |

##### returns

|  name   | type  | description  |
|  ----  | ----  | ---- |
| tokenAAmount | uint256 | amount of token A that UNI-V2 returned |
| tokenBAmount | uint256 | amount of token B that UNI-V2 returned |


#### :point_right: flashRemoveLPForOneToken
```
function flashRemoveLPForOneToken(
        address _lp, 
        address _outToken, 
        address payable _to, 
        uint256 _amount) external validLP(_lp) returns(uint256 outTokenAmount)
```

##### description
>remove liquidity and get back the token of user specified.

##### parameters

|  name   | type  | description  |
|  ----  | ----  | ---- |
| _lp | address | the lp token address|
| _outToken | address | the token (token A or token B) user want to get back |
| _to | address | the receiver for token returned by UNI-V2 |
| _amount | uint256 | token amount of the lp token user provide |

##### returns
|  name   | type  | description  |
|  ----  | ----  | ---- |
| outTokenAmount | uint256 | amount of token that UNI-V2 returned |
