pragma solidity ^0.5.9;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

contract ERC20TokenSupplier is Ownable {
    using SafeMath for uint256;

    mapping(address=>IERC20) public tokens;
    address[] public tokenArray;

    mapping(address=>bool) public consumers;
    modifier onlyConsumer() {
        require(consumers[msg.sender], "not consumer");
        _;
    }

    constructor(address _owner) public Ownable(_owner) {}

    function tokenCount() external view returns(uint256) {
        return tokenArray.length;
    }

    function getTokenSupply(address _token) external view returns(uint256) {
        require(IERC20(0) != tokens[_token], "not supported yet");

        IERC20 token = tokens[_token];
        return token.balanceOf(address(this));
    }

    function addConsumer(address _consumer) external onlyOwner {
        consumers[_consumer] = true;
    }

    function removeConsumer(address _consumer) external onlyOwner {
        delete consumers[_consumer];
    }

    function addToken(address _token) external onlyOwner{
        tokens[_token] = IERC20(_token);
        tokenArray.push(_token);
    }

    function mint(address _token, address _to, uint256 _amount) external onlyConsumer returns(uint256) {
        IERC20 token = tokens[_token];
        require(token != IERC20(0), "no such token");

        uint256 supplyBeforeMint = token.balanceOf(address(this));

        uint256 amountToMint = _amount;
        if(supplyBeforeMint < amountToMint) {
            amountToMint = supplyBeforeMint;
        }
        token.transfer(_to, amountToMint);
        uint256 supplyAfterMint = token.balanceOf(address(this));

        return supplyBeforeMint.sub(supplyAfterMint);
    }
}
