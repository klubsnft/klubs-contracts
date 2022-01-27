// SPDX-License-Identifier: MIT

pragma solidity ^0.5.0;

import "../klaytn-contracts/token/KIP37/KIP37Holder.sol";
import "../klaytn-contracts/token/KIP37/IERC1155Receiver.sol";

contract ERC1155KIP37Holder is KIP37Holder, IERC1155Receiver {
    constructor() public {
        _registerInterface(IERC1155Receiver(0).onERC1155Received.selector ^ IERC1155Receiver(0).onERC1155BatchReceived.selector);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}
