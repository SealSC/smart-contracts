# SealNFTStandard721 contract

# Summary概括

该合约为标准的的seal nft ERC721方法合约。

# Constructor
```
constructor(
    address _owner,
    string memory _name,
    string memory _symbol,
    bool _enablelockToken
)

```

##### parameters

|  name   | type  | description  |
|  ----  | ----  | ---- |
| _owner  | address | 合约的所有者，所有者也具有管理员角色. |
| _name  | string | 设置合约名称. |
| _symbol  | string | 设置合约的符号. |
| _enablelockToken  | boole | 设置是否开启锁定Token. |


## 合约调用接口

#### :point_right: setBaseURI
该方法仅Admin权限调用   
```
function setBaseURI(string calldata _uri) external onlyAdmin;
```
##### 描述
> 该方法为设置基础的URI

##### 参数
**_uri**
> string类型，基础URI


#### :point_right: setTokenURI
该方法仅Admin权限调用   
```
function setTokenURI(uint256 _id, string calldata _uri) external onlyAdmin;
```
##### 描述
> 该方法为设置指定Token的URI

##### 参数
**_id**
> uint256类型，指定token的id

**_uri**
> string类型，token的uri


#### :point_right: mint
该方法仅Admin权限调用   
```
function mint(address _to, uint256 _id) external onlyAdmin;
```
##### 描述
> 该方法为铸造token

##### 参数
**_to**
> address类型，token接收者

**_id**
> uint256类型，铸造token的唯一id



#### :point_right: burn
该方法仅token所有者调用   
```
function burn(uint256 _id) external isTokenOwner;
```
##### 描述
> 该方法为销毁Token

##### 参数
**_id**
> uint256类型，指定要销毁的token的id


#### :point_right: lockToken
该方法仅Owner权限调用   
```
function lockToken(uint256 _id) external onlyOwner;
```
##### 描述
> 该方法为将指定id的token进行锁定

##### 参数
**_id**
> uint256类型，指定要锁定的token的id

#### :point_right: unlockToken
该方法仅Owner权限调用   
```
function unlockToken(uint256 _id) external onlyOwner;
```
##### 描述
> 该方法为将锁定的token进行解锁

##### 参数
**_id**
> uint256类型，解锁被锁定的token的id


#### :point_right: transfer
该方法仅token所有者权限调用   
```
function transfer(address from, address to, uint256 tokenId) external isTokenOwner(tokenId) {
```
##### 描述
> 该方法为将指定token进行转移

##### 参数
**_from**
> address类型，被转移账户的账户地址

**_to**
> address类型，接收者的账户地址

**_from**
> uint256类型，指定token的id



## 合约事件

#### :point_right: BaseURISet
```
event BaseURISet(string _uri);
```
##### 描述
> 设置基础的URI的合约事件

##### 参数
**_uri**
> string类型，基础URI


#### :point_right: TokenURISet 
```
event TokenURISet(uint256 _id, string _uri);
```
##### 描述
> 设置指定Token的URI的合约事件

##### 参数
**_id**
> uint256类型，指定token的id

**_uri**
> string类型，token的uri


#### :point_right: MintTo
```
event MintTo(address owner, address _to, uint256 _id);
```
##### 描述
> 铸造token的合约事件

##### 参数
**_owner**
> address类型，操作者

**_to**
> address类型，token接收者

**_id**
> uint256类型，铸造token的唯一id



#### :point_right: TokenBurn
```
event TokenBurn(address owner, uint256 _id);
```
##### 描述
> 销毁Token的合约事件

##### 参数
**_owner**
> address类型，操作者

**_id**
> uint256类型，指定要销毁的token的id


#### :point_right: LockToken
```
event LockToken(uint256 _id);
```
##### 描述
> 将指定id的token进行锁定的合约事件

##### 参数
**_id**
> uint256类型，指定要锁定的token的id

#### :point_right: UnLockToken
```
event UnLockToken(uint256 _id);
```
##### 描述
> 将锁定的token进行解锁的合约事件

##### 参数
**_id**
> uint256类型，解锁被锁定的token的id


#### :point_right: TransferToken
```
event TransferToken(address from, address to, uint256 tokenId);
```
##### 描述
> 将指定token转出的合约事件

##### 参数
**_from**
> address类型，发送账户地址

**_to**
> address类型，接受token的账户地址

**_tokenId**
> uint256类型，指定的tokenid

