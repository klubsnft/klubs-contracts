pragma solidity ^0.5.6;

interface IArtStore {
    event Sell(uint256 indexed id, address indexed owner, uint256 price);
    event ChangeSellPrice(uint256 indexed id, address indexed owner, uint256 price);
    event Buy(uint256 indexed id, address indexed buyer, uint256 price);
    event CancelSale(uint256 indexed id, address indexed owner);

    event MakeOffer(uint256 indexed id, uint256 indexed offerId, address offeror, uint256 price);
    event CancelOffer(uint256 indexed id, uint256 indexed offerId, address offeror);
    event AcceptOffer(uint256 indexed id, uint256 indexed offerId, address acceptor);

    event CreateAuction(uint256 indexed id, address indexed owner, uint256 startPrice, uint256 endBlock);
    event CancelAuction(uint256 indexed id, address indexed owner);
    event Bid(uint256 indexed id, address indexed bidder, uint256 price);
    event Claim(uint256 indexed id, address indexed bidder, uint256 price);

    event CancelSaleByOwner(uint256 indexed id);
    event CancelOfferByOwner(uint256 indexed id, uint256 indexed offerId);
    event CancelAuctionByOwner(uint256 indexed id);

    event Ban(address indexed user);
    event Unban(address indexed user);

    function auctionExtensionInterval() external view returns (uint256);

    function batchTransfer(uint256[] calldata ids, address[] calldata to) external;

    function sales(uint256 id) external view returns (address seller, uint256 price);
    function userSellInfo(address seller, uint256 index) external view returns (uint256 id, uint256 price);
    function userSellInfoLength(address seller) external view returns (uint256);
    function checkSelling(uint256 id) external view returns (bool);

    function onSalesCount() view external returns (uint256);
    function onSales(uint256 index) view external returns (uint256);

    function sell(uint256[] calldata ids, uint256[] calldata prices) external;
    function cancelSale(uint256[] calldata ids) external;
    function buy(uint256[] calldata ids, uint256[] calldata prices, uint256[] calldata mileages) external;

    function offers(uint256 id, uint256 index) external view returns (address offeror, uint256 price, uint256 mileage);
    function userOfferInfo(address offeror, uint256 index) external view returns (uint256 id, uint256 price);
    function userOfferInfoLength(address offeror) external view returns (uint256);
    function offerCount(uint256 id) external view returns (uint256);

    function makeOffer(uint256 id, uint256 price, uint256 mileage) external returns (uint256 offerId);
    function cancelOffer(uint256 id, uint256 offerId) external;
    function acceptOffer(uint256 id, uint256 offerId) external;

    function auctions(uint256 id) external view returns (address seller, uint256 startPrice, uint256 endBlock);
    function userAuctionInfo(address seller, uint256 index) external view returns (uint256 id, uint256 startPrice);
    function userAuctionInfoLength(address seller) external view returns (uint256);
    function checkAuction(uint256 id) external view returns (bool);

    function onAuctionsCount() view external returns (uint256);
    function onAuctions(uint256 index) view external returns (uint256);

    function createAuction(uint256 id, uint256 startPrice, uint256 endBlock) external;
    function cancelAuction(uint256 id) external;

    function biddings(uint256 id, uint256 index) external view returns (address bidder, uint256 price, uint256 mileage);
    function userBiddingInfo(address bidder, uint256 index) external view returns (uint256 id, uint256 price);
    function userBiddingInfoLength(address bidder) external view returns (uint256);
    function biddingCount(uint256 id) external view returns (uint256);

    function bid(uint256 id, uint256 price, uint256 mileage) external returns (uint256 biddingId);
    function claim(uint256 id) external;
}
