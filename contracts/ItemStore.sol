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

    modifier metaverseWhitelist(uint256 metaverseId) {
        require(metaverseId < metaverses.metaverseCount() && !metaverses.banned(metaverseId));
        _;
    }

    modifier itemWhitelist(uint256 metaverseId, address item) {
        require(metaverseId < metaverses.metaverseCount() && !metaverses.banned(metaverseId));
        require(metaverses.itemAdded(metaverseId, item));
        _;
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

        //delete onSales
        uint256 lastIndex = onSales[sale.item].length.sub(1);
        uint256 index = _onSalesIndex[hash][saleId];
        if (index != lastIndex) {
            SaleInfo memory lastSaleInfo = onSales[sale.item][lastIndex];
            onSales[sale.item][index] = lastSaleInfo;
            _onSalesIndex[lastSaleInfo.hash][lastSaleInfo.saleId] = index;
        }
        onSales[sale.item].length--;
        delete _onSalesIndex[hash][saleId];

        //delete userSellInfo
        lastIndex = userSellInfo[sale.seller].length.sub(1);
        index = _userSellIndex[hash][saleId];
        if (index != lastIndex) {
            SaleInfo memory lastSaleInfo = userSellInfo[sale.seller][lastIndex];
            userSellInfo[sale.seller][index] = lastSaleInfo;
            _userSellIndex[lastSaleInfo.hash][lastSaleInfo.saleId] = index;
        }
        userSellInfo[sale.seller].length--;
        delete _userSellIndex[hash][saleId];

        //delete salesOnMetaverse
        lastIndex = salesOnMetaverse[sale.metaverseId].length.sub(1);
        index = _salesOnMvIndex[hash][saleId];
        if (index != lastIndex) {
            SaleInfo memory lastSaleInfo = salesOnMetaverse[sale.metaverseId][lastIndex];
            salesOnMetaverse[sale.metaverseId][index] = lastSaleInfo;
            _salesOnMvIndex[lastSaleInfo.hash][lastSaleInfo.saleId] = index;
        }
        salesOnMetaverse[sale.metaverseId].length--;
        delete _salesOnMvIndex[hash][saleId];

        //delete sales
        lastIndex = sales[hash].length.sub(1);
        if (saleId != lastIndex) {
            Sale memory lastSale = sales[hash][lastIndex];
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
                lastIndex,
                saleId
            );
        }
        sales[hash].length--;

        //subtract amounts
        if (sale.amount > 0) {
            bytes32 iisHash = keccak256(abi.encodePacked(sale.item, sale.id, sale.seller));
            userOnSaleAmounts[iisHash] = userOnSaleAmounts[iisHash].sub(sale.amount);
        }
    }

    function _removeOffer(bytes32 hash, uint256 offerId) private {
        Offer memory _offer = offers[hash][offerId];

        //delete userOfferInfo
        uint256 lastIndex = userOfferInfo[_offer.offeror].length.sub(1);
        uint256 index = _userOfferIndex[hash][offerId];
        if (index != lastIndex) {
            OfferInfo memory lastOfferInfo = userOfferInfo[_offer.offeror][lastIndex];
            userOfferInfo[_offer.offeror][index] = lastOfferInfo;
            _userOfferIndex[lastOfferInfo.hash][lastOfferInfo.offerId] = index;
        }
        userOfferInfo[_offer.offeror].length--;
        delete _userOfferIndex[hash][offerId];

        //delete sales
        lastIndex = offers[hash].length.sub(1);
        if (offerId != lastIndex) {
            Offer memory lastOffer = offers[hash][lastIndex];
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
                lastIndex,
                offerId
            );
        }
        offers[hash].length--;
    }

    function _removeAuction(bytes32 hash, uint256 auctionId) private {
        // if (checkAuction(metaverseId, addr, id) == true) {
        //     uint256 lastIndex = onAuctionsCount(metaverseId, addr).sub(1);
        //     uint256 index = onAuctionsIndex[metaverseId][addr][id];
        //     if (index != lastIndex) {
        //         uint256 last = onAuctions[metaverseId][addr][lastIndex];
        //         onAuctions[metaverseId][addr][index] = last;
        //         onAuctionsIndex[metaverseId][addr][last] = index;
        //     }
        //     onAuctions[metaverseId][addr].length--;
        //     delete onAuctionsIndex[metaverseId][addr][id];
        // }
        // delete auctions[metaverseId][addr][id];
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

    //Sale
    struct Sale {
        address seller;
        uint256 metaverseId;
        address item;
        uint256 id;
        uint256 amount;
        uint256 unitPrice;
        bool partialBuying;
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

    function userSalesOnMetaverseLength(uint256 metaverseId) external view returns (uint256) {
        return salesOnMetaverse[metaverseId].length;
    }

    function canSell(
        address seller,
        uint256 metaverseId,
        address item,
        uint256 id,
        uint256 amount
    ) public view returns (bool) {
        if (_isERC1155(metaverseId, item)) {
            require(amount > 0);
            IKIP37 nft = IKIP37(item);
            require(nft.isApprovedForAll(seller, address(this)));
            bytes32 hash = keccak256(abi.encodePacked(item, id, seller));
            require(userOnSaleAmounts[hash].add(amount) <= nft.balanceOf(seller, id));
        } else {
            require(amount == 1);
            IKIP17 nft = IKIP17(item);
            require(nft.ownerOf(id) == seller);
            require(nft.isApprovedForAll(seller, address(this)));
            bytes32 hash = keccak256(abi.encodePacked(item, id, seller));
            require(userOnSaleAmounts[hash] == 0);
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
        uint256 metaverseCount = metaverses.metaverseCount();
        for (uint256 i = 0; i < metaverseIds.length; i++) {
            uint256 metaverseId = metaverseIds[i];
            require(metaverseId < metaverseCount && !metaverses.banned(metaverseId));
            require(metaverses.itemAdded(metaverseId, items[i]));
            require(unitPrices[i] > 0);

            canSell(msg.sender, metaverseId, items[i], ids[i], amounts[i]);

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
                    partialBuying: partialBuyings[i]
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

            emit Sell(metaverseId, items[i], ids[i], msg.sender, amounts[i], unitPrices[i], partialBuyings[i], hash, saleId);
        }
    }

    function changeSellPrice(
        bytes32[] calldata hashes,
        uint256[] calldata saleIds,
        uint256[] calldata unitPrices
    ) external userWhitelist(msg.sender) {
        require(hashes.length == saleIds.length && hashes.length == unitPrices.length);
        for (uint256 i = 0; i < hashes.length; i++) {
            Sale storage sale = sales[hashes[i]][saleIds[i]];
            require(sale.seller == msg.sender);
            require(sale.unitPrice != unitPrices[i]);
            sale.unitPrice = unitPrices[i];
            emit ChangeSellPrice(sale.metaverseId, sale.item, sale.id, msg.sender, unitPrices[i], hashes[i], saleIds[i]);
        }
    }

    function cancelSale(bytes32[] calldata hashes, uint256[] calldata saleIds) external {
        require(hashes.length == saleIds.length);
        for (uint256 i = 0; i < hashes.length; i++) {
            Sale memory sale = sales[hashes[i]][saleIds[i]];
            require(sale.seller == msg.sender);

            _removeSale(hashes[i], saleIds[i]);
            emit CancelSale(sale.metaverseId, sale.item, sale.id, msg.sender, sale.amount, hashes[i], saleIds[i]);
        }
    }

    function buy(
        bytes32[] calldata hashes,
        uint256[] calldata saleIds,
        uint256[] calldata amounts,
        uint256[] calldata unitPrices,
        uint256[] calldata mileages
    ) external userWhitelist(msg.sender) {
        require(
            hashes.length == saleIds.length &&
                hashes.length == amounts.length &&
                hashes.length == unitPrices.length &&
                hashes.length == mileages.length
        );
        for (uint256 i = 0; i < hashes.length; i++) {
            Sale memory sale = sales[hashes[i]][saleIds[i]];
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
        if (_isERC1155(metaverseId, item)) {
            require(amount > 0);
        } else {
            require(amount == 1);
            require(IKIP17(item).ownerOf(id) != offeror);
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
    ) external userWhitelist(msg.sender) itemWhitelist(metaverseId, item) returns (uint256 offerId) {
        require(unitPrice > 0 && amount > 0);
        canOffer(msg.sender, metaverseId, item, id, amount);

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
                mileage: _mileage
            })
        );

        _userOfferIndex[hash][offerId] = userOfferInfo[msg.sender].length;
        userOfferInfo[msg.sender].push(OfferInfo({hash: hash, offerId: offerId}));

        mix.transferFrom(msg.sender, address(this), amount.mul(unitPrice).sub(_mileage));
        if (_mileage > 0) mileage.use(msg.sender, _mileage);

        emit MakeOffer(metaverseId, item, id, msg.sender, amount, unitPrice, partialBuying, hash, offerId);
    }

    function cancelOffer(bytes32 hash, uint256 offerId) external {
        Offer memory _offer = offers[hash][offerId];
        require(_offer.offeror == msg.sender);

        _removeOffer(hash, offerId);

        mix.transfer(msg.sender, _offer.amount.mul(_offer.unitPrice).sub(_offer.mileage));
        if (_offer.mileage > 0) {
            mix.approve(address(mileage), _offer.mileage);
            mileage.charge(msg.sender, _offer.mileage);
        }

        emit CancelOffer(_offer.metaverseId, _offer.item, _offer.id, msg.sender, _offer.amount, hash, offerId);
    }

    function acceptOffer(
        bytes32 hash,
        uint256 offerId,
        uint256 amount,
        uint256 unitPrice
    ) external userWhitelist(msg.sender) {
        Offer memory _offer = offers[hash][offerId];
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
}
