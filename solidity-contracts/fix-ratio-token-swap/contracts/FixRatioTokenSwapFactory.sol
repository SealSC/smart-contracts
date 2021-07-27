// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6.0;

import "../../contract-libs/seal-sc/Simple3Role.sol";
import "./FixRatioTokenSwap.sol";

contract FixRatioTokenSwapFactory is Simple3Role, RejectDirectETH {
    constructor(address _owner) public Simple3Role(_owner) {}

    mapping(bytes32=>bool) public listedSwap;

    struct SwapPreset {
        address projectAdmin;
        address contractAdmin;
        bool isPrivate;
        bool accepted;
    }

    mapping (bytes32=>SwapPreset) public acceptedSwap;

    event SwapAccepted(address swapCurrenty, address pricingCurrency, address projectAdmin);

    function _calcSwapContractKey(address _pricingCurrency, address _swapCurrency) pure internal returns(bytes32 key){
        key = keccak256(abi.encodePacked(_pricingCurrency, _swapCurrency));
        return key;
    }

    function presetSwap(
        address _projectAdmin,
        address _contractAdmin,
        bool _isPrivate,
        address _pricingCurrency,
        address _swapCurrency
    ) external onlyAdmin {
        bytes32 key = _calcSwapContractKey(_pricingCurrency, _swapCurrency);
        acceptedSwap[key] = SwapPreset({
            projectAdmin: _projectAdmin,
            contractAdmin: _contractAdmin,
            isPrivate: _isPrivate,
            accepted: true
        });

        emit SwapAccepted(_swapCurrency, _pricingCurrency, _projectAdmin);
    }

    function createSwap(
        IERC20 _pricingCurrency,
        IERC20 _swapCurrency,
        uint256 _ratio,
        uint256 _startTime,
        uint256 _duration,
        uint256 _supplyCap,
        uint256 _minInAmount,
        uint256 _maxInAmount
    ) external onlyExecutor returns(address swap) {
        bytes memory bytecode = type(FixRatioTokenSwap).creationCode;
        bytes32 key = _calcSwapContractKey(address(_pricingCurrency), address(_swapCurrency));
        require(!listedSwap[key], "listed already");

        SwapPreset memory preset = acceptedSwap[key];
        require(preset.accepted, "not accepted");

        assembly {
            swap := create2(0, add(bytecode, 32), mload(bytecode), key)
        }

        require(swap != address(0), "create failed");

        IFixRatioTokenSwap(swap).setConfigure(
            _pricingCurrency,
            _swapCurrency,
            _ratio,
            _startTime,
            _duration,
            _supplyCap,
            _minInAmount,
            _maxInAmount
        );

        IFixRatioTokenSwap(swap).setProjectAddress(preset.projectAdmin);
        IFixRatioTokenSwap(swap).setContractAdmin(preset.contractAdmin);
        if(preset.isPrivate) {
            IFixRatioTokenSwap(swap).switchToPrivate();
        }

        Ownable(swap).transferOwnership(owner());

        return swap;
    }
}
