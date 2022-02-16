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

// SPDX-License-Identifier: MIT
/**
 * @dev Required interface of an KIP37 compliant contract, as defined in the
 * https://kips.klaytn.com/KIPs/kip-37
 */
contract IKIP37 is IKIP13 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transfered from `from` to `to` by `operator`.
     */
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    /**
     * @dev Batch-operations version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IKIP37Receiver-onKIP37Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev Batch-operations version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IKIP37Receiver-onKIP37BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

interface IMetaverses {
    enum ItemType {
        ERC1155,
        ERC721
    }

    event Add(address indexed manager);
    event AddManager(uint256 indexed id, address indexed manager);
    event RemoveManager(uint256 indexed id, address indexed manager);
    event SetExtra(uint256 indexed id, string extra);
    event SetRoyalty(uint256 indexed id, address receiver, uint256 royalty);

    event JoinOnlyKlubsMembership(uint256 indexed id);
    event ExitOnlyKlubsMembership(uint256 indexed id);
    event MileageOn(uint256 indexed id);
    event MileageOff(uint256 indexed id);

    event Ban(uint256 indexed id);
    event Unban(uint256 indexed id);

    event ProposeItem(uint256 indexed id, address indexed item, ItemType itemType, address indexed proposer);
    event AddItem(uint256 indexed id, address indexed item, ItemType itemType);
    event SetItemEnumerable(uint256 indexed id, address indexed item, bool enumerable);
    event SetItemTotalSupply(uint256 indexed id, address indexed item, uint256 totalSupply);
    event SetItemExtra(uint256 indexed id, address indexed item, string extra);

    function addMetaverse(string calldata extra) external;

    function metaverseCount() external view returns (uint256);

    function managerCount(uint256 id) external view returns (uint256);

    function managers(uint256 id, uint256 index) external view returns (address);

    function managerMetaversesCount(address manager) external view returns (uint256);

    function managerMetaverses(address manager, uint256 index) external view returns (uint256);

    function existsManager(uint256 id, address manager) external view returns (bool);

    function addManager(uint256 id, address manager) external;

    function removeManager(uint256 id, address manager) external;

    function extras(uint256 id) external view returns (string memory);

    function setExtra(uint256 id, string calldata extra) external;

    function royalties(uint256 id) external view returns (address receiver, uint256 royalty);

    function setRoyalty(
        uint256 id,
        address receiver,
        uint256 royalty
    ) external;

    function onlyKlubsMembership(uint256 id) external view returns (bool);

    function mileageMode(uint256 id) external view returns (bool);

    function mileageOn(uint256 id) external;

    function mileageOff(uint256 id) external;

    function banned(uint256 id) external view returns (bool);

    function itemProposals(uint256 index)
        external
        view
        returns (
            uint256 id,
            address item,
            ItemType itemType,
            address proposer
        );

    function proposeItem(
        uint256 id,
        address item,
        ItemType itemType
    ) external;

    function itemProposalCount() external view returns (uint256);

    function itemAddrCount(uint256 id) external view returns (uint256);

    function itemAddrs(uint256 id, uint256 index) external view returns (address);

    function itemAdded(uint256 id, address item) external view returns (bool);

    function itemAddedBlocks(uint256 id, address item) external view returns (uint256);

    function itemTypes(uint256 id, address item) external view returns (ItemType);

    function addItem(
        uint256 id,
        address item,
        ItemType itemType,
        string calldata extra
    ) external;

    function passProposal(uint256 proposalId, string calldata extra) external;

    function removeProposal(uint256 proposalId) external;

    function itemEnumerables(uint256 id, address item) external view returns (bool);

    function setItemEnumerable(
        uint256 id,
        address item,
        bool enumerable
    ) external;

    function itemTotalSupplies(uint256 id, address item) external view returns (uint256);

    function setItemTotalSupply(
        uint256 id,
        address item,
        uint256 totalSupply
    ) external;

    function getItemTotalSupply(uint256 id, address item) external view returns (uint256);

    function itemExtras(uint256 id, address item) external view returns (string memory);

    function setItemExtra(
        uint256 id,
        address item,
        string calldata extra
    ) external;
}

library ItemStoreLibrary {
    function _isERC1155(address item, IMetaverses metaverses, uint256 metaverseId) internal view returns (bool) {
        return metaverses.itemTypes(metaverseId, item) == IMetaverses.ItemType.ERC1155;
    }

    function _transferItems(
        address item,
        IMetaverses metaverses,
        uint256 metaverseId,
        uint256 id,
        uint256 amount,
        address from,
        address to
    ) internal {
        if (_isERC1155(item, metaverses, metaverseId)) {
            require(amount > 0);
            IKIP37(item).safeTransferFrom(from, to, id, amount, "");
        } else {
            require(amount == 1);
            IKIP17(item).transferFrom(from, to, id);
        }
    }
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

interface IItemStoreCommon {
    event Ban(address indexed user);
    event Unban(address indexed user);

    function metaverses() external view returns (IMetaverses);

    function mix() external view returns (IMix);

    function mileage() external view returns (IMileage);

    function fee() external view returns (uint256);

    function feeReceiver() external view returns (address);

    function auctionExtensionInterval() external view returns (uint256);

    function setFee(uint256 _fee) external;

    function setFeeReceiver(address _receiver) external;

    function setAuctionExtensionInterval(uint256 interval) external;

    function setMetaverses(IMetaverses _metaverses) external;

    function isMetaverseWhitelisted(uint256 metaverseId) external view returns (bool);

    function isItemWhitelisted(uint256 metaverseId, address item) external view returns (bool);

    function isBannedUser(address user) external view returns (bool);

    function banUser(address user) external;

    function unbanUser(address user) external;

    function batchTransfer(
        uint256[] calldata metaverseIds,
        address[] calldata items,
        uint256[] calldata ids,
        address[] calldata to,
        uint256[] calldata amounts
    ) external;
}

interface IItemStoreSale {
    event Sell(
        uint256 indexed metaverseId,
        address indexed item,
        uint256 id,
        address seller,
        uint256 amount,
        uint256 unitPrice,
        bool partialBuying,
        bytes32 indexed saleVerificationID
    );
    event ChangeSellPrice(uint256 indexed metaverseId, address indexed item, uint256 id, uint256 newUnitPrice, bytes32 indexed saleVerificationID);
    event Buy(
        uint256 indexed metaverseId,
        address indexed item,
        uint256 id,
        address buyer,
        uint256 amount,
        bool isFulfilled,
        bytes32 indexed saleVerificationID
    );
    event CancelSale(uint256 indexed metaverseId, address indexed item, uint256 id, uint256 amount, bytes32 indexed saleVerificationID);

    event MakeOffer(
        uint256 indexed metaverseId,
        address indexed item,
        uint256 id,
        address offeror,
        uint256 amount,
        uint256 unitPrice,
        bool partialBuying,
        bytes32 indexed offerVerificationID
    );
    event CancelOffer(uint256 indexed metaverseId, address indexed item, uint256 id, uint256 amount, bytes32 indexed offerVerificationID);
    event AcceptOffer(
        uint256 indexed metaverseId,
        address indexed item,
        uint256 id,
        address acceptor,
        uint256 amount,
        bool isFulfilled,
        bytes32 indexed offerVerificationID
    );

    event CancelSaleByOwner(uint256 indexed metaverseId, address indexed item, uint256 id, bytes32 indexed saleVerificationID);
    event CancelOfferByOwner(uint256 indexed metaverseId, address indexed item, uint256 id, bytes32 indexed offerVerificationID);

    function commonData() external view returns (IItemStoreCommon);

    function nonce(address user) external view returns (uint256);

    //Sale
    function sales(
        address item,
        uint256 id,
        uint256 saleId
    )
        external
        view
        returns (
            address seller,
            uint256 metaverseId,
            address _item,
            uint256 _id,
            uint256 amount,
            uint256 unitPrice,
            bool partialBuying,
            bytes32 verificationID
        );

    function onSales(address item, uint256 index) external view returns (bytes32 saleVerificationID);

    function userSellInfo(address seller, uint256 index) external view returns (bytes32 saleVerificationID);

    function salesOnMetaverse(uint256 metaverseId, uint256 index) external view returns (bytes32 saleVerificationID);

    function userOnSaleAmounts(
        address seller,
        address item,
        uint256 id
    ) external view returns (uint256);

    function getSaleInfo(bytes32 saleVerificationID)
        external
        view
        returns (
            address item,
            uint256 id,
            uint256 saleId
        );

    function salesCount(address item, uint256 id) external view returns (uint256);

    function onSalesCount(address item) external view returns (uint256);

    function userSellInfoLength(address seller) external view returns (uint256);

    function salesOnMetaverseLength(uint256 metaverseId) external view returns (uint256);

    function canSell(
        address seller,
        uint256 metaverseId,
        address item,
        uint256 id,
        uint256 amount
    ) external view returns (bool);

    function sell(
        uint256[] calldata metaverseIds,
        address[] calldata items,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        uint256[] calldata unitPrices,
        bool[] calldata partialBuyings
    ) external;

    function changeSellPrice(bytes32[] calldata saleVerificationIDs, uint256[] calldata unitPrices) external;

    function cancelSale(bytes32[] calldata saleVerificationIDs) external;

    function buy(
        bytes32[] calldata saleVerificationIDs,
        uint256[] calldata amounts,
        uint256[] calldata unitPrices,
        uint256[] calldata mileages
    ) external;

    //Offer
    function offers(
        address item,
        uint256 id,
        uint256 offerId
    )
        external
        view
        returns (
            address offeror,
            uint256 metaverseId,
            address _item,
            uint256 _id,
            uint256 amount,
            uint256 unitPrice,
            bool partialBuying,
            uint256 mileage,
            bytes32 verificationID
        );

    function userOfferInfo(address offeror, uint256 index) external view returns (bytes32 offerVerificationID);

    function getOfferInfo(bytes32 offerVerificationID)
        external
        view
        returns (
            address item,
            uint256 id,
            uint256 offerId
        );

    function userOfferInfoLength(address offeror) external view returns (uint256);

    function offersCount(address item, uint256 id) external view returns (uint256);

    function canOffer(
        address offeror,
        uint256 metaverseId,
        address item,
        uint256 id,
        uint256 amount
    ) external view returns (bool);

    function makeOffer(
        uint256 metaverseId,
        address item,
        uint256 id,
        uint256 amount,
        uint256 unitPrice,
        bool partialBuying,
        uint256 mileage
    ) external returns (uint256 offerId);

    function cancelOffer(bytes32 offerVerificationID) external;

    function acceptOffer(bytes32 offerVerificationID, uint256 amount) external;
}

contract ItemStoreSale is Ownable, IItemStoreSale {
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
    function _removeSale(bytes32 saleVerificationID) private {
        SaleInfo storage saleInfo = _saleInfo[saleVerificationID];
        address item = saleInfo.item;
        uint256 id = saleInfo.id;
        uint256 saleId = saleInfo.saleId;

        Sale storage sale = sales[item][id][saleId];

        //delete onSales
        uint256 lastIndex = onSales[item].length.sub(1);
        uint256 index = _onSalesIndex[saleVerificationID];
        if (index != lastIndex) {
            bytes32 lastSaleVerificationID = onSales[item][lastIndex];
            onSales[item][index] = lastSaleVerificationID;
            _onSalesIndex[lastSaleVerificationID] = index;
        }
        onSales[item].length--;
        delete _onSalesIndex[saleVerificationID];

        //delete userSellInfo
        address seller = sale.seller;
        lastIndex = userSellInfo[seller].length.sub(1);
        index = _userSellIndex[saleVerificationID];
        if (index != lastIndex) {
            bytes32 lastSaleVerificationID = userSellInfo[seller][lastIndex];
            userSellInfo[seller][index] = lastSaleVerificationID;
            _userSellIndex[lastSaleVerificationID] = index;
        }
        userSellInfo[seller].length--;
        delete _userSellIndex[saleVerificationID];

        //delete salesOnMetaverse
        uint256 metaverseId = sale.metaverseId;
        lastIndex = salesOnMetaverse[metaverseId].length.sub(1);
        index = _salesOnMvIndex[saleVerificationID];
        if (index != lastIndex) {
            bytes32 lastSaleVerificationID = salesOnMetaverse[metaverseId][lastIndex];
            salesOnMetaverse[metaverseId][index] = lastSaleVerificationID;
            _salesOnMvIndex[lastSaleVerificationID] = index;
        }
        salesOnMetaverse[metaverseId].length--;
        delete _salesOnMvIndex[saleVerificationID];

        //subtract amounts.
        uint256 amount = sale.amount;
        if (amount > 0) {
            userOnSaleAmounts[seller][item][id] = userOnSaleAmounts[seller][item][id].sub(amount);
        }

        //delete sales
        uint256 lastSaleId = sales[item][id].length.sub(1);
        Sale memory lastSale = sales[item][id][lastSaleId];
        if (saleId != lastSaleId) {
            sales[item][id][saleId] = lastSale;
            _saleInfo[lastSale.verificationID].saleId = saleId;
        }
        sales[item][id].length--;
        delete _saleInfo[saleVerificationID];
    }

    function _removeOffer(bytes32 offerVerificationID) private {
        OfferInfo storage offerInfo = _offerInfo[offerVerificationID];
        address item = offerInfo.item;
        uint256 id = offerInfo.id;
        uint256 offerId = offerInfo.offerId;

        Offer storage offer = offers[item][id][offerId];

        //delete userOfferInfo
        address offeror = offer.offeror;
        uint256 lastIndex = userOfferInfo[offeror].length.sub(1);
        uint256 index = _userOfferIndex[offerVerificationID];
        if (index != lastIndex) {
            bytes32 lastOfferVerificationID = userOfferInfo[offeror][lastIndex];
            userOfferInfo[offeror][index] = lastOfferVerificationID;
            _userOfferIndex[lastOfferVerificationID] = index;
        }
        userOfferInfo[offeror].length--;
        delete _userOfferIndex[offerVerificationID];

        //delete offers
        uint256 lastOfferId = offers[item][id].length.sub(1);
        Offer memory lastOffer = offers[item][id][lastOfferId];
        if (offerId != lastOfferId) {
            offers[item][id][offerId] = lastOffer;
            _offerInfo[lastOffer.verificationID].offerId = offerId;
        }
        offers[item][id].length--;
        delete _offerInfo[offerVerificationID];
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

    //Sale
    struct Sale {
        address seller;
        uint256 metaverseId;
        address item;
        uint256 id;
        uint256 amount;
        uint256 unitPrice;
        bool partialBuying;
        bytes32 verificationID;
    }

    struct SaleInfo {
        address item;
        uint256 id;
        uint256 saleId;
    }

    mapping(address => mapping(uint256 => Sale[])) public sales; //sales[item][id].
    mapping(bytes32 => SaleInfo) internal _saleInfo; //_saleInfo[saleVerificationID].

    mapping(address => bytes32[]) public onSales; //onSales[item]. 아이템 계약 중 onSale 중인 정보들. "return saleVerificationID."
    mapping(bytes32 => uint256) private _onSalesIndex; //_onSalesIndex[saleVerificationID]. 특정 세일의 onSales index.

    mapping(address => bytes32[]) public userSellInfo; //userSellInfo[seller] 셀러가 팔고있는 세일의 정보. "return saleVerificationID."
    mapping(bytes32 => uint256) private _userSellIndex; //_userSellIndex[saleVerificationID]. 특정 세일의 userSellInfo index.

    mapping(uint256 => bytes32[]) public salesOnMetaverse; //salesOnMetaverse[metaverseId]. 특정 메타버스에서 판매되고있는 모든 세일들. "return saleVerificationID."
    mapping(bytes32 => uint256) private _salesOnMvIndex; //_salesOnMvIndex[saleVerificationID]. 특정 세일의 salesOnMetaverse index.

    mapping(address => mapping(address => mapping(uint256 => uint256))) public userOnSaleAmounts; //userOnSaleAmounts[seller][item][id]. 셀러가 판매중인 특정 id의 아이템의 총 합.

    function getSaleInfo(bytes32 saleVerificationID)
        external
        view
        returns (
            address item,
            uint256 id,
            uint256 saleId
        )
    {
        SaleInfo memory saleInfo = _saleInfo[saleVerificationID];
        require(saleInfo.item != address(0));

        return (saleInfo.item, saleInfo.id, saleInfo.saleId);
    }

    function salesCount(address item, uint256 id) external view returns (uint256) {
        return sales[item][id].length;
    }

    function onSalesCount(address item) external view returns (uint256) {
        return onSales[item].length;
    }

    function userSellInfoLength(address seller) external view returns (uint256) {
        return userSellInfo[seller].length;
    }

    function salesOnMetaverseLength(uint256 metaverseId) external view returns (uint256) {
        return salesOnMetaverse[metaverseId].length;
    }

    function canSell(
        address seller,
        uint256 metaverseId,
        address item,
        uint256 id,
        uint256 amount
    ) public view returns (bool) {
        if (!commonData.isItemWhitelisted(metaverseId, item)) return false;

        if (item._isERC1155(commonData.metaverses(), metaverseId)) {
            return (amount > 0) && (userOnSaleAmounts[seller][item][id].add(amount) <= IKIP37(item).balanceOf(seller, id));
        } else {
            return (amount == 1) && (IKIP17(item).ownerOf(id) == seller) && (userOnSaleAmounts[seller][item][id] == 0);
        }
    }

    function sell(
        uint256[] calldata metaverseIds,
        address[] calldata items,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        uint256[] calldata unitPrices,
        bool[] calldata partialBuyings
    ) external {
        require(!commonData.isBannedUser(msg.sender));
        require(
            metaverseIds.length == items.length &&
                metaverseIds.length == ids.length &&
                metaverseIds.length == amounts.length &&
                metaverseIds.length == unitPrices.length &&
                metaverseIds.length == partialBuyings.length
        );
        for (uint256 i = 0; i < metaverseIds.length; i++) {
            uint256 metaverseId = metaverseIds[i];
            address item = items[i];
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            uint256 unitPrice = unitPrices[i];
            bool partialBuying = partialBuyings[i];

            require(unitPrice > 0);
            require(canSell(msg.sender, metaverseId, item, id, amount));

            bytes32 verificationID = keccak256(
                abi.encodePacked(msg.sender, metaverseId, item, id, amount, unitPrice, partialBuying, nonce[msg.sender]++)
            );

            require(_saleInfo[verificationID].item == address(0));

            uint256 saleId = sales[item][id].length;
            sales[item][id].push(
                Sale({
                    seller: msg.sender,
                    metaverseId: metaverseId,
                    item: item,
                    id: id,
                    amount: amount,
                    unitPrice: unitPrice,
                    partialBuying: partialBuying,
                    verificationID: verificationID
                })
            );

            _saleInfo[verificationID] = SaleInfo({item: item, id: id, saleId: saleId});

            _onSalesIndex[verificationID] = onSales[item].length;
            onSales[item].push(verificationID);

            _userSellIndex[verificationID] = userSellInfo[msg.sender].length;
            userSellInfo[msg.sender].push(verificationID);

            _salesOnMvIndex[verificationID] = salesOnMetaverse[metaverseId].length;
            salesOnMetaverse[metaverseId].push(verificationID);

            userOnSaleAmounts[msg.sender][item][id] = userOnSaleAmounts[msg.sender][item][id].add(amount);

            emit Sell(metaverseId, item, id, msg.sender, amount, unitPrice, partialBuying, verificationID);
        }
    }

    function changeSellPrice(bytes32[] calldata saleVerificationIDs, uint256[] calldata unitPrices) external {
        require(!commonData.isBannedUser(msg.sender));
        require(saleVerificationIDs.length == unitPrices.length);
        for (uint256 i = 0; i < saleVerificationIDs.length; i++) {
            SaleInfo storage saleInfo = _saleInfo[saleVerificationIDs[i]];
            address item = saleInfo.item;
            uint256 id = saleInfo.id;

            Sale storage sale = sales[item][id][saleInfo.saleId];
            require(sale.seller == msg.sender);
            require(sale.unitPrice != unitPrices[i]);
            require(unitPrices[i] > 0);

            sale.unitPrice = unitPrices[i];
            emit ChangeSellPrice(sale.metaverseId, item, id, unitPrices[i], saleVerificationIDs[i]);
        }
    }

    function cancelSale(bytes32[] calldata saleVerificationIDs) external {
        for (uint256 i = 0; i < saleVerificationIDs.length; i++) {
            SaleInfo storage saleInfo = _saleInfo[saleVerificationIDs[i]];
            address item = saleInfo.item;
            uint256 id = saleInfo.id;

            Sale storage sale = sales[item][id][saleInfo.saleId];
            require(sale.seller == msg.sender);

            emit CancelSale(sale.metaverseId, item, id, sale.amount, saleVerificationIDs[i]);

            _removeSale(saleVerificationIDs[i]);
        }
    }

    function buy(
        bytes32[] calldata saleVerificationIDs,
        uint256[] calldata amounts,
        uint256[] calldata unitPrices,
        uint256[] calldata mileages
    ) external {
        require(!commonData.isBannedUser(msg.sender));
        require(amounts.length == saleVerificationIDs.length && amounts.length == unitPrices.length && amounts.length == mileages.length);

        IMetaverses metaverses = commonData.metaverses();

        for (uint256 i = 0; i < amounts.length; i++) {
            bytes32 saleVerificationID = saleVerificationIDs[i];
            SaleInfo memory saleInfo = _saleInfo[saleVerificationID];
            Sale storage sale = sales[saleInfo.item][saleInfo.id][saleInfo.saleId];

            address seller = sale.seller;
            uint256 metaverseId = sale.metaverseId;

            require(commonData.isItemWhitelisted(metaverseId, saleInfo.item));
            require(seller != address(0) && seller != msg.sender);
            require(sale.unitPrice == unitPrices[i]);

            uint256 amount = amounts[i];
            uint256 amountLeft;

            {
                uint256 saleAmount = sale.amount;
                if (!sale.partialBuying) {
                    require(saleAmount == amount);
                } else {
                    require(saleAmount >= amount);
                }

                amountLeft = saleAmount.sub(amount);
                sale.amount = amountLeft;
            }

            saleInfo.item._transferItems(metaverses, metaverseId, saleInfo.id, amount, seller, msg.sender);
            uint256 price = amount.mul(unitPrices[i]);

            uint256 _mileage = mileages[i];
            mix.transferFrom(msg.sender, address(this), price.sub(_mileage));
            if (_mileage > 0) mileage.use(msg.sender, _mileage);
            _distributeReward(metaverseId, msg.sender, seller, price);

            userOnSaleAmounts[seller][saleInfo.item][saleInfo.id] = userOnSaleAmounts[seller][saleInfo.item][saleInfo.id].sub(amount);

            bool isFulfilled = false;
            if (amountLeft == 0) {
                _removeSale(saleVerificationID);
                isFulfilled = true;
            }

            emit Buy(metaverseId, saleInfo.item, saleInfo.id, msg.sender, amount, isFulfilled, saleVerificationID);
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
        bytes32 verificationID;
    }

    struct OfferInfo {
        address item;
        uint256 id;
        uint256 offerId;
    }

    mapping(address => mapping(uint256 => Offer[])) public offers; //offers[item][id].
    mapping(bytes32 => OfferInfo) internal _offerInfo; //_offerInfo[offerVerificationID].

    mapping(address => bytes32[]) public userOfferInfo; //userOfferInfo[offeror] 오퍼러의 오퍼들 정보.  "return offerVerificationID."
    mapping(bytes32 => uint256) private _userOfferIndex; //_userOfferIndex[offerVerificationID]. 특정 오퍼의 userOfferInfo index.

    function getOfferInfo(bytes32 offerVerificationID)
        external
        view
        returns (
            address item,
            uint256 id,
            uint256 offerId
        )
    {
        OfferInfo memory offerInfo = _offerInfo[offerVerificationID];
        require(offerInfo.item != address(0));

        return (offerInfo.item, offerInfo.id, offerInfo.offerId);
    }

    function userOfferInfoLength(address offeror) external view returns (uint256) {
        return userOfferInfo[offeror].length;
    }

    function offersCount(address item, uint256 id) external view returns (uint256) {
        return offers[item][id].length;
    }

    function canOffer(
        address offeror,
        uint256 metaverseId,
        address item,
        uint256 id,
        uint256 amount
    ) public view returns (bool) {
        if (!commonData.isItemWhitelisted(metaverseId, item)) return false;
        if (item._isERC1155(commonData.metaverses(), metaverseId)) {
            return (amount > 0);
        } else {
            return (amount == 1) && (IKIP17(item).ownerOf(id) != offeror);
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
    ) external returns (uint256 offerId) {
        require(!commonData.isBannedUser(msg.sender));
        require(unitPrice > 0);
        require(canOffer(msg.sender, metaverseId, item, id, amount));

        bytes32 verificationID = keccak256(
            abi.encodePacked(msg.sender, metaverseId, item, id, amount, unitPrice, partialBuying, _mileage, nonce[msg.sender]++)
        );

        require(_offerInfo[verificationID].item == address(0));

        offerId = offers[item][id].length;
        offers[item][id].push(
            Offer({
                offeror: msg.sender,
                metaverseId: metaverseId,
                item: item,
                id: id,
                amount: amount,
                unitPrice: unitPrice,
                partialBuying: partialBuying,
                mileage: _mileage,
                verificationID: verificationID
            })
        );

        _offerInfo[verificationID] = OfferInfo({item: item, id: id, offerId: offerId});

        _userOfferIndex[verificationID] = userOfferInfo[msg.sender].length;
        userOfferInfo[msg.sender].push(verificationID);

        mix.transferFrom(msg.sender, address(this), amount.mul(unitPrice).sub(_mileage));
        if (_mileage > 0) mileage.use(msg.sender, _mileage);

        emit MakeOffer(metaverseId, item, id, msg.sender, amount, unitPrice, partialBuying, verificationID);
    }

    function cancelOffer(bytes32 offerVerificationID) external {
        OfferInfo storage offerInfo = _offerInfo[offerVerificationID];
        address item = offerInfo.item;
        uint256 id = offerInfo.id;

        Offer storage offer = offers[item][id][offerInfo.offerId];
        require(offer.offeror == msg.sender);

        uint256 amount = offer.amount;
        uint256 _mileage = offer.mileage;

        mix.transfer(msg.sender, amount.mul(offer.unitPrice).sub(_mileage));
        if (_mileage > 0) {
            mix.approve(address(mileage), _mileage);
            mileage.charge(msg.sender, _mileage);
        }

        emit CancelOffer(offer.metaverseId, item, id, amount, offerVerificationID);
        _removeOffer(offerVerificationID);
    }

    function acceptOffer(bytes32 offerVerificationID, uint256 amount) external {
        require(!commonData.isBannedUser(msg.sender));
        OfferInfo storage offerInfo = _offerInfo[offerVerificationID];
        address item = offerInfo.item;
        uint256 id = offerInfo.id;

        Offer storage offer = offers[item][id][offerInfo.offerId];

        address offeror = offer.offeror;
        uint256 metaverseId = offer.metaverseId;
        uint256 offerAmount = offer.amount;

        require(commonData.isItemWhitelisted(metaverseId, item));
        require(offeror != address(0) && offeror != msg.sender);

        if (!offer.partialBuying) {
            require(offerAmount == amount);
        } else {
            require(offerAmount >= amount);
        }

        item._transferItems(commonData.metaverses(), metaverseId, id, amount, msg.sender, offeror);
        uint256 price = amount.mul(offer.unitPrice);

        _distributeReward(metaverseId, offeror, msg.sender, price);

        bool isFulfilled;
        {
            uint256 amountLeft = offerAmount.sub(amount);
            offer.amount = amountLeft;

            if (amountLeft == 0) {
                _removeOffer(offerVerificationID);
                isFulfilled = true;
            }
        }

        emit AcceptOffer(metaverseId, item, id, msg.sender, amount, isFulfilled, offerVerificationID);
    }

    //"cancel" functions with ownership
    function cancelSaleByOwner(bytes32[] calldata saleVerificationIDs) external onlyOwner {
        for (uint256 i = 0; i < saleVerificationIDs.length; i++) {
            SaleInfo storage saleInfo = _saleInfo[saleVerificationIDs[i]];
            address item = saleInfo.item;
            uint256 id = saleInfo.id;

            Sale storage sale = sales[item][id][saleInfo.saleId];
            address seller = sale.seller;
            require(seller != address(0));

            uint256 metaverseId = sale.metaverseId;
            emit CancelSale(metaverseId, item, id, sale.amount, saleVerificationIDs[i]);
            emit CancelSaleByOwner(metaverseId, item, id, saleVerificationIDs[i]);

            _removeSale(saleVerificationIDs[i]);
        }
    }

    function cancelOfferByOwner(bytes32[] calldata offerVerificationIDs) external onlyOwner {
        for (uint256 i = 0; i < offerVerificationIDs.length; i++) {
            OfferInfo storage offerInfo = _offerInfo[offerVerificationIDs[i]];
            address item = offerInfo.item;
            uint256 id = offerInfo.id;

            Offer storage offer = offers[item][id][offerInfo.offerId];
            address offeror = offer.offeror;
            require(offeror != address(0));

            uint256 amount = offer.amount;
            uint256 _mileage = offer.mileage;

            mix.transfer(offeror, amount.mul(offer.unitPrice).sub(_mileage));
            if (_mileage > 0) {
                mix.approve(address(mileage), _mileage);
                mileage.charge(offeror, _mileage);
            }

            uint256 metaverseId = offer.metaverseId;
            emit CancelOffer(metaverseId, item, id, amount, offerVerificationIDs[i]);
            emit CancelOfferByOwner(metaverseId, item, id, offerVerificationIDs[i]);

            _removeOffer(offerVerificationIDs[i]);
        }
    }
}