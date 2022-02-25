# seal-nft contract

# Summary概括

该合约是一本符合ERC 720标准的合约，提供简洁的三角色管理，并提供带有Seal签名的NFT Token铸造能力。

# Constructor
```
constructor(
    address _owner,
    string memory _name,
    string memory _symbol,
    address payable _periphery
) public Simple3Role(_owner) ERC721(_name, _symbol)

```

##### parameters

|  name   | type  | description  |
|  ----  | ----  | ---- |
| _owner  | address | 合约的所有者，所有者也具有管理员角色. |
| _name  | string | NFT的名称. |
| _symbol  | string | NFT的符号. |
| _periphery  | address | NFT的周边合约地址. |

## 合约调用接口

#### :point_right: setBaseURI
该方法仅admin权限调用   
```
function setBaseURI(string calldata _newURI) external onlyAdmin
```
##### 描述
> 该方法为设置元数据基础URI

##### 参数
**_newURI**
> string类型，新的Token的基础URI


#### :point_right: mintHashed
该方法仅Admin权限调用   
```
function mintHashed(address _to, bytes32 _metadataHash) external onlyAdmin
```
##### 描述
> 该方法为铸造带哈希的NFT

##### 参数
**_to**
> address类型，NFT的接受者的账户地址

**_metadataHash**
> bytes32类型，NFT对应的元数据的hash，该hash也将作为NFT ID使用。


#### :point_right: mintSigned
该方法仅Executor权限调用   
```
function mintSigned(address _to, bytes32 _metadataHash, bytes calldata _sig, uint256 _feeCategory, address _feeSupplier) external onlyExecutor
```
##### 描述
> 该方法为铸造带签名的NFT

##### 参数
**_to**
> address类型，本枚NFT通证的所有者

**_metadataHash**
> bytes32类型，本枚NFT元数据metadata的哈希值

**_sig**
> bytes类型，平台对元数据的签名，后端给出

**_feeCategory**
> uint256类型，收费类型，后端给出

**_feeSupplier**
> address类型，付费地址，一般为当前钱包的账户地址


#### :point_right: mintSequentially
该方法仅Executor权限调用   
```
function mintSequentially(address _to) external onlyExecutor
```
##### 描述
> 该方法为铸造带顺序ID的NFT

##### 参数
**_to**
> address类型，NFT的接受者的账户地址


#### :point_right: mintDirect
该方法仅Executor权限调用      
```
function mintDirect(address _to, uint256 _id) external onlyExecutor
```
##### 描述
> 该方法为可直接铸造任意id的NFT

##### 参数
**_to**
> address类型，该NFT的接受者的账户地址

**_id**
> uint256类型，该NFT的ID(如已铸造过重复的ID，则会铸造失败)


## 合约读取接口

#### :point_right: tokenURI
该方法无权限配置   
```
function tokenURI(uint256 _id) override view public returns(string memory uri) 
```
##### 描述
该方法为读取token元数据的URI

##### 参数
**_id**
> uint256类型，token的ID

##### 返回值说明
**uri**
> string类型，返回token元数据的URI


#### :point_right: getSealNFTURI
该方法无权限配置   
```
function getSealNFTURI(uint256 _id) external view returns(string memory sealURI)
```
##### 描述
> 该方法为查询token在SealNFT中的URI

##### 参数
**_id**
> uint256类型，token的ID

##### 返回值说明
**sealURI**
> string类型，返回该token在SealNFT中的元数据URI


#### :point_right: getStoredInfo
该方法无权限配置   
```
 function getStoredInfo(uint256 _id) external view
    returns(address recorder, uint256 key, uint256 blk, bytes memory sig)
```
##### 描述
> 该方法为查询token在SealNFT中存证索引信息

##### 参数
**_id**
> address类型，要查询的token的ID

##### 返回值说明
**recorder**
> address类型，返回数据存储者的地址

**key**
> uint256类型，返回数据的Key

**blk**
> uint256类型，返回存储的高度

**sig**
> bytes类型，返回存证的签名

