# erc20-token-supplier

# Summary概括

该合约为通用的ERC20 token供应商合约

# Constructor
```
constructor(address _owner) public Ownable(_owner)
```

##### parameters

|  name   | type  | description  |
|  ----  | ----  | ---- |
| _owner  | address | 合约的所有者，所有者也具有管理员角色. |

## 合约调用接口

#### :point_right: addConsumer
该方法仅Owner权限调用   
```
function addConsumer(address _consumer) external onlyOwner
```
##### 描述
> 该方法为添加消费者到消费者列表内

##### 参数
**_consumer**
> address类型，添加的消费者的账户地址


#### :point_right: removeConsumer
该方法仅Owner权限调用      
```
function removeConsumer(address _consumer) external onlyOwner
```
##### 描述
> 该方法为将该消费者移除消费者列表

##### 参数
**_consumer**
> address类型，将要移除的消费者的账户地址


#### :point_right: addToken
该方法仅Owner权限调用   
```
function addToken(address _token, uint256 mode) external onlyOwner
```
##### 描述
> 该方法为添加token到该合约内

##### 参数
**_token**
> address类型，要添加的ERC20 token的合约地址

**mode**
> uint256类型，token的供应方式（Transfer或Mineable）


#### :point_right: _supplyByTransfer
该方法无权限设置   
```
function _supplyByTransfer(TokenInfo memory ti, address to, uint256 amount) internal returns(uint256) 
```
##### 描述
> 该方法为向外通过转账方式来供应ERC20 token

##### 参数
**ti**
> token的详细信息

**to**
> address类型，token的接受者地址

**amount**
> uint256类型，转账供应的数量

##### 返回值说明
**_uint256**
> 剩余的token余额


#### :point_right: _supplyByMint
该方法无权限设置      
```
function _supplyByMint(TokenInfo memory ti, address to, uint256 amount) internal returns(uint256)
```
##### 描述
> 该方法为向外通过铸造方式来供应ERC20 token

##### 参数
**ti**
> token的详细信息

**to**
> address类型，token的接受者地址

**amount**
> uint256类型，转账供应的数量

##### 返回值说明
**_uint256**
> 剩余的token余额


#### :point_right: mint
该方法仅Consumer权限调用  
```
function mint(address _token, address _to, uint256 _amount) external onlyConsumer noReentrancy returns(uint256)
```
##### 描述
> 该方法为铸造ERC20 token的方式

##### 参数
**_token**
> address类型，ERC20 token的合约地址

**_to**
> address类型，ERC20 token的接收账户地址

**_amount**
> uint256类型，发放token的数量


## 合约读取接口

#### :point_right: getTokenSupply
该方法无权限配置   
```
function getTokenSupply(address _token) external view returns(uint256) 
```
##### 描述
> 该方法为查询该ERC20 token的供应量

##### 参数
**_token**
> address类型，ERC20 token的合约地址

##### 返回值说明
**uint256**
> uint256类型，该ERC20 token的供应量

