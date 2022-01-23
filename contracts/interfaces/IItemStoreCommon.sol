pragma solidity ^0.5.6;

import "./IMetaverses.sol";
import "./IMix.sol";
import "./IMileage.sol";

interface IItemStoreCommon {
    event Ban(address indexed user);
    event Unban(address indexed user);

    function metaverses() external view returns (IMetaverses);

    function mix() external view returns (IMix);

    function mileage() external view returns (IMileage);

    function fee() external view returns (uint256);

    function feeReceiver() external view returns (address);

    function auctionExtensionInterval() external view returns (uint256);

    function setFee(uint256 _fee) external;

    function setFeeReceiver(address _receiver) external;

    function setAuctionExtensionInterval(uint256 interval) external;

    function setMetaverses(IMetaverses _metaverses) external;

    function isMetaverseWhitelisted(uint256 metaverseId) external view returns (bool);

    function isItemWhitelisted(uint256 metaverseId, address item) external view returns (bool);

    function isBannedUser(address user) external view returns (bool);

    function banUser(address user) external;

    function unbanUser(address user) external;

    function batchTransfer(
        uint256[] calldata metaverseIds,
        address[] calldata items,
        uint256[] calldata ids,
        address[] calldata to,
        uint256[] calldata amounts
    ) external;
}
