// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.6.0;

interface ISealOnchainIdxStore {
    struct Data {
        uint256 key;
        address recorder;
        uint256 block;
        bytes sig;
    }

    function store(uint256 _key) external returns(bool exists, bool stored);
    function storeWithVerify(uint256 _key, bytes calldata _sig, uint256 _feeCategory, address _feeSupplier) payable external returns(bool exists, bool stored);
    function getStored(address _recorder, uint256 _key) view external returns(address recorder,uint256 key, uint256 blk, bytes memory sig);
    function validSigner(address _signer) view external returns(bool valid);
}