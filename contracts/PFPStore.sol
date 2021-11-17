pragma solidity ^0.5.6;

import "./klaytn-contracts/ownership/Ownable.sol";
import "./klaytn-contracts/math/SafeMath.sol";
import "./klaytn-contracts/token/KIP17/IKIP17.sol";
import "./interfaces/IPFPStore.sol";
import "./interfaces/IPFPs.sol";
import "./interfaces/IMix.sol";

contract PFPStore is Ownable, IPFPStore {
    using SafeMath for uint256;

    struct PFPInfo {
        address pfp;
        uint256 id;
        uint256 price;
    }

    uint256 public fee = 250;
    address public feeReceiver;
    uint256 public auctionExtensionInterval = 300;

    IPFPs public pfps;
    IMix public mix;

    constructor(IPFPs _pfps, IMix _mix) public {
        feeReceiver = msg.sender;
        pfps = _pfps;
        mix = _mix;
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

    function setPFPs(IPFPs _pfps) external onlyOwner {
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

    function distributeReward(
        address addr,
        uint256 id,
        address to,
        uint256 amount
    ) private {
        uint256 _fee = amount.mul(fee).div(1e4);
        if (_fee > 0) mix.transfer(feeReceiver, _fee);

        (address receiver, uint256 royalty) = pfps.royalties(addr);
        uint256 _royalty = amount.mul(royalty).div(1e4);
        if (_royalty > 0) mix.transfer(receiver, _royalty);

        mix.transfer(to, amount.sub(_fee).sub(_royalty));

        delete sales[addr][id];
        delete auctions[addr][id];
        delete biddings[addr][id];
    }

    struct Sale {
        address seller;
        uint256 price;
    }
    mapping(address => mapping(uint256 => Sale)) public sales; //sales[addr][id]
    mapping(address => PFPInfo[]) public userSellInfo; //userSellInfo[seller]
    mapping(address => mapping(uint256 => uint256)) private userSellIndex; //userSellIndex[addr][id]

    function userSellInfoLength(address seller) public view returns (uint256) {
        return userSellInfo[seller].length;
    }

    function checkSelling(address addr, uint256 id) external view returns (bool) {
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
            nft.transferFrom(msg.sender, address(this), ids[i]);

            sales[addrs[i]][ids[i]] = Sale({seller: msg.sender, price: prices[i]});

            uint256 lastIndex = userSellInfoLength(msg.sender);
            userSellInfo[msg.sender].push(PFPInfo({pfp: addrs[i], id: ids[i], price: prices[i]}));
            userSellIndex[addrs[i]][ids[i]] = lastIndex;

            emit Sell(addrs[i], ids[i], msg.sender, prices[i]);
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

            IKIP17(addrs[i]).transferFrom(address(this), seller, ids[i]);
            delete sales[addrs[i]][ids[i]];
            removeUserSell(seller, addrs[i], ids[i]);

            emit CancelSale(addrs[i], ids[i], msg.sender);
        }
    }

    function buy(address[] calldata addrs, uint256[] calldata ids) external userWhitelist(msg.sender) {
        require(addrs.length == ids.length);
        for (uint256 i = 0; i < addrs.length; i++) {
            Sale memory sale = sales[addrs[i]][ids[i]];
            require(sale.seller != address(0) && sale.seller != msg.sender);

            IKIP17(addrs[i]).safeTransferFrom(address(this), msg.sender, ids[i]);

            mix.transferFrom(msg.sender, address(this), sale.price);
            distributeReward(addrs[i], ids[i], sale.seller, sale.price);
            removeUserSell(sale.seller, addrs[i], ids[i]);

            emit Buy(addrs[i], ids[i], msg.sender, sale.price);
        }
    }

    struct OfferInfo {
        address offeror;
        uint256 price;
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
        uint256 price
    ) external pfpWhitelist(addr) userWhitelist(msg.sender) returns (uint256 offerId) {
        require(price > 0);
        require(IKIP17(addr).ownerOf(id) != msg.sender);

        if (userOfferInfoLength(msg.sender) > 0) {
            PFPInfo storage _pInfo = userOfferInfo[msg.sender][0];
            require(userOfferIndex[addr][id][msg.sender] == 0 && (_pInfo.pfp != addr || _pInfo.id != id));
        }

        OfferInfo[] storage os = offers[addr][id];
        offerId = os.length;

        os.push(OfferInfo({offeror: msg.sender, price: price}));

        mix.transferFrom(msg.sender, address(this), price);

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
        mix.transfer(msg.sender, _offer.price);

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

        IKIP17(addr).safeTransferFrom(msg.sender, _offer.offeror, id);
        uint256 price = _offer.price;
        delete os[offerId];

        distributeReward(addr, id, msg.sender, price);
        removeUserOffer(_offer.offeror, addr, id);
        emit AcceptOffer(addr, id, offerId, msg.sender);
    }

    struct AuctionInfo {
        address seller;
        uint256 startPrice;
        uint256 endBlock;
    }
    mapping(address => mapping(uint256 => AuctionInfo)) public auctions; //auctions[addr][id]
    mapping(address => PFPInfo[]) public userAuctionInfo; //userAuctionInfo[seller]
    mapping(address => mapping(uint256 => uint256)) private userAuctionIndex; //userAuctionIndex[addr][id]

    function userAuctionInfoLength(address seller) public view returns (uint256) {
        return userAuctionInfo[seller].length;
    }

    function checkAuction(address addr, uint256 id) external view returns (bool) {
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
        nft.transferFrom(msg.sender, address(this), id);

        auctions[addr][id] = AuctionInfo({seller: msg.sender, startPrice: startPrice, endBlock: endBlock});

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

        delete auctions[addr][id];
        removeUserAuction(seller, addr, id);

        emit CancelAuction(addr, id, msg.sender);
    }

    struct Bidding {
        address bidder;
        uint256 price;
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
        uint256 price
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
            mix.transfer(bestBidding.bidder, bestBidding.price);
            removeUserBidding(bestBidding.bidder, addr, id);
        }

        bs.push(Bidding({bidder: msg.sender, price: price}));

        mix.transferFrom(msg.sender, address(this), price);

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

        IKIP17(addr).safeTransferFrom(address(this), bidding.bidder, id);

        distributeReward(addr, id, _auction.seller, bidding.price);
        removeUserAuction(_auction.seller, addr, id);
        removeUserBidding(bidding.bidder, addr, id);

        emit Claim(addr, id, bidding.bidder, bidding.price);
    }

    //"cancel" functions with ownership
    function cancelSaleByOwner(address[] calldata addrs, uint256[] calldata ids) external onlyOwner {
        require(addrs.length == ids.length);
        for (uint256 i = 0; i < addrs.length; i++) {
            address seller = sales[addrs[i]][ids[i]].seller;

            IKIP17(addrs[i]).transferFrom(address(this), seller, ids[i]);
            delete sales[addrs[i]][ids[i]];
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
            mix.transfer(_offer.offeror, _offer.price);

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
                mix.transfer(bestBidding.bidder, bestBidding.price);
                removeUserBidding(bestBidding.bidder, addrs[i], ids[i]);
                delete biddings[addrs[i]][ids[i]];
            }

            IKIP17(addrs[i]).transferFrom(address(this), _auction.seller, ids[i]);

            delete auctions[addrs[i]][ids[i]];
            removeUserAuction(_auction.seller, addrs[i], ids[i]);

            emit CancelAuction(addrs[i], ids[i], _auction.seller);
            emit CancelAuctionByOwner(addrs[i], ids[i]);
        }
    }
}
