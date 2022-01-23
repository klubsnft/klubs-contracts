pragma solidity ^0.5.6;

import "../interfaces/IMetaverses.sol";
import "../klaytn-contracts/token/KIP17/IKIP17.sol";
import "../klaytn-contracts/token/KIP37/IKIP37.sol";

library ItemStoreLibrary {
    function _isERC1155(address item, IMetaverses metaverses, uint256 metaverseId) internal view returns (bool) {
        return metaverses.itemTypes(metaverseId, item) == IMetaverses.ItemType.ERC1155;
    }

    function _transferItems(
        address item,
        IMetaverses metaverses,
        uint256 metaverseId,
        uint256 id,
        uint256 amount,
        address from,
        address to
    ) internal {
        if (_isERC1155(item, metaverses, metaverseId)) {
            require(amount > 0);
            IKIP37(item).safeTransferFrom(from, to, id, amount, "");
        } else {
            require(amount == 1);
            IKIP17(item).transferFrom(from, to, id);
        }
    }
}
