// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6.0;

import "../../contract-libs/seal-sc/SimpleSealSCSignature.sol";
import "../../contract-libs/seal-sc/RejectDirectETH.sol";
import "./ERC20Minable.sol";
import "./ERC20WithBlackList.sol";

contract ParameterizedERC20 is ERC20WithBlackList, ERC20Minable, SimpleSealSCSignature, RejectDirectETH {
    constructor(
        address _owner,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        bool _minable,
        uint256 _initSupply)
    public ERC20(_name, _symbol, _decimals) Simple3Role(_owner){
        require(_owner != ZERO_ADDRESS);
        minable = _minable;
        _mint(_owner, _initSupply);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override(ERC20WithBlackList, ERC20) {
        ERC20WithBlackList._transfer(sender, recipient, amount);
    }
}
