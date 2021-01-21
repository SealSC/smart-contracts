// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6.0;

import "../../../contract-libs/open-zeppelin/Ownable.sol";
import "../../../contract-libs/open-zeppelin/SafeMath.sol";
import "../../../contract-libs/seal-sc/Constants.sol";

abstract contract AdventureIslandRoleManager is Ownable, Constants {
    using SafeMath for uint256;

    event AddAdmin(address indexed newAdmin, uint256 indexed blockNumber);
    event RemoveAdmin(address indexed theAdmin, uint256 indexed blockNumber);

    mapping(address=>address) public admins;

    modifier onlyAdmin() {
        require(address(0) != admins[msg.sender], "caller is not the administrator");
        _;
    }

    function addAdmin(address _admin) public onlyOwner {
        require(_admin != ZERO_ADDRESS && admins[_admin] == ZERO_ADDRESS, "invalid parameters");

        admins[_admin] = _admin;
        emit AddAdmin(_admin, block.number);
    }

    function removeAdmin(address _admin) public onlyOwner {
        require(admins[_admin] != ZERO_ADDRESS, "not admin yet");

        delete admins[_admin];
        emit RemoveAdmin(_admin, block.number);
    }

    function isAdmin(address _admin) public view returns(bool) {
        return (address(0) != admins[_admin]);
    }
}
