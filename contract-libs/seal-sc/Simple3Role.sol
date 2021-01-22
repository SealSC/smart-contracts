pragma solidity ^0.6.0;

import "../open-zeppelin/Ownable.sol";


contract Simple3Role is Ownable {
    mapping(address=>bool) administrator;
    mapping(address=>bool) executor;

    constructor(address _owner) public Ownable(_owner) {
        administrator[_owner] = true;
        executor[_owner] = true;
    }

    modifier onlyAdmin() {
        require(administrator[msg.sender], "not administrator");
        _;
    }

    modifier onlyExecutor() {
        require(executor[msg.sender], "not executor");
        _;
    }

    function isAdministrator(address addr) external view returns(bool) {
        return administrator[addr];
    }

    function isExecutor(address addr) external view returns(bool) {
        return executor[addr];
    }

    function addAdministrator(address addr) external onlyOwner {
        administrator[addr] = true;
    }

    function removeAdministrator(address addr) external onlyOwner {
        administrator[addr] = false;
    }

    function addExecutor(address addr) external onlyAdmin {
        executor[addr] = true;
    }

    function removeExecutor(address addr) external onlyAdmin {
        executor[addr] = false;
    }
}
