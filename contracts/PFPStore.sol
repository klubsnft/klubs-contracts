pragma solidity ^0.5.6;

import "./klaytn-contracts/ownership/Ownable.sol";
import "./klaytn-contracts/math/SafeMath.sol";
import "./klaytn-contracts/token/KIP17/IKIP17.sol";
import "./interfaces/IPFPStore.sol";
import "./interfaces/IPFPs.sol";
import "./interfaces/IMix.sol";

contract PFPStore is Ownable, IPFPStore {
    using SafeMath for uint256;

    uint256 public fee = 25;
    address public feeReceiver;

    IPFPs public pfps;
    IMix public mix;

    constructor(IPFPs _pfps, IMix _mix) public {
        feeReceiver = msg.sender;
        pfps = _pfps;
        mix = _mix;
    }

    function setFee(uint256 _fee) onlyOwner external {
        require(fee < 9 * 1e3);     //max 90%
        fee = _fee;
    }

    function setFeeReceiver(address _receiver) onlyOwner external {
        feeReceiver = _receiver;
    }

    function setPFPs(address _pfps) onlyOwner external {
        pfps = _pfps;
    }

    modifier whitelist(address addr) {
        require(pfps.banned(addr) != true);
        _;
    }

    function distributeReward(address addr, uint256 id, address to, uint256 amount) private {

        uint256 _fee = amount.mul(fee).div(1e4);
        mix.transfer(feeReceiver, _fee);

        (address receiver, uint256 royalty) = pfps.royalties(addr);
        uint256 _royalty = amount.mul(royalty).div(1e4);
        mix.transfer(receiver, _royalty);

        mix.transfer(to, amount.sub(_fee).sub(_royalty));

        delete sales[addr][id];
        delete auctions[addr][id];
        delete biddings[addr][id];
    }

    struct Sale {
        address seller;
        uint256 price;
    }
    mapping(address => mapping(uint256 => Sale)) public sales;

    function sell(address addr, uint256 id, uint256 price) whitelist(addr) external {
        require(checkAuction(addr, id) != true);

        IKIP17 nft = IKIP17(addr);
        require(nft.ownerOf(id) == msg.sender);
        nft.transferFrom(msg.sender, address(this), id);

        sales[addr][id] = Sale({
            seller: msg.sender,
            price: price
        });

        emit Sell(addr, id, msg.sender, price);
    }

    function checkSelling(address addr, uint256 id) view public returns (bool) {
        return sales[addr][id].seller != address(0);
    }

    function buy(address addr, uint256 id) external {

        Sale memory sale = sales[addr][id];
        require(sale.seller != address(0));

        IKIP17(addr).transferFrom(address(this), msg.sender, id);

        mix.transferFrom(msg.sender, address(this), sale.price);
        distributeReward(addr, id, sale.seller, sale.price);

        emit Buy(addr, id, msg.sender, sale.price);
    }

    function cancelSale(address addr, uint256 id) external {

        address seller = sales[addr][id].seller;
        require(seller == msg.sender);

        IKIP17(addr).transferFrom(address(this), seller, id);

        delete sales[addr][id];

        emit CancelSale(addr, id, msg.sender);
    }

    struct OfferInfo {
        address offeror;
        uint256 price;
    }
    mapping(address => mapping(uint256 => OfferInfo[])) public offers;

    function offerCount(address addr, uint256 id) view external returns (uint256) {
        return offers[addr][id].length;
    }

    function offer(address addr, uint256 id, uint256 price) whitelist(addr) external returns (uint256 offerId) {
        require(price > 0);

        OfferInfo[] storage os = offers[addr][id];
        offerId = os.length;

        os.push(OfferInfo({
            offeror: msg.sender,
            price: price
        }));

        mix.transferFrom(msg.sender, address(this), price);

        emit Offer(addr, id, offerId, msg.sender, price);
    }

    function cancelOffer(address addr, uint256 id, uint256 offerId) external {

        OfferInfo[] storage os = offers[addr][id];
        OfferInfo memory _offer = os[offerId];
        require(_offer.offeror == msg.sender);
        uint256 price = _offer.price;
        delete os[offerId];

        mix.transfer(msg.sender, price);

        emit CancelOffer(addr, id, offerId, _offer.offeror);
    }

    function acceptOffer(address addr, uint256 id, uint256 offerId) external {

        OfferInfo[] storage os = offers[addr][id];
        OfferInfo memory _offer = os[offerId];

        IKIP17(addr).transferFrom(msg.sender, _offer.offeror, id);
        uint256 price = _offer.price;
        delete os[offerId];

        distributeReward(addr, id, msg.sender, price);

        emit AcceptOffer(addr, id, offerId, msg.sender);
    }

    struct AuctionInfo {
        address seller;
        uint256 startPrice;
        uint256 endBlock;
    }
    mapping(address => mapping(uint256 => AuctionInfo)) public auctions;

    function checkAuction(address addr, uint256 id) view public returns (bool) {
        return auctions[addr][id].seller != address(0);
    }

    function auction(address addr, uint256 id, uint256 startPrice, uint256 endBlock) whitelist(addr) public {
        require(checkSelling(addr, id) != true);

        IKIP17 nft = IKIP17(addr);
        require(nft.ownerOf(id) == msg.sender);
        nft.transferFrom(msg.sender, address(this), id);

        auctions[addr][id] = AuctionInfo({
            seller: msg.sender,
            startPrice: startPrice,
            endBlock: endBlock
        });

        emit Auction(addr, id, msg.sender, startPrice, endBlock);
    }

    function cancelAuction(address addr, uint256 id) external {
        require(biddings[addr][id].length == 0);

        address seller = auctions[addr][id].seller;
        require(seller == msg.sender);

        IKIP17(addr).transferFrom(address(this), seller, id);

        delete auctions[addr][id];

        emit CancelAuction(addr, id, msg.sender);
    }
    
    struct Bidding {
        address bidder;
        uint256 price;
    }
    mapping(address => mapping(uint256 => Bidding[])) public biddings;

    function biddingCount(address addr, uint256 id) view external returns (uint256) {
        return biddings[addr][id].length;
    }

    function bid(address addr, uint256 id, uint256 price) external returns (uint256 biddingId) {

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
        }

        bs.push(Bidding({
            bidder: msg.sender,
            price: price
        }));

        mix.transferFrom(msg.sender, address(this), price);

        emit Bid(addr, id, msg.sender, price);
    }

    function claim(address addr, uint256 id) external {

        AuctionInfo memory _auction = auctions[addr][id];
        Bidding[] memory bs = biddings[addr][id];
        Bidding memory bidding = bs[bs.length - 1];

        require(bidding.bidder == msg.sender && block.number >= _auction.endBlock);

        IKIP17(addr).transferFrom(address(this), msg.sender, id);

        distributeReward(addr, id, _auction.seller, bidding.price);

        emit Claim(addr, id, msg.sender, bidding.price);
    }
}
