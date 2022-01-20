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

    function _removeSale(bytes32 hash, uint256 saleId) private {
        Sale memory sale = sales[hash][saleId];
        // require(sale.seller != address(0));

        //delete sales
        uint256 lastSaleId = sales[hash].length.sub(1);
        Sale memory lastSale = sales[hash][lastSaleId];
        if (saleId != lastSaleId) {
            sales[hash][saleId] = lastSale;
            emit ChangeSaleId(
                lastSale.metaverseId,
                lastSale.item,
                lastSale.id,
                lastSale.seller,
                lastSale.amount,
                lastSale.unitPrice,
                lastSale.partialBuying,
                hash,
                lastSaleId,
                saleId
            );
        }
        sales[hash].length--;

        //delete onSales
        uint256 lastIndex = onSales[lastSale.item].length.sub(1);
        uint256 index = _onSalesIndex[hash][lastSaleId];
        if (index != lastIndex) {
            SaleInfo memory lastSaleInfo = onSales[lastSale.item][lastIndex];
            onSales[lastSale.item][index] = lastSaleInfo;
            _onSalesIndex[lastSaleInfo.hash][lastSaleInfo.saleId] = index;
        }
        onSales[lastSale.item].length--;
        delete _onSalesIndex[hash][lastSaleId];

        //delete userSellInfo
        lastIndex = userSellInfo[sale.seller].length.sub(1);
        index = _userSellIndex[hash][saleId];
        if (index != lastIndex) {
            SaleInfo memory lastSaleInfo = userSellInfo[sale.seller][lastIndex];
            userSellInfo[sale.seller][index] = lastSaleInfo;
            _userSellIndex[lastSaleInfo.hash][lastSaleInfo.saleId] = index;
        }
        userSellInfo[sale.seller].length--;

        uint256 _lastSaleUserIndex = _userSellIndex[hash][lastSaleId];
        userSellInfo[lastSale.seller][_lastSaleUserIndex].saleId = saleId;
        _userSellIndex[hash][saleId] = _lastSaleUserIndex;
        delete _userSellIndex[hash][lastSaleId];

        //delete salesOnMetaverse
        lastIndex = salesOnMetaverse[sale.metaverseId].length.sub(1);
        index = _salesOnMvIndex[hash][saleId];
        if (index != lastIndex) {
            SaleInfo memory lastSaleInfo = salesOnMetaverse[sale.metaverseId][lastIndex];
            salesOnMetaverse[sale.metaverseId][index] = lastSaleInfo;
            _salesOnMvIndex[lastSaleInfo.hash][lastSaleInfo.saleId] = index;
        }
        salesOnMetaverse[sale.metaverseId].length--;

        uint256 _lastSaleMvIndex = _salesOnMvIndex[hash][lastSaleId];
        salesOnMetaverse[lastSale.metaverseId][_lastSaleMvIndex].saleId = saleId;
        _salesOnMvIndex[hash][saleId] = _lastSaleMvIndex;
        delete _salesOnMvIndex[hash][lastSaleId];

        //subtract amounts
        if (sale.amount > 0) {
            bytes32 iisHash = keccak256(abi.encodePacked(sale.item, sale.id, sale.seller));
            userOnSaleAmounts[iisHash] = userOnSaleAmounts[iisHash].sub(sale.amount);
        }
    }

    function _removeOffer(bytes32 hash, uint256 offerId) private {
        Offer memory _offer = offers[hash][offerId];

        //delete sales
        uint256 lastOfferId = offers[hash].length.sub(1);
        Offer memory lastOffer = offers[hash][lastOfferId];
        if (offerId != lastOfferId) {
            offers[hash][offerId] = lastOffer;
            emit ChangeOfferId(
                lastOffer.metaverseId,
                lastOffer.item,
                lastOffer.id,
                lastOffer.offeror,
                lastOffer.amount,
                lastOffer.unitPrice,
                lastOffer.partialBuying,
                hash,
                lastOfferId,
                offerId
            );
        }
        offers[hash].length--;

        //delete userOfferInfo
        uint256 lastIndex = userOfferInfo[_offer.offeror].length.sub(1);
        uint256 index = _userOfferIndex[hash][offerId];
        if (index != lastIndex) {
            OfferInfo memory lastOfferInfo = userOfferInfo[_offer.offeror][lastIndex];
            userOfferInfo[_offer.offeror][index] = lastOfferInfo;
            _userOfferIndex[lastOfferInfo.hash][lastOfferInfo.offerId] = index;
        }
        userOfferInfo[_offer.offeror].length--;

        uint256 _lastOfferUserIndex = _userOfferIndex[hash][lastOfferId];
        userOfferInfo[lastOffer.offeror][_lastOfferUserIndex].offerId = offerId;
        _userOfferIndex[hash][offerId] = _lastOfferUserIndex;
        delete _userOfferIndex[hash][lastOfferId];
    }

    function _removeAuction(bytes32 hash, uint256 auctionId) private {
        Auction memory auction = auctions[hash][auctionId];

        //delete auctions
        uint256 lastAuctionId = auctions[hash].length.sub(1);
        Auction memory lastAuction = auctions[hash][lastAuctionId];
        if (auctionId != lastAuctionId) {
            auctions[hash][auctionId] = lastAuction;
            emit ChangeAuctionId(
                lastAuction.metaverseId,
                lastAuction.item,
                lastAuction.id,
                lastAuction.seller,
                lastAuction.amount,
                lastAuction.startTotalPrice,
                lastAuction.endBlock,
                hash,
                lastAuctionId,
                auctionId
            );
        }
        auctions[hash].length--;

        //delete onAuctions
        uint256 lastIndex = onAuctions[lastAuction.item].length.sub(1);
        uint256 index = _onAuctionsIndex[hash][lastAuctionId];
        if (index != lastIndex) {
            AuctionInfo memory lastAuctionInfo = onAuctions[lastAuction.item][lastIndex];
            onAuctions[lastAuction.item][index] = lastAuctionInfo;
            _onAuctionsIndex[lastAuctionInfo.hash][lastAuctionInfo.auctionId] = index;
        }
        onAuctions[lastAuction.item].length--;
        delete _onAuctionsIndex[hash][lastAuctionId];

        //delete userAuctionInfo
        lastIndex = userAuctionInfo[auction.seller].length.sub(1);
        index = _userAuctionIndex[hash][auctionId];
        if (index != lastIndex) {
            AuctionInfo memory lastAuctionInfo = userAuctionInfo[auction.seller][lastIndex];
            userAuctionInfo[auction.seller][index] = lastAuctionInfo;
            _userAuctionIndex[lastAuctionInfo.hash][lastAuctionInfo.auctionId] = index;
        }
        userAuctionInfo[auction.seller].length--;

        uint256 _lastAuctionUserIndex = _userAuctionIndex[hash][lastAuctionId];
        userAuctionInfo[lastAuction.seller][_lastAuctionUserIndex].auctionId = auctionId;
        _userAuctionIndex[hash][auctionId] = _lastAuctionUserIndex;
        delete _userAuctionIndex[hash][lastAuctionId];

        //delete auctionsOnMetaverse
        lastIndex = auctionsOnMetaverse[auction.metaverseId].length.sub(1);
        index = _auctionsOnMvIndex[hash][auctionId];
        if (index != lastIndex) {
            AuctionInfo memory lastAuctionInfo = auctionsOnMetaverse[auction.metaverseId][lastIndex];
            auctionsOnMetaverse[auction.metaverseId][index] = lastAuctionInfo;
            _auctionsOnMvIndex[lastAuctionInfo.hash][lastAuctionInfo.auctionId] = index;
        }
        auctionsOnMetaverse[auction.metaverseId].length--;

        uint256 _lastAuctionMvIndex = _auctionsOnMvIndex[hash][lastAuctionId];
        auctionsOnMetaverse[lastAuction.metaverseId][_lastAuctionMvIndex].auctionId = auctionId;
        _auctionsOnMvIndex[hash][auctionId] = _lastAuctionMvIndex;
        delete _auctionsOnMvIndex[hash][lastAuctionId];
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
        bytes32 hash;
        uint256 saleId;
    }

    mapping(bytes32 => Sale[]) public sales; //sales[hash]. hash: item,id

    mapping(address => SaleInfo[]) public onSales; //onSales[item]. 아이템 계약 중 onSale 중인 정보들.
    mapping(bytes32 => mapping(uint256 => uint256)) private _onSalesIndex; //_onSalesIndex[saleHash][saleId]. 특정 세일의 onSales index.

    mapping(address => SaleInfo[]) public userSellInfo; //userSellInfo[seller] 셀러가 팔고있는 세일의 정보.
    mapping(bytes32 => mapping(uint256 => uint256)) private _userSellIndex; //_userSellIndex[saleHash][saleId]. 특정 세일의 userSellInfo index.

    mapping(uint256 => SaleInfo[]) public salesOnMetaverse; //salesOnMetaverse[metaverseId]. 특정 메타버스에서 판매되고있는 모든 세일들.
    mapping(bytes32 => mapping(uint256 => uint256)) private _salesOnMvIndex; //_salesOnMvIndex[saleHash][saleId]. 특정 세일의 salesOnMetaverse index.

    mapping(bytes32 => uint256) public userOnSaleAmounts; //userSaleAmounts[iisHash]. iisHash: item,id,seller. 셀러가 판매중인 특정 id의 아이템의 총 합.

    //TODO 한번에 모든 배열이 불러와지지 않는 경우 대비.

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
            IKIP37 nft = IKIP37(item);
            bytes32 hash = keccak256(abi.encodePacked(item, id, seller));
            if (userOnSaleAmounts[hash].add(amount) > nft.balanceOf(seller, id)) return false;
            return true;
        } else {
            if (amount != 1) return false;
            IKIP17 nft = IKIP17(item);
            if (nft.ownerOf(id) != seller) return false;
            bytes32 hash = keccak256(abi.encodePacked(item, id, seller));
            if (userOnSaleAmounts[hash] != 0) return false;
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

            require(unitPrices[i] > 0);
            require(canSell(msg.sender, metaverseId, items[i], ids[i], amounts[i]));

            bytes32 verificationID = keccak256(
                abi.encodePacked(msg.sender, metaverseIds[i], items[i], ids[i], amounts[i], unitPrices[i], partialBuyings[i], nonce[msg.sender]++)
            );

            bytes32 hash = keccak256(abi.encodePacked(items[i], ids[i]));
            uint256 saleId = sales[hash].length;
            sales[hash].push(
                Sale({
                    seller: msg.sender,
                    metaverseId: metaverseId,
                    item: items[i],
                    id: ids[i],
                    amount: amounts[i],
                    unitPrice: unitPrices[i],
                    partialBuying: partialBuyings[i],
                    verificationID: verificationID
                })
            );

            SaleInfo memory _info = SaleInfo({hash: hash, saleId: saleId});

            _onSalesIndex[hash][saleId] = onSales[items[i]].length;
            onSales[items[i]].push(_info);

            _userSellIndex[hash][saleId] = userSellInfo[msg.sender].length;
            userSellInfo[msg.sender].push(_info);

            _salesOnMvIndex[hash][saleId] = salesOnMetaverse[metaverseId].length;
            salesOnMetaverse[metaverseId].push(_info);

            bytes32 iisHash = keccak256(abi.encodePacked(items[i], ids[i], msg.sender));
            userOnSaleAmounts[iisHash] = userOnSaleAmounts[iisHash].add(amounts[i]);

            emit Sell(metaverseId, items[i], ids[i], msg.sender, amounts[i], unitPrices[i], partialBuyings[i], hash, saleId, verificationID);
        }
    }

    function changeSellPrice(
        bytes32[] calldata hashes,
        uint256[] calldata saleIds,
        uint256[] calldata unitPrices,
        bytes32[] calldata _verificationIDes
    ) external userWhitelist(msg.sender) {
        require(hashes.length == saleIds.length && hashes.length == unitPrices.length);
        for (uint256 i = 0; i < hashes.length; i++) {
            Sale storage sale = sales[hashes[i]][saleIds[i]];
            require(sale.seller == msg.sender);
            require(sale.unitPrice != unitPrices[i]);
            require(sale.verificationID == _verificationIDes[i]);

            sale.unitPrice = unitPrices[i];
            emit ChangeSellPrice(sale.metaverseId, sale.item, sale.id, msg.sender, unitPrices[i], hashes[i], saleIds[i]);
        }
    }

    function cancelSale(
        bytes32[] calldata hashes,
        uint256[] calldata saleIds,
        bytes32[] calldata _verificationIDes
    ) external {
        require(hashes.length == saleIds.length && hashes.length == _verificationIDes.length);
        for (uint256 i = 0; i < hashes.length; i++) {
            Sale memory sale = sales[hashes[i]][saleIds[i]];
            require(sale.seller == msg.sender);
            require(sale.verificationID == _verificationIDes[i]);

            _removeSale(hashes[i], saleIds[i]);
            emit CancelSale(sale.metaverseId, sale.item, sale.id, msg.sender, sale.amount, sale.unitPrice, hashes[i], saleIds[i]);
        }
    }

    function buy(
        address[] calldata items,
        bytes32[] calldata hashes,
        uint256[] calldata saleIds,
        uint256[] calldata amounts,
        uint256[] calldata unitPrices,
        uint256[] calldata mileages
    ) external userWhitelist(msg.sender) {
        require(
            items.length == hashes.length &&
                items.length == saleIds.length &&
                items.length == amounts.length &&
                items.length == unitPrices.length &&
                items.length == mileages.length
        );
        for (uint256 i = 0; i < items.length; i++) {
            Sale memory sale = sales[hashes[i]][saleIds[i]];
            require(isItemWhitelisted(sale.metaverseId, sale.item));
            require(sale.item == items[i]);
            require(sale.seller != address(0) && sale.seller != msg.sender);
            require(sale.unitPrice == unitPrices[i]);

            if (!sale.partialBuying) {
                require(sale.amount == amounts[i]);
            } else {
                require(sale.amount >= amounts[i]);
            }

            _itemTransfer(sale.metaverseId, sale.item, sale.id, amounts[i], sale.seller, msg.sender);
            uint256 price = amounts[i].mul(unitPrices[i]);

            mix.transferFrom(msg.sender, address(this), price.sub(mileages[i]));
            if (mileages[i] > 0) mileage.use(msg.sender, mileages[i]);
            _distributeReward(sale.metaverseId, msg.sender, sale.seller, price);

            uint256 amountLeft = sale.amount.sub(amounts[i]);
            sales[hashes[i]][saleIds[i]].amount = amountLeft;

            bytes32 iisHash = keccak256(abi.encodePacked(sale.item, sale.id, sale.seller));
            userOnSaleAmounts[iisHash] = userOnSaleAmounts[iisHash].sub(amounts[i]);

            bool isFulfilled = false;
            if (amountLeft == 0) {
                _removeSale(hashes[i], saleIds[i]);
                isFulfilled = true;
            }

            emit Buy(sale.metaverseId, sale.item, sale.id, sale.seller, msg.sender, amounts[i], unitPrices[i], hashes[i], saleIds[i], isFulfilled);
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
        bytes32 hash;
        uint256 offerId;
    }

    mapping(bytes32 => Offer[]) public offers; //offers[hash]. hash: item,id

    mapping(address => OfferInfo[]) public userOfferInfo; //userOfferInfo[offeror] 오퍼러의 오퍼들 정보.
    mapping(bytes32 => mapping(uint256 => uint256)) private _userOfferIndex; //_userOfferIndex[offerHash][offerId]. 특정 오퍼의 userOfferInfo index.

    function userOfferInfoLength(address offeror) external view returns (uint256) {
        return userOfferInfo[offeror].length;
    }

    function offerCount(bytes32 offerHash) external view returns (uint256) {
        return offers[offerHash].length;
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

        bytes32 hash = keccak256(abi.encodePacked(item, id));
        offerId = offers[hash].length;
        offers[hash].push(
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

        _userOfferIndex[hash][offerId] = userOfferInfo[msg.sender].length;
        userOfferInfo[msg.sender].push(OfferInfo({hash: hash, offerId: offerId}));

        mix.transferFrom(msg.sender, address(this), amount.mul(unitPrice).sub(_mileage));
        if (_mileage > 0) mileage.use(msg.sender, _mileage);

        emit MakeOffer(metaverseId, item, id, msg.sender, amount, unitPrice, partialBuying, hash, offerId, verificationID);
    }

    function cancelOffer(
        bytes32 hash,
        uint256 offerId,
        bytes32 _verificationID
    ) external {
        Offer memory _offer = offers[hash][offerId];
        require(_offer.offeror == msg.sender);
        require(_offer.verificationID == _verificationID);

        _removeOffer(hash, offerId);

        mix.transfer(msg.sender, _offer.amount.mul(_offer.unitPrice).sub(_offer.mileage));
        if (_offer.mileage > 0) {
            mix.approve(address(mileage), _offer.mileage);
            mileage.charge(msg.sender, _offer.mileage);
        }

        emit CancelOffer(_offer.metaverseId, _offer.item, _offer.id, msg.sender, _offer.amount, _offer.unitPrice, hash, offerId);
    }

    function acceptOffer(
        address item,
        bytes32 hash,
        uint256 offerId,
        uint256 amount,
        uint256 unitPrice
    ) external userWhitelist(msg.sender) {
        Offer memory _offer = offers[hash][offerId];
        require(isItemWhitelisted(_offer.metaverseId, _offer.item));
        require(_offer.item == item);
        require(_offer.offeror != address(0) && _offer.offeror != msg.sender);
        require(_offer.unitPrice == unitPrice);

        if (!_offer.partialBuying) {
            require(_offer.amount == amount);
        } else {
            require(_offer.amount >= amount);
        }

        _itemTransfer(_offer.metaverseId, _offer.item, _offer.id, amount, msg.sender, _offer.offeror);
        uint256 price = amount.mul(_offer.unitPrice);

        _distributeReward(_offer.metaverseId, _offer.offeror, msg.sender, price);

        uint256 amountLeft = _offer.amount.sub(amount);
        offers[hash][offerId].amount = amountLeft;

        bool isFulfilled = false;
        if (amountLeft == 0) {
            _removeOffer(hash, offerId);
            isFulfilled = true;
        }

        emit AcceptOffer(
            _offer.metaverseId,
            _offer.item,
            _offer.id,
            _offer.offeror,
            msg.sender,
            _offer.amount,
            _offer.unitPrice,
            hash,
            offerId,
            isFulfilled
        );
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
        bytes32 hash;
        uint256 auctionId;
    }

    mapping(bytes32 => Auction[]) public auctions; //auctions[hash]. hash: item,id

    mapping(address => AuctionInfo[]) public onAuctions; //onAuctions[item]. 아이템 계약 중 onAuction 중인 정보들.
    mapping(bytes32 => mapping(uint256 => uint256)) private _onAuctionsIndex; //_onAuctionsIndex[auctionHash][auctionId]. 특정 옥션의 onAuctions index.

    mapping(address => AuctionInfo[]) public userAuctionInfo; //userAuctionInfo[seller] 셀러의 옥션들 정보.
    mapping(bytes32 => mapping(uint256 => uint256)) private _userAuctionIndex; //_userAuctionIndex[auctionHash][auctionId]. 특정 옥션의 userAuctionInfo index.

    mapping(uint256 => AuctionInfo[]) public auctionsOnMetaverse; //auctionsOnMetaverse[metaverseId]. 특정 메타버스의 모든 옥션들.
    mapping(bytes32 => mapping(uint256 => uint256)) private _auctionsOnMvIndex; //_auctionsOnMvIndex[auctionHash][auctionId]. 특정 옥션의 auctionsOnMetaverse index.

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

        bytes32 hash = keccak256(abi.encodePacked(item, id));
        auctionId = auctions[hash].length;
        auctions[hash].push(
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

        AuctionInfo memory _info = AuctionInfo({hash: hash, auctionId: auctionId});

        _onAuctionsIndex[hash][auctionId] = onAuctions[item].length;
        onAuctions[item].push(_info);

        _userAuctionIndex[hash][auctionId] = userAuctionInfo[msg.sender].length;
        userAuctionInfo[msg.sender].push(_info);

        _auctionsOnMvIndex[hash][auctionId] = auctionsOnMetaverse[metaverseId].length;
        auctionsOnMetaverse[metaverseId].push(_info);

        _itemTransfer(metaverseId, item, id, amount, msg.sender, address(this));

        emit CreateAuction(metaverseId, item, id, msg.sender, amount, startTotalPrice, endBlock, hash, auctionId, verificationID);
    }

    function cancelAuction(
        bytes32 hash,
        uint256 auctionId,
        bytes32 _verificationID
    ) external {
        require(biddings[hash][_verificationID].length == 0);
        Auction memory auction = auctions[hash][auctionId];
        require(auction.seller == msg.sender);
        require(auction.verificationID == _verificationID);

        _removeAuction(hash, auctionId);

        _itemTransfer(auction.metaverseId, auction.item, auction.id, auction.amount, address(this), msg.sender);

        emit CancelAuction(auction.metaverseId, auction.item, auction.id, auction.seller, auction.amount, auction.startTotalPrice, hash, auctionId);
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
        bytes32 verificationID;
    }

    struct BiddingInfo {
        bytes32 hash;
        bytes32 auctionVerificationID;
        uint256 biddingIndex;
        bytes32 biddingVerificationID;
    }

    mapping(bytes32 => mapping(bytes32 => Bidding[])) public biddings; //biddings[hash][auction_verificationID]. hash: item,id

    mapping(address => BiddingInfo[]) public userBiddingInfo; //userBiddingInfo[bidder] 비더의 비딩들 정보.
    mapping(bytes32 => mapping(bytes32 => uint256)) private _userBiddingIndex; //_userBiddingIndex[hash][bidding_verificationID]. 특정 비딩의 userBiddingInfo index.

    function userBiddingInfoLength(address bidder) external view returns (uint256) {
        return userBiddingInfo[bidder].length;
    }

    function biddingCount(bytes32 hash, bytes32 verificationID) external view returns (uint256) {
        return biddings[hash][verificationID].length;
    }

    function canBid(
        address bidder,
        uint256 price,
        bytes32 auctionHash,
        uint256 auctionId,
        bytes32 auctionVerificationID
    ) public view returns (bool) {
        Auction memory auction = auctions[auctionHash][auctionId];
        if (!isItemWhitelisted(auction.metaverseId, auction.item)) return false;

        if (auction.verificationID != auctionVerificationID) return false;
        if (auction.seller == address(0) || auction.seller == bidder) return false;
        if (auction.endBlock <= block.number) return false;

        Bidding[] storage bs = biddings[auctionHash][auctionVerificationID];
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
        bytes32 auctionHash,
        uint256 auctionId,
        bytes32 auctionVerificationID,
        uint256 price,
        uint256 _mileage
    ) external userWhitelist(msg.sender) returns (uint256 biddingId) {
        require(canBid(msg.sender, price, auctionHash, auctionId, auctionVerificationID));
        Auction memory auction = auctions[auctionHash][auctionId];

        require(auction.metaverseId < metaverses.metaverseCount() && !metaverses.banned(auction.metaverseId));
        require(metaverses.itemAdded(auction.metaverseId, auction.item));

        Bidding[] storage bs = biddings[auctionHash][auctionVerificationID];
        biddingId = bs.length;
        if (biddingId > 0) {
            Bidding storage bestBidding = bs[biddingId - 1];
            address lastBidder = bestBidding.bidder;
            uint256 lastMileage = bestBidding.mileage;
            mix.transfer(lastBidder, bestBidding.price.sub(lastMileage));
            if (lastMileage > 0) {
                mix.approve(address(mileage), lastMileage);
                mileage.charge(lastBidder, lastMileage);
            }
            _removeUserBiddingInfo(lastBidder, auctionHash, bestBidding.verificationID);
        }

        bytes32 biddingVerificationID = keccak256(
            abi.encodePacked(msg.sender, auction.metaverseId, auction.item, auction.id, auction.amount, price, _mileage, nonce[msg.sender]++)
        );

        bs.push(
            Bidding({
                bidder: msg.sender,
                metaverseId: auction.metaverseId,
                item: auction.item,
                id: auction.id,
                amount: auction.amount,
                price: price,
                mileage: _mileage,
                verificationID: biddingVerificationID
            })
        );

        _userBiddingIndex[auctionHash][biddingVerificationID] = userBiddingInfo[msg.sender].length;
        userBiddingInfo[msg.sender].push(
            BiddingInfo({
                hash: auctionHash,
                auctionVerificationID: auctionVerificationID,
                biddingIndex: biddingId,
                biddingVerificationID: biddingVerificationID
            })
        );

        mix.transferFrom(msg.sender, address(this), price.sub(_mileage));
        if (_mileage > 0) mileage.use(msg.sender, _mileage);

        if (block.number >= auction.endBlock.sub(auctionExtensionInterval)) {
            auctions[auctionHash][auctionId].endBlock = auction.endBlock.add(auctionExtensionInterval);
        }

        emit Bid(
            auction.metaverseId,
            auction.item,
            auction.id,
            msg.sender,
            auction.amount,
            price,
            auctionHash,
            auctionId,
            auctionVerificationID,
            biddingVerificationID
        );
    }

    function _removeUserBiddingInfo(
        address bidder,
        bytes32 hash,
        bytes32 biddingVerificationID
    ) private {
        uint256 lastIndex = userBiddingInfo[bidder].length.sub(1);
        uint256 index = _userBiddingIndex[hash][biddingVerificationID];

        if (index != lastIndex) {
            BiddingInfo memory lastBiddingInfo = userBiddingInfo[bidder][lastIndex];
            userBiddingInfo[bidder][index] = lastBiddingInfo;
            _userBiddingIndex[lastBiddingInfo.hash][lastBiddingInfo.biddingVerificationID] = index;
        }
        delete _userBiddingIndex[hash][biddingVerificationID];
        userBiddingInfo[bidder].length--;
    }
}
