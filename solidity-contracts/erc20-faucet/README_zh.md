# ERC20-Faucet contract

# Summary概括

该合约为通用的ERC20 水龙头合约，即为领取ERC20 token的合约。

# Constructor
```
constructor(
    address _owner,
    uint256 _interval
)
```

##### parameters


|  name   | type  | description  |
|  ----  | ----  | ---- |
| _owner  | address | 合约的所有者，所有者也具有管理员角色. |
| _interval  | number | 设置领取ERC20 token的间隔时长. |

## 合约调用接口

#### :point_right: addToken

#### :point_right: setInterval

#### :point_right: setTokenAmount

#### :point_right: clear

#### :point_right: transferOutERC20

#### :point_right: claim

## 合约读取接口

#### :point_right: getSettings

#### :point_right: validUser
