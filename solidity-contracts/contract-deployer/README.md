# Summary

This contract is used for the parameterized deployment of preset contracts. With the matching front-end and centralized system, preset contracts can be deployed directly without compilation.   

The deployer has two roles, owner and admin. The owner is used to configure the admin, and the admin is used to set up the preset contract.  

# constructor
```
constructor(address _owner) public Simple3Role(_owner)
```

##### parameters

|  name   | type  | description  |
|  ----  | ----  | ---- |
| _owner  | address | Owner of the contract, an owner is also has role of admin. |


# admin interfaces

The methods blow only can be called by admin role.

#### :point_right: addPresetContract
```
function addPresetContract(uint256 _fee, bytes32 _codeHash, string calldata _name, bool _disabled) external onlyAdmin 
```

##### description
>Add preset contract.

##### parameters
|  name   | type  | description  |
|  ----  | ----  | ---- |
| _fee  | uint256 | the external fee when deploy the preset contract. |
| _codeHash  | bytes32 | the keccak256 hash value of the contract's bytecode. |
| _name  | string | name of the preset contract. |
| _disabled  | bool | disable flag, can be changed by method **setPresetContractDisableFlag**. |

#### :point_right: disablePresetContract
```
function setPresetContractDisableFlag(uint256 _idx, bool _disableFlag) external onlyAdmin
```

##### description
>set preset contract disable flag value

##### parameters
|  name   | type  | description  |
|  ----  | ----  | ---- |
| _idx  | uint256 | the preset contract index. |
| _disableFlag  | bool | the new value of the disabled flag. |

#### :point_right: updatePresetContractName
```
function updatePresetContractName(uint256 _idx, string calldata _name) external onlyAdmin
```

##### description
>update preset contract's name

##### parameters
|  name   | type  | description  |
|  ----  | ----  | ---- |
| _idx  | uint256 | the preset contract index. |
| _name  | string | new name of the preset contract. |

#### :point_right: updatePresetContractFee
```
function updatePresetContractFee(uint256 _idx, uint256 _fee) external onlyAdmin
```

##### description
>update deploy fee of the preset contract.

##### parameters
|  name   | type  | description  |
|  ----  | ----  | ---- |
| _idx  | uint256 | the preset contract index. |
| _fee  | uint256 | new deploy fee in wei. |

#### :point_right: setDeployApprover
```
function setDeployApprover(address _approver) external onlyAdmin
```

##### description
>set deploy approver. every deploying of the preset contract must be signed by approver.

##### parameters
|  name   | type  | description  |
|  ----  | ----  | ---- |
| _approver  | address | the new approver. |

# user interfaces

The methods blow can be called by any account.

#### :point_right: deployPresetContract
```
function deployPresetContract(
                uint256 _idx, 
                bytes calldata _codeSig, 
                bytes32 _deployHash, 
                bytes calldata _deploySig, 
                bytes32 _salt, 
                bytes calldata _bytecode)
```

##### description
>deploy a preset contract by using Create2

##### parameters
|  name   | type  | description  |
|  ----  | ----  | ---- |
| _idx  | uint256 | the preset contract index. |
| _codeSig  | bytes | a signature singed by approver. *1 |
| _deployHash  | bytes32 | the keccak256 hash value of the contract's bytecode. |
| _deploySig  | bytes | a signature singed by approver. *2 |
| _salt  | bytes32 | salt used by Create2 |
| _bytecode  | bytes | the bytecode of the preset contract |

>*1  _codeSig's raw message will be
```javascript 
:${keccak256(abi.encodePacked(_idx, msg.sender))}
```

>*2  _deploySig's raw message will be
```javascript 
:${keccak256(abi.encodePacked(_idx, _salt, msg.sender))}
```
