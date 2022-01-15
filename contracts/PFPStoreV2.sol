pragma solidity ^0.5.6;

import "./klaytn-contracts/ownership/Ownable.sol";
import "./klaytn-contracts/math/SafeMath.sol";
import "./klaytn-contracts/token/KIP17/IKIP17.sol";
import "./interfaces/IPFPStoreV2.sol";
import "./interfaces/IPFPsV2.sol";
import "./interfaces/IMix.sol";
import "./interfaces/IMileage.sol";

contract PFPStoreV2 is Ownable, IPFPStoreV2 {
    using SafeMath for uint256;

    struct PFPInfo {
        address pfp;
        uint256 id;
        uint256 price;
    }

    uint256 public fee = 250;
    address public feeReceiver;
    uint256 public auctionExtensionInterval = 300;

    IPFPsV2 public pfps;
    IMix public mix;
    IMileage public mileage;

    constructor(IPFPsV2 _pfps, IMix _mix, IMileage _mileage) public {
        feeReceiver = msg.sender;
        pfps = _pfps;
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

    function setPFPs(IPFPsV2 _pfps) external onlyOwner {
        pfps = _pfps;
    }

    modifier pfpWhitelist(address addr) {
        require(pfps.added(addr) && !pfps.banned(addr));
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

    function batchTransfer(
        address[] calldata addrs,
        uint256[] calldata ids,
        address[] calldata to
    ) external userWhitelist(msg.sender) {
        require(addrs.length == ids.length && addrs.length == to.length);
        for (uint256 i = 0; i < addrs.length; i++) {
            require(pfps.added(addrs[i]) && !pfps.banned(addrs[i]));
            IKIP17(addrs[i]).transferFrom(msg.sender, to[i], ids[i]);
        }
    }

    function removeSale(address addr, uint256 id) private {
        if (checkSelling(addr, id) == true) {
            uint256 lastIndex = onSalesCount(addr).sub(1);
            uint256 index = onSalesIndex[addr][id];
            if (index != lastIndex) {
                uint256 last = onSales[addr][lastIndex];
                onSales[addr][index] = last;
                onSalesIndex[addr][last] = index;
            }
            onSales[addr].length--;
            delete onSalesIndex[addr][id];
        }
        delete sales[addr][id];
    }

    function removeAuction(address addr, uint256 id) private {
        if (checkAuction(addr, id) == true) {
            uint256 lastIndex = onAuctionsCount(addr).sub(1);
            uint256 index = onAuctionsIndex[addr][id];
            if (index != lastIndex) {
                uint256 last = onAuctions[addr][lastIndex];
                onAuctions[addr][index] = last;
                onAuctionsIndex[addr][last] = index;
            }
            onAuctions[addr].length--;
            delete onAuctionsIndex[addr][id];
        }
        delete auctions[addr][id];
    }

    function distributeReward(
        address addr,
        uint256 id,
        address buyer,
        address to,
        uint256 amount
    ) private {
        (address receiver, uint256 royalty) = pfps.royalties(addr);

        uint256 _fee;
        uint256 _royalty;
        uint256 _mileage;

        if (pfps.mileageMode(addr)) {
            if (pfps.onlyKlubsMembership(addr)) {
                uint256 mileageFromFee = amount.mul(mileage.onlyKlubsPercent()).div(1e4);
                _fee = amount.mul(fee).div(1e4);

                if (_fee > mileageFromFee) {
                    _mileage = mileageFromFee;
                    _fee = _fee.sub(mileageFromFee);
                } else {
                    _mileage = _fee;
                    _fee = 0;
                }

                uint256 mileageFromRoyalty = amount.mul(mileage.mileagePercent()).div(1e4).sub(mileageFromFee);
                _royalty = amount.mul(royalty).div(1e4);

                if (_royalty > mileageFromRoyalty) {
                    _mileage = _mileage.add(mileageFromRoyalty);
                    _royalty = _royalty.sub(mileageFromRoyalty);
                } else {
                    _mileage = _mileage.add(_royalty);
                    _royalty = 0;
                }
            } else {
                _fee = amount.mul(fee).div(1e4);
                _mileage = amount.mul(mileage.mileagePercent()).div(1e4);
                _royalty = amount.mul(royalty).div(1e4);

                if (_royalty > _mileage) {
                    _royalty = _royalty.sub(_mileage);
                } else {
                    _mileage = _royalty;
                    _royalty = 0;
                }
            }
        } else {
            _fee = amount.mul(fee).div(1e4);
            _royalty = amount.mul(royalty).div(1e4);
        }

        if (_fee > 0) mix.transfer(feeReceiver, _fee);
        if (_royalty > 0) mix.transfer(receiver, _royalty);
        if (_mileage > 0) {
            mix.approve(address(mileage), _mileage);
            mileage.charge(buyer, _mileage);
        }

        mix.transfer(to, amount.sub(_fee).sub(_royalty).sub(_mileage));

        removeSale(addr, id);
        removeAuction(addr, id);
        delete biddings[addr][id];
    }

    struct Sale {
        address seller;
        uint256 price;
    }
    mapping(address => mapping(uint256 => Sale)) public sales; //sales[addr][id]
    mapping(address => uint256[]) public onSales;
    mapping(address => mapping(uint256 => uint256)) public onSalesIndex;
    mapping(address => PFPInfo[]) public userSellInfo; //userSellInfo[seller]
    mapping(address => mapping(uint256 => uint256)) private userSellIndex; //userSellIndex[addr][id]

    function onSalesCount(address addr) public view returns (uint256) {
        return onSales[addr].length;
    }

    function userSellInfoLength(address seller) public view returns (uint256) {
        return userSellInfo[seller].length;
    }

    function checkSelling(address addr, uint256 id) public view returns (bool) {
        return sales[addr][id].seller != address(0);
    }

    function sell(
        address[] calldata addrs,
        uint256[] calldata ids,
        uint256[] calldata prices
    ) external userWhitelist(msg.sender) {
        require(addrs.length == ids.length && addrs.length == prices.length);
        for (uint256 i = 0; i < addrs.length; i++) {
            require(pfps.added(addrs[i]) && !pfps.banned(addrs[i]));
            require(prices[i] > 0);

            IKIP17 nft = IKIP17(addrs[i]);
            require(nft.ownerOf(ids[i]) == msg.sender);
            require(nft.isApprovedForAll(msg.sender, address(this)));
            require(!checkSelling(addrs[i], ids[i]));

            sales[addrs[i]][ids[i]] = Sale({seller: msg.sender, price: prices[i]});
            onSalesIndex[addrs[i]][ids[i]] = onSales[addrs[i]].length;
            onSales[addrs[i]].push(ids[i]);

            uint256 lastIndex = userSellInfoLength(msg.sender);
            userSellInfo[msg.sender].push(PFPInfo({pfp: addrs[i], id: ids[i], price: prices[i]}));
            userSellIndex[addrs[i]][ids[i]] = lastIndex;

            emit Sell(addrs[i], ids[i], msg.sender, prices[i]);
        }
    }

    function changeSellPrice(
        address[] calldata addrs,
        uint256[] calldata ids,
        uint256[] calldata prices
    ) external userWhitelist(msg.sender) {
        require(addrs.length == ids.length && addrs.length == prices.length);
        for (uint256 i = 0; i < addrs.length; i++) {
            Sale storage sale = sales[addrs[i]][ids[i]];
            require(sale.seller == msg.sender);
            sale.price = prices[i];
            userSellInfo[msg.sender][userSellIndex[addrs[i]][ids[i]]].price = prices[i];
            emit ChangeSellPrice(addrs[i], ids[i], msg.sender, prices[i]);
        }
    }

    function removeUserSell(
        address seller,
        address addr,
        uint256 id
    ) internal {
        uint256 lastSellIndex = userSellInfoLength(seller).sub(1);
        uint256 sellIndex = userSellIndex[addr][id];

        if (sellIndex != lastSellIndex) {
            PFPInfo memory lastSellInfo = userSellInfo[seller][lastSellIndex];

            userSellInfo[seller][sellIndex] = lastSellInfo;
            userSellIndex[lastSellInfo.pfp][lastSellInfo.id] = sellIndex;
        }

        userSellInfo[seller].length--;
        delete userSellIndex[addr][id];
    }

    function cancelSale(address[] calldata addrs, uint256[] calldata ids) external {
        require(addrs.length == ids.length);
        for (uint256 i = 0; i < addrs.length; i++) {
            address seller = sales[addrs[i]][ids[i]].seller;
            require(seller == msg.sender);

            removeSale(addrs[i], ids[i]);
            removeUserSell(seller, addrs[i], ids[i]);

            emit CancelSale(addrs[i], ids[i], msg.sender);
        }
    }

    function buy(
        address[] calldata addrs,
        uint256[] calldata ids,
        uint256[] calldata prices,
        uint256[] calldata mileages
    ) external userWhitelist(msg.sender) {
        require(addrs.length == ids.length && addrs.length == prices.length);
        for (uint256 i = 0; i < addrs.length; i++) {
            Sale memory sale = sales[addrs[i]][ids[i]];
            require(sale.seller != address(0) && sale.seller != msg.sender);
            require(sale.price == prices[i]);

            IKIP17(addrs[i]).transferFrom(sale.seller, msg.sender, ids[i]);

            mix.transferFrom(msg.sender, address(this), sale.price.sub(mileages[i]));
            if(mileages[i] > 0) mileage.use(msg.sender, mileages[i]);
            distributeReward(addrs[i], ids[i], msg.sender, sale.seller, sale.price);
            removeUserSell(sale.seller, addrs[i], ids[i]);

            emit Buy(addrs[i], ids[i], msg.sender, sale.price);
        }
    }

    struct OfferInfo {
        address offeror;
        uint256 price;
        uint256 mileage;
    }
    mapping(address => mapping(uint256 => OfferInfo[])) public offers; //offers[addr][id]
    mapping(address => PFPInfo[]) public userOfferInfo; //userOfferInfo[offeror]
    mapping(address => mapping(uint256 => mapping(address => uint256))) private userOfferIndex; //userOfferIndex[addr][id][user]

    function userOfferInfoLength(address offeror) public view returns (uint256) {
        return userOfferInfo[offeror].length;
    }

    function offerCount(address addr, uint256 id) external view returns (uint256) {
        return offers[addr][id].length;
    }

    function makeOffer(
        address addr,
        uint256 id,
        uint256 price,
        uint256 _mileage
    ) external pfpWhitelist(addr) userWhitelist(msg.sender) returns (uint256 offerId) {
        require(price > 0);
        require(IKIP17(addr).ownerOf(id) != msg.sender);

        if (userOfferInfoLength(msg.sender) > 0) {
            PFPInfo storage _pInfo = userOfferInfo[msg.sender][0];
            require(userOfferIndex[addr][id][msg.sender] == 0 && (_pInfo.pfp != addr || _pInfo.id != id));
        }

        OfferInfo[] storage os = offers[addr][id];
        offerId = os.length;

        os.push(OfferInfo({offeror: msg.sender, price: price, mileage: _mileage}));

        mix.transferFrom(msg.sender, address(this), price.sub(_mileage));
        if(_mileage > 0) mileage.use(msg.sender, _mileage);

        uint256 lastIndex = userOfferInfoLength(msg.sender);
        userOfferInfo[msg.sender].push(PFPInfo({pfp: addr, id: id, price: price}));
        userOfferIndex[addr][id][msg.sender] = lastIndex;

        emit MakeOffer(addr, id, offerId, msg.sender, price);
    }

    function removeUserOffer(
        address offeror,
        address addr,
        uint256 id
    ) internal {
        uint256 lastOfferIndex = userOfferInfoLength(offeror).sub(1);
        uint256 offerIndex = userOfferIndex[addr][id][offeror];

        if (offerIndex != lastOfferIndex) {
            PFPInfo memory lastOfferInfo = userOfferInfo[offeror][lastOfferIndex];

            userOfferInfo[offeror][offerIndex] = lastOfferInfo;
            userOfferIndex[lastOfferInfo.pfp][lastOfferInfo.id][offeror] = offerIndex;
        }

        userOfferInfo[offeror].length--;
        delete userOfferIndex[addr][id][offeror];
    }

    function cancelOffer(
        address addr,
        uint256 id,
        uint256 offerId
    ) external {
        OfferInfo[] storage os = offers[addr][id];
        OfferInfo memory _offer = os[offerId];
        require(_offer.offeror == msg.sender);
        delete os[offerId];
        removeUserOffer(msg.sender, addr, id);
        mix.transfer(msg.sender, _offer.price.sub(_offer.mileage));
        if(_offer.mileage > 0) {
            mix.approve(address(mileage), _offer.mileage);
            mileage.charge(msg.sender, _offer.mileage);
        }

        emit CancelOffer(addr, id, offerId, msg.sender);
    }

    function acceptOffer(
        address addr,
        uint256 id,
        uint256 offerId
    ) external userWhitelist(msg.sender) {
        OfferInfo[] storage os = offers[addr][id];
        OfferInfo memory _offer = os[offerId];
        require(_offer.offeror != msg.sender);

        IKIP17(addr).transferFrom(msg.sender, _offer.offeror, id);
        uint256 price = _offer.price;
        delete os[offerId];

        distributeReward(addr, id, _offer.offeror, msg.sender, price);
        removeUserOffer(_offer.offeror, addr, id);
        emit AcceptOffer(addr, id, offerId, msg.sender);
    }

    struct AuctionInfo {
        address seller;
        uint256 startPrice;
        uint256 endBlock;
    }
    mapping(address => mapping(uint256 => AuctionInfo)) public auctions; //auctions[addr][id]
    mapping(address => uint256[]) public onAuctions;
    mapping(address => mapping(uint256 => uint256)) public onAuctionsIndex;
    mapping(address => PFPInfo[]) public userAuctionInfo; //userAuctionInfo[seller]
    mapping(address => mapping(uint256 => uint256)) private userAuctionIndex; //userAuctionIndex[addr][id]

    function onAuctionsCount(address addr) public view returns (uint256) {
        return onAuctions[addr].length;
    }

    function userAuctionInfoLength(address seller) public view returns (uint256) {
        return userAuctionInfo[seller].length;
    }

    function checkAuction(address addr, uint256 id) public view returns (bool) {
        return auctions[addr][id].seller != address(0);
    }

    function createAuction(
        address addr,
        uint256 id,
        uint256 startPrice,
        uint256 endBlock
    ) external pfpWhitelist(addr) userWhitelist(msg.sender) {
        IKIP17 nft = IKIP17(addr);
        require(nft.ownerOf(id) == msg.sender);
        require(endBlock > block.number);
        require(!checkSelling(addr, id));
        nft.transferFrom(msg.sender, address(this), id);

        auctions[addr][id] = AuctionInfo({seller: msg.sender, startPrice: startPrice, endBlock: endBlock});
        onAuctionsIndex[addr][id] = onAuctions[addr].length;
        onAuctions[addr].push(id);

        uint256 lastIndex = userAuctionInfoLength(msg.sender);
        userAuctionInfo[msg.sender].push(PFPInfo({pfp: addr, id: id, price: startPrice}));
        userAuctionIndex[addr][id] = lastIndex;

        emit CreateAuction(addr, id, msg.sender, startPrice, endBlock);
    }

    function removeUserAuction(
        address seller,
        address addr,
        uint256 id
    ) internal {
        uint256 lastAuctionIndex = userAuctionInfoLength(seller).sub(1);
        uint256 sellIndex = userAuctionIndex[addr][id];

        if (sellIndex != lastAuctionIndex) {
            PFPInfo memory lastAuctionInfo = userAuctionInfo[seller][lastAuctionIndex];

            userAuctionInfo[seller][sellIndex] = lastAuctionInfo;
            userAuctionIndex[lastAuctionInfo.pfp][lastAuctionInfo.id] = sellIndex;
        }

        userAuctionInfo[seller].length--;
        delete userAuctionIndex[addr][id];
    }

    function cancelAuction(address addr, uint256 id) external {
        require(biddings[addr][id].length == 0);

        address seller = auctions[addr][id].seller;
        require(seller == msg.sender);

        IKIP17(addr).transferFrom(address(this), seller, id);

        removeAuction(addr, id);
        removeUserAuction(seller, addr, id);

        emit CancelAuction(addr, id, msg.sender);
    }

    struct Bidding {
        address bidder;
        uint256 price;
        uint256 mileage;
    }
    mapping(address => mapping(uint256 => Bidding[])) public biddings; //bidding[addr][id]
    mapping(address => PFPInfo[]) public userBiddingInfo; //userBiddingInfo[seller]
    mapping(address => mapping(uint256 => uint256)) private userBiddingIndex; //userBiddingIndex[addr][id]

    function userBiddingInfoLength(address bidder) public view returns (uint256) {
        return userBiddingInfo[bidder].length;
    }

    function biddingCount(address addr, uint256 id) external view returns (uint256) {
        return biddings[addr][id].length;
    }

    function bid(
        address addr,
        uint256 id,
        uint256 price,
        uint256 _mileage
    ) external pfpWhitelist(addr) userWhitelist(msg.sender) returns (uint256 biddingId) {
        AuctionInfo storage _auction = auctions[addr][id];
        uint256 endBlock = _auction.endBlock;
        address seller = _auction.seller;
        require(seller != address(0) && seller != msg.sender && block.number < endBlock);

        Bidding[] storage bs = biddings[addr][id];
        biddingId = bs.length;

        if (biddingId == 0) {
            require(_auction.startPrice <= price);
        } else {
            Bidding memory bestBidding = bs[biddingId - 1];
            require(bestBidding.price < price);
            mix.transfer(bestBidding.bidder, bestBidding.price.sub(bestBidding.mileage));
            if(bestBidding.mileage > 0) {
                mix.approve(address(mileage), bestBidding.mileage);
                mileage.charge(bestBidding.bidder, bestBidding.mileage);
            }
            removeUserBidding(bestBidding.bidder, addr, id);
        }

        bs.push(Bidding({bidder: msg.sender, price: price, mileage: _mileage}));

        mix.transferFrom(msg.sender, address(this), price.sub(_mileage));
        if(_mileage > 0) mileage.use(msg.sender, _mileage);

        uint256 lastIndex = userBiddingInfoLength(msg.sender);
        userBiddingInfo[msg.sender].push(PFPInfo({pfp: addr, id: id, price: price}));
        userBiddingIndex[addr][id] = lastIndex;

        if(block.number >= endBlock.sub(auctionExtensionInterval)) {
            _auction.endBlock = endBlock.add(auctionExtensionInterval);
        }

        emit Bid(addr, id, msg.sender, price);
    }

    function removeUserBidding(
        address bidder,
        address addr,
        uint256 id
    ) internal {
        uint256 lastBiddingIndex = userBiddingInfoLength(bidder).sub(1);
        uint256 sellIndex = userBiddingIndex[addr][id];

        if (sellIndex != lastBiddingIndex) {
            PFPInfo memory lastBiddingInfo = userBiddingInfo[bidder][lastBiddingIndex];

            userBiddingInfo[bidder][sellIndex] = lastBiddingInfo;
            userBiddingIndex[lastBiddingInfo.pfp][lastBiddingInfo.id] = sellIndex;
        }

        userBiddingInfo[bidder].length--;
        delete userBiddingIndex[addr][id];
    }

    function claim(address addr, uint256 id) external {
        AuctionInfo memory _auction = auctions[addr][id];
        Bidding[] memory bs = biddings[addr][id];
        Bidding memory bidding = bs[bs.length.sub(1)];

        require(block.number >= _auction.endBlock);

        IKIP17(addr).transferFrom(address(this), bidding.bidder, id);

        distributeReward(addr, id, bidding.bidder, _auction.seller, bidding.price);
        removeUserAuction(_auction.seller, addr, id);
        removeUserBidding(bidding.bidder, addr, id);

        emit Claim(addr, id, bidding.bidder, bidding.price);
    }

    //"cancel" functions with ownership
    function cancelSaleByOwner(address[] calldata addrs, uint256[] calldata ids) external onlyOwner {
        require(addrs.length == ids.length);
        for (uint256 i = 0; i < addrs.length; i++) {
            address seller = sales[addrs[i]][ids[i]].seller;

            removeSale(addrs[i], ids[i]);
            removeUserSell(seller, addrs[i], ids[i]);

            emit CancelSale(addrs[i], ids[i], seller);
            emit CancelSaleByOwner(addrs[i], ids[i]);
        }
    }

    function cancelOfferByOwner(
        address[] calldata addrs,
        uint256[] calldata ids,
        uint256[] calldata offerIds
    ) external onlyOwner {
        require(addrs.length == ids.length && addrs.length == offerIds.length);
        for (uint256 i = 0; i < addrs.length; i++) {
            OfferInfo[] storage os = offers[addrs[i]][ids[i]];
            OfferInfo memory _offer = os[offerIds[i]];

            delete os[offerIds[i]];
            removeUserOffer(_offer.offeror, addrs[i], ids[i]);
            mix.transfer(_offer.offeror, _offer.price.sub(_offer.mileage));
            if(_offer.mileage > 0) {
                mix.approve(address(mileage), _offer.mileage);
                mileage.charge(_offer.offeror, _offer.mileage);
            }

            emit CancelOffer(addrs[i], ids[i], offerIds[i], _offer.offeror);
            emit CancelOfferByOwner(addrs[i], ids[i], offerIds[i]);
        }
    }

    function cancelAuctionByOwner(address[] calldata addrs, uint256[] calldata ids) external onlyOwner {
        require(addrs.length == ids.length);
        for (uint256 i = 0; i < addrs.length; i++) {
            AuctionInfo memory _auction = auctions[addrs[i]][ids[i]];
            Bidding[] memory bs = biddings[addrs[i]][ids[i]];

            if (bs.length > 0) {
                Bidding memory bestBidding = bs[bs.length - 1];
                mix.transfer(bestBidding.bidder, bestBidding.price.sub(bestBidding.mileage));
                if(bestBidding.mileage > 0) {
                    mix.approve(address(mileage), bestBidding.mileage);
                    mileage.charge(bestBidding.bidder, bestBidding.mileage);
                }
                removeUserBidding(bestBidding.bidder, addrs[i], ids[i]);
                delete biddings[addrs[i]][ids[i]];
            }

            IKIP17(addrs[i]).transferFrom(address(this), _auction.seller, ids[i]);

            removeAuction(addrs[i], ids[i]);
            removeUserAuction(_auction.seller, addrs[i], ids[i]);

            emit CancelAuction(addrs[i], ids[i], _auction.seller);
            emit CancelAuctionByOwner(addrs[i], ids[i]);
        }
    }
}
