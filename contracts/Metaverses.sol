pragma solidity ^0.5.6;

import "./klaytn-contracts/utils/Address.sol";
import "./klaytn-contracts/ownership/Ownable.sol";
import "./klaytn-contracts/math/SafeMath.sol";
import "./klaytn-contracts/token/KIP17/IKIP17.sol";
import "./klaytn-contracts/access/roles/MinterRole.sol";
import "./klaytn-contracts/token/KIP17/IKIP17Enumerable.sol";
import "./interfaces/IMetaverses.sol";

contract Metaverses is Ownable, IMetaverses {
    using SafeMath for uint256;

    uint256 public metaverseCount;

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
        require(royalty <= 1e3); // max royalty is 10%
        royalties[id] = RoyaltyInfo({
            receiver: receiver,
            royalty: royalty
        });
        emit SetRoyalty(id, receiver, royalty);
    }
    
    mapping(uint256 => string) public extras;

    function setExtra(uint256 id, string calldata extra) onlyManager(id) external {
        extras[id] = extra;
        emit SetExtra(id, extra);
    }

    mapping(uint256 => bool) public onlyKlubsMembership;

    function joinOnlyKlubsMembership(uint256 id) onlyOwner external {
        onlyKlubsMembership[id] = true;
        emit JoinOnlyKlubsMembership(id);
    }

    function exitOnlyKlubsMembership(uint256 id) onlyOwner external {
        onlyKlubsMembership[id] = false;
        emit ExitOnlyKlubsMembership(id);
    }

    mapping(uint256 => bool) public mileageMode;

    function mileageOn(uint256 id) onlyManager(id) external {
        mileageMode[id] = true;
        emit MileageOn(id);
    }

    function mileageOff(uint256 id) onlyManager(id) external {
        mileageMode[id] = false;
        emit MileageOff(id);
    }

    mapping(uint256 => bool) public banned;

    function ban(uint256 id) onlyOwner external {
        banned[id] = true;
        emit Ban(id);
    }

    function unban(uint256 id) onlyOwner external {
        banned[id] = false;
        emit Unban(id);
    }

    // enum ItemType { ERC1155, ERC721 }
    struct ItemProposal {
        uint256 id;
        address addr;
        ItemType itemType;
        address proposer;
    }
    ItemProposal[] public itemProposals;

    function proposeItem(uint256 id, address addr, ItemType itemType) onlyManager(id) external {
        itemProposals.push(ItemProposal({
            id: id,
            addr: addr,
            itemType: itemType,
            proposer: msg.sender
        }));
        emit ProposeItem(id, addr, itemType, msg.sender);
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

    function _addItem(uint256 id, address addr, ItemType itemType) private {
        require(!itemAdded[id][addr]);

        itemAddrs[id].push(addr);
        itemAdded[id][addr] = true;
        itemAddedBlocks[id][addr] = block.number;
        itemTypes[id][addr] = itemType;

        emit AddItem(id, addr, itemType);
    }

    function addItem(uint256 id, address addr, ItemType itemType) onlyManager(id) public {
        require(_itemManagingRoleCheck(addr));
        _addItem(id, addr, itemType);
    }

    function _itemManagingRoleCheck(address addr) internal view returns (bool) {
        if(isOwner()) return true;
        else if(Address.isContract(addr)) {
            (bool success0, bytes memory data0) = addr.staticcall(abi.encodeWithSignature("owner()"));
            if(success0 && (abi.decode(data0, (address)) == msg.sender)) return true;

            (bool success1, bytes memory data1) = addr.staticcall(abi.encodeWithSignature("isMinter(address)", msg.sender));
            if(success1 && (abi.decode(data1, (bool)))) return true;
        } else return false;
    }

    function passProposal(uint256 proposalId) external {
        ItemProposal memory proposal = itemProposals[proposalId];
        require(_itemManagingRoleCheck(proposal.addr));
        _addItem(proposal.id, proposal.addr, proposal.itemType);

        delete itemProposals[proposalId];
    }

    function removeProposal(uint256 proposalId) external {
        ItemProposal storage proposal = itemProposals[proposalId];
        require(existsManager(proposal.id, msg.sender) || _itemManagingRoleCheck(proposal.addr));

        delete itemProposals[proposalId];
    }

    //remove item : unnecessary

    mapping(uint256 => mapping(address => bool)) public itemEnumerables;
    mapping(uint256 => mapping(address => uint256)) public itemTotalSupplies;

    function setItemEnumerable(uint256 id, address addr, bool enumerable) onlyManager(id) public {
        itemEnumerables[id][addr] = enumerable;
        emit SetItemEnumerable(id, addr, enumerable);
    }

    function setItemTotalSupply(uint256 id, address addr, uint256 totalSupply) onlyManager(id) external {
        if (itemEnumerables[id][addr]) {
            setItemEnumerable(id, addr, false);
        }
        itemTotalSupplies[id][addr] = totalSupply;
        emit SetItemTotalSupply(id, addr, totalSupply);
    }

    function getItemTotalSupply(uint256 id, address addr) view external returns (uint256) {
        if (itemEnumerables[id][addr]) {
            return IKIP17Enumerable(addr).totalSupply();
        } else {
            return itemTotalSupplies[id][addr];
        }
    }

    mapping(uint256 => mapping(address => string)) public itemExtras;

    function setItemExtra(uint256 id, address addr, string calldata extra) onlyManager(id) external {
        itemExtras[id][addr] = extra;
        emit SetItemExtra(id, addr, extra);
    }
}