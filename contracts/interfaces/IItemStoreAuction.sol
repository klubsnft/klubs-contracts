pragma solidity ^0.5.6;

import "./IItemStoreCommon.sol";

interface IItemStoreAuction {
    event CreateAuction(
        uint256 indexed metaverseId,
        address indexed item,
        uint256 id,
        address seller,
        uint256 amount,
        uint256 startPrice,
        uint256 endBlock,
        bytes32 indexed auctionVerificationID
    );
    event CancelAuction(uint256 indexed metaverseId, address indexed item, uint256 id, bytes32 indexed auctionVerificationID);

    event Bid(
        uint256 indexed metaverseId,
        address indexed item,
        uint256 id,
        address bidder,
        uint256 amount,
        uint256 price,
        bytes32 indexed auctionVerificationID,
        uint256 biddingId
    );
    event Claim(
        uint256 indexed metaverseId,
        address indexed item,
        uint256 id,
        address bestBidder,
        uint256 amount,
        uint256 price,
        bytes32 indexed auctionVerificationID,
        uint256 biddingId
    );

    event CancelAuctionByOwner(uint256 indexed metaverseId, address indexed item, uint256 id, bytes32 indexed auctionVerificationID);

    function commonData() external view returns (IItemStoreCommon);

    function nonce(address user) external view returns (uint256);

    //Auction
    function auctions(
        address item,
        uint256 id,
        uint256 auctionId
    )
        external
        view
        returns (
            address seller,
            uint256 metaverseId,
            address _item,
            uint256 _id,
            uint256 amount,
            uint256 startTotalPrice,
            uint256 endBlock,
            bytes32 verificationID
        );

    function onAuctions(address item, uint256 index) external view returns (bytes32 auctionVerificationID);

    function userAuctionInfo(address seller, uint256 index) external view returns (bytes32 auctionVerificationID);

    function auctionsOnMetaverse(uint256 metaverseId, uint256 index) external view returns (bytes32 auctionVerificationID);

    function getAuctionInfo(bytes32 auctionVerificationID)
        external
        view
        returns (
            address item,
            uint256 id,
            uint256 auctionId
        );

    function auctionsCount(address item, uint256 id) external view returns (uint256);

    function onAuctionsCount(address item) external view returns (uint256);

    function userAuctionInfoLength(address seller) external view returns (uint256);

    function auctionsOnMetaverseLength(uint256 metaverseId) external view returns (uint256);

    function canCreateAuction(
        address seller,
        uint256 metaverseId,
        address item,
        uint256 id,
        uint256 amount
    ) external view returns (bool);

    function createAuction(
        uint256 metaverseId,
        address item,
        uint256 id,
        uint256 amount,
        uint256 startTotalPrice,
        uint256 endBlock
    ) external returns (uint256 auctionId);

    function cancelAuction(bytes32 auctionVerificationID) external;

    //Bidding
    function biddings(bytes32 auctionVerificationID, uint256 biddingId)
        external
        view
        returns (
            address bidder,
            uint256 metaverseId,
            address item,
            uint256 id,
            uint256 amount,
            uint256 price,
            uint256 mileage
        );

    function userBiddingInfo(address bidder, uint256 index) external view returns (bytes32 auctionVerificationID, uint256 biddingId);

    function userBiddingInfoLength(address bidder) external view returns (uint256);

    function biddingsCount(bytes32 auctionVerificationID) external view returns (uint256);

    function canBid(
        address bidder,
        uint256 price,
        bytes32 auctionVerificationID
    ) external view returns (bool);

    function bid(
        bytes32 auctionVerificationID,
        uint256 price,
        uint256 mileage
    ) external returns (uint256 biddingId);

    function claim(bytes32 auctionVerificationID) external;
}
