pragma solidity ^0.5.6;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address payable private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address payable) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address payable newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address payable newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @dev Interface of the KIP-13 standard, as defined in the
 * [KIP-13](http://kips.klaytn.com/KIPs/kip-13-interface_query_standard).
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others.
 *
 * For an implementation, see `KIP13`.
 */
interface IKIP13 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [KIP-13 section](http://kips.klaytn.com/KIPs/kip-13-interface_query_standard#how-interface-identifiers-are-defined)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Required interface of an KIP17 compliant contract.
 */
contract IKIP17 is IKIP13 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in `owner`'s account.
     */
    function balanceOf(address owner) public view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) public view returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either `approve` or `setApproveForAll`.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public;

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either `approve` or `setApproveForAll`.
     */
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

interface IPFPStore {
    event Sell(address indexed addr, uint256 indexed id, address indexed owner, uint256 price);
    event Buy(address indexed addr, uint256 indexed id, address indexed buyer, uint256 price);
    event CancelSale(address indexed addr, uint256 indexed id, address indexed owner);

    event MakeOffer(address indexed addr, uint256 indexed id, uint256 indexed offerId, address offeror, uint256 price);
    event CancelOffer(address indexed addr, uint256 indexed id, uint256 indexed offerId, address offeror);
    event AcceptOffer(address indexed addr, uint256 indexed id, uint256 indexed offerId, address acceptor);

    event CreateAuction(address indexed addr, uint256 indexed id, address indexed owner, uint256 startPrice, uint256 endBlock);
    event CancelAuction(address indexed addr, uint256 indexed id, address indexed owner);
    event Bid(address indexed addr, uint256 indexed id, address indexed bidder, uint256 price);
    event Claim(address indexed addr, uint256 indexed id, address indexed bidder, uint256 price);

    event CancelSaleByOwner(address indexed addr, uint256 indexed id);
    event CancelOfferByOwner(address indexed addr, uint256 indexed id, uint256 indexed offerId);
    event CancelAuctionByOwner(address indexed addr, uint256 indexed id);

    event Ban(address indexed addr);
    event Unban(address indexed addr);

    function auctionExtensionInterval() external view returns (uint256);
    function isBanned(address user) external view returns (bool);

    function sales(address addr, uint256 id) external view returns (address seller, uint256 price);
    function userSellInfo(address seller, uint256 index) external view returns (address pfp, uint256 id, uint256 price);
    function userSellInfoLength(address seller) external view returns (uint256);
    function checkSelling(address addr, uint256 id) external view returns (bool);

    function onSalesCount(address addr) view external returns (uint256);
    function onSales(address addr, uint256 index) view external returns (uint256);

    function sell(address[] calldata addrs, uint256[] calldata ids, uint256[] calldata prices) external;
    function cancelSale(address[] calldata addrs, uint256[] calldata ids) external;
    function buy(address[] calldata addrs, uint256[] calldata ids) external;

    function offers(address addr, uint256 id, uint256 index) external view returns (address offeror, uint256 price);
    function userOfferInfo(address offeror, uint256 index) external view returns (address pfp, uint256 id, uint256 price);
    function userOfferInfoLength(address offeror) external view returns (uint256);
    function offerCount(address addr, uint256 id) external view returns (uint256);

    function makeOffer(address addr, uint256 id, uint256 price) external returns (uint256 offerId);
    function cancelOffer(address addr, uint256 id, uint256 offerId) external;
    function acceptOffer(address addr, uint256 id, uint256 offerId) external;

    function auctions(address addr, uint256 id) external view returns (address seller, uint256 startPrice, uint256 endBlock);
    function userAuctionInfo(address seller, uint256 index) external view returns (address pfp, uint256 id, uint256 startPrice);
    function userAuctionInfoLength(address seller) external view returns (uint256);
    function checkAuction(address addr, uint256 id) external view returns (bool);

    function onAuctionsCount(address addr) view external returns (uint256);
    function onAuctions(address addr, uint256 index) view external returns (uint256);

    function createAuction(address addr, uint256 id, uint256 startPrice, uint256 endBlock) external;
    function cancelAuction(address addr, uint256 id) external;

    function biddings(address addr, uint256 id, uint256 index) external view returns (address bidder, uint256 price);
    function userBiddingInfo(address bidder, uint256 index) external view returns (address pfp, uint256 id, uint256 price);
    function userBiddingInfoLength(address bidder) external view returns (uint256);
    function biddingCount(address addr, uint256 id) external view returns (uint256);

    function bid(address addr, uint256 id, uint256 price) external returns (uint256 biddingId);
    function claim(address addr, uint256 id) external;
}

interface IPFPs {

    event Propose(address indexed addr, address indexed manager);
    event Add(address indexed addr, address indexed manager);

    event AddManager(address indexed addr, address indexed manager);
    event RemoveManager(address indexed addr, address indexed manager);

    event SetEnumerable(address indexed addr, bool enumerable);
    event SetTotalSupply(address indexed addr, uint256 totalSupply);

    event SetRoyalty(address indexed addr, address receiver, uint256 royalty);
    event SetExtra(address indexed addr, string extra);

    event Ban(address indexed addr);
    event Unban(address indexed addr);

    function propose(address addr) external;

    function addrCount() view external returns (uint256);
    function addrs(uint256 index) view external returns (address);
    function added(address addr) view external returns (bool);
    function addedBlocks(address addr) view external returns (uint256);

    function managerCount(address addr) view external returns (uint256);
    function managers(address addr, uint256 index) view external returns (address);
    function managerPFPCount(address manager) view external returns (uint256);
    function managerPFPs(address manager, uint256 index) view external returns (address);

    function addByPFPOwner(address addr) external;
    function addByMinter(address addr) external;

    function existsManager(address addr, address manager) view external returns (bool);
    function addManager(address addr, address manager) external;
    function removeManager(address addr, address manager) external;

    function enumerables(address addr) view external returns (bool);
    function setEnumerable(address addr, bool enumerable) external;
    function totalSupplies(address addr) view external returns (uint256);
    function setTotalSupply(address addr, uint256 totalSupply) external;
    function getTotalSupply(address addr) view external returns (uint256);

    function royalties(address addr) view external returns (address receiver, uint256 royalty);
    function setRoyalty(address addr, address receiver, uint256 royalty) external;

    function extras(address addr) view external returns (string memory);
    function setExtra(address addr, string calldata extra) external;

    function banned(address addr) view external returns (bool);
}

/**
 * @dev Interface of the KIP7 standard as defined in the KIP. Does not include
 * the optional functions; to access them see `KIP7Metadata`.
 * See http://kips.klaytn.com/KIPs/kip-7-fungible_token
 */
contract IKIP7 is IKIP13 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
    * @dev Moves `amount` tokens from the caller's account to `recipient`.
    */
    function safeTransfer(address recipient, uint256 amount, bytes memory data) public;

    /**
    * @dev  Moves `amount` tokens from the caller's account to `recipient`.
    */
    function safeTransfer(address recipient, uint256 amount) public;

    /**
    * @dev Moves `amount` tokens from `sender` to `recipient` using the allowance mechanism.
    * `amount` is then deducted from the caller's allowance.
    */
    function safeTransferFrom(address sender, address recipient, uint256 amount, bytes memory data) public;

    /**
    * @dev Moves `amount` tokens from `sender` to `recipient` using the allowance mechanism.
    * `amount` is then deducted from the caller's allowance.
    */
    function safeTransferFrom(address sender, address recipient, uint256 amount) public;

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IMix {

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}

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

    function removeSale(address addr, uint256 id) private {
        delete sales[addr][id];

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
    }

    function removeAuction(address addr, uint256 id) private {
        delete auctions[addr][id];

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
            nft.transferFrom(msg.sender, address(this), ids[i]);

            sales[addrs[i]][ids[i]] = Sale({seller: msg.sender, price: prices[i]});
            onSalesIndex[addrs[i]][ids[i]] = onSales[addrs[i]].length;
            onSales[addrs[i]].push(ids[i]);

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
            removeSale(addrs[i], ids[i]);
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

            removeAuction(addrs[i], ids[i]);
            removeUserAuction(_auction.seller, addrs[i], ids[i]);

            emit CancelAuction(addrs[i], ids[i], _auction.seller);
            emit CancelAuctionByOwner(addrs[i], ids[i]);
        }
    }
}