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

interface IArtStore {
    event Sell(uint256 indexed id, address indexed owner, uint256 price);
    event ChangeSellPrice(uint256 indexed id, address indexed owner, uint256 price);
    event Buy(uint256 indexed id, address indexed buyer, uint256 price);
    event CancelSale(uint256 indexed id, address indexed owner);

    event MakeOffer(uint256 indexed id, uint256 indexed offerId, address offeror, uint256 price);
    event CancelOffer(uint256 indexed id, uint256 indexed offerId, address offeror);
    event AcceptOffer(uint256 indexed id, uint256 indexed offerId, address acceptor);

    event CreateAuction(uint256 indexed id, address indexed owner, uint256 startPrice, uint256 endBlock);
    event CancelAuction(uint256 indexed id, address indexed owner);
    event Bid(uint256 indexed id, address indexed bidder, uint256 price);
    event Claim(uint256 indexed id, address indexed bidder, uint256 price);

    event CancelSaleByOwner(uint256 indexed id);
    event CancelOfferByOwner(uint256 indexed id, uint256 indexed offerId);
    event CancelAuctionByOwner(uint256 indexed id);

    event Ban(address indexed user);
    event Unban(address indexed user);

    function auctionExtensionInterval() external view returns (uint256);

    function batchTransfer(uint256[] calldata ids, address[] calldata to) external;

    function sales(uint256 id) external view returns (address seller, uint256 price);
    function userSellInfo(address seller, uint256 index) external view returns (uint256 id, uint256 price);
    function userSellInfoLength(address seller) external view returns (uint256);
    function checkSelling(uint256 id) external view returns (bool);

    function onSalesCount() view external returns (uint256);
    function onSales(uint256 index) view external returns (uint256);

    function sell(uint256[] calldata ids, uint256[] calldata prices) external;
    function changeSellPrice(uint256[] calldata ids, uint256[] calldata prices) external;
    function cancelSale(uint256[] calldata ids) external;
    function buy(uint256[] calldata ids, uint256[] calldata prices, uint256[] calldata mileages) external;

    function offers(uint256 id, uint256 index) external view returns (address offeror, uint256 price, uint256 mileage);
    function userOfferInfo(address offeror, uint256 index) external view returns (uint256 id, uint256 price);
    function userOfferInfoLength(address offeror) external view returns (uint256);
    function offerCount(uint256 id) external view returns (uint256);

    function makeOffer(uint256 id, uint256 price, uint256 mileage) external returns (uint256 offerId);
    function cancelOffer(uint256 id, uint256 offerId) external;
    function acceptOffer(uint256 id, uint256 offerId) external;

    function auctions(uint256 id) external view returns (address seller, uint256 startPrice, uint256 endBlock);
    function userAuctionInfo(address seller, uint256 index) external view returns (uint256 id, uint256 startPrice);
    function userAuctionInfoLength(address seller) external view returns (uint256);
    function checkAuction(uint256 id) external view returns (bool);

    function onAuctionsCount() view external returns (uint256);
    function onAuctions(uint256 index) view external returns (uint256);

    function createAuction(uint256 id, uint256 startPrice, uint256 endBlock) external;
    function cancelAuction(uint256 id) external;

    function biddings(uint256 id, uint256 index) external view returns (address bidder, uint256 price, uint256 mileage);
    function userBiddingInfo(address bidder, uint256 index) external view returns (uint256 id, uint256 price);
    function userBiddingInfoLength(address bidder) external view returns (uint256);
    function biddingCount(uint256 id) external view returns (uint256);

    function bid(uint256 id, uint256 price, uint256 mileage) external returns (uint256 biddingId);
    function claim(uint256 id) external;
}

interface IArtists {

    event Add(address indexed artist);
    event SetBaseRoyalty(address indexed artist, uint256 baseRoyalty);
    event SetExtra(address indexed artist, string extra);
    event JoinOnlyKlubsMembership(address indexed artist);
    event ExitOnlyKlubsMembership(address indexed artist);
    event Ban(address indexed artist);
    event Unban(address indexed artist);

    function artistCount() view external returns (uint256);
    function artists(uint256 index) view external returns (address);
    function added(address artist) view external returns (bool);
    function addedBlocks(address artist) view external returns (uint256);

    function add() external;

    function baseRoyalty(address artist) view external returns (uint256);
    function setBaseRoyalty(uint256 _baseRoyalty) external;

    function extras(address artist) view external returns (string memory);
    function setExtra(string calldata extra) external;

    function onlyKlubsMembership(address artist) view external returns (bool);
    function banned(address artist) view external returns (bool);
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

interface IMileage {
    event AddToWhitelist(address indexed addr);
    event RemoveFromWhitelist(address indexed addr);
    event Charge(address indexed user, uint256 amount);
    event Use(address indexed user, uint256 amount);

    function mileages(address user) external view returns (uint256);
    function mileagePercent() external view returns (uint256);
    function onlyKlubsPercent() external view returns (uint256);
    function whitelist(address addr) external view returns (bool);
    function charge(address user, uint256 amount) external;
    function use(address user, uint256 amount) external;
}

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract IERC721Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a `safeTransfer`. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

/**
 * @title KIP17 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from KIP17 asset contracts.
 * @dev see http://kips.klaytn.com/KIPs/kip-17-non_fungible_token
 */
contract IKIP17Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The KIP17 smart contract calls this function on the recipient
     * after a `safeTransfer`. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onKIP17Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the KIP17 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onKIP17Received(address,address,uint256,bytes)"))`
     */
    function onKIP17Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the SafeMath
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

/**
 * @dev Implementation of the `IKIP13` interface.
 *
 * Contracts may inherit from this and call `_registerInterface` to declare
 * their support of an interface.
 */
contract KIP13 is IKIP13 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_KIP13 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for KIP13 itself here
        _registerInterface(_INTERFACE_ID_KIP13);
    }

    /**
     * @dev See `IKIP13.supportsInterface`.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual KIP13 interface is automatic and
     * registering its interface id is not required.
     *
     * See `IKIP13.supportsInterface`.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the KIP13 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "KIP13: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

/**
 * @title KIP17 Non-Fungible Token Standard basic implementation
 * @dev see http://kips.klaytn.com/KIPs/kip-17-non_fungible_token
 */
contract KIP17 is KIP13, IKIP17 {
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;

    // Equals to `bytes4(keccak256("onKIP17Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IKIP17Receiver(0).onKIP17Received.selector`
    bytes4 private constant _KIP17_RECEIVED = 0x6745782b;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from token ID to owner
    mapping (uint256 => address) private _tokenOwner;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to number of owned token
    mapping (address => Counters.Counter) private _ownedTokensCount;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_KIP17 = 0x80ac58cd;

    constructor () public {
        // register the supported interfaces to conform to KIP17 via KIP13
        _registerInterface(_INTERFACE_ID_KIP17);
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner address to query the balance of
     * @return uint256 representing the amount owned by the passed address
     */
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "KIP17: balance query for the zero address");

        return _ownedTokensCount[owner].current();
    }

    /**
     * @dev Gets the owner of the specified token ID.
     * @param tokenId uint256 ID of the token to query the owner of
     * @return address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "KIP17: owner query for nonexistent token");

        return owner;
    }

    /**
     * @dev Approves another address to transfer the given token ID
     * The zero address indicates there is no approved address.
     * There can only be one approved address per token at a given time.
     * Can only be called by the token owner or an approved operator.
     * @param to address to be approved for the given token ID
     * @param tokenId uint256 ID of the token to be approved
     */
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "KIP17: approval to current owner");

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "KIP17: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Gets the approved address for a token ID, or zero if no address set
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to query the approval of
     * @return address currently approved for the given token ID
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "KIP17: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Sets or unsets the approval of a given operator
     * An operator is allowed to transfer all tokens of the sender on their behalf.
     * @param to operator address to set the approval
     * @param approved representing the status of the approval to be set
     */
    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender, "KIP17: approve to caller");

        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    /**
     * @dev Tells whether an operator is approved by a given owner.
     * @param owner owner address which you want to query the approval of
     * @param operator operator address which you want to query the approval of
     * @return bool whether the given operator is approved by the given owner
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Transfers the ownership of a given token ID to another address.
     * Usage of this method is discouraged, use `safeTransferFrom` whenever possible.
     * Requires the msg.sender to be the owner, approved, or operator.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function transferFrom(address from, address to, uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "KIP17: transfer caller is not owner nor approved");

        _transferFrom(from, to, tokenId);
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onKIP17Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onKIP17Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onKIP17Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onKIP17Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        transferFrom(from, to, tokenId);
        require(_checkOnKIP17Received(from, to, tokenId, _data), "KIP17: transfer to non KIP17Receiver implementer");
    }

    /**
     * @dev Returns whether the specified token exists.
     * @param tokenId uint256 ID of the token to query the existence of
     * @return bool whether the token exists
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

    /**
     * @dev Returns whether the given spender can transfer a given token ID.
     * @param spender address of the spender to query
     * @param tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     * is an operator of the owner, or is the owner of the token
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "KIP17: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Internal function to mint a new token.
     * Reverts if the given token ID already exists.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "KIP17: mint to the zero address");
        require(!_exists(tokenId), "KIP17: token already minted");

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].increment();

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * Deprecated, use _burn(uint256) instead.
     * @param owner owner of the token to burn
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(address owner, uint256 tokenId) internal {
        require(ownerOf(tokenId) == owner, "KIP17: burn of token that is not own");

        _clearApproval(tokenId);

        _ownedTokensCount[owner].decrement();
        _tokenOwner[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(uint256 tokenId) internal {
        _burn(ownerOf(tokenId), tokenId);
    }

    /**
     * @dev Internal function to transfer ownership of a given token ID to another address.
     * As opposed to transferFrom, this imposes no restrictions on msg.sender.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "KIP17: transfer of token that is not own");
        require(to != address(0), "KIP17: transfer to the zero address");

        _clearApproval(tokenId);

        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Internal function to invoke `onKIP17Received` on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * This function is deprecated.
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnKIP17Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        bool success; 
        bytes memory returndata;

        if (!to.isContract()) {
            return true;
        }

        // Logic for compatibility with ERC721.
        (success, returndata) = to.call(
            abi.encodeWithSelector(_ERC721_RECEIVED, msg.sender, from, tokenId, _data)
        );
        if (returndata.length != 0 && abi.decode(returndata, (bytes4)) == _ERC721_RECEIVED) {
            return true;
        }

        (success, returndata) = to.call(
            abi.encodeWithSelector(_KIP17_RECEIVED, msg.sender, from, tokenId, _data)
        );
        if (returndata.length != 0 && abi.decode(returndata, (bytes4)) == _KIP17_RECEIVED) {
            return true;
        }

        return false;
    }

    /**
     * @dev Private function to clear current approval of a given token ID.
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}

/**
 * @title KIP-17 Non-Fungible Token Standard, optional enumeration extension
 * @dev See http://kips.klaytn.com/KIPs/kip-17-non_fungible_token
 */
contract IKIP17Enumerable is IKIP17 {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
}

/**
 * @title KIP-17 Non-Fungible Token with optional enumeration extension logic
 * @dev See http://kips.klaytn.com/KIPs/kip-17-non_fungible_token
 */
contract KIP17Enumerable is KIP13, KIP17, IKIP17Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => uint256[]) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_KIP17_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Constructor function.
     */
    constructor () public {
        // register the supported interface to conform to KIP17Enumerable via KIP13
        _registerInterface(_INTERFACE_ID_KIP17_ENUMERABLE);
    }

    /**
     * @dev Gets the token ID at a given index of the tokens list of the requested owner.
     * @param owner address owning the tokens list to be accessed
     * @param index uint256 representing the index to be accessed of the requested tokens list
     * @return uint256 token ID at the given index of the tokens list owned by the requested address
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner), "KIP17Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev Gets the total amount of tokens stored by the contract.
     * @return uint256 representing the total amount of tokens
     */
    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev Gets the token ID at a given index of all the tokens in this contract
     * Reverts if the index is greater or equal to the total number of tokens.
     * @param index uint256 representing the index to be accessed of the tokens list
     * @return uint256 token ID at the given index of the tokens list
     */
    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply(), "KIP17Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Internal function to transfer ownership of a given token ID to another address.
     * As opposed to transferFrom, this imposes no restrictions on msg.sender.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        super._transferFrom(from, to, tokenId);

        _removeTokenFromOwnerEnumeration(from, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);
    }

    /**
     * @dev Internal function to mint a new token.
     * Reverts if the given token ID already exists.
     * @param to address the beneficiary that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _mint(address to, uint256 tokenId) internal {
        super._mint(to, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);

        _addTokenToAllTokensEnumeration(tokenId);
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * Deprecated, use _burn(uint256) instead.
     * @param owner owner of the token to burn
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

        _removeTokenFromOwnerEnumeration(owner, tokenId);
        // Since tokenId will be deleted, we can clear its slot in _ownedTokensIndex to trigger a gas refund
        _ownedTokensIndex[tokenId] = 0;

        _removeTokenFromAllTokensEnumeration(tokenId);
    }

    /**
     * @dev Gets the list of token IDs of the requested owner.
     * @param owner address owning the tokens
     * @return uint256[] List of token IDs owned by the requested address
     */
    function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
        return _ownedTokens[owner];
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the _ownedTokensIndex mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        _ownedTokens[from].length--;

        // Note that _ownedTokensIndex[tokenId] hasn't been cleared: it still points to the old slot (now occupied by
        // lastTokenId, or just over the end of the array if the token was the last one).
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length.sub(1);
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        _allTokens.length--;
        _allTokensIndex[tokenId] = 0;
    }
}

/**
 * @title KIP-17 Non-Fungible Token Standard, optional metadata extension
 * @dev See http://kips.klaytn.com/KIPs/kip-17-non_fungible_token
 */
contract IKIP17Metadata is IKIP17 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract KIP17Metadata is KIP13, KIP17, IKIP17Metadata {
    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_KIP17_METADATA = 0x5b5e139f;

    /**
     * @dev Constructor function
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;

        // register the supported interfaces to conform to KIP17 via KIP13
        _registerInterface(_INTERFACE_ID_KIP17_METADATA);
    }

    /**
     * @dev Gets the token name.
     * @return string representing the token name
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev Gets the token symbol.
     * @return string representing the token symbol
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns an URI for a given token ID.
     * Throws if the token ID does not exist. May return an empty string.
     * @param tokenId uint256 ID of the token to query
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "KIP17Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

    /**
     * @dev Internal function to set the token URI for a given token.
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to set its URI
     * @param uri string URI to assign
     */
    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        require(_exists(tokenId), "KIP17Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = uri;
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * Deprecated, use _burn(uint256) instead.
     * @param owner owner of the token to burn
     * @param tokenId uint256 ID of the token being burned by the msg.sender
     */
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

/**
 * @title Full KIP-17 Token
 * This implementation includes all the required and some optional functionality of the KIP-17 standard
 * Moreover, it includes approve all functionality using operator terminology
 * @dev see http://kips.klaytn.com/KIPs/kip-17-non_fungible_token
 */
contract KIP17Full is KIP17, KIP17Enumerable, KIP17Metadata {
    constructor (string memory name, string memory symbol) public KIP17Metadata(name, symbol) {
        // solhint-disable-previous-line no-empty-blocks
    }
}

/**
 * @title KIP17 Burnable Token
 * @dev KIP17 Token that can be irreversibly burned (destroyed).
 * See http://kips.klaytn.com/KIPs/kip-17-non_fungible_token
 */
contract KIP17Burnable is KIP13, KIP17 {
    /*
     *     bytes4(keccak256('burn(uint256)')) == 0x42966c68
     *
     *     => 0x42966c68 == 0x42966c68
     */
    bytes4 private constant _INTERFACE_ID_KIP17_BURNABLE = 0x42966c68;

    /**
     * @dev Constructor function.
     */
    constructor () public {
        // register the supported interface to conform to KIP17Burnable via KIP13
        _registerInterface(_INTERFACE_ID_KIP17_BURNABLE);
    }

    /**
     * @dev Burns a specific KIP17 token.
     * @param tokenId uint256 id of the KIP17 token to be burned.
     */
    function burn(uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "KIP17Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is PauserRole {
    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state. Assigns the Pauser role
     * to the deployer.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

/**
 * @title KIP17 Non-Fungible Pausable token
 * @dev KIP17 modified with pausable transfers.
 */
contract KIP17Pausable is KIP13, KIP17, Pausable {
    /*
     *     bytes4(keccak256('paused()')) == 0x5c975abb
     *     bytes4(keccak256('pause()')) == 0x8456cb59
     *     bytes4(keccak256('unpause()')) == 0x3f4ba83a
     *     bytes4(keccak256('isPauser(address)')) == 0x46fbf68e
     *     bytes4(keccak256('addPauser(address)')) == 0x82dc1ec4
     *     bytes4(keccak256('renouncePauser()')) == 0x6ef8d66d
     *
     *     => 0x5c975abb ^ 0x8456cb59 ^ 0x3f4ba83a ^ 0x46fbf68e ^ 0x82dc1ec4 ^ 0x6ef8d66d == 0x4d5507ff
     */
    bytes4 private constant _INTERFACE_ID_KIP17_PAUSABLE = 0x4d5507ff;

    /**
     * @dev Constructor function.
     */
    constructor () public {
        // register the supported interface to conform to KIP17Pausable via KIP13
        _registerInterface(_INTERFACE_ID_KIP17_PAUSABLE);
    }

    function approve(address to, uint256 tokenId) public whenNotPaused {
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address to, bool approved) public whenNotPaused {
        super.setApprovalForAll(to, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) public whenNotPaused {
        super.transferFrom(from, to, tokenId);
    }
}

contract Arts is Ownable, KIP17Full("Klubs Arts", "ARTS"), KIP17Burnable, KIP17Pausable {
    using SafeMath for uint256;

    event SetArtists(IArtists artists);
    event SetBaseURI(string baseURI);
    event SetExceptionalRoyalty(uint256 indexed id, uint256 royalty);
    event MileageOn(uint256 indexed id);
    event MileageOff(uint256 indexed id);
    event Ban(uint256 indexed id);
    event Unban(uint256 indexed id);

    IArtists public artists;

    constructor(IArtists _artists) public {
        artists = _artists;
        emit SetArtists(_artists);
    }

    function setArtists(IArtists _newArtists) external onlyOwner {
        artists = _newArtists;
        emit SetArtists(_newArtists);
    }

    string public baseURI = "https://api.klu.bs/arts/";

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
        emit SetBaseURI(_baseURI);
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "KIP17Metadata: URI query for nonexistent token");
        
        if (tokenId == 0) {
            return string(abi.encodePacked(baseURI, "0"));
        }

        string memory idstr;
        
        uint256 temp = tokenId;
        uint256 digits;
        while (temp != 0) {
            digits += 1;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (tokenId != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(tokenId % 10)));
            tokenId /= 10;
        }
        idstr = string(buffer);

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, idstr)) : "";
    }

    modifier artistWhitelist() {
        require(artists.added(msg.sender) && !artists.banned(msg.sender));
        _;
    }

    mapping(uint256 => address) public artToArtist;
    mapping(address => uint256[]) public artistArts;

    uint256 public mintCount;

    function mint() public artistWhitelist {
        uint256 id = mintCount;
        _mint(msg.sender, id);
        artToArtist[id] = msg.sender;
        artistArts[msg.sender].push(id);
        mintCount = mintCount.add(1);
    }

    function artistArtCount(address artist) external view returns (uint256) {
        return artistArts[artist].length;
    }

    modifier onlyArtist(uint256 id) {
        require(artToArtist[id] == msg.sender);
        _;
    }

    /** 
        exceptionalRoyalties == 0 : follow baseRoyalty
        exceptionalRoyalties == uint256(-1) : not follow baseRoyalty. use exceptioanlRoyalty and it is 0
        0 < exceptionalRoyalties <= 1e3 : not follow baseRoyalty. use exceptioanlRoyalty and it is same with its value
    */
    mapping(uint256 => uint256) public exceptionalRoyalties;

    function setExceptionalRoyalties(uint256[] calldata ids, uint256[] calldata royalties) external {
        require(ids.length == royalties.length);
        for(uint256 i = 0; i < ids.length; i++) {
            require(artToArtist[ids[i]] == msg.sender);
            require(royalties[i] <= 1e3 || royalties[i] == uint256(-1)); // max royalty is 10%
            exceptionalRoyalties[ids[i]] = royalties[i];
            emit SetExceptionalRoyalty(ids[i], royalties[i]);
        }
    }

    function royalties(uint256 id) external view returns (uint256) {
        if(exceptionalRoyalties[id] == 0) {
            return artists.baseRoyalty(artToArtist[id]);
        } else {
            return exceptionalRoyalties[id] == uint256(-1) ? 0 : exceptionalRoyalties[id];
        }
    }

    mapping(uint256 => bool) public mileageMode;

    function mileageOn(uint256 id) onlyArtist(id) external {
        mileageMode[id] = true;
        emit MileageOn(id);
    }

    function mileageOff(uint256 id) onlyArtist(id) external {
        mileageMode[id] = false;
        emit MileageOff(id);
    }

    mapping(uint256 => bool) private _banned;

    function ban(uint256 id) onlyOwner external {
        _banned[id] = true;
        emit Ban(id);
    }

    function unban(uint256 id) onlyOwner external {
        _banned[id] = false;
        emit Unban(id);
    }

    function isBanned(uint256 id) external view returns (bool) {
        return _banned[id] || artists.banned(artToArtist[id]);
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }
}

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
            require(!arts.isBanned(ids[i]));
            arts.safeTransferFrom(msg.sender, to[i], ids[i]);
        }
    }

    function removeSale(uint256 id) private {
        if (checkSelling(id)) {
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
        if (checkAuction(id)) {
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

        uint256 _fee;
        uint256 _royalty;
        uint256 _mileage;

        if (arts.mileageMode(id)) {
            if (artists.onlyKlubsMembership(artist)) {
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
                _royalty = amount.mul(arts.royalties(id)).div(1e4);

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
                _royalty = amount.mul(arts.royalties(id)).div(1e4);

                if (_royalty > _mileage) {
                    _royalty = _royalty.sub(_mileage);
                } else {
                    _mileage = _royalty;
                    _royalty = 0;
                }
            }
        } else {
            _fee = amount.mul(fee).div(1e4);
            _royalty = amount.mul(arts.royalties(id)).div(1e4);
        }

        if (_fee > 0) mix.transfer(feeReceiver, _fee);
        if (_royalty > 0) mix.transfer(artist, _royalty);
        if (_mileage > 0) {
            mix.approve(address(mileage), _mileage);
            mileage.charge(buyer, _mileage);
        }

        mix.transfer(to, amount.sub(_fee).sub(_royalty).sub(_mileage));

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
            require(!arts.isBanned(ids[i]));
            require(prices[i] > 0);

            require(arts.ownerOf(ids[i]) == msg.sender);
            require(arts.isApprovedForAll(msg.sender, address(this)));
            require(!checkSelling(ids[i]));

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
        require(ids.length == prices.length && ids.length == mileages.length);
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
        require(!arts.isBanned(id));

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
        require(!arts.isBanned(id));
        require(endBlock > block.number);
        require(!checkSelling(id));
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
        require(!arts.isBanned(id));
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