pragma solidity ^0.5.6;

import "./klaytn-contracts/ownership/Ownable.sol";
import "./libraries/ItemStoreLibrary.sol";
import "./interfaces/IItemStoreCommon.sol";

contract ItemStoreCommon is Ownable, IItemStoreCommon {
    using ItemStoreLibrary for *;

    uint256 public fee = 250;
    address public feeReceiver;
    uint256 public auctionExtensionInterval = 300;

    IMetaverses public metaverses;
    IMix public mix;
    IMileage public mileage;

    constructor(
        IMetaverses _metaverses,
        IMix _mix,
        IMileage _mileage
    ) public {
        feeReceiver = msg.sender;
        metaverses = _metaverses;
        mix = _mix;
        mileage = _mileage;
    }

    function setFee(uint256 _fee) external onlyOwner {
        require(_fee < 9 * 1e3); //max 90%
        fee = _fee;
    }

    function setFeeReceiver(address _receiver) external onlyOwner {
        feeReceiver = _receiver;
    }

    function setAuctionExtensionInterval(uint256 interval) external onlyOwner {
        auctionExtensionInterval = interval;
    }

    function setMetaverses(IMetaverses _metaverses) external onlyOwner {
        metaverses = _metaverses;
    }

    function isMetaverseWhitelisted(uint256 metaverseId) public view returns (bool) {
        return (metaverseId < metaverses.metaverseCount() && !metaverses.banned(metaverseId));
    }

    function isItemWhitelisted(uint256 metaverseId, address item) public view returns (bool) {
        return (isMetaverseWhitelisted(metaverseId) && metaverses.itemAdded(metaverseId, item));
    }

    mapping(address => bool) public isBannedUser;

    function banUser(address user) external onlyOwner {
        isBannedUser[user] = true;
        emit Ban(user);
    }

    function unbanUser(address user) external onlyOwner {
        isBannedUser[user] = false;
        emit Unban(user);
    }

    function batchTransfer(
        uint256[] calldata metaverseIds,
        address[] calldata items,
        uint256[] calldata ids,
        address[] calldata to,
        uint256[] calldata amounts
    ) external {
        require(
            metaverseIds.length == items.length &&
                metaverseIds.length == ids.length &&
                metaverseIds.length == to.length &&
                metaverseIds.length == amounts.length
        );
        require(!isBannedUser[msg.sender]);
        for (uint256 i = 0; i < metaverseIds.length; i++) {
            require(isItemWhitelisted(metaverseIds[i], items[i]));
            items[i]._transferItems(metaverses, metaverseIds[i], ids[i], amounts[i], msg.sender, to[i]);
        }
    }
}
