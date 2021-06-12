// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6.0;

import "../open-zeppelin/ECDSA.sol";
import "../open-zeppelin/Strings.sol";
import "../open-zeppelin/SafeMath.sol";

contract Mutex {
    bool internal _utils_mutex_locked;

    //code from solidity document
    modifier noReentrancy() {
        require(
            !_utils_mutex_locked,
            "Reentrant call."
        );
        _utils_mutex_locked = true;
        _;
        _utils_mutex_locked = false;
    }
}


library SealUtils {
    using ECDSA for bytes32;
    using Strings for uint256;
    using SafeMath for uint256;

    string constant lowerCaseAlphabet = "0123456789abcdef";
    string constant upperCaseAlphabet = "0123456789ABCDEF";


    function toHexString(bytes memory _value, bytes memory _alphabet) private pure returns(string memory) {
        uint256 bytesCount = _value.length;
        bytes memory str = new bytes((bytesCount*2) + 2);
        str[0] = '0';
        str[1] = 'x';
        for (uint256 i = 0; i < _value.length; i++) {
            str[2+i*2] = _alphabet[uint8(_value[i] >> 4)];
            str[3+i*2] = _alphabet[uint8(_value[i] & 0x0f)];
        }
        return string(str);
    }

    function toUpperCaseHex(address _addr) internal pure returns(string memory) {
        return toHexString(abi.encodePacked(_addr), bytes(upperCaseAlphabet));
    }

    function toLowerCaseHex(address _addr) internal pure returns(string memory) {
        return toHexString(abi.encodePacked(_addr), bytes(lowerCaseAlphabet));
    }

    function toUpperCaseHex(uint256 _uint) internal pure returns(string memory) {
        return toHexString(abi.encodePacked(_uint), bytes(upperCaseAlphabet));
    }

    function toLowerCaseHex(uint256 _uint) internal pure returns(string memory) {
        return toHexString(abi.encodePacked(_uint), bytes(lowerCaseAlphabet));
    }

    function toUpperCaseHex(bytes memory _bytes) internal pure returns(string memory) {
        return toHexString(_bytes, bytes(upperCaseAlphabet));
    }

    function toLowerCaseHex(bytes memory _bytes) internal pure returns(string memory) {
        return toHexString(_bytes, bytes(lowerCaseAlphabet));
    }

    function verifySignature(address signer, bytes memory rawData, bytes memory sig, string memory assertMsg) internal pure returns(bytes32) {
        bytes memory evmRawData = abi.encodePacked("\x19Ethereum Signed Message:\n", rawData.length.toString(), rawData);
        bytes32 dataHash = keccak256(evmRawData);

        require(signer == dataHash.recover(sig), string(abi.encodePacked("invalid signature: ", assertMsg)));

        return dataHash;
    }

    function calcFee(uint256 _amount, uint256 _fee, uint256 _feeBP) internal pure returns(uint256) {
        return _amount.mul(_fee).div(_feeBP);
    }

    function reduceFee(uint256 _amount, uint256 _fee, uint256 _feeBP) internal pure returns(uint256) {
        uint256 feeAmount = calcFee(_amount, _fee, _feeBP);
        return _amount.sub(feeAmount);
    }
}
