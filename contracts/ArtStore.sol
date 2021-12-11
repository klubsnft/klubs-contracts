pragma solidity ^0.5.6;

import "./klaytn-contracts/ownership/Ownable.sol";
import "./klaytn-contracts/math/SafeMath.sol";
import "./klaytn-contracts/token/KIP17/IKIP17.sol";
import "./interfaces/IArtStore.sol";
import "./interfaces/IArtists.sol";
import "./interfaces/IMix.sol";
import "./interfaces/IMileage.sol";
import "./Arts.sol";

contract ArtStore is Ownable, IArtStore {
    using SafeMath for uint256;

    struct ArtInfo {
        uint256 id;
        uint256 price;
    }

    uint256 public fee = 250;
    address public feeReceiver;
    uint256 public auctionExtensionInterval = 300;

    IArtists public artists;
    Arts public arts;
    IMix public mix;
    IMileage public mileage;

    constructor(IArtists _artists, Arts _arts, IMix _mix, IMileage _mileage) public {
        feeReceiver = msg.sender;
        artists = _artists;
        arts = _arts;
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

    function setArtists(IArtists _artists) external onlyOwner {
        artists = _artists;
    }

    function setArts(Arts _arts) external onlyOwner {
        arts = _arts;
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
        uint256[] calldata ids,
        address[] calldata to
    ) external userWhitelist(msg.sender) {
        require(ids.length == to.length);
        for (uint256 i = 0; i < ids.length; i++) {
            require(arts.isBanned(ids[i]) != true);
            arts.safeTransferFrom(msg.sender, to[i], ids[i]);
        }
    }

    function removeSale(uint256 id) private {
        if (checkSelling(id) == true) {
            uint256 lastIndex = onSalesCount().sub(1);
            uint256 index = onSalesIndex[id];
            if (index != lastIndex) {
                uint256 last = onSales[lastIndex];
                onSales[index] = last;
                onSalesIndex[last] = index;
            }
            onSales.length--;
            delete onSalesIndex[id];
        }
        delete sales[id];
    }

    function removeAuction(uint256 id) private {
        if (checkAuction(id) == true) {
            uint256 lastIndex = onAuctionsCount().sub(1);
            uint256 index = onAuctionsIndex[id];
            if (index != lastIndex) {
                uint256 last = onAuctions[lastIndex];
                onAuctions[index] = last;
                onAuctionsIndex[last] = index;
            }
            onAuctions.length--;
            delete onAuctionsIndex[id];
        }
        delete auctions[id];
    }

    function distributeReward(
        uint256 id,
        address buyer,
        address to,
        uint256 amount
    ) private {

        address artist = arts.artToArtist(id);
        if (arts.mileageMode(id)) {
            if (artists.onlyKlubsMembership(artist)) {

                uint256 halfMileage = amount.mul(mileage.mileagePercent()).div(1e4).div(2);

                uint256 _fee = amount.mul(fee).div(1e4);
                if (_fee > halfMileage) {
                    mix.transfer(feeReceiver, _fee.sub(halfMileage));
                    mix.approve(address(mileage), halfMileage);
                    mileage.charge(buyer, halfMileage);
                } else if (_fee > 0) {
                    mix.approve(address(mileage), _fee);
                    mileage.charge(buyer, _fee);
                }

                uint256 royalty = arts.royalties(id);
                uint256 _royalty = amount.mul(royalty).div(1e4);
                if (_royalty > halfMileage) {
                    mix.transfer(artist, _royalty.sub(halfMileage));
                    mix.approve(address(mileage), halfMileage);
                    mileage.charge(buyer, halfMileage);
                } else if (_royalty > 0) {
                    mix.approve(address(mileage), _royalty);
                    mileage.charge(buyer, _royalty);
                }

                mix.transfer(to, amount.sub(_fee).sub(_royalty));
            }

            else {
                uint256 _fee = amount.mul(fee).div(1e4);
                if (_fee > 0) mix.transfer(feeReceiver, _fee);

                uint256 _mileage = amount.mul(mileage.mileagePercent()).div(1e4);

                uint256 royalty = arts.royalties(id);
                uint256 _royalty = amount.mul(royalty).div(1e4);
                if (_royalty > _mileage) {
                    mix.transfer(artist, _royalty.sub(_mileage));
                    mix.approve(address(mileage), _mileage);
                    mileage.charge(buyer, _mileage);
                } else if (_royalty > 0) {
                    mix.approve(address(mileage), _royalty);
                    mileage.charge(buyer, _royalty);
                }

                mix.transfer(to, amount.sub(_fee).sub(_royalty));
            }
        }

        else {
            uint256 _fee = amount.mul(fee).div(1e4);
            if (_fee > 0) mix.transfer(feeReceiver, _fee);

            uint256 royalty = arts.royalties(id);
            uint256 _royalty = amount.mul(royalty).div(1e4);
            if (_royalty > 0) mix.transfer(artist, _royalty);

            mix.transfer(to, amount.sub(_fee).sub(_royalty));
        }

        removeSale(id);
        removeAuction(id);
        delete biddings[id];
    }

    struct Sale {
        address seller;
        uint256 price;
    }
    mapping(uint256 => Sale) public sales; //sales[id]
    uint256[] public onSales;
    mapping(uint256 => uint256) public onSalesIndex;
    mapping(address => ArtInfo[]) public userSellInfo; //userSellInfo[seller]
    mapping(uint256 => uint256) private userSellIndex; //userSellIndex[id]

    function onSalesCount() public view returns (uint256) {
        return onSales.length;
    }

    function userSellInfoLength(address seller) public view returns (uint256) {
        return userSellInfo[seller].length;
    }

    function checkSelling(uint256 id) public view returns (bool) {
        return sales[id].seller != address(0);
    }

    function sell(
        uint256[] calldata ids,
        uint256[] calldata prices
    ) external userWhitelist(msg.sender) {
        require(ids.length == prices.length);
        for (uint256 i = 0; i < ids.length; i++) {
            require(arts.isBanned(ids[i]) != true);
            require(prices[i] > 0);

            require(arts.ownerOf(ids[i]) == msg.sender);
            require(arts.isApprovedForAll(msg.sender, address(this)));

            sales[ids[i]] = Sale({seller: msg.sender, price: prices[i]});
            onSalesIndex[ids[i]] = onSales.length;
            onSales.push(ids[i]);

            uint256 lastIndex = userSellInfoLength(msg.sender);
            userSellInfo[msg.sender].push(ArtInfo({id: ids[i], price: prices[i]}));
            userSellIndex[ids[i]] = lastIndex;

            emit Sell(ids[i], msg.sender, prices[i]);
        }
    }

    function changeSellPrice(
        uint256[] calldata ids,
        uint256[] calldata prices
    ) external userWhitelist(msg.sender) {
        require(ids.length == prices.length);
        for (uint256 i = 0; i < ids.length; i++) {
            Sale storage sale = sales[ids[i]];
            require(sale.seller == msg.sender);
            sale.price = prices[i];
            userSellInfo[msg.sender][userSellIndex[ids[i]]].price = prices[i];
            emit ChangeSellPrice(ids[i], msg.sender, prices[i]);
        }
    }

    function removeUserSell(
        address seller,
        uint256 id
    ) internal {
        uint256 lastSellIndex = userSellInfoLength(seller).sub(1);
        uint256 sellIndex = userSellIndex[id];

        if (sellIndex != lastSellIndex) {
            ArtInfo memory lastSellInfo = userSellInfo[seller][lastSellIndex];

            userSellInfo[seller][sellIndex] = lastSellInfo;
            userSellIndex[lastSellInfo.id] = sellIndex;
        }

        userSellInfo[seller].length--;
        delete userSellIndex[id];
    }

    function cancelSale(uint256[] calldata ids) external {
        for (uint256 i = 0; i < ids.length; i++) {
            address seller = sales[ids[i]].seller;
            require(seller == msg.sender);

            removeSale(ids[i]);
            removeUserSell(seller, ids[i]);

            emit CancelSale(ids[i], msg.sender);
        }
    }

    function buy(
        uint256[] calldata ids,
        uint256[] calldata prices,
        uint256[] calldata mileages
    ) external userWhitelist(msg.sender) {
        require(ids.length == prices.length);
        for (uint256 i = 0; i < ids.length; i++) {
            Sale memory sale = sales[ids[i]];
            require(sale.seller != address(0) && sale.seller != msg.sender);
            require(sale.price == prices[i]);

            arts.safeTransferFrom(sale.seller, msg.sender, ids[i]);

            mix.transferFrom(msg.sender, address(this), sale.price.sub(mileages[i]));
            if(mileages[i] > 0) mileage.use(msg.sender, mileages[i]);
            distributeReward(ids[i], msg.sender, sale.seller, sale.price);
            removeUserSell(sale.seller, ids[i]);

            emit Buy(ids[i], msg.sender, sale.price);
        }
    }

    struct OfferInfo {
        address offeror;
        uint256 price;
        uint256 mileage;
    }
    mapping(uint256 => OfferInfo[]) public offers; //offers[id]
    mapping(address => ArtInfo[]) public userOfferInfo; //userOfferInfo[offeror]
    mapping(uint256 => mapping(address => uint256)) private userOfferIndex; //userOfferIndex[id][user]

    function userOfferInfoLength(address offeror) public view returns (uint256) {
        return userOfferInfo[offeror].length;
    }

    function offerCount(uint256 id) external view returns (uint256) {
        return offers[id].length;
    }

    function makeOffer(
        uint256 id,
        uint256 price,
        uint256 _mileage
    ) external userWhitelist(msg.sender) returns (uint256 offerId) {
        require(price > 0);
        require(arts.ownerOf(id) != msg.sender);

        if (userOfferInfoLength(msg.sender) > 0) {
            ArtInfo storage _pInfo = userOfferInfo[msg.sender][0];
            require(userOfferIndex[id][msg.sender] == 0 && _pInfo.id != id);
        }

        OfferInfo[] storage os = offers[id];
        offerId = os.length;

        os.push(OfferInfo({offeror: msg.sender, price: price, mileage: _mileage}));

        mix.transferFrom(msg.sender, address(this), price.sub(_mileage));
        if(_mileage > 0) mileage.use(msg.sender, _mileage);

        uint256 lastIndex = userOfferInfoLength(msg.sender);
        userOfferInfo[msg.sender].push(ArtInfo({id: id, price: price}));
        userOfferIndex[id][msg.sender] = lastIndex;

        emit MakeOffer(id, offerId, msg.sender, price);
    }

    function removeUserOffer(
        address offeror,
        uint256 id
    ) internal {
        uint256 lastOfferIndex = userOfferInfoLength(offeror).sub(1);
        uint256 offerIndex = userOfferIndex[id][offeror];

        if (offerIndex != lastOfferIndex) {
            ArtInfo memory lastOfferInfo = userOfferInfo[offeror][lastOfferIndex];

            userOfferInfo[offeror][offerIndex] = lastOfferInfo;
            userOfferIndex[lastOfferInfo.id][offeror] = offerIndex;
        }

        userOfferInfo[offeror].length--;
        delete userOfferIndex[id][offeror];
    }

    function cancelOffer(
        uint256 id,
        uint256 offerId
    ) external {
        OfferInfo[] storage os = offers[id];
        OfferInfo memory _offer = os[offerId];
        require(_offer.offeror == msg.sender);
        delete os[offerId];
        removeUserOffer(msg.sender, id);
        mix.transfer(msg.sender, _offer.price.sub(_offer.mileage));
        if(_offer.mileage > 0) {
            mix.approve(address(mileage), _offer.mileage);
            mileage.charge(msg.sender, _offer.mileage);
        }

        emit CancelOffer(id, offerId, msg.sender);
    }

    function acceptOffer(
        uint256 id,
        uint256 offerId
    ) external userWhitelist(msg.sender) {
        OfferInfo[] storage os = offers[id];
        OfferInfo memory _offer = os[offerId];
        require(_offer.offeror != msg.sender);

        arts.safeTransferFrom(msg.sender, _offer.offeror, id);
        uint256 price = _offer.price;
        delete os[offerId];

        distributeReward(id, _offer.offeror, msg.sender, price);
        removeUserOffer(_offer.offeror, id);
        emit AcceptOffer(id, offerId, msg.sender);
    }

    struct AuctionInfo {
        address seller;
        uint256 startPrice;
        uint256 endBlock;
    }
    mapping(uint256 => AuctionInfo) public auctions; //auctions[id]
    uint256[] public onAuctions;
    mapping(uint256 => uint256) public onAuctionsIndex;
    mapping(address => ArtInfo[]) public userAuctionInfo; //userAuctionInfo[seller]
    mapping(uint256 => uint256) private userAuctionIndex; //userAuctionIndex[id]

    function onAuctionsCount() public view returns (uint256) {
        return onAuctions.length;
    }

    function userAuctionInfoLength(address seller) public view returns (uint256) {
        return userAuctionInfo[seller].length;
    }

    function checkAuction(uint256 id) public view returns (bool) {
        return auctions[id].seller != address(0);
    }

    function createAuction(
        uint256 id,
        uint256 startPrice,
        uint256 endBlock
    ) external userWhitelist(msg.sender) {
        require(arts.ownerOf(id) == msg.sender);
        require(endBlock > block.number);
        arts.transferFrom(msg.sender, address(this), id);

        auctions[id] = AuctionInfo({seller: msg.sender, startPrice: startPrice, endBlock: endBlock});
        onAuctionsIndex[id] = onAuctions.length;
        onAuctions.push(id);

        uint256 lastIndex = userAuctionInfoLength(msg.sender);
        userAuctionInfo[msg.sender].push(ArtInfo({id: id, price: startPrice}));
        userAuctionIndex[id] = lastIndex;

        emit CreateAuction(id, msg.sender, startPrice, endBlock);
    }

    function removeUserAuction(
        address seller,
        uint256 id
    ) internal {
        uint256 lastAuctionIndex = userAuctionInfoLength(seller).sub(1);
        uint256 sellIndex = userAuctionIndex[id];

        if (sellIndex != lastAuctionIndex) {
            ArtInfo memory lastAuctionInfo = userAuctionInfo[seller][lastAuctionIndex];

            userAuctionInfo[seller][sellIndex] = lastAuctionInfo;
            userAuctionIndex[lastAuctionInfo.id] = sellIndex;
        }

        userAuctionInfo[seller].length--;
        delete userAuctionIndex[id];
    }

    function cancelAuction(uint256 id) external {
        require(biddings[id].length == 0);

        address seller = auctions[id].seller;
        require(seller == msg.sender);

        arts.transferFrom(address(this), seller, id);

        removeAuction(id);
        removeUserAuction(seller, id);

        emit CancelAuction(id, msg.sender);
    }

    struct Bidding {
        address bidder;
        uint256 price;
        uint256 mileage;
    }
    mapping(uint256 => Bidding[]) public biddings; //bidding[id]
    mapping(address => ArtInfo[]) public userBiddingInfo; //userBiddingInfo[seller]
    mapping(uint256 => uint256) private userBiddingIndex; //userBiddingIndex[id]

    function userBiddingInfoLength(address bidder) public view returns (uint256) {
        return userBiddingInfo[bidder].length;
    }

    function biddingCount(uint256 id) external view returns (uint256) {
        return biddings[id].length;
    }

    function bid(
        uint256 id,
        uint256 price,
        uint256 _mileage
    ) external userWhitelist(msg.sender) returns (uint256 biddingId) {
        AuctionInfo storage _auction = auctions[id];
        uint256 endBlock = _auction.endBlock;
        address seller = _auction.seller;
        require(seller != address(0) && seller != msg.sender && block.number < endBlock);

        Bidding[] storage bs = biddings[id];
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
            removeUserBidding(bestBidding.bidder, id);
        }

        bs.push(Bidding({bidder: msg.sender, price: price, mileage: _mileage}));

        mix.transferFrom(msg.sender, address(this), price.sub(_mileage));
        if(_mileage > 0) mileage.use(msg.sender, _mileage);

        uint256 lastIndex = userBiddingInfoLength(msg.sender);
        userBiddingInfo[msg.sender].push(ArtInfo({id: id, price: price}));
        userBiddingIndex[id] = lastIndex;

        if(block.number >= endBlock.sub(auctionExtensionInterval)) {
            _auction.endBlock = endBlock.add(auctionExtensionInterval);
        }

        emit Bid(id, msg.sender, price);
    }

    function removeUserBidding(
        address bidder,
        uint256 id
    ) internal {
        uint256 lastBiddingIndex = userBiddingInfoLength(bidder).sub(1);
        uint256 sellIndex = userBiddingIndex[id];

        if (sellIndex != lastBiddingIndex) {
            ArtInfo memory lastBiddingInfo = userBiddingInfo[bidder][lastBiddingIndex];

            userBiddingInfo[bidder][sellIndex] = lastBiddingInfo;
            userBiddingIndex[lastBiddingInfo.id] = sellIndex;
        }

        userBiddingInfo[bidder].length--;
        delete userBiddingIndex[id];
    }

    function claim(uint256 id) external {
        AuctionInfo memory _auction = auctions[id];
        Bidding[] memory bs = biddings[id];
        Bidding memory bidding = bs[bs.length.sub(1)];

        require(block.number >= _auction.endBlock);

        arts.safeTransferFrom(address(this), bidding.bidder, id);

        distributeReward(id, bidding.bidder, _auction.seller, bidding.price);
        removeUserAuction(_auction.seller, id);
        removeUserBidding(bidding.bidder, id);

        emit Claim(id, bidding.bidder, bidding.price);
    }

    //"cancel" functions with ownership
    function cancelSaleByOwner(uint256[] calldata ids) external onlyOwner {
        for (uint256 i = 0; i < ids.length; i++) {
            address seller = sales[ids[i]].seller;

            removeSale(ids[i]);
            removeUserSell(seller, ids[i]);

            emit CancelSale(ids[i], seller);
            emit CancelSaleByOwner(ids[i]);
        }
    }

    function cancelOfferByOwner(
        uint256[] calldata ids,
        uint256[] calldata offerIds
    ) external onlyOwner {
        require(ids.length == offerIds.length);
        for (uint256 i = 0; i < ids.length; i++) {
            OfferInfo[] storage os = offers[ids[i]];
            OfferInfo memory _offer = os[offerIds[i]];

            delete os[offerIds[i]];
            removeUserOffer(_offer.offeror, ids[i]);
            mix.transfer(_offer.offeror, _offer.price.sub(_offer.mileage));
            if(_offer.mileage > 0) {
                mix.approve(address(mileage), _offer.mileage);
                mileage.charge(_offer.offeror, _offer.mileage);
            }

            emit CancelOffer(ids[i], offerIds[i], _offer.offeror);
            emit CancelOfferByOwner(ids[i], offerIds[i]);
        }
    }

    function cancelAuctionByOwner(uint256[] calldata ids) external onlyOwner {
        for (uint256 i = 0; i < ids.length; i++) {
            AuctionInfo memory _auction = auctions[ids[i]];
            Bidding[] memory bs = biddings[ids[i]];

            if (bs.length > 0) {
                Bidding memory bestBidding = bs[bs.length - 1];
                mix.transfer(bestBidding.bidder, bestBidding.price.sub(bestBidding.mileage));
                if(bestBidding.mileage > 0) {
                    mix.approve(address(mileage), bestBidding.mileage);
                    mileage.charge(bestBidding.bidder, bestBidding.mileage);
                }
                removeUserBidding(bestBidding.bidder, ids[i]);
                delete biddings[ids[i]];
            }

            arts.transferFrom(address(this), _auction.seller, ids[i]);

            removeAuction(ids[i]);
            removeUserAuction(_auction.seller, ids[i]);

            emit CancelAuction(ids[i], _auction.seller);
            emit CancelAuctionByOwner(ids[i]);
        }
    }
}
