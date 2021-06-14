pragma solidity =0.6.0;

import './interfaces/IUniswapV2Pair.sol';
import './UniswapV2Pair.sol';
import "./parameterized/listedPair.sol";

contract UniswapV2Factory is ApprovedTokenList {
    address public feeTo;
    address public feeToSetter;

    string public commonTokenName = 'Uniswap V2';
    string public commonTokenSymbol = 'UNI-V2';

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _feeToSetter, address _owner, bool _enableListCtrl, string memory _name, string memory _symbol) public ApprovedTokenList(_owner) {
        feeToSetter = _feeToSetter;
        pairListControlEnable = _enableListCtrl;

        commonTokenName = _name;
        commonTokenSymbol = _symbol;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));

        require(listedPair(salt), "not listed");

        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IUniswapV2Pair(pair).initialize(token0, token1);
        IUniswapV2Pair(pair).setNameAndSymbol(commonTokenName, commonTokenSymbol);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
}
