pragma solidity ^0.5.6;

import "../klaytn-contracts/token/KIP17/KIP17Full.sol";
import "../klaytn-contracts/token/KIP17/KIP17Mintable.sol";
import "../klaytn-contracts/token/KIP17/KIP17Burnable.sol";
import "../klaytn-contracts/token/KIP17/KIP17Pausable.sol";

contract TestPFP is KIP17Full("TEST PFP", "TPFP"), KIP17Mintable, KIP17Burnable, KIP17Pausable {
    function bulkTransfer(address[] calldata tos, uint256[] calldata ids) external {
        uint256 length = ids.length;
        for (uint256 i = 0; i < length; i++) {
            transferFrom(msg.sender, tos[i], ids[i]);
        }
    }

    function massMint(address to, uint256 amount) external onlyMinter {
        for (uint256 i = 0; i < amount; i++) {
            mint(to, i);
        }
    }
}
