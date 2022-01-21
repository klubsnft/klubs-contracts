pragma solidity ^0.5.6;

interface IItemStore {
    event Sell(
        uint256 indexed metaverseId,
        address indexed item,
        uint256 id,
        address seller,
        uint256 amount,
        uint256 unitPrice,
        bool partialBuying,
        bytes32 indexed saleVerificationID
    );
    event ChangeSellPrice(uint256 indexed metaverseId, address indexed item, uint256 id, uint256 newUnitPrice, bytes32 indexed saleVerificationID);
    event Buy(
        uint256 indexed metaverseId,
        address indexed item,
        uint256 id,
        address buyer,
        uint256 amount,
        bool isFulfilled,
        bytes32 indexed saleVerificationID
    );
    event CancelSale(uint256 indexed metaverseId, address indexed item, uint256 id, uint256 amount, bytes32 indexed saleVerificationID);

    event MakeOffer(
        uint256 indexed metaverseId,
        address indexed item,
        uint256 id,
        address offeror,
        uint256 amount,
        uint256 unitPrice,
        bool partialBuying,
        bytes32 indexed offerVerificationID
    );
    event CancelOffer(uint256 indexed metaverseId, address indexed item, uint256 id, uint256 amount, bytes32 indexed offerVerificationID);
    event AcceptOffer(
        uint256 indexed metaverseId,
        address indexed item,
        uint256 id,
        address acceptor,
        uint256 amount,
        bool isFulfilled,
        bytes32 indexed offerVerificationID
    );

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

    event CancelSaleByOwner(uint256 indexed metaverseId, address indexed item, uint256 id, bytes32 indexed saleVerificationID);
    event CancelOfferByOwner(uint256 indexed metaverseId, address indexed item, uint256 id, bytes32 indexed offerVerificationID);
    event CancelAuctionByOwner(uint256 indexed metaverseId, address indexed item, uint256 id, bytes32 indexed auctionVerificationID);

    event Ban(address indexed user);
    event Unban(address indexed user);

    function fee() external view returns (uint256);

    function feeReceiver() external view returns (address);

    function auctionExtensionInterval() external view returns (uint256);

    function isBanned(address user) external view returns (bool);

    function batchTransfer(
        uint256[] calldata metaverseIds,
        address[] calldata items,
        uint256[] calldata ids,
        address[] calldata to,
        uint256[] calldata amounts
    ) external;

    function nonce(address user) external view returns (uint256);

    //Sale
    function sales(
        address item,
        uint256 id,
        uint256 saleId
    )
        external
        view
        returns (
            address seller,
            uint256 metaverseId,
            address _item,
            uint256 _id,
            uint256 amount,
            uint256 unitPrice,
            bool partialBuying,
            bytes32 verificationID
        );

    function onSales(address item, uint256 index) external view returns (bytes32 saleVerificationID);

    function userSellInfo(address seller, uint256 index) external view returns (bytes32 saleVerificationID);

    function salesOnMetaverse(address metaverseId, uint256 index) external view returns (bytes32 saleVerificationID);

    function userOnSaleAmounts(
        address seller,
        address item,
        uint256 id
    ) external view returns (uint256);

    function getSaleInfo(bytes32 saleVerificationID)
        external
        view
        returns (
            address item,
            uint256 id,
            uint256 saleId
        );

    function salesCount(address item, uint256 id) external view returns (uint256);

    function onSalesCount(address item) external view returns (uint256);

    function userSellInfoLength(address seller) external view returns (uint256);

    function salesOnMetaverseLength(uint256 metaverseId) external view returns (uint256);

    function canSell(
        address seller,
        uint256 metaverseId,
        address item,
        uint256 id,
        uint256 amount
    ) external view returns (bool);

    function sell(
        uint256[] calldata metaverseIds,
        address[] calldata items,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        uint256[] calldata unitPrices,
        bool[] calldata partialBuyings
    ) external;

    function changeSellPrice(bytes32[] calldata saleVerificationIDs, uint256[] calldata unitPrices) external;

    function cancelSale(bytes32[] calldata saleVerificationIDs) external;

    function buy(
        bytes32[] calldata saleVerificationIDs,
        uint256[] calldata amounts,
        uint256[] calldata unitPrices,
        uint256[] calldata mileages
    ) external;

    //Offer
    function offers(
        address item,
        uint256 id,
        uint256 offerId
    )
        external
        view
        returns (
            address offeror,
            uint256 metaverseId,
            address _item,
            uint256 _id,
            uint256 amount,
            uint256 unitPrice,
            bool partialBuying,
            uint256 mileage,
            bytes32 verificationID
        );

    function userOfferInfo(address offeror, uint256 index) external view returns (bytes32 offerVerificationID);

    function getOfferInfo(bytes32 offerVerificationID)
        external
        view
        returns (
            address item,
            uint256 id,
            uint256 offerId
        );

    function userOfferInfoLength(address offeror) external view returns (uint256);

    function offersCount(address item, uint256 id) external view returns (uint256);

    function canOffer(
        address offeror,
        uint256 metaverseId,
        address item,
        uint256 id,
        uint256 amount
    ) external view returns (bool);

    function makeOffer(
        uint256 metaverseId,
        address item,
        uint256 id,
        uint256 amount,
        uint256 unitPrice,
        bool partialBuying,
        uint256 mileage
    ) external returns (uint256 offerId);

    function cancelOffer(bytes32 offerVerificationID) external;

    function acceptOffer(bytes32 offerVerificationID, uint256 amount) external;

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

    function auctionsOnMetaverse(address metaverseId, uint256 index) external view returns (bytes32 auctionVerificationID);

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
