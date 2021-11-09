pragma solidity ^0.5.6;

interface IPFPStore {
    
    event Sell(address indexed addr, uint256 indexed id, address indexed owner, uint256 price);
    event Buy(address indexed addr, uint256 indexed id, address indexed buyer, uint256 price);
    event CancelSale(address indexed addr, uint256 indexed id, address indexed owner);

    event Offer(address indexed addr, uint256 indexed id, uint256 indexed offerId, address offeror, uint256 price);
    event CancelOffer(address indexed addr, uint256 indexed id, uint256 indexed offerId, address offeror);
    event AcceptOffer(address indexed addr, uint256 indexed id, uint256 indexed offerId, address acceptor);

    event Auction(address indexed addr, uint256 indexed id, address indexed owner, uint256 startPrice, uint256 endBlock);
    event CancelAuction(address indexed addr, uint256 indexed id, address indexed owner);
    event Bid(address indexed addr, uint256 indexed id, address indexed bidder, uint256 price);
    event Claim(address indexed addr, uint256 indexed id, address indexed bidder, uint256 price);

    function sales(address addr, uint256 id) external returns (
        address seller,
        uint256 price
    );
    function sell(address addr, uint256 id, uint256 price) external;
    function checkSelling(address addr, uint256 id) view external returns (bool);
    function buy(address addr, uint256 id) external;
    function cancelSale(address addr, uint256 id) external;

    function offers(address addr, uint256 id, uint256 index) external returns (
        address offeror,
        uint256 price
    );
    function offerCount(address addr, uint256 id) view external returns (uint256);
    function offer(address addr, uint256 id, uint256 price) external returns (uint256 offerId);
    function cancelOffer(address addr, uint256 id, uint256 offerId) external;
    function acceptOffer(address addr, uint256 id, uint256 offerId) external;

    function auctions(address addr, uint256 id) external returns (
        address seller,
        uint256 startPrice,
        uint256 endBlock
    );
    function auction(address addr, uint256 id, uint256 startPrice, uint256 endBlock) external;
    function cancelAuction(address addr, uint256 id) external;
    function checkAuction(address addr, uint256 id) view external returns (bool);

    function biddings(address addr, uint256 id, uint256 index) external returns (
        address bidder,
        uint256 price
    );
    function biddingCount(address addr, uint256 id) view external returns (uint256);
    function bid(address addr, uint256 id, uint256 price) external returns (uint256 biddingId);
    function claim(address addr, uint256 id) external;
}
