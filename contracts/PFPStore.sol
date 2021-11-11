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

    uint256 public fee = 25;
    address public feeReceiver;

    IPFPs public pfps;
    IMix public mix;

    constructor(IPFPs _pfps, IMix _mix) public {
        feeReceiver = msg.sender;
        pfps = _pfps;
        mix = _mix;
    }

    function setFee(uint256 _fee) external onlyOwner {
        require(fee < 9 * 1e3); //max 90%
        fee = _fee;
    }

    function setFeeReceiver(address _receiver) external onlyOwner {
        feeReceiver = _receiver;
    }

    function setPFPs(IPFPs _pfps) external onlyOwner {
        pfps = _pfps;
    }

    modifier whitelist(address addr) {
        require(pfps.added(addr) && !pfps.banned(addr));
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
    mapping(address => mapping(uint256 => Sale)) public sales;      //sales[addr][id]
    mapping(address => PFPInfo[]) public userSellInfo;              //userSellInfo[seller]
    mapping(address => mapping(uint256 => uint256)) private userSellIndex;   //userSellIndex[addr][id]

    function userSellInfoLength(address seller) public view returns (uint256) {
        return userSellInfo[seller].length;
    }

    function checkSelling(address addr, uint256 id) external view returns (bool) {
        return sales[addr][id].seller != address(0);
    }

    function sell(
        address addr,
        uint256 id,
        uint256 price
    ) external whitelist(addr) {
        require(price > 0);

        IKIP17 nft = IKIP17(addr);
        require(nft.ownerOf(id) == msg.sender);
        nft.transferFrom(msg.sender, address(this), id);

        sales[addr][id] = Sale({seller: msg.sender, price: price});

        uint256 lastIndex = userSellInfoLength(msg.sender);
        userSellInfo[msg.sender].push(PFPInfo({pfp: addr, id: id, price: price}));
        userSellIndex[addr][id] = lastIndex;

        emit Sell(addr, id, msg.sender, price);
    }

    function removeUserSell(address seller, address addr, uint256 id) internal {
        uint256 lastSellIndex = userSellInfoLength(seller);
        uint256 sellIndex = userSellIndex[addr][id];

        if (sellIndex != lastSellIndex) {
            PFPInfo memory lastSellInfo = userSellInfo[seller][lastSellIndex.sub(1)];

            userSellInfo[seller][sellIndex] = lastSellInfo;
            userSellIndex[lastSellInfo.pfp][lastSellInfo.id] = sellIndex;
        }

        userSellInfo[seller].length--;
        delete userSellIndex[addr][id];
    }

    function cancelSale(address addr, uint256 id) external {
        address seller = sales[addr][id].seller;
        require(seller == msg.sender);

        IKIP17(addr).transferFrom(address(this), seller, id);
        delete sales[addr][id];
        removeUserSell(seller, addr, id);

        emit CancelSale(addr, id, msg.sender);
    }

    function buy(address addr, uint256 id) external {
        Sale memory sale = sales[addr][id];
        require(sale.seller != address(0));

        IKIP17(addr).safeTransferFrom(address(this), msg.sender, id);

        mix.transferFrom(msg.sender, address(this), sale.price);
        distributeReward(addr, id, sale.seller, sale.price);
        removeUserSell(sale.seller, addr, id);

        emit Buy(addr, id, msg.sender, sale.price);
    }

    struct OfferInfo {
        address offeror;
        uint256 price;
    }
    mapping(address => mapping(uint256 => OfferInfo[])) public offers;      //offers[addr][id]
    mapping(address => PFPInfo[]) public userOfferInfo;                     //userOfferInfo[offeror]
    mapping(address => mapping(uint256 => uint256)) private userOfferIndex;   //userOfferIndex[addr][id]

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
    ) external whitelist(addr) returns (uint256 offerId) {
        require(price > 0);

        OfferInfo[] storage os = offers[addr][id];
        offerId = os.length;

        os.push(OfferInfo({offeror: msg.sender, price: price}));

        mix.transferFrom(msg.sender, address(this), price);

        uint256 lastIndex = userOfferInfoLength(msg.sender);
        userOfferInfo[msg.sender].push(PFPInfo({pfp: addr, id: id, price: price}));
        userOfferIndex[addr][id] = lastIndex;

        emit MakeOffer(addr, id, offerId, msg.sender, price);
    }

    function removeUserOffer(address offeror, address addr, uint256 id) internal {
        uint256 lastOfferIndex = userOfferInfoLength(offeror);
        uint256 offerIndex = userOfferIndex[addr][id];

        if (offerIndex != lastOfferIndex) {
            PFPInfo memory lastOfferInfo = userOfferInfo[offeror][lastOfferIndex.sub(1)];

            userOfferInfo[offeror][offerIndex] = lastOfferInfo;
            userOfferIndex[lastOfferInfo.pfp][lastOfferInfo.id] = offerIndex;
        }

        userOfferInfo[offeror].length--;
        delete userOfferIndex[addr][id];
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
    ) external {
        OfferInfo[] storage os = offers[addr][id];
        OfferInfo memory _offer = os[offerId];

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
    mapping(address => mapping(uint256 => AuctionInfo)) public auctions;        //auctions[addr][id]
    mapping(address => PFPInfo[]) public userAuctionInfo;                       //userAuctionInfo[seller]
    mapping(address => mapping(uint256 => uint256)) private userAuctionIndex;   //userAuctionIndex[addr][id]

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
    ) external whitelist(addr) {
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

    function removeUserAuction(address seller, address addr, uint256 id) internal {
        uint256 lastAuctionIndex = userAuctionInfoLength(seller);
        uint256 sellIndex = userAuctionIndex[addr][id];

        if (sellIndex != lastAuctionIndex) {
            PFPInfo memory lastAuctionInfo = userAuctionInfo[seller][lastAuctionIndex.sub(1)];

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
    mapping(address => mapping(uint256 => Bidding[])) public biddings;      //bidding[addr][id]
    mapping(address => PFPInfo[]) public userBiddingInfo;                       //userBiddingInfo[seller]
    mapping(address => mapping(uint256 => uint256)) private userBiddingIndex;   //userBiddingIndex[addr][id]

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
    ) external returns (uint256 biddingId) {
        AuctionInfo memory _auction = auctions[addr][id];
        require(_auction.seller != address(0) && block.number < _auction.endBlock);

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

        emit Bid(addr, id, msg.sender, price);
    }

    function removeUserBidding(address bidder, address addr, uint256 id) internal {
        uint256 lastBiddingIndex = userBiddingInfoLength(bidder);
        uint256 sellIndex = userBiddingIndex[addr][id];

        if (sellIndex != lastBiddingIndex) {
            PFPInfo memory lastBiddingInfo = userBiddingInfo[bidder][lastBiddingIndex.sub(1)];

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
}
