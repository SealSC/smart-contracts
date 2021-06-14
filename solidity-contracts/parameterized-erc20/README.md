# Summary

This contract extend the standard ERC20 contract. Added mining and blacklisting functions to the standard contract through owner, administrator and minter roles.


# constructor
```
constructor(
        address _owner,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        bool _minable,
        uint256 _initSupply)
```

##### parameters

|  name   | type  | description  |
|  ----  | ----  | ---- |
| _owner  | address | Owner of the contract, an owner is also has role of admin. |
| _name  | string | ERC20 token's name. |
| _symbol  | string | ERC20 token's symbol. |
| _decimals  | uint8 | ERC20 token's decimals. |
| _minable  | bool | minable flag. |
| _initSupply  | uint256 | the init supply of the token, if minalbe is false, then this value will be the hard-cap supply. |


# admin interfaces

The methods blow only can be called by admin role.

#### :point_right: setMintEnableStatus
```
function setMintEnableStatus(bool _enabled) external onlyAdmin
```

##### description
>set mint enable flag, minters can only mint token when minable flag is true

##### parameters

|  name   | type  | description  |
|  ----  | ----  | ---- |
| _enabled  | bool | new minable value. |

#### :point_right: addMinter
```
addMinter(address _minter, uint256 _factor) external onlyAdmin
```

##### description
>add minter, minters can mint extra tokens.

##### parameters

|  name   | type  | description  |
|  ----  | ----  | ---- |
| _minter  | address | minter's address. |
| _factor  | uint256 | mint factor of minter *1. |

>*1 extra token mint by minters will conform the formula (basePoint is constant 1e18):  
```(amount * factor) / basePoint```

#### :point_right: updateMinterFactor
```
function updateMinterFactor(address[] calldata _minters, uint256[] calldata _factors) external onlyAdmin
```

##### description
>update minter's factor  

##### parameters

|  name   | type  | description  |
|  ----  | ----  | ---- |
| _minters  | address[] | a list of minter's address. |
| _factors  | uint256[] | a list of new factor of minters. |


#### :point_right: removeMinter
```
function removeMinter(address _minter) external onlyAdmin
```

##### description
>remove minter

##### parameters

|  name   | type  | description  |
|  ----  | ----  | ---- |
| _minter  | address | the minter to remove. |


#### :point_right: addToBlackList
```
function addToBlackList(address _user) external onlyAdmin
```

##### description
>add user to blacklist. users who in the black list will not be able to transfer in or out tokens.  

##### parameters

|  name   | type  | description  |
|  ----  | ----  | ---- |
| _user  | address | address will add to the list. |

#### :point_right: removeFromBlackList
```
function removeFromBlackList(address _user) external onlyAdmin
```

##### description
>remove user from blacklist

##### parameters

|  name   | type  | description  |
|  ----  | ----  | ---- |
| _user  | address | address will remove from the list. |


# user interfaces
Only list the extend interfaces beyond the standard ERC20 tokens.

#### :point_right: mint
```
function mint(address _to, uint256 _amount) public onlyMinter
```

##### description
>mint extra tokens by minter.

##### parameters

|  name   | type  | description  |
|  ----  | ----  | ---- |
| _to  | address | extra token will mint to. |
| _amount  | uint256 | the amount may mint out, effected by minter's factor. |
