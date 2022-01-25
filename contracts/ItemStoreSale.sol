pragma solidity ^0.5.6;

import "./klaytn-contracts/ownership/Ownable.sol";
import "./klaytn-contracts/math/SafeMath.sol";
import "./klaytn-contracts/token/KIP17/IKIP17.sol";
import "./klaytn-contracts/token/KIP37/IKIP37.sol";
import "./libraries/ItemStoreLibrary.sol";
import "./interfaces/IItemStoreSale.sol";
import "./interfaces/IMetaverses.sol";
import "./interfaces/IMix.sol";
import "./interfaces/IMileage.sol";

contract ItemStoreSale is Ownable, IItemStoreSale {
    using SafeMath for uint256;
    using ItemStoreLibrary for *;

    IItemStoreCommon public commonData;
    IMix public mix;
    IMileage public mileage;

    constructor(IItemStoreCommon _commonData) public {
        commonData = _commonData;
        mix = _commonData.mix();
        mileage = _commonData.mileage();
    }

    //use verificationID as a parameter in "_removeXXXX" functions for safety despite a waste of gas
    function _removeSale(bytes32 saleVerificationID) private {
        SaleInfo storage saleInfo = _saleInfo[saleVerificationID];
        address item = saleInfo.item;
        uint256 id = saleInfo.id;
        uint256 saleId = saleInfo.saleId;

        Sale storage sale = sales[item][id][saleId];

        //delete sales
        uint256 lastSaleId = sales[item][id].length.sub(1);
        Sale memory lastSale = sales[item][id][lastSaleId];
        if (saleId != lastSaleId) {
            sales[item][id][saleId] = lastSale;
            _saleInfo[lastSale.verificationID].saleId = saleId;
        }
        sales[item][id].length--;
        delete _saleInfo[saleVerificationID];

        //delete onSales
        uint256 lastIndex = onSales[item].length.sub(1);
        uint256 index = _onSalesIndex[saleVerificationID];
        if (index != lastIndex) {
            bytes32 lastSaleVerificationID = onSales[item][lastIndex];
            onSales[item][index] = lastSaleVerificationID;
            _onSalesIndex[lastSaleVerificationID] = index;
        }
        onSales[item].length--;
        delete _onSalesIndex[saleVerificationID];

        //delete userSellInfo
        address seller = sale.seller;
        lastIndex = userSellInfo[seller].length.sub(1);
        index = _userSellIndex[saleVerificationID];
        if (index != lastIndex) {
            bytes32 lastSaleVerificationID = userSellInfo[seller][lastIndex];
            userSellInfo[seller][index] = lastSaleVerificationID;
            _userSellIndex[lastSaleVerificationID] = index;
        }
        userSellInfo[seller].length--;
        delete _userSellIndex[saleVerificationID];

        //delete salesOnMetaverse
        uint256 metaverseId = sale.metaverseId;
        lastIndex = salesOnMetaverse[metaverseId].length.sub(1);
        index = _salesOnMvIndex[saleVerificationID];
        if (index != lastIndex) {
            bytes32 lastSaleVerificationID = salesOnMetaverse[metaverseId][lastIndex];
            salesOnMetaverse[metaverseId][index] = lastSaleVerificationID;
            _salesOnMvIndex[lastSaleVerificationID] = index;
        }
        salesOnMetaverse[metaverseId].length--;
        delete _salesOnMvIndex[saleVerificationID];

        //subtract amounts.
        uint256 amount = sale.amount;
        if (amount > 0) {
            userOnSaleAmounts[seller][item][id] = userOnSaleAmounts[seller][item][id].sub(amount);
        }
    }

    function _removeOffer(bytes32 offerVerificationID) private {
        OfferInfo storage offerInfo = _offerInfo[offerVerificationID];
        address item = offerInfo.item;
        uint256 id = offerInfo.id;
        uint256 offerId = offerInfo.offerId;

        Offer storage offer = offers[item][id][offerId];

        //delete offers
        uint256 lastOfferId = offers[item][id].length.sub(1);
        Offer memory lastOffer = offers[item][id][lastOfferId];
        if (offerId != lastOfferId) {
            offers[item][id][offerId] = lastOffer;
            _offerInfo[lastOffer.verificationID].offerId = offerId;
        }
        offers[item][id].length--;
        delete _offerInfo[offerVerificationID];

        //delete userOfferInfo
        address offeror = offer.offeror;
        uint256 lastIndex = userOfferInfo[offeror].length.sub(1);
        uint256 index = _userOfferIndex[offerVerificationID];
        if (index != lastIndex) {
            bytes32 lastOfferVerificationID = userOfferInfo[offeror][lastIndex];
            userOfferInfo[offeror][index] = lastOfferVerificationID;
            _userOfferIndex[lastOfferVerificationID] = index;
        }
        userOfferInfo[offeror].length--;
        delete _userOfferIndex[offerVerificationID];
    }

    function _distributeReward(
        uint256 metaverseId,
        address buyer,
        address seller,
        uint256 price
    ) private {
        IMetaverses metaverses = commonData.metaverses();

        uint256 fee = commonData.fee();

        (address receiver, uint256 royalty) = metaverses.royalties(metaverseId);

        uint256 _fee;
        uint256 _royalty;
        uint256 _mileage;

        if (metaverses.mileageMode(metaverseId)) {
            if (metaverses.onlyKlubsMembership(metaverseId)) {
                uint256 mileageFromFee = price.mul(mileage.onlyKlubsPercent()).div(1e4);
                _fee = price.mul(fee).div(1e4);

                if (_fee > mileageFromFee) {
                    _mileage = mileageFromFee;
                    _fee = _fee.sub(mileageFromFee);
                } else {
                    _mileage = _fee;
                    _fee = 0;
                }

                uint256 mileageFromRoyalty = price.mul(mileage.mileagePercent()).div(1e4).sub(mileageFromFee);
                _royalty = price.mul(royalty).div(1e4);

                if (_royalty > mileageFromRoyalty) {
                    _mileage = _mileage.add(mileageFromRoyalty);
                    _royalty = _royalty.sub(mileageFromRoyalty);
                } else {
                    _mileage = _mileage.add(_royalty);
                    _royalty = 0;
                }
            } else {
                _fee = price.mul(fee).div(1e4);
                _mileage = price.mul(mileage.mileagePercent()).div(1e4);
                _royalty = price.mul(royalty).div(1e4);

                if (_royalty > _mileage) {
                    _royalty = _royalty.sub(_mileage);
                } else {
                    _mileage = _royalty;
                    _royalty = 0;
                }
            }
        } else {
            _fee = price.mul(fee).div(1e4);
            _royalty = price.mul(royalty).div(1e4);
        }

        if (_fee > 0) mix.transfer(commonData.feeReceiver(), _fee);
        if (_royalty > 0) mix.transfer(receiver, _royalty);
        if (_mileage > 0) {
            mix.approve(address(mileage), _mileage);
            mileage.charge(buyer, _mileage);
        }

        price = price.sub(_fee).sub(_royalty).sub(_mileage);
        mix.transfer(seller, price);
    }

    mapping(address => uint256) public nonce;

    //Sale
    struct Sale {
        address seller;
        uint256 metaverseId;
        address item;
        uint256 id;
        uint256 amount;
        uint256 unitPrice;
        bool partialBuying;
        bytes32 verificationID;
    }

    struct SaleInfo {
        address item;
        uint256 id;
        uint256 saleId;
    }

    mapping(address => mapping(uint256 => Sale[])) public sales; //sales[item][id].
    mapping(bytes32 => SaleInfo) internal _saleInfo; //_saleInfo[saleVerificationID].

    mapping(address => bytes32[]) public onSales; //onSales[item]. 아이템 계약 중 onSale 중인 정보들. "return saleVerificationID."
    mapping(bytes32 => uint256) private _onSalesIndex; //_onSalesIndex[saleVerificationID]. 특정 세일의 onSales index.

    mapping(address => bytes32[]) public userSellInfo; //userSellInfo[seller] 셀러가 팔고있는 세일의 정보. "return saleVerificationID."
    mapping(bytes32 => uint256) private _userSellIndex; //_userSellIndex[saleVerificationID]. 특정 세일의 userSellInfo index.

    mapping(uint256 => bytes32[]) public salesOnMetaverse; //salesOnMetaverse[metaverseId]. 특정 메타버스에서 판매되고있는 모든 세일들. "return saleVerificationID."
    mapping(bytes32 => uint256) private _salesOnMvIndex; //_salesOnMvIndex[saleVerificationID]. 특정 세일의 salesOnMetaverse index.

    mapping(address => mapping(address => mapping(uint256 => uint256))) public userOnSaleAmounts; //userOnSaleAmounts[seller][item][id]. 셀러가 판매중인 특정 id의 아이템의 총 합.

    function getSaleInfo(bytes32 saleVerificationID)
        external
        view
        returns (
            address item,
            uint256 id,
            uint256 saleId
        )
    {
        SaleInfo memory saleInfo = _saleInfo[saleVerificationID];
        require(saleInfo.item != address(0));

        return (saleInfo.item, saleInfo.id, saleInfo.saleId);
    }

    function salesCount(address item, uint256 id) external view returns (uint256) {
        return sales[item][id].length;
    }

    function onSalesCount(address item) external view returns (uint256) {
        return onSales[item].length;
    }

    function userSellInfoLength(address seller) external view returns (uint256) {
        return userSellInfo[seller].length;
    }

    function salesOnMetaverseLength(uint256 metaverseId) external view returns (uint256) {
        return salesOnMetaverse[metaverseId].length;
    }

    function canSell(
        address seller,
        uint256 metaverseId,
        address item,
        uint256 id,
        uint256 amount
    ) public view returns (bool) {
        if (!commonData.isItemWhitelisted(metaverseId, item)) return false;

        if (item._isERC1155(commonData.metaverses(), metaverseId)) {
            return (amount > 0) && (userOnSaleAmounts[seller][item][id].add(amount) <= IKIP37(item).balanceOf(seller, id));
        } else {
            return (amount == 1) && (IKIP17(item).ownerOf(id) == seller) && (userOnSaleAmounts[seller][item][id] == 0);
        }
    }

    function sell(
        uint256[] calldata metaverseIds,
        address[] calldata items,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        uint256[] calldata unitPrices,
        bool[] calldata partialBuyings
    ) external {
        require(!commonData.isBannedUser(msg.sender));
        require(
            metaverseIds.length == items.length &&
                metaverseIds.length == ids.length &&
                metaverseIds.length == amounts.length &&
                metaverseIds.length == unitPrices.length &&
                metaverseIds.length == partialBuyings.length
        );
        for (uint256 i = 0; i < metaverseIds.length; i++) {
            uint256 metaverseId = metaverseIds[i];
            address item = items[i];
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            uint256 unitPrice = unitPrices[i];
            bool partialBuying = partialBuyings[i];

            require(unitPrice > 0);
            require(canSell(msg.sender, metaverseId, item, id, amount));

            bytes32 verificationID = keccak256(
                abi.encodePacked(msg.sender, metaverseId, item, id, amount, unitPrice, partialBuying, nonce[msg.sender]++)
            );

            require(_saleInfo[verificationID].item == address(0));

            uint256 saleId = sales[item][id].length;
            sales[item][id].push(
                Sale({
                    seller: msg.sender,
                    metaverseId: metaverseId,
                    item: item,
                    id: id,
                    amount: amount,
                    unitPrice: unitPrice,
                    partialBuying: partialBuying,
                    verificationID: verificationID
                })
            );

            _saleInfo[verificationID] = SaleInfo({item: item, id: id, saleId: saleId});

            _onSalesIndex[verificationID] = onSales[item].length;
            onSales[item].push(verificationID);

            _userSellIndex[verificationID] = userSellInfo[msg.sender].length;
            userSellInfo[msg.sender].push(verificationID);

            _salesOnMvIndex[verificationID] = salesOnMetaverse[metaverseId].length;
            salesOnMetaverse[metaverseId].push(verificationID);

            userOnSaleAmounts[msg.sender][item][id] = userOnSaleAmounts[msg.sender][item][id].add(amount);

            emit Sell(metaverseId, item, id, msg.sender, amount, unitPrice, partialBuying, verificationID);
        }
    }

    function changeSellPrice(bytes32[] calldata saleVerificationIDs, uint256[] calldata unitPrices) external {
        require(!commonData.isBannedUser(msg.sender));
        require(saleVerificationIDs.length == unitPrices.length);
        for (uint256 i = 0; i < saleVerificationIDs.length; i++) {
            SaleInfo storage saleInfo = _saleInfo[saleVerificationIDs[i]];
            address item = saleInfo.item;
            uint256 id = saleInfo.id;

            Sale storage sale = sales[item][id][saleInfo.saleId];
            require(sale.seller == msg.sender);
            require(sale.unitPrice != unitPrices[i]);

            sale.unitPrice = unitPrices[i];
            emit ChangeSellPrice(sale.metaverseId, item, id, unitPrices[i], saleVerificationIDs[i]);
        }
    }

    function cancelSale(bytes32[] calldata saleVerificationIDs) external {
        for (uint256 i = 0; i < saleVerificationIDs.length; i++) {
            SaleInfo storage saleInfo = _saleInfo[saleVerificationIDs[i]];
            address item = saleInfo.item;
            uint256 id = saleInfo.id;

            Sale storage sale = sales[item][id][saleInfo.saleId];
            require(sale.seller == msg.sender);

            emit CancelSale(sale.metaverseId, item, id, sale.amount, saleVerificationIDs[i]);

            _removeSale(saleVerificationIDs[i]);
        }
    }

    function buy(
        bytes32[] calldata saleVerificationIDs,
        uint256[] calldata amounts,
        uint256[] calldata unitPrices,
        uint256[] calldata mileages
    ) external {
        require(!commonData.isBannedUser(msg.sender));
        require(amounts.length == saleVerificationIDs.length && amounts.length == unitPrices.length && amounts.length == mileages.length);

        IMetaverses metaverses = commonData.metaverses();

        for (uint256 i = 0; i < amounts.length; i++) {
            bytes32 saleVerificationID = saleVerificationIDs[i];
            SaleInfo memory saleInfo = _saleInfo[saleVerificationID];
            Sale storage sale = sales[saleInfo.item][saleInfo.id][saleInfo.saleId];

            address seller = sale.seller;
            uint256 metaverseId = sale.metaverseId;

            require(commonData.isItemWhitelisted(metaverseId, saleInfo.item));
            require(seller != address(0) && seller != msg.sender);
            require(sale.unitPrice == unitPrices[i]);

            uint256 amount = amounts[i];
            uint256 amountLeft;

            {
                uint256 saleAmount = sale.amount;
                if (!sale.partialBuying) {
                    require(saleAmount == amount);
                } else {
                    require(saleAmount >= amount);
                }

                amountLeft = saleAmount.sub(amount);
                sale.amount = amountLeft;
            }

            saleInfo.item._transferItems(metaverses, metaverseId, saleInfo.id, amount, seller, msg.sender);
            uint256 price = amount.mul(unitPrices[i]);

            uint256 _mileage = mileages[i];
            mix.transferFrom(msg.sender, address(this), price.sub(_mileage));
            if (_mileage > 0) mileage.use(msg.sender, _mileage);
            _distributeReward(metaverseId, msg.sender, seller, price);

            userOnSaleAmounts[msg.sender][saleInfo.item][saleInfo.id] = userOnSaleAmounts[msg.sender][saleInfo.item][saleInfo.id].sub(amount);

            bool isFulfilled = false;
            if (amountLeft == 0) {
                _removeSale(saleVerificationID);
                isFulfilled = true;
            }

            emit Buy(metaverseId, saleInfo.item, saleInfo.id, msg.sender, amount, isFulfilled, saleVerificationID);
        }
    }

    //Offer
    struct Offer {
        address offeror;
        uint256 metaverseId;
        address item;
        uint256 id;
        uint256 amount;
        uint256 unitPrice;
        bool partialBuying;
        uint256 mileage;
        bytes32 verificationID;
    }

    struct OfferInfo {
        address item;
        uint256 id;
        uint256 offerId;
    }

    mapping(address => mapping(uint256 => Offer[])) public offers; //offers[item][id].
    mapping(bytes32 => OfferInfo) internal _offerInfo; //_offerInfo[offerVerificationID].

    mapping(address => bytes32[]) public userOfferInfo; //userOfferInfo[offeror] 오퍼러의 오퍼들 정보.  "return offerVerificationID."
    mapping(bytes32 => uint256) private _userOfferIndex; //_userOfferIndex[offerVerificationID]. 특정 오퍼의 userOfferInfo index.

    function getOfferInfo(bytes32 offerVerificationID)
        external
        view
        returns (
            address item,
            uint256 id,
            uint256 offerId
        )
    {
        OfferInfo memory offerInfo = _offerInfo[offerVerificationID];
        require(offerInfo.item != address(0));

        return (offerInfo.item, offerInfo.id, offerInfo.offerId);
    }

    function userOfferInfoLength(address offeror) external view returns (uint256) {
        return userOfferInfo[offeror].length;
    }

    function offersCount(address item, uint256 id) external view returns (uint256) {
        return offers[item][id].length;
    }

    function canOffer(
        address offeror,
        uint256 metaverseId,
        address item,
        uint256 id,
        uint256 amount
    ) public view returns (bool) {
        if (!commonData.isItemWhitelisted(metaverseId, item)) return false;
        if (item._isERC1155(commonData.metaverses(), metaverseId)) {
            return (amount > 0);
        } else {
            return (amount == 1) && (IKIP17(item).ownerOf(id) != offeror);
        }
    }

    function makeOffer(
        uint256 metaverseId,
        address item,
        uint256 id,
        uint256 amount,
        uint256 unitPrice,
        bool partialBuying,
        uint256 _mileage
    ) external returns (uint256 offerId) {
        require(!commonData.isBannedUser(msg.sender));
        require(unitPrice > 0);
        require(canOffer(msg.sender, metaverseId, item, id, amount));

        bytes32 verificationID = keccak256(
            abi.encodePacked(msg.sender, metaverseId, item, id, amount, unitPrice, partialBuying, _mileage, nonce[msg.sender]++)
        );

        require(_offerInfo[verificationID].item == address(0));

        offerId = offers[item][id].length;
        offers[item][id].push(
            Offer({
                offeror: msg.sender,
                metaverseId: metaverseId,
                item: item,
                id: id,
                amount: amount,
                unitPrice: unitPrice,
                partialBuying: partialBuying,
                mileage: _mileage,
                verificationID: verificationID
            })
        );

        _userOfferIndex[verificationID] = userOfferInfo[msg.sender].length;
        userOfferInfo[msg.sender].push(verificationID);

        mix.transferFrom(msg.sender, address(this), amount.mul(unitPrice).sub(_mileage));
        if (_mileage > 0) mileage.use(msg.sender, _mileage);

        emit MakeOffer(metaverseId, item, id, msg.sender, amount, unitPrice, partialBuying, verificationID);
    }

    function cancelOffer(bytes32 offerVerificationID) external {
        OfferInfo storage offerInfo = _offerInfo[offerVerificationID];
        address item = offerInfo.item;
        uint256 id = offerInfo.id;

        Offer storage offer = offers[item][id][offerInfo.offerId];
        require(offer.offeror == msg.sender);

        uint256 amount = offer.amount;
        uint256 _mileage = offer.mileage;

        mix.transfer(msg.sender, amount.mul(offer.unitPrice).sub(_mileage));
        if (_mileage > 0) {
            mix.approve(address(mileage), _mileage);
            mileage.charge(msg.sender, _mileage);
        }

        emit CancelOffer(offer.metaverseId, item, id, amount, offerVerificationID);
        _removeOffer(offerVerificationID);
    }

    function acceptOffer(bytes32 offerVerificationID, uint256 amount) external {
        require(!commonData.isBannedUser(msg.sender));
        OfferInfo storage offerInfo = _offerInfo[offerVerificationID];
        address item = offerInfo.item;
        uint256 id = offerInfo.id;

        Offer storage offer = offers[item][id][offerInfo.offerId];

        address offeror = offer.offeror;
        uint256 metaverseId = offer.metaverseId;
        uint256 offerAmount = offer.amount;

        require(commonData.isItemWhitelisted(metaverseId, item));
        require(offeror != address(0) && offeror != msg.sender);

        if (!offer.partialBuying) {
            require(offerAmount == amount);
        } else {
            require(offerAmount >= amount);
        }

        uint256 amountLeft = offerAmount.sub(amount);
        offer.amount = amountLeft;

        item._transferItems(commonData.metaverses(), metaverseId, id, amount, msg.sender, offeror);
        uint256 price = amount.mul(offer.unitPrice);

        _distributeReward(metaverseId, offeror, msg.sender, price);

        bool isFulfilled = false;
        if (amountLeft == 0) {
            _removeOffer(offerVerificationID);
            isFulfilled = true;
        }

        emit AcceptOffer(metaverseId, item, id, msg.sender, offerAmount, isFulfilled, offerVerificationID);
    }

    //"cancel" functions with ownership
    function cancelSaleByOwner(bytes32[] calldata saleVerificationIDs) external onlyOwner {
        for (uint256 i = 0; i < saleVerificationIDs.length; i++) {
            SaleInfo storage saleInfo = _saleInfo[saleVerificationIDs[i]];
            address item = saleInfo.item;
            uint256 id = saleInfo.id;

            Sale storage sale = sales[item][id][saleInfo.saleId];
            address seller = sale.seller;
            require(seller != address(0));

            uint256 metaverseId = sale.metaverseId;
            emit CancelSale(metaverseId, item, id, sale.amount, saleVerificationIDs[i]);
            emit CancelSaleByOwner(metaverseId, item, id, saleVerificationIDs[i]);

            _removeSale(saleVerificationIDs[i]);
        }
    }

    function cancelOfferByOwner(bytes32[] calldata offerVerificationIDs) external onlyOwner {
        for (uint256 i = 0; i < offerVerificationIDs.length; i++) {
            OfferInfo storage offerInfo = _offerInfo[offerVerificationIDs[i]];
            address item = offerInfo.item;
            uint256 id = offerInfo.id;

            Offer storage offer = offers[item][id][offerInfo.offerId];
            address offeror = offer.offeror;
            require(offeror != address(0));

            uint256 amount = offer.amount;
            uint256 _mileage = offer.mileage;

            mix.transfer(offeror, amount.mul(offer.unitPrice).sub(_mileage));
            if (_mileage > 0) {
                mix.approve(address(mileage), _mileage);
                mileage.charge(offeror, _mileage);
            }

            uint256 metaverseId = offer.metaverseId;
            emit CancelOffer(metaverseId, item, id, amount, offerVerificationIDs[i]);
            emit CancelOfferByOwner(metaverseId, item, id, offerVerificationIDs[i]);

            _removeOffer(offerVerificationIDs[i]);
        }
    }
}
