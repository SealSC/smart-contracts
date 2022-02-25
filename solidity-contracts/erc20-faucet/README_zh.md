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
该方法仅admin权限调用   
```
function addToken(address _token,uint256 _amount ) external onlyAdmin
```

##### 描述
> 该方法为添加水龙头支持的token，在领取时依次发放

##### 参数
**_token**
> address类型，支持的ERC20 token的合约地址

**_amount**
> uint256类型，水龙头的单次领取数量

#### :point_right: setInterval
该方法仅admin权限调用      
```
function setInterval(uint256 _interval) external onlyAdmin
```

##### 描述
> 该方法为设置用户两次领取token的最小间隔时长

##### 参数
**_interval**
> uint256类型，水龙头中的最小领取间隔时间，以秒为单位的时间戳

#### :point_right: setTokenAmount
该方法仅admin权限调用   
```
function setTokenAmount(uint256 _idx, uint256 _amount) external onlyAdmin
```

##### 描述
> 该方法为设置水龙头中已添加token的单次发放数额

##### 参数
**_idx**
> uint256类型，要设置的ERC20token合约的索引值，该索引值为添加到水龙头中的顺序号(从0开始)。

**_amount**
> uint256类型，水龙头的单次领取数额

#### :point_right: clear
该方法仅admin权限调用   
```
function clear() external onlyAdmin
```

##### 描述
> 该方法为清空水龙头，将水龙头中所有可领取的token转回给Owner

#### :point_right: transferOutERC20
该方法仅Owner权限调用      
```
function transferOutERC20(IERC20 _token, address _to) external onlyOwner
```

##### 描述
> 该方法为转出水龙头合约中的任意ERC20 Token到指定地址，该方法主要用于token误转入的取出操作

##### 参数
**_token**
> address类型，要取出的token的合约地址

**_to**
> address类型，取出token的接收地址

#### :point_right: claim
该方法无权限设置，都可调用   
```
function claim(address _receiver) external
```

##### 描述
> 该方法为领取水龙头中的token到指定账户地址

##### 参数
**_receiver**
> address类型，领取token的接收账户地址

## 合约读取接口

#### :point_right: getSettings
该方法无权限配置   
```
function getSettings() external view returns(IERC20[] memory token, uint256[] memory amount, uint256 interval)
```

##### 描述
该方法为读取水龙头中的设置参数

##### 返回值说明
**token**
> address数组类型，返回添加到该水龙头中的token合约地址

**amount**
> uint256数组类型，返回添加到该水龙头中的token单次领取数额设置

**interval**
> uint256类型，水龙头两次领取token的间隔时长

#### :point_right: validUser
该方法无权限配置   
```
function validUser(address _user) public view returns(bool valid)
```

##### 描述
> 该方法为查询指定用户是否可领取token

##### 参数
**_user**
> address类型，要查询的用户的账户地址

##### 返回值说明
**valid**
> bool类型，返回该用户是否可领取水龙头中的token，可领取则返回true，不可领取则返回false

