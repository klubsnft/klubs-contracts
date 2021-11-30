pragma solidity ^0.5.6;

interface IPFPStoreV2 {
    event Sell(address indexed addr, uint256 indexed id, address indexed owner, uint256 price);
    event ChangeSellPrice(address indexed addr, uint256 indexed id, address indexed owner, uint256 price);
    event Buy(address indexed addr, uint256 indexed id, address indexed buyer, uint256 price);
    event CancelSale(address indexed addr, uint256 indexed id, address indexed owner);

    event MakeOffer(address indexed addr, uint256 indexed id, uint256 indexed offerId, address offeror, uint256 price);
    event CancelOffer(address indexed addr, uint256 indexed id, uint256 indexed offerId, address offeror);
    event AcceptOffer(address indexed addr, uint256 indexed id, uint256 indexed offerId, address acceptor);

    event CreateAuction(address indexed addr, uint256 indexed id, address indexed owner, uint256 startPrice, uint256 endBlock);
    event CancelAuction(address indexed addr, uint256 indexed id, address indexed owner);
    event Bid(address indexed addr, uint256 indexed id, address indexed bidder, uint256 price);
    event Claim(address indexed addr, uint256 indexed id, address indexed bidder, uint256 price);

    event CancelSaleByOwner(address indexed addr, uint256 indexed id);
    event CancelOfferByOwner(address indexed addr, uint256 indexed id, uint256 indexed offerId);
    event CancelAuctionByOwner(address indexed addr, uint256 indexed id);

    event Ban(address indexed user);
    event Unban(address indexed user);

    function auctionExtensionInterval() external view returns (uint256);
    function isBanned(address user) external view returns (bool);

    function batchTransfer(address[] calldata addrs, uint256[] calldata ids, address[] calldata to) external;

    function sales(address addr, uint256 id) external view returns (address seller, uint256 price);
    function userSellInfo(address seller, uint256 index) external view returns (address pfp, uint256 id, uint256 price);
    function userSellInfoLength(address seller) external view returns (uint256);
    function checkSelling(address addr, uint256 id) external view returns (bool);

    function onSalesCount(address addr) view external returns (uint256);
    function onSales(address addr, uint256 index) view external returns (uint256);

    function sell(address[] calldata addrs, uint256[] calldata ids, uint256[] calldata prices) external;
    function cancelSale(address[] calldata addrs, uint256[] calldata ids) external;
    function buy(address[] calldata addrs, uint256[] calldata ids) external;

    function offers(address addr, uint256 id, uint256 index) external view returns (address offeror, uint256 price);
    function userOfferInfo(address offeror, uint256 index) external view returns (address pfp, uint256 id, uint256 price);
    function userOfferInfoLength(address offeror) external view returns (uint256);
    function offerCount(address addr, uint256 id) external view returns (uint256);

    function makeOffer(address addr, uint256 id, uint256 price) external returns (uint256 offerId);
    function cancelOffer(address addr, uint256 id, uint256 offerId) external;
    function acceptOffer(address addr, uint256 id, uint256 offerId) external;

    function auctions(address addr, uint256 id) external view returns (address seller, uint256 startPrice, uint256 endBlock);
    function userAuctionInfo(address seller, uint256 index) external view returns (address pfp, uint256 id, uint256 startPrice);
    function userAuctionInfoLength(address seller) external view returns (uint256);
    function checkAuction(address addr, uint256 id) external view returns (bool);

    function onAuctionsCount(address addr) view external returns (uint256);
    function onAuctions(address addr, uint256 index) view external returns (uint256);

    function createAuction(address addr, uint256 id, uint256 startPrice, uint256 endBlock) external;
    function cancelAuction(address addr, uint256 id) external;

    function biddings(address addr, uint256 id, uint256 index) external view returns (address bidder, uint256 price);
    function userBiddingInfo(address bidder, uint256 index) external view returns (address pfp, uint256 id, uint256 price);
    function userBiddingInfoLength(address bidder) external view returns (uint256);
    function biddingCount(address addr, uint256 id) external view returns (uint256);

    function bid(address addr, uint256 id, uint256 price) external returns (uint256 biddingId);
    function claim(address addr, uint256 id) external;
}
