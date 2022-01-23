pragma solidity ^0.5.6;

import "./IItemStoreCommon.sol";

interface IItemStoreSale {
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

    event CancelSaleByOwner(uint256 indexed metaverseId, address indexed item, uint256 id, bytes32 indexed saleVerificationID);
    event CancelOfferByOwner(uint256 indexed metaverseId, address indexed item, uint256 id, bytes32 indexed offerVerificationID);

    function commonData() external view returns (IItemStoreCommon);

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

    function salesOnMetaverse(uint256 metaverseId, uint256 index) external view returns (bytes32 saleVerificationID);

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
}
