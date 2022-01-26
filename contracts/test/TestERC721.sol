pragma solidity ^0.5.6;

import "../klaytn-contracts/ownership/Ownable.sol";
import "../klaytn-contracts/token/KIP17/KIP17Full.sol";
import "../klaytn-contracts/token/KIP17/KIP17Mintable.sol";
import "../klaytn-contracts/token/KIP17/KIP17Burnable.sol";
import "../klaytn-contracts/token/KIP17/KIP17Pausable.sol";

contract TestERC721 is KIP17Full("TEST", "T"), KIP17Mintable, KIP17Burnable, KIP17Pausable, Ownable {
    function isTokenExistent(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function bulkTransfer(address[] calldata tos, uint256[] calldata ids) external {
        uint256 length = ids.length;
        for (uint256 i = 0; i < length; i++) {
            transferFrom(msg.sender, tos[i], ids[i]);
        }
    }

    function massMint2(address to, uint256 fromId, uint256 amount) external {
        for (uint256 i = 0; i < amount; i++) {
            mint(to, fromId + i);
        }
    }
}
