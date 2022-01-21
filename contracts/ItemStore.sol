pragma solidity ^0.5.6;

import "./klaytn-contracts/ownership/Ownable.sol";
import "./klaytn-contracts/math/SafeMath.sol";
import "./klaytn-contracts/token/KIP17/IKIP17.sol";
import "./klaytn-contracts/token/KIP37/IKIP37.sol";
import "./interfaces/IItemStore.sol";
import "./interfaces/IMetaverses.sol";
import "./interfaces/IMix.sol";
import "./interfaces/IMileage.sol";

contract ItemStore is Ownable, IItemStore {
    using SafeMath for uint256;

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

    function isMetaverseWhitelisted(uint256 metaverseId) private view returns (bool) {
        return (metaverseId < metaverses.metaverseCount() && !metaverses.banned(metaverseId));
    }

    function isItemWhitelisted(uint256 metaverseId, address item) private view returns (bool) {
        if (!isMetaverseWhitelisted(metaverseId)) return false;
        return (metaverses.itemAdded(metaverseId, item));
    }

    mapping(address => bool) public isBanned;

    function banUser(address user) external onlyOwner {
        isBanned[user] = true;
        emit Ban(user);
    }

    function unbanUser(address user) external onlyOwner {
        isBanned[user] = false;
        emit Unban(user);
    }

    modifier userWhitelist(address user) {
        require(!isBanned[user]);
        _;
    }

    function _isERC1155(uint256 metaverseId, address item) internal view returns (bool) {
        return metaverses.itemTypes(metaverseId, item) == IMetaverses.ItemType.ERC1155;
    }

    function batchTransfer(
        uint256[] calldata metaverseIds,
        address[] calldata items,
        uint256[] calldata ids,
        address[] calldata to,
        uint256[] calldata amounts
    ) external userWhitelist(msg.sender) {
        require(
            metaverseIds.length == items.length &&
                metaverseIds.length == ids.length &&
                metaverseIds.length == to.length &&
                metaverseIds.length == amounts.length
        );
        uint256 metaverseCount = metaverses.metaverseCount();
        for (uint256 i = 0; i < metaverseIds.length; i++) {
            uint256 metaverseId = metaverseIds[i];
            require(metaverseId < metaverseCount && !metaverses.banned(metaverseId));
            require(metaverses.itemAdded(metaverseId, items[i]));
            _itemTransfer(metaverseId, items[i], ids[i], amounts[i], msg.sender, to[i]);
        }
    }

    function _itemTransfer(
        uint256 metaverseId,
        address item,
        uint256 id,
        uint256 amount,
        address from,
        address to
    ) internal {
        if (_isERC1155(metaverseId, item)) {
            require(amount > 0);
            IKIP37(item).safeTransferFrom(from, to, id, amount, "");
        } else {
            require(amount == 1);
            IKIP17(item).transferFrom(from, to, id);
        }
    }

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

    function _removeAuction(bytes32 auctionVerificationID) private {
        AuctionInfo storage auctionInfo = _auctionInfo[auctionVerificationID];
        address item = auctionInfo.item;
        uint256 id = auctionInfo.id;
        uint256 auctionId = auctionInfo.auctionId;

        Auction storage auction = auctions[item][id][auctionId];

        //delete auctions
        uint256 lastAuctionId = auctions[item][id].length.sub(1);
        Auction memory lastAuction = auctions[item][id][lastAuctionId];
        if (auctionId != lastAuctionId) {
            auctions[item][id][auctionId] = lastAuction;
            _auctionInfo[lastAuction.verificationID].auctionId = auctionId;
        }
        auctions[item][id].length--;
        delete _auctionInfo[auctionVerificationID];

        //delete onAuctions
        uint256 lastIndex = onAuctions[item].length.sub(1);
        uint256 index = _onAuctionsIndex[auctionVerificationID];
        if (index != lastIndex) {
            bytes32 lastAuctionVerificationID = onAuctions[item][lastIndex];
            onAuctions[item][index] = lastAuctionVerificationID;
            _onAuctionsIndex[lastAuctionVerificationID] = index;
        }
        onAuctions[item].length--;
        delete _onAuctionsIndex[auctionVerificationID];

        //delete userAuctionInfo
        address seller = auction.seller;
        lastIndex = userAuctionInfo[seller].length.sub(1);
        index = _userAuctionIndex[auctionVerificationID];
        if (index != lastIndex) {
            bytes32 lastAuctionVerificationID = userAuctionInfo[seller][lastIndex];
            userAuctionInfo[seller][index] = lastAuctionVerificationID;
            _userAuctionIndex[lastAuctionVerificationID] = index;
        }
        userAuctionInfo[seller].length--;
        delete _userAuctionIndex[auctionVerificationID];

        //delete auctionsOnMetaverse
        uint256 metaverseId = auction.metaverseId;
        lastIndex = auctionsOnMetaverse[metaverseId].length.sub(1);
        index = _auctionsOnMvIndex[auctionVerificationID];
        if (index != lastIndex) {
            bytes32 lastAuctionVerificationID = auctionsOnMetaverse[metaverseId][lastIndex];
            auctionsOnMetaverse[metaverseId][index] = lastAuctionVerificationID;
            _auctionsOnMvIndex[lastAuctionVerificationID] = index;
        }
        auctionsOnMetaverse[metaverseId].length--;
        delete _auctionsOnMvIndex[auctionVerificationID];
    }

    function _distributeReward(
        uint256 metaverseId,
        address buyer,
        address seller,
        uint256 price
    ) private {
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

        if (_fee > 0) mix.transfer(feeReceiver, _fee);
        if (_royalty > 0) mix.transfer(receiver, _royalty);
        if (_mileage > 0) {
            mix.approve(address(mileage), _mileage);
            mileage.charge(buyer, _mileage);
        }

        mix.transfer(seller, price.sub(_fee).sub(_royalty).sub(_mileage));
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

    //TODO 한번에 모든 배열이 불러와지지 않는 경우 대비.

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
        if (!isItemWhitelisted(metaverseId, item)) return false;

        if (_isERC1155(metaverseId, item)) {
            if (amount == 0) return false;
            if (userOnSaleAmounts[seller][item][id].add(amount) > IKIP37(item).balanceOf(seller, id)) return false;
            return true;
        } else {
            if (amount != 1) return false;
            if (IKIP17(item).ownerOf(id) != seller) return false;
            if (userOnSaleAmounts[seller][item][id] != 0) return false;
            return true;
        }
    }

    function sell(
        uint256[] calldata metaverseIds,
        address[] calldata items,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        uint256[] calldata unitPrices,
        bool[] calldata partialBuyings
    ) external userWhitelist(msg.sender) {
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

    function changeSellPrice(bytes32[] calldata saleVerificationIDs, uint256[] calldata unitPrices) external userWhitelist(msg.sender) {
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
    ) external userWhitelist(msg.sender) {
        require(amounts.length == saleVerificationIDs.length && amounts.length == unitPrices.length && amounts.length == mileages.length);
        for (uint256 i = 0; i < amounts.length; i++) {
            bytes32 saleVerificationID = saleVerificationIDs[i];
            SaleInfo memory saleInfo = _saleInfo[saleVerificationID];
            Sale storage sale = sales[saleInfo.item][saleInfo.id][saleInfo.saleId];

            address seller = sale.seller;
            uint256 metaverseId = sale.metaverseId;

            require(isItemWhitelisted(metaverseId, saleInfo.item));
            require(seller != address(0) && seller != msg.sender);
            require(sale.unitPrice == unitPrices[i]);

            uint256 amount = amounts[i];
            uint256 saleAmount = sale.amount;
            if (!sale.partialBuying) {
                require(saleAmount == amount);
            } else {
                require(saleAmount >= amount);
            }

            uint256 amountLeft = saleAmount.sub(amount);
            sale.amount = amountLeft;

            _itemTransfer(metaverseId, saleInfo.item, saleInfo.id, amount, seller, msg.sender);
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

    mapping(address => bytes32[]) public userOfferInfo; //userOfferInfo[offeror] 오퍼러의 오퍼들 정보.  "return saleVerificationID."
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
        if (!isItemWhitelisted(metaverseId, item)) return false;
        if (_isERC1155(metaverseId, item)) {
            if (amount == 0) return false;
            return true;
        } else {
            if (amount != 1) return false;
            if (IKIP17(item).ownerOf(id) == offeror) return false;
            return true;
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
    ) external userWhitelist(msg.sender) returns (uint256 offerId) {
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

    function acceptOffer(bytes32 offerVerificationID, uint256 amount) external userWhitelist(msg.sender) {
        OfferInfo storage offerInfo = _offerInfo[offerVerificationID];
        address item = offerInfo.item;
        uint256 id = offerInfo.id;

        Offer storage offer = offers[item][id][offerInfo.offerId];

        address offeror = offer.offeror;
        uint256 metaverseId = offer.metaverseId;
        uint256 offerAmount = offer.amount;

        require(isItemWhitelisted(metaverseId, item));
        require(offeror != address(0) && offeror != msg.sender);

        if (!offer.partialBuying) {
            require(offerAmount == amount);
        } else {
            require(offerAmount >= amount);
        }

        uint256 amountLeft = offerAmount.sub(amount);
        offer.amount = amountLeft;

        _itemTransfer(metaverseId, item, id, amount, msg.sender, offeror);
        uint256 price = amount.mul(offer.unitPrice);

        _distributeReward(metaverseId, offeror, msg.sender, price);

        bool isFulfilled = false;
        if (amountLeft == 0) {
            _removeOffer(offerVerificationID);
            isFulfilled = true;
        }

        emit AcceptOffer(metaverseId, item, id, msg.sender, offerAmount, isFulfilled, offerVerificationID);
    }

    //Auction
    struct Auction {
        address seller;
        uint256 metaverseId;
        address item;
        uint256 id;
        uint256 amount;
        uint256 startTotalPrice;
        uint256 endBlock;
        bytes32 verificationID;
    }

    struct AuctionInfo {
        address item;
        uint256 id;
        uint256 auctionId;
    }

    mapping(address => mapping(uint256 => Auction[])) public auctions; //auctions[item][id].
    mapping(bytes32 => AuctionInfo) internal _auctionInfo; //_auctionInfo[auctionVerificationID].

    mapping(address => bytes32[]) public onAuctions; //onAuctions[item]. 아이템 계약 중 onAuction 중인 정보들. "return saleVerificationID."
    mapping(bytes32 => uint256) private _onAuctionsIndex; //_onAuctionsIndex[auctionHash][auctionId]. 특정 옥션의 onAuctions index.

    mapping(address => bytes32[]) public userAuctionInfo; //userAuctionInfo[seller] 셀러의 옥션들 정보. "return saleVerificationID."
    mapping(bytes32 => uint256) private _userAuctionIndex; //_userAuctionIndex[auctionHash][auctionId]. 특정 옥션의 userAuctionInfo index.

    mapping(uint256 => bytes32[]) public auctionsOnMetaverse; //auctionsOnMetaverse[metaverseId]. 특정 메타버스의 모든 옥션들. "return saleVerificationID."
    mapping(bytes32 => uint256) private _auctionsOnMvIndex; //_auctionsOnMvIndex[auctionHash][auctionId]. 특정 옥션의 auctionsOnMetaverse index.

    function getAuctionInfo(bytes32 auctionVerificationID)
        external
        view
        returns (
            address item,
            uint256 id,
            uint256 auctionId
        )
    {
        AuctionInfo memory auctionInfo = _auctionInfo[auctionVerificationID];
        require(auctionInfo.item != address(0));

        return (auctionInfo.item, auctionInfo.id, auctionInfo.auctionId);
    }

    function auctionsCount(address item, uint256 id) external view returns (uint256) {
        return auctions[item][id].length;
    }

    function onAuctionsCount(address item) external view returns (uint256) {
        return onAuctions[item].length;
    }

    function userAuctionInfoLength(address seller) external view returns (uint256) {
        return userAuctionInfo[seller].length;
    }

    function auctionsOnMetaverseLength(uint256 metaverseId) external view returns (uint256) {
        return auctionsOnMetaverse[metaverseId].length;
    }

    function canCreateAuction(
        address seller,
        uint256 metaverseId,
        address item,
        uint256 id,
        uint256 amount
    ) public view returns (bool) {
        if (!isItemWhitelisted(metaverseId, item)) return false;

        if (_isERC1155(metaverseId, item)) {
            if (amount == 0) return false;
            if (IKIP37(item).balanceOf(seller, id) < amount) return false;
            return true;
        } else {
            if (amount != 1) return false;
            if (IKIP17(item).ownerOf(id) != seller) return false;
            return true;
        }
    }

    function createAuction(
        uint256 metaverseId,
        address item,
        uint256 id,
        uint256 amount,
        uint256 startTotalPrice,
        uint256 endBlock
    ) external userWhitelist(msg.sender) returns (uint256 auctionId) {
        require(startTotalPrice > 0);
        require(endBlock > block.number);
        require(canCreateAuction(msg.sender, metaverseId, item, id, amount));

        bytes32 verificationID = keccak256(
            abi.encodePacked(msg.sender, metaverseId, item, id, amount, startTotalPrice, endBlock, nonce[msg.sender]++)
        );

        require(_auctionInfo[verificationID].item == address(0));

        auctionId = auctions[item][id].length;
        auctions[item][id].push(
            Auction({
                seller: msg.sender,
                metaverseId: metaverseId,
                item: item,
                id: id,
                amount: amount,
                startTotalPrice: startTotalPrice,
                endBlock: endBlock,
                verificationID: verificationID
            })
        );

        _auctionInfo[verificationID] = AuctionInfo({item: item, id: id, auctionId: auctionId});

        _onAuctionsIndex[verificationID] = onAuctions[item].length;
        onAuctions[item].push(verificationID);

        _userAuctionIndex[verificationID] = userAuctionInfo[msg.sender].length;
        userAuctionInfo[msg.sender].push(verificationID);

        _auctionsOnMvIndex[verificationID] = auctionsOnMetaverse[metaverseId].length;
        auctionsOnMetaverse[metaverseId].push(verificationID);

        _itemTransfer(metaverseId, item, id, amount, msg.sender, address(this));

        emit CreateAuction(metaverseId, item, id, msg.sender, amount, startTotalPrice, endBlock, verificationID);
    }

    function cancelAuction(bytes32 auctionVerificationID) external {
        require(biddings[auctionVerificationID].length == 0);
        AuctionInfo storage auctionInfo = _auctionInfo[auctionVerificationID];
        address item = auctionInfo.item;
        uint256 id = auctionInfo.id;

        Auction storage auction = auctions[item][id][auctionInfo.auctionId];

        require(auction.seller == msg.sender);

        uint256 metaverseId = auction.metaverseId;
        _itemTransfer(metaverseId, item, id, auction.amount, address(this), msg.sender);
        emit CancelAuction(metaverseId, item, id, auctionVerificationID);

        _removeAuction(auctionVerificationID);
    }

    //Bidding
    struct Bidding {
        address bidder;
        uint256 metaverseId;
        address item;
        uint256 id;
        uint256 amount;
        uint256 price;
        uint256 mileage;
    }

    struct BiddingInfo {
        bytes32 auctionVerificationID;
        uint256 biddingId;
    }

    mapping(bytes32 => Bidding[]) public biddings; //biddings[auctionVerificationID].

    mapping(address => BiddingInfo[]) public userBiddingInfo; //userBiddingInfo[bidder] 비더의 비딩들 정보.   "return saleVerificationID."
    mapping(address => mapping(bytes32 => uint256)) private _userBiddingIndex; //_userBiddingIndex[bidder][auctionVerificationID]. 특정 비딩의 userBiddingInfo index.

    function userBiddingInfoLength(address bidder) external view returns (uint256) {
        return userBiddingInfo[bidder].length;
    }

    function biddingsCount(bytes32 auctionVerificationID) external view returns (uint256) {
        return biddings[auctionVerificationID].length;
    }

    function canBid(
        address bidder,
        uint256 price,
        bytes32 auctionVerificationID
    ) public view returns (bool) {
        AuctionInfo storage auctionInfo = _auctionInfo[auctionVerificationID];
        address item = auctionInfo.item;

        if (item == address(0)) return false;

        Auction storage auction = auctions[item][auctionInfo.id][auctionInfo.auctionId];

        if (!isItemWhitelisted(auction.metaverseId, item)) return false;

        address seller = auction.seller;
        if (seller == address(0) || seller == bidder) return false;
        if (auction.endBlock <= block.number) return false;

        Bidding[] storage bs = biddings[auctionVerificationID];
        uint256 biddingLength = bs.length;
        if (biddingLength == 0) {
            if (auction.startTotalPrice > price) return false;
            return true;
        } else {
            if (bs[biddingLength - 1].price >= price) return false;
            return true;
        }
    }

    function bid(
        bytes32 auctionVerificationID,
        uint256 price,
        uint256 _mileage
    ) external userWhitelist(msg.sender) returns (uint256 biddingId) {
        require(canBid(msg.sender, price, auctionVerificationID));
        AuctionInfo memory auctionInfo = _auctionInfo[auctionVerificationID];

        Auction storage auction = auctions[auctionInfo.item][auctionInfo.id][auctionInfo.auctionId];

        uint256 metaverseId = auction.metaverseId;
        uint256 amount = auction.amount;

        Bidding[] storage bs = biddings[auctionVerificationID];
        biddingId = bs.length;
        if (biddingId > 0) {
            Bidding storage lastBidding = bs[biddingId - 1];
            address lastBidder = lastBidding.bidder;
            uint256 lastMileage = lastBidding.mileage;
            mix.transfer(lastBidder, lastBidding.price.sub(lastMileage));
            if (lastMileage > 0) {
                mix.approve(address(mileage), lastMileage);
                mileage.charge(lastBidder, lastMileage);
            }
            _removeUserBiddingInfo(lastBidder, auctionVerificationID);
        }

        bs.push(
            Bidding({
                bidder: msg.sender,
                metaverseId: metaverseId,
                item: auctionInfo.item,
                id: auctionInfo.id,
                amount: amount,
                price: price,
                mileage: _mileage
            })
        );

        _userBiddingIndex[msg.sender][auctionVerificationID] = userBiddingInfo[msg.sender].length;
        userBiddingInfo[msg.sender].push(BiddingInfo({auctionVerificationID: auctionVerificationID, biddingId: biddingId}));

        mix.transferFrom(msg.sender, address(this), price.sub(_mileage));
        if (_mileage > 0) mileage.use(msg.sender, _mileage);
        {
            //to avoid stack too deep error
            uint256 endBlock = auction.endBlock;
            if (block.number >= endBlock.sub(auctionExtensionInterval)) {
                auction.endBlock = endBlock.add(auctionExtensionInterval);
            }
        }
        emit Bid(metaverseId, auctionInfo.item, auctionInfo.id, msg.sender, amount, price, auctionVerificationID, biddingId);
    }

    function _removeUserBiddingInfo(address bidder, bytes32 auctionVerificationID) private {
        uint256 lastIndex = userBiddingInfo[bidder].length.sub(1);
        uint256 index = _userBiddingIndex[bidder][auctionVerificationID];

        if (index != lastIndex) {
            BiddingInfo memory lastBiddingInfo = userBiddingInfo[bidder][lastIndex];
            userBiddingInfo[bidder][index] = lastBiddingInfo;
            _userBiddingIndex[bidder][lastBiddingInfo.auctionVerificationID] = index;
        }
        delete _userBiddingIndex[bidder][auctionVerificationID];
        userBiddingInfo[bidder].length--;
    }

    function claim(bytes32 auctionVerificationID) external {
        AuctionInfo storage auctionInfo = _auctionInfo[auctionVerificationID];
        address item = auctionInfo.item;
        uint256 id = auctionInfo.id;

        Auction storage auction = auctions[item][id][auctionInfo.auctionId];

        uint256 metaverseId = auction.metaverseId;
        uint256 amount = auction.amount;

        Bidding[] storage bs = biddings[auctionVerificationID];
        uint256 bestBiddingId = bs.length.sub(1);
        Bidding storage bestBidding = bs[bestBiddingId];

        address bestBidder = bestBidding.bidder;
        uint256 bestBiddingPrice = bestBidding.price;

        require(block.number >= auction.endBlock);

        _itemTransfer(metaverseId, item, id, amount, address(this), bestBidder);
        _distributeReward(metaverseId, bestBidder, auction.seller, bestBiddingPrice);

        _removeUserBiddingInfo(bestBidder, auctionVerificationID);
        delete biddings[auctionVerificationID];
        _removeAuction(auctionVerificationID);

        emit Claim(metaverseId, item, id, bestBidder, amount, bestBiddingPrice, auctionVerificationID, bestBiddingId);
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

    function cancelAuctionByOwner(bytes32[] calldata auctionVerificationIDs) external onlyOwner {
        for (uint256 i = 0; i < auctionVerificationIDs.length; i++) {
            AuctionInfo storage auctionInfo = _auctionInfo[auctionVerificationIDs[i]];
            address item = auctionInfo.item;
            uint256 id = auctionInfo.id;

            Auction storage auction = auctions[item][id][auctionInfo.auctionId];
            Bidding[] storage bs = biddings[auctionVerificationIDs[i]];
            uint256 biddingLength = bs.length;
            if (biddingLength > 0) {
                Bidding storage lastBidding = bs[biddingLength - 1];
                address lastBidder = lastBidding.bidder;
                uint256 lastMileage = lastBidding.mileage;
                mix.transfer(lastBidder, lastBidding.price.sub(lastMileage));
                if (lastMileage > 0) {
                    mix.approve(address(mileage), lastMileage);
                    mileage.charge(lastBidder, lastMileage);
                }
                _removeUserBiddingInfo(lastBidder, auctionVerificationIDs[i]);
                delete biddings[auctionVerificationIDs[i]];
            }
            uint256 metaverseId = auction.metaverseId;
            _itemTransfer(metaverseId, item, id, auction.amount, address(this), auction.seller);
            _removeAuction(auctionVerificationIDs[i]);
            emit CancelAuction(metaverseId, item, id, auctionVerificationIDs[i]);
            emit CancelAuctionByOwner(metaverseId, item, id, auctionVerificationIDs[i]);
        }
    }
}
