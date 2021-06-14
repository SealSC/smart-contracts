pragma solidity >=0.6.0;

contract ApprovedTokenList {
    mapping(bytes32=>bool) public listed;
    mapping(bytes32=>bool) public delisted;

    address public owner;
    bool public pairListControlEnable = false;

    event ListToken(address indexed token0, address indexed token1, uint256 indexed blockNum);
    event DelistToken(address indexed token0, address indexed token1, uint256 indexed blockNum);
    event RelistToken(address indexed token0, address indexed token1, uint256 indexed blockNum);

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function listedPair(bytes32 _salt) view internal returns(bool) {
        require(listed[_salt], "pair not listed");
        require(!delisted[_salt], "pair delisted");
        return true;
    }

    constructor(address _owner) public {
        owner = _owner;
    }

    function _getPairSalt(address _tokenA, address _tokenB) pure internal returns(bytes32, address, address) {
        require(_tokenA != _tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
        (address token0, address token1) = _tokenA < _tokenB ? (_tokenA, _tokenB) : (_tokenB, _tokenA);
        require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');
        return (keccak256(abi.encodePacked(token0, token1)), token0, token1);
    }

    function listPair(address _tokenA, address _tokenB) external onlyOwner {
        (bytes32 pairSalt, address _token0, address _token1) = _getPairSalt(_tokenA, _tokenB);

        require(!listed[pairSalt], "pair already listed");
        require(!delisted[pairSalt], "pair already delisted");

        listed[pairSalt] = true;

        emit ListToken(_token0, _token1, block.number);
    }

    function delistPair(address _tokenA, address _tokenB) external onlyOwner {
        (bytes32 pairSalt, address _token0, address _token1) = _getPairSalt(_tokenA, _tokenB);

        require(listed[pairSalt], "pair not listed");
        require(!delisted[pairSalt], "pair already delisted");

        listed[pairSalt] = false;
        delisted[pairSalt] = true;

        emit DelistToken(_token0, _token1, block.number);
    }

    function relistPair(address _tokenA, address _tokenB) external onlyOwner {
        (bytes32 pairSalt, address _token0, address _token1) = _getPairSalt(_tokenA, _tokenB);

        require(!listed[pairSalt], "pair already listed");
        require(delisted[pairSalt], "pair not delisted");

        delisted[pairSalt] = false;
        listed[pairSalt] = true;

        emit RelistToken(_token0, _token1, block.number);
    }

    function setListControl(bool _enable) external onlyOwner {
        pairListControlEnable = _enable;
    }
}
