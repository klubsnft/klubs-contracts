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

// SPDX-License-Identifier: MIT
contract IKIP37Receiver is IKIP13 {
    /**
        @dev Handles the receipt of a single KIP37 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onKIP37Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xe78b3325, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onKIP37Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onKIP37Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple KIP37 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onKIP37BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0x9b49e332, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onKIP37BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onKIP37BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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

// SPDX-License-Identifier: MIT
contract KIP37Receiver is KIP13, IKIP37Receiver {
    constructor() public {
        _registerInterface(
            KIP37Receiver(0).onKIP37Received.selector ^
                KIP37Receiver(0).onKIP37BatchReceived.selector
        );
    }
}

// SPDX-License-Identifier: MIT
contract KIP37Holder is KIP37Receiver {
    function onKIP37Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public returns (bytes4) {
        return this.onKIP37Received.selector;
    }

    function onKIP37BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public returns (bytes4) {
        return this.onKIP37BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
contract IERC1155Receiver is IKIP13 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
contract ERC1155KIP37Holder is KIP37Holder, IERC1155Receiver {
    constructor() public {
        _registerInterface(IERC1155Receiver(0).onERC1155Received.selector ^ IERC1155Receiver(0).onERC1155BatchReceived.selector);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
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

interface IItemStoreAuction {
    event CreateAuction(
        uint256 indexed metaverseId,
        address indexed item,
        uint256 id,
        address seller,
        uint256 amount,
        uint256 startPrice,
        uint256 endBlock,
        bytes32 indexed auctionVerificationID
    );
    event CancelAuction(uint256 indexed metaverseId, address indexed item, uint256 id, bytes32 indexed auctionVerificationID);

    event Bid(
        uint256 indexed metaverseId,
        address indexed item,
        uint256 id,
        address bidder,
        uint256 amount,
        uint256 price,
        bytes32 indexed auctionVerificationID,
        uint256 biddingId
    );
    event Claim(
        uint256 indexed metaverseId,
        address indexed item,
        uint256 id,
        address bestBidder,
        uint256 amount,
        uint256 price,
        bytes32 indexed auctionVerificationID,
        uint256 biddingId
    );

    event CancelAuctionByOwner(uint256 indexed metaverseId, address indexed item, uint256 id, bytes32 indexed auctionVerificationID);

    function commonData() external view returns (IItemStoreCommon);

    function nonce(address user) external view returns (uint256);

    //Auction
    function auctions(
        address item,
        uint256 id,
        uint256 auctionId
    )
        external
        view
        returns (
            address seller,
            uint256 metaverseId,
            address _item,
            uint256 _id,
            uint256 amount,
            uint256 startTotalPrice,
            uint256 endBlock,
            bytes32 verificationID
        );

    function onAuctions(address item, uint256 index) external view returns (bytes32 auctionVerificationID);

    function userAuctionInfo(address seller, uint256 index) external view returns (bytes32 auctionVerificationID);

    function auctionsOnMetaverse(uint256 metaverseId, uint256 index) external view returns (bytes32 auctionVerificationID);

    function getAuctionInfo(bytes32 auctionVerificationID)
        external
        view
        returns (
            address item,
            uint256 id,
            uint256 auctionId
        );

    function auctionsCount(address item, uint256 id) external view returns (uint256);

    function onAuctionsCount(address item) external view returns (uint256);

    function userAuctionInfoLength(address seller) external view returns (uint256);

    function auctionsOnMetaverseLength(uint256 metaverseId) external view returns (uint256);

    function canCreateAuction(
        address seller,
        uint256 metaverseId,
        address item,
        uint256 id,
        uint256 amount
    ) external view returns (bool);

    function createAuction(
        uint256 metaverseId,
        address item,
        uint256 id,
        uint256 amount,
        uint256 startTotalPrice,
        uint256 endBlock
    ) external returns (uint256 auctionId);

    function cancelAuction(bytes32 auctionVerificationID) external;

    //Bidding
    function biddings(bytes32 auctionVerificationID, uint256 biddingId)
        external
        view
        returns (
            address bidder,
            uint256 metaverseId,
            address item,
            uint256 id,
            uint256 amount,
            uint256 price,
            uint256 mileage
        );

    function userBiddingInfo(address bidder, uint256 index) external view returns (bytes32 auctionVerificationID, uint256 biddingId);

    function userBiddingInfoLength(address bidder) external view returns (uint256);

    function biddingsCount(bytes32 auctionVerificationID) external view returns (uint256);

    function canBid(
        address bidder,
        uint256 price,
        bytes32 auctionVerificationID
    ) external view returns (bool);

    function bid(
        bytes32 auctionVerificationID,
        uint256 price,
        uint256 mileage
    ) external returns (uint256 biddingId);

    function claim(bytes32 auctionVerificationID) external;
}

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