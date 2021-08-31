// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.6.0;

import "./ERC20DistributionInShares.sol";

contract ERC20DistributionInSharesFactory is Simple3Role, SimpleSealSCSignature {
    constructor(address _owner) public Simple3Role(_owner) {}

    event EDISCreated(address edisAddr, address projectAdmin, address accItem, bool isPrivate);

    function deployEDIS(address _projectAdmin, address _accItem, bool _isPrivate) external onlyAdmin {
        ERC20DistributionInShares edisAddr = new ERC20DistributionInShares();

        edisAddr.setPeriphery(_projectAdmin, _accItem);

        if(_isPrivate) {
            edisAddr.switchToPrivate();
        }

        edisAddr.addAdministrator(msg.sender);
        edisAddr.transferOwnership(owner());

        emit EDISCreated(address(edisAddr), _projectAdmin, _accItem, _isPrivate);
    }
}
