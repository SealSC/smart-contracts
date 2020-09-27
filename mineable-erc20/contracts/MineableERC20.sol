pragma solidity ^0.5.9;

import "../../contract-libs/open-zeppelin/ERC20.sol";
import "../../contract-libs/open-zeppelin/ERC20Detailed.sol";
import "../../contract-libs/seal-sc/Constants.sol";
import "../../contract-libs/seal-sc/Calculation.sol";
import "../../contract-libs/seal-sc/SimpleSealSCSignature.sol";
import "./interface/IMineableERC20.sol";
import "../../contract-libs/seal-sc/RejectDirectETH.sol";

contract MineableERC20 is IMineableERC20, ERC20, ERC20Detailed, Ownable, Constants, SimpleSealSCSignature, RejectDirectETH {
    using SafeMath for uint256;
    using Calculation for uint256;

    mapping(address=>MinterInfo) public minters;
    mapping(address=>bool) public admins;

    modifier onlyAdmin() {
        require(admins[msg.sender], "not admin");
        _;
    }

     modifier onlyMinter() {
         require(minters[msg.sender].minter != ZERO_ADDRESS, "not minter");
         _;
     }

    constructor(
        address _owner,
        address _admin,
        string memory _name,
        string memory _symbol,
        uint8 _decimals)
    public ERC20Detailed(_name, _symbol, _decimals) Ownable(_owner){
        require(_owner != ZERO_ADDRESS);
        require(_admin != ZERO_ADDRESS);

        admins[_admin] = true;
    }

    function addAdmin(address _admin) external onlyOwner {
        require(_admin != ZERO_ADDRESS, "can't set address zero as admin");
        admins[_admin] = true;
    }

    function removeAdmin(address _admin) external onlyOwner {
        delete admins[_admin];
    }

    function setMinter(address _minter, uint256 _weight) external onlyAdmin {
        MinterInfo memory mi = minters[_minter];
        require(mi.minter !=  ZERO_ADDRESS, "minter already set");

        uint256 minterWeight  = _weight;
        if(minterWeight == 0) {
            minterWeight = BASIS_POINT_PRECISION;
        }

        mi.minter = _minter;
        mi.weight = _weight;
        minters[_minter] = mi;
    }

    function updateMinterWeight(address[] calldata _minters, uint256[] calldata _weights) external onlyAdmin {
        require(_minters.length == _weights.length, "parameter's length not match");
        for(uint256 i=0; i<_minters.length; i++) {
            MinterInfo storage mi = minters[_minters[i]];
            if(mi.minter == ZERO_ADDRESS) {
                continue;
            }

            mi.weight = _weights[i];
        }
    }

    function removeMinter(address _minter) external onlyAdmin {
        delete minters[_minter];
    }

    function mint(address to, uint256 amount) external onlyMinter {
        require(to != ZERO_ADDRESS, "can not mint to address 0");
        MinterInfo memory minter = minters[msg.sender];

        uint256 actualAmount = amount.percentageMul(minter.weight, BASIS_POINT_PRECISION);
        _mint(to, actualAmount);
    }
}
