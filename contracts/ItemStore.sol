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

    struct ItemInfo {
        uint256 metaverseId;
        uint256 id;
        uint256 price;
    }

    uint256 public fee = 250;
    address public feeReceiver;
    uint256 public auctionExtensionInterval = 300;

    IMetaverses public metaverses;
    IMix public mix;
    IMileage public mileage;

    constructor(IMetaverses _metaverses, IMix _mix, IMileage _mileage) public {
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

    modifier itemWhitelist(uint256 metaverseId, address addr) {
        require(metaverseId < metaverses.metaverseCount() && !metaverses.banned(metaverseId));
        require(metaverses.itemAdded(metaverseId, addr));
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
        uint256[] calldata metaverseIds,
        address[] calldata addrs,
        uint256[] calldata ids,
        address[] calldata to,
        uint256[] calldata counts
    ) external userWhitelist(msg.sender) {
        require(
            metaverseIds.length == addrs.length &&
            metaverseIds.length == ids.length &&
            metaverseIds.length == to.length &&
            metaverseIds.length == counts.length
        );
        uint256 metaverseCount = metaverses.metaverseCount();
        for (uint256 i = 0; i < metaverseIds.length; i++) {
            uint256 metaverseId = metaverseIds[i];
            require(metaverseId < metaverseCount && !metaverses.banned(metaverseId));
            require(metaverses.itemAdded(metaverseId, addrs[i]));
            if (metaverses.itemTypes(metaverseId, addrs[i]) == IMetaverses.ItemType.ERC1155) {
                IKIP37(addrs[i]).safeTransferFrom(msg.sender, to[i], ids[i], counts[i], "");
            } else {
                IKIP17(addrs[i]).transferFrom(msg.sender, to[i], ids[i]);
            }
        }
    }

    function removeSale(uint256 metaverseId, address addr, uint256 id) private {
        if (checkSelling(metaverseId, addr, id) == true) {
            uint256 lastIndex = onSalesCount(metaverseId, addr).sub(1);
            uint256 index = onSalesIndex[metaverseId][addr][id];
            if (index != lastIndex) {
                uint256 last = onSales[metaverseId][addr][lastIndex];
                onSales[metaverseId][addr][index] = last;
                onSalesIndex[metaverseId][addr][last] = index;
            }
            onSales[metaverseId][addr].length--;
            delete onSalesIndex[metaverseId][addr][id];
        }
        delete sales[metaverseId][addr][id];
    }

    function removeAuction(uint256 metaverseId, address addr, uint256 id) private {
        if (checkAuction(metaverseId, addr, id) == true) {
            uint256 lastIndex = onAuctionsCount(metaverseId, addr).sub(1);
            uint256 index = onAuctionsIndex[metaverseId][addr][id];
            if (index != lastIndex) {
                uint256 last = onAuctions[metaverseId][addr][lastIndex];
                onAuctions[metaverseId][addr][index] = last;
                onAuctionsIndex[metaverseId][addr][last] = index;
            }
            onAuctions[metaverseId][addr].length--;
            delete onAuctionsIndex[metaverseId][addr][id];
        }
        delete auctions[metaverseId][addr][id];
    }

    function distributeReward(
        uint256 metaverseId,
        address addr,
        uint256 id,
        address buyer,
        address to,
        uint256 amount
    ) private {
        (address receiver, uint256 royalty) = metaverses.royalties(metaverseId);

        uint256 _fee;
        uint256 _royalty;
        uint256 _mileage;

        if (metaverses.mileageMode(metaverseId)) {
            if (metaverses.onlyKlubsMembership(metaverseId)) {
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

        removeSale(metaverseId, addr, id);
        removeAuction(metaverseId, addr, id);
        delete biddings[metaverseId][addr][id];
    }

    struct Sale {
        address seller;
        uint256 price;
    }
    mapping(uint256 => mapping(address => mapping(uint256 => Sale))) public sales; //sales[metaverseId][addr][id]
    mapping(uint256 => mapping(address => uint256[])) public onSales;
    mapping(uint256 => mapping(address => mapping(uint256 => uint256))) public onSalesIndex;
    mapping(address => ItemInfo[]) public userSellInfo; //userSellInfo[seller]
    mapping(address => mapping(uint256 => uint256)) private userSellIndex; //userSellIndex[addr][id]

    function onSalesCount(uint256 metaverseId, address addr) public view returns (uint256) {
        return onSales[metaverseId][addr].length;
    }

    function userSellInfoLength(address seller) public view returns (uint256) {
        return userSellInfo[seller].length;
    }

    function checkSelling(uint256 metaverseId, address addr, uint256 id) public view returns (bool) {
        return sales[metaverseId][addr][id].seller != address(0);
    }

    function sell(
        uint256[] calldata metaverseIds,
        address[] calldata addrs,
        uint256[] calldata ids,
        uint256[] calldata prices,
        uint256[] calldata counts
    ) external userWhitelist(msg.sender) {
        require(
            metaverseIds.length == addrs.length &&
            metaverseIds.length == ids.length &&
            metaverseIds.length == prices.length &&
            metaverseIds.length == counts.length
        );
        uint256 metaverseCount = metaverses.metaverseCount();
        for (uint256 i = 0; i < metaverseIds.length; i++) {
            uint256 metaverseId = metaverseIds[i];
            require(metaverseId < metaverseCount && !metaverses.banned(metaverseId));
            require(metaverses.itemAdded(metaverseId, addrs[i]));
            require(prices[i] > 0);

            if (metaverses.itemTypes(metaverseId, addrs[i]) == IMetaverses.ItemType.ERC1155) {
                IKIP37 nft = IKIP37(addrs[i]);
                uint256 count = counts[i];
                require(count > 0 && nft.balanceOf(msg.sender, ids[i]) >= counts[i]);
                require(nft.isApprovedForAll(msg.sender, address(this)));
                require(!checkSelling(metaverseId, addrs[i], ids[i]));
            } else {
                IKIP17 nft = IKIP17(addrs[i]);
                require(nft.ownerOf(ids[i]) == msg.sender);
                require(nft.isApprovedForAll(msg.sender, address(this)));
                require(!checkSelling(metaverseId, addrs[i], ids[i]));
            }

            sales[metaverseId][addrs[i]][ids[i]] = Sale({seller: msg.sender, price: prices[i]});
            onSalesIndex[metaverseId][addrs[i]][ids[i]] = onSales[addrs[i]].length;
            onSales[metaverseId][addrs[i]].push(ids[i]);

            uint256 lastIndex = userSellInfoLength(msg.sender);
            userSellInfo[msg.sender].push(ItemInfo({metaverseId: metaverseId, pfp: addrs[i], id: ids[i], price: prices[i]}));
            userSellIndex[addrs[i]][ids[i]] = lastIndex;

            emit Sell(metaverseId, addrs[i], ids[i], msg.sender, prices[i]);
        }
    }

    function changeSellPrice(
        uint256[] calldata metaverseIds,
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
        uint256 metaverseId,
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

    function cancelSale(uint256[] calldata metaverseIds, address[] calldata addrs, uint256[] calldata ids) external {
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
        uint256[] calldata metaverseIds,
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
}
