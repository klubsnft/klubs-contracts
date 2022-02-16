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

contract ItemStoreCommon is Ownable, IItemStoreCommon {
    using ItemStoreLibrary for *;

    uint256 public fee = 250;
    address public feeReceiver;
    uint256 public auctionExtensionInterval = 300;

    IMetaverses public metaverses;
    IMix public mix;
    IMileage public mileage;

    constructor(
        IMetaverses _metaverses,
        IMix _mix,
        IMileage _mileage
    ) public {
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

    function isMetaverseWhitelisted(uint256 metaverseId) public view returns (bool) {
        return (metaverseId < metaverses.metaverseCount() && !metaverses.banned(metaverseId));
    }

    function isItemWhitelisted(uint256 metaverseId, address item) public view returns (bool) {
        return (isMetaverseWhitelisted(metaverseId) && metaverses.itemAdded(metaverseId, item));
    }

    mapping(address => bool) public isBannedUser;

    function banUser(address user) external onlyOwner {
        isBannedUser[user] = true;
        emit Ban(user);
    }

    function unbanUser(address user) external onlyOwner {
        isBannedUser[user] = false;
        emit Unban(user);
    }

    function batchTransfer(
        uint256[] calldata metaverseIds,
        address[] calldata items,
        uint256[] calldata ids,
        address[] calldata to,
        uint256[] calldata amounts
    ) external {
        require(
            metaverseIds.length == items.length &&
                metaverseIds.length == ids.length &&
                metaverseIds.length == to.length &&
                metaverseIds.length == amounts.length
        );
        require(!isBannedUser[msg.sender]);
        for (uint256 i = 0; i < metaverseIds.length; i++) {
            require(isItemWhitelisted(metaverseIds[i], items[i]));
            items[i]._transferItems(metaverses, metaverseIds[i], ids[i], amounts[i], msg.sender, to[i]);
        }
    }
}