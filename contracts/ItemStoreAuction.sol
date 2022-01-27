pragma solidity ^0.5.6;

import "./klaytn-contracts/ownership/Ownable.sol";
import "./klaytn-contracts/math/SafeMath.sol";
import "./klaytn-contracts/token/KIP17/IKIP17.sol";
import "./klaytn-contracts/token/KIP37/IKIP37.sol";
import "./libraries/ItemStoreLibrary.sol";
import "./libraries/ERC1155KIP37Holder.sol";
import "./interfaces/IItemStoreAuction.sol";
import "./interfaces/IMetaverses.sol";
import "./interfaces/IMix.sol";
import "./interfaces/IMileage.sol";

contract ItemStoreAuction is Ownable, ERC1155KIP37Holder, IItemStoreAuction {
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
    function _removeAuction(bytes32 auctionVerificationID) private {
        AuctionInfo storage auctionInfo = _auctionInfo[auctionVerificationID];
        address item = auctionInfo.item;
        uint256 id = auctionInfo.id;
        uint256 auctionId = auctionInfo.auctionId;

        Auction storage auction = auctions[item][id][auctionId];

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

        //delete auctions
        uint256 lastAuctionId = auctions[item][id].length.sub(1);
        Auction memory lastAuction = auctions[item][id][lastAuctionId];
        if (auctionId != lastAuctionId) {
            auctions[item][id][auctionId] = lastAuction;
            _auctionInfo[lastAuction.verificationID].auctionId = auctionId;
        }
        auctions[item][id].length--;
        delete _auctionInfo[auctionVerificationID];
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

    mapping(address => bytes32[]) public onAuctions; //onAuctions[item]. 아이템 계약 중 onAuction 중인 정보들. "return auctionsVerificationID."
    mapping(bytes32 => uint256) private _onAuctionsIndex; //_onAuctionsIndex[auctionVerificationID]. 특정 옥션의 onAuctions index.

    mapping(address => bytes32[]) public userAuctionInfo; //userAuctionInfo[seller] 셀러의 옥션들 정보. "return auctionsVerificationID."
    mapping(bytes32 => uint256) private _userAuctionIndex; //_userAuctionIndex[auctionVerificationID]. 특정 옥션의 userAuctionInfo index.

    mapping(uint256 => bytes32[]) public auctionsOnMetaverse; //auctionsOnMetaverse[metaverseId]. 특정 메타버스의 모든 옥션들. "return auctionsVerificationID."
    mapping(bytes32 => uint256) private _auctionsOnMvIndex; //_auctionsOnMvIndex[auctionVerificationID]. 특정 옥션의 auctionsOnMetaverse index.

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
        if (!commonData.isItemWhitelisted(metaverseId, item)) return false;

        if (item._isERC1155(commonData.metaverses(), metaverseId)) {
            return (amount != 0) && (IKIP37(item).balanceOf(seller, id) >= amount);
        } else {
            return (amount == 1) && (IKIP17(item).ownerOf(id) == seller);
        }
    }

    function createAuction(
        uint256 metaverseId,
        address item,
        uint256 id,
        uint256 amount,
        uint256 startTotalPrice,
        uint256 endBlock
    ) external returns (uint256 auctionId) {
        require(!commonData.isBannedUser(msg.sender));
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

        item._transferItems(commonData.metaverses(), metaverseId, id, amount, msg.sender, address(this));

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
        item._transferItems(commonData.metaverses(), metaverseId, id, auction.amount, address(this), msg.sender);
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

    mapping(address => BiddingInfo[]) public userBiddingInfo; //userBiddingInfo[bidder] 비더의 비딩들 정보.   "return BiddingInfo"
    mapping(address => mapping(bytes32 => uint256)) private _userBiddingIndex;

    //_userBiddingIndex[bidder][auctionVerificationID]. 특정 유저가 특정 옥션에 최종 입찰 중인 비딩의 userBiddingInfo index.

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

        if (!commonData.isItemWhitelisted(auction.metaverseId, item)) return false;

        address seller = auction.seller;
        if (seller == address(0) || seller == bidder) return false;
        if (auction.endBlock <= block.number) return false;

        Bidding[] storage bs = biddings[auctionVerificationID];
        uint256 biddingLength = bs.length;
        if (biddingLength == 0) {
            return (auction.startTotalPrice <= price);
        } else {
            return (bs[biddingLength - 1].price < price);
        }
    }

    function bid(
        bytes32 auctionVerificationID,
        uint256 price,
        uint256 _mileage
    ) external returns (uint256 biddingId) {
        require(!commonData.isBannedUser(msg.sender));
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
            uint256 auctionExtensionInterval = commonData.auctionExtensionInterval();

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

        uint256 bestBiddingId;
        address bestBidder;
        uint256 bestBiddingPrice;
        {
            Bidding[] storage bs = biddings[auctionVerificationID];
            bestBiddingId = bs.length.sub(1);
            Bidding storage bestBidding = bs[bestBiddingId];

            bestBidder = bestBidding.bidder;
            bestBiddingPrice = bestBidding.price;
        }

        require(block.number >= auction.endBlock);

        IMetaverses metaverses = commonData.metaverses();
        item._transferItems(metaverses, metaverseId, id, amount, address(this), bestBidder);
        _distributeReward(metaverseId, bestBidder, auction.seller, bestBiddingPrice);

        _removeUserBiddingInfo(bestBidder, auctionVerificationID);
        delete biddings[auctionVerificationID];
        _removeAuction(auctionVerificationID);

        emit Claim(metaverseId, item, id, bestBidder, amount, bestBiddingPrice, auctionVerificationID, bestBiddingId);
    }

    //"cancel" functions with ownership
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
            item._transferItems(commonData.metaverses(), metaverseId, id, auction.amount, address(this), auction.seller);
            _removeAuction(auctionVerificationIDs[i]);
            emit CancelAuction(metaverseId, item, id, auctionVerificationIDs[i]);
            emit CancelAuctionByOwner(metaverseId, item, id, auctionVerificationIDs[i]);
        }
    }
}
