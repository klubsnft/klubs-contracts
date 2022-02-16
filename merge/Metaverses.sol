pragma solidity ^0.5.6;


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

contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
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

/**
 * @title KIP-17 Non-Fungible Token Standard, optional enumeration extension
 * @dev See http://kips.klaytn.com/KIPs/kip-17-non_fungible_token
 */
contract IKIP17Enumerable is IKIP17 {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
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

contract Metaverses is Ownable, IMetaverses {
    using SafeMath for uint256;

    uint256 public metaverseCount;

    function addMetaverse(string calldata extra) external {
        uint256 id = metaverseCount++;
        _addManager(id, msg.sender);

        if (bytes(extra).length > 0) {
            extras[id] = extra;
            emit SetExtra(id, extra);
        }
    }

    mapping(uint256 => address[]) public managers;
    mapping(uint256 => mapping(address => uint256)) public managersIndex;
    mapping(address => uint256[]) public managerMetaverses;
    mapping(address => mapping(uint256 => uint256)) public managerMetaversesIndex;

    function managerCount(uint256 id) view external returns (uint256) {
        return managers[id].length;
    }

    function managerMetaversesCount(address manager) view external returns (uint256) {
        return managerMetaverses[manager].length;
    }

    function existsManager(uint256 id, address manager) view public returns (bool) {
        return managers[id][managersIndex[id][manager]] == manager;
    }

    modifier onlyManager(uint256 id) {
        require(existsManager(id, msg.sender) || isOwner());
        _;
    }

    function addManager(uint256 id, address manager) onlyManager(id) external {
        require(!existsManager(id, manager));
        require(id < metaverseCount);
        _addManager(id, manager);
    }

    function _addManager(uint256 id, address manager) internal {
        managersIndex[id][manager] = managers[id].length;
        managers[id].push(manager);
        managerMetaversesIndex[manager][id] = managerMetaverses[manager].length;
        managerMetaverses[manager].push(id);
        emit AddManager(id, manager);
    }

    function removeManager(uint256 id, address manager) onlyManager(id) external {
        require(manager != msg.sender && existsManager(id, manager));

        uint256 lastIndex = managers[id].length.sub(1);
        require(lastIndex != 0);
        uint256 index = managersIndex[id][manager];
        if (index != lastIndex) {
            address last = managers[id][lastIndex];
            managers[id][index] = last;
            managersIndex[id][last] = index;
        }
        managers[id].length--;
        delete managersIndex[id][manager];

        lastIndex = managerMetaverses[manager].length.sub(1);
        index = managerMetaversesIndex[manager][id];
        if (index != lastIndex) {
            uint256 last = managerMetaverses[manager][lastIndex];
            managerMetaverses[manager][index] = last;
            managerMetaversesIndex[manager][last] = index;
        }
        managerMetaverses[manager].length--;
        delete managerMetaversesIndex[manager][id];

        emit RemoveManager(id, manager);
    }

    struct RoyaltyInfo {
        address receiver;
        uint256 royalty;
    }
    mapping(uint256 => RoyaltyInfo) public royalties;

    function setRoyalty(uint256 id, address receiver, uint256 royalty) onlyManager(id) external {
        require(id < metaverseCount);
        require(royalty <= 1e3); // max royalty is 10%
        royalties[id] = RoyaltyInfo({
            receiver: receiver,
            royalty: royalty
        });
        emit SetRoyalty(id, receiver, royalty);
    }
    
    mapping(uint256 => string) public extras;

    function setExtra(uint256 id, string calldata extra) onlyManager(id) external {
        require(id < metaverseCount);
        require(bytes(extra).length > 0);
        extras[id] = extra;
        emit SetExtra(id, extra);
    }

    mapping(uint256 => bool) public onlyKlubsMembership;

    function joinOnlyKlubsMembership(uint256 id) onlyOwner external {
        require(id < metaverseCount);
        onlyKlubsMembership[id] = true;
        emit JoinOnlyKlubsMembership(id);
    }

    function exitOnlyKlubsMembership(uint256 id) onlyOwner external {
        require(id < metaverseCount);
        onlyKlubsMembership[id] = false;
        emit ExitOnlyKlubsMembership(id);
    }

    mapping(uint256 => bool) public mileageMode;

    function mileageOn(uint256 id) onlyManager(id) external {
        require(id < metaverseCount);
        mileageMode[id] = true;
        emit MileageOn(id);
    }

    function mileageOff(uint256 id) onlyManager(id) external {
        require(id < metaverseCount);
        mileageMode[id] = false;
        emit MileageOff(id);
    }

    mapping(uint256 => bool) public banned;

    function ban(uint256 id) onlyOwner external {
        require(id < metaverseCount);
        banned[id] = true;
        emit Ban(id);
    }

    function unban(uint256 id) onlyOwner external {
        require(id < metaverseCount);
        banned[id] = false;
        emit Unban(id);
    }

    // enum ItemType { ERC1155, ERC721 }
    struct ItemProposal {
        uint256 id;
        address item;
        ItemType itemType;
        address proposer;
    }
    ItemProposal[] public itemProposals;

    function proposeItem(uint256 id, address item, ItemType itemType) onlyManager(id) external {
        require(id < metaverseCount);
        itemProposals.push(ItemProposal({
            id: id,
            item: item,
            itemType: itemType,
            proposer: msg.sender
        }));
        emit ProposeItem(id, item, itemType, msg.sender);
    }

    function itemProposalCount() view external returns (uint256) {
        return itemProposals.length;
    }

    mapping(uint256 => address[]) public itemAddrs;
    mapping(uint256 => mapping(address => bool)) public itemAdded;
    mapping(uint256 => mapping(address => uint256)) public itemAddedBlocks;
    mapping(uint256 => mapping(address => ItemType)) public itemTypes;

    function itemAddrCount(uint256 id) view external returns (uint256) {
        return itemAddrs[id].length;
    }

    function _addItem(uint256 id, address item, ItemType itemType) private {
        require(!itemAdded[id][item]);

        itemAddrs[id].push(item);
        itemAdded[id][item] = true;
        itemAddedBlocks[id][item] = block.number;
        itemTypes[id][item] = itemType;

        emit AddItem(id, item, itemType);
    }

    function addItem(uint256 id, address item, ItemType itemType, string calldata extra) onlyManager(id) external {
        require(id < metaverseCount);
        require(_itemManagingRoleCheck(item));
        _addItem(id, item, itemType);

        if (bytes(extra).length > 0) {
            itemExtras[id][item] = extra;
            emit SetItemExtra(id, item, extra);
        }
    }

    function updateItemType(uint256 id, address item, ItemType itemType) onlyManager(id) external {
        require(id < metaverseCount);
        require(_itemManagingRoleCheck(item));
        require(itemTypes[id][item] != itemType);
        
        itemTypes[id][item] = itemType;
    }

    function _itemManagingRoleCheck(address item) internal view returns (bool) {
        if(isOwner()) return true;
        else if(Address.isContract(item)) {
            (bool success0, bytes memory data0) = item.staticcall(abi.encodeWithSignature("owner()"));
            if(success0 && (abi.decode(data0, (address)) == msg.sender)) return true;

            (bool success1, bytes memory data1) = item.staticcall(abi.encodeWithSignature("isMinter(address)", msg.sender));
            if(success1 && (abi.decode(data1, (bool)))) return true;
        } else return false;
    }

    function passProposal(uint256 proposalId, string calldata extra) external {
        ItemProposal memory proposal = itemProposals[proposalId];
        require(_itemManagingRoleCheck(proposal.item));
        _addItem(proposal.id, proposal.item, proposal.itemType);

        if (bytes(extra).length > 0) {
            itemExtras[proposal.id][proposal.item] = extra;
            emit SetItemExtra(proposal.id, proposal.item, extra);
        }

        delete itemProposals[proposalId];
    }

    function removeProposal(uint256 proposalId) external {
        ItemProposal storage proposal = itemProposals[proposalId];
        require(existsManager(proposal.id, msg.sender) || _itemManagingRoleCheck(proposal.item));

        delete itemProposals[proposalId];
    }

    //remove item : unnecessary

    mapping(uint256 => mapping(address => bool)) public itemEnumerables;
    mapping(uint256 => mapping(address => uint256)) public itemTotalSupplies;

    function setItemEnumerable(uint256 id, address item, bool enumerable) onlyManager(id) public {
        require(id < metaverseCount);
        require(itemAdded[id][item]);
        if(itemTypes[id][item] == ItemType.ERC1155) {
            require(!enumerable);
        }

        itemEnumerables[id][item] = enumerable;
        emit SetItemEnumerable(id, item, enumerable);
    }

    function setItemTotalSupply(uint256 id, address item, uint256 totalSupply) onlyManager(id) external {
        require(id < metaverseCount);
        require(itemAdded[id][item]);
        if (itemEnumerables[id][item]) {
            setItemEnumerable(id, item, false);
        }
        itemTotalSupplies[id][item] = totalSupply;
        emit SetItemTotalSupply(id, item, totalSupply);
    }

    function getItemTotalSupply(uint256 id, address item) view external returns (uint256) {
        if (itemEnumerables[id][item] && itemTypes[id][item] == ItemType.ERC721) {
            return IKIP17Enumerable(item).totalSupply();
        } else {
            return itemTotalSupplies[id][item];
        }
    }

    mapping(uint256 => mapping(address => string)) public itemExtras;

    function setItemExtra(uint256 id, address item, string calldata extra) onlyManager(id) external {
        require(id < metaverseCount);
        itemExtras[id][item] = extra;
        emit SetItemExtra(id, item, extra);
    }
}