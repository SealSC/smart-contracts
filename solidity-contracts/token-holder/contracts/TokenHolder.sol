pragma solidity ^0.6.2;

import "../../contract-libs/seal-sc/SimpleSealSCSignature.sol";
import "../../contract-libs/seal-sc/Simple3Role.sol";
import "../../contract-libs/seal-sc/TokenTransferOut.sol";
import "../../contract-libs/open-zeppelin/ERC1155/ERC1155Receiver.sol";
import "../../contract-libs/open-zeppelin/ECDSA.sol";
import "../../contract-libs/open-zeppelin/ERC721/ERC721Holder.sol";

contract SealNFT1155Receiver is ERC1155Receiver {
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    )
    override
    external
    returns(bytes4) {
        address _tokenAddress = msg.sender;
        require(IERC165(_tokenAddress).supportsInterface(_INTERFACE_ID_ERC1155), "onERC1155Received caller needs to implement ERC1155!");
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    )
    override
    external
    returns(bytes4 notSupport) {
        return notSupport;
    }
}

contract TokenHolder is ERC721Holder, SealNFT1155Receiver, Simple3Role, SimpleSealSCSignature {
    using Address for address payable;
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    constructor() public Simple3Role(msg.sender) {}

    function transferOutETH(address payable _to, uint256 _amount) external onlyAdmin {
        _to.sendValue(_amount);
    }

    function transferOutERC1155(IERC1155 _token, address _to, uint256 _id, uint256 _amount) external onlyAdmin {
        TokenTransferOut.transferOutERC1155(_token, _to, _id, _amount);
    }

    function transferOutERC721(IERC721 _token, address _to, uint256 _id) external onlyAdmin {
        TokenTransferOut.transferOutERC721(_token, _to, _id);
    }

    function transferOutERC20(IERC20 _token, address _to, uint256 _amount) external onlyAdmin {
        TokenTransferOut.transferOutERC20(_token, _to, _amount);
    }
}
