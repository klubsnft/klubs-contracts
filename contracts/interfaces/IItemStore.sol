pragma solidity ^0.5.6;

interface IItemStore {

    event Sell(uint256 indexed metaverseId, address indexed addr, uint256 indexed id, address owner, uint256 price, uint256 count);
    event ChangeSellPrice(uint256 indexed metaverseId, address indexed addr, uint256 indexed id, address owner, uint256 price);
    event Buy(uint256 indexed metaverseId, address indexed addr, uint256 indexed id, address buyer, uint256 price);
    event CancelSale(uint256 indexed metaverseId, address indexed addr, uint256 indexed id, address owner);

    event MakeOffer(uint256 indexed metaverseId, address indexed addr, uint256 indexed id, uint256 offerId, address offeror, uint256 price);
    event CancelOffer(uint256 indexed metaverseId, address indexed addr, uint256 indexed id, uint256 offerId, address offeror);
    event AcceptOffer(uint256 indexed metaverseId, address indexed addr, uint256 indexed id, uint256 offerId, address acceptor);

    event CreateAuction(uint256 indexed metaverseId, address indexed addr, uint256 indexed id, address owner, uint256 startPrice, uint256 endBlock);
    event CancelAuction(uint256 indexed metaverseId, address indexed addr, uint256 indexed id, address owner);
    event Bid(uint256 indexed metaverseId, address indexed addr, uint256 indexed id, address bidder, uint256 price);
    event Claim(uint256 indexed metaverseId, address indexed addr, uint256 indexed id, address bidder, uint256 price);

    event CancelSaleByOwner(uint256 indexed metaverseId, address indexed addr, uint256 indexed id);
    event CancelOfferByOwner(uint256 indexed metaverseId, address indexed addr, uint256 indexed id, uint256 offerId);
    event CancelAuctionByOwner(uint256 indexed metaverseId, address indexed addr, uint256 indexed id);

    event Ban(address indexed user);
    event Unban(address indexed user);

    function auctionExtensionInterval() external view returns (uint256);
    function isBanned(address user) external view returns (bool);

    function batchTransfer(uint256[] calldata metaverseIds, address[] calldata addrs, uint256[] calldata ids, address[] calldata to, uint256[] calldata counts) external;

    function sales(uint256 metaverseId, address addr, uint256 id) external view returns (address seller, uint256 price, uint256 count);
    function userSellInfo(address seller, uint256 index) external view returns (uint256 metaverseId, uint256 id, uint256 price, uint256 count);
    function userSellInfoLength(address seller) external view returns (uint256);
    function checkSelling(uint256 metaverseId, address addr, uint256 id) external view returns (bool);

    function onSalesCount(uint256 metaverseId, address addr) view external returns (uint256);
    function onSales(uint256 metaverseId, address addr, uint256 index) view external returns (uint256);

    function sell(uint256[] calldata metaverseIds, address[] calldata addrs, uint256[] calldata ids, uint256[] calldata prices, uint256[] calldata counts) external;
    function changeSellPrice(uint256[] calldata metaverseIds, address[] calldata addrs, uint256[] calldata ids, uint256[] calldata prices) external;
    function cancelSale(uint256[] calldata metaverseIds, address[] calldata addrs, uint256[] calldata ids) external;
    function buy(uint256[] calldata metaverseIds, address[] calldata addrs, uint256[] calldata ids) external;

    function offers(uint256 metaverseId, address addr, uint256 id, uint256 index) external view returns (address offeror, uint256 price);
    function userOfferInfo(address offeror, uint256 index) external view returns (address pfp, uint256 id, uint256 price);
    function userOfferInfoLength(address offeror) external view returns (uint256);
    function offerCount(uint256 metaverseId, address addr, uint256 id) external view returns (uint256);

    function makeOffer(uint256 metaverseId, address addr, uint256 id, uint256 price) external returns (uint256 offerId);
    function cancelOffer(uint256 metaverseId, address addr, uint256 id, uint256 offerId) external;
    function acceptOffer(uint256 metaverseId, address addr, uint256 id, uint256 offerId) external;

    function auctions(uint256 metaverseId, address addr, uint256 id) external view returns (address seller, uint256 startPrice, uint256 endBlock);
    function userAuctionInfo(address seller, uint256 index) external view returns (address pfp, uint256 id, uint256 startPrice);
    function userAuctionInfoLength(address seller) external view returns (uint256);
    function checkAuction(uint256 metaverseId, address addr, uint256 id) external view returns (bool);

    function onAuctionsCount(uint256 metaverseId, address addr) view external returns (uint256);
    function onAuctions(uint256 metaverseId, address addr, uint256 index) view external returns (uint256);

    function createAuction(uint256 metaverseId, address addr, uint256 id, uint256 startPrice, uint256 endBlock) external;
    function cancelAuction(uint256 metaverseId, address addr, uint256 id) external;

    function biddings(uint256 metaverseId, address addr, uint256 id, uint256 index) external view returns (address bidder, uint256 price);
    function userBiddingInfo(address bidder, uint256 index) external view returns (address pfp, uint256 id, uint256 price);
    function userBiddingInfoLength(address bidder) external view returns (uint256);
    function biddingCount(uint256 metaverseId, address addr, uint256 id) external view returns (uint256);

    function bid(uint256 metaverseId, address addr, uint256 id, uint256 price) external returns (uint256 biddingId);
    function claim(uint256 metaverseId, address addr, uint256 id) external;
}
