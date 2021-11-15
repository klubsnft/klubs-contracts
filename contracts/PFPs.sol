pragma solidity ^0.5.6;

import "./klaytn-contracts/ownership/Ownable.sol";
import "./klaytn-contracts/math/SafeMath.sol";
import "./klaytn-contracts/token/KIP17/IKIP17.sol";
import "./klaytn-contracts/token/KIP17/KIP17Mintable.sol";
import "./klaytn-contracts/token/KIP17/IKIP17Enumerable.sol";
import "./interfaces/IPFPs.sol";

contract PFPs is Ownable, IPFPs {
    using SafeMath for uint256;

    struct Proposal {
        address addr;
        address manager;
    }
    Proposal[] public proposals;

    function propose(address addr) external {
        proposals.push(Proposal({
            addr: addr,
            manager: msg.sender
        }));
        emit Propose(addr, msg.sender);
    }

    function proposalCount() view external returns (uint256) {
        return proposals.length;
    }

    address[] public addrs;
    mapping(address => bool) public added;
    mapping(address => uint256) public addedBlocks;

    mapping(address => address[]) public managers;
    mapping(address => mapping(address => uint256)) public managersIndex;
    mapping(address => address[]) public managerPFPs;
    mapping(address => mapping(address => uint256)) public managerPFPsIndex;

    function addrCount() view external returns (uint256) {
        return addrs.length;
    }

    function managerCount(address addr) view external returns (uint256) {
        return managers[addr].length;
    }

    function managerPFPCount(address manager) view external returns (uint256) {
        return managerPFPs[manager].length;
    }

    function add(address addr, address manager) private {
        require(added[addr] != true);

        addrs.push(addr);
        added[addr] = true;
        addedBlocks[addr] = block.number;

        managers[addr].push(manager);
        managerPFPsIndex[manager][addr] = managerPFPs[manager].length;
        managerPFPs[manager].push(addr);

        emit Add(addr, manager);
    }

    function addByOwner(address addr, address manager) onlyOwner public {
        add(addr, manager);
    }

    function addByPFPOwner(address addr) external {
        require(Ownable(addr).owner() == msg.sender);
        add(addr, msg.sender);
    }

    function addByMinter(address addr) external {
        require(KIP17Mintable(addr).isMinter(msg.sender) == true);
        add(addr, msg.sender);
    }

    function passProposal(uint256 proposalId) onlyOwner external {
        Proposal memory proposal = proposals[proposalId];
        add(proposal.addr, proposal.manager);
    }

    function existsManager(address addr, address manager) view public returns (bool) {
        return managers[addr][managersIndex[addr][manager]] == manager;
    }

    modifier onlyManager(address addr) {
        require(isOwner() == true || existsManager(addr, msg.sender) == true);
        _;
    }

    function addManager(address addr, address manager) onlyManager(addr) external {
        require(existsManager(addr, manager) != true);
        managersIndex[addr][manager] = managers[addr].length;
        managers[addr].push(manager);
        managerPFPsIndex[manager][addr] = managerPFPs[manager].length;
        managerPFPs[manager].push(addr);
        emit AddManager(addr, manager);
    }

    function removeManager(address addr, address manager) onlyManager(addr) external {
        require(manager != msg.sender && existsManager(addr, manager) == true);

        uint256 lastIndex = managers[addr].length.sub(1);
        require(lastIndex != 0);
        uint256 index = managersIndex[addr][manager];
        if (index != lastIndex) {
            address last = managers[addr][lastIndex];
            managers[addr][index] = last;
            managersIndex[addr][last] = index;
        }
        managers[addr].length--;
        delete managersIndex[addr][manager];

        lastIndex = managerPFPs[manager].length.sub(1);
        index = managerPFPsIndex[manager][addr];
        if (index != lastIndex) {
            address last = managerPFPs[manager][lastIndex];
            managerPFPs[manager][index] = last;
            managerPFPsIndex[manager][last] = index;
        }
        managerPFPs[manager].length--;
        delete managerPFPsIndex[manager][addr];

        emit RemoveManager(addr, manager);
    }

    mapping(address => bool) public enumerables;
    mapping(address => uint256) public totalSupplies;

    function setEnumerable(address addr, bool enumerable) onlyManager(addr) external {
        enumerables[addr] = enumerable;
        emit SetEnumerable(addr, enumerable);
    }

    function setTotalSupply(address addr, uint256 totalSupply) onlyManager(addr) external {
        totalSupplies[addr] = totalSupply;
        emit SetTotalSupply(addr, totalSupply);
    }

    function getTotalSupply(address addr) view external returns (uint256) {
        if (enumerables[addr] == true) {
            return IKIP17Enumerable(addr).totalSupply();
        } else {
            return totalSupplies[addr];
        }
    }

    struct RoyaltyInfo {
        address receiver;
        uint256 royalty;
    }
    mapping(address => RoyaltyInfo) public royalties;

    function setRoyalty(address addr, address receiver, uint256 royalty) onlyManager(addr) external {
        require(royalty <= 1e3); // max royalty is 10%
        royalties[addr] = RoyaltyInfo({
            receiver: receiver,
            royalty: royalty
        });
        emit SetRoyalty(addr, receiver, royalty);
    }
    
    mapping(address => string) public extras;

    function setExtra(address addr, string calldata extra) onlyManager(addr) external {
        extras[addr] = extra;
        emit SetExtra(addr, extra);
    }

    mapping(address => bool) public banned;

    function ban(address addr) onlyOwner external {
        banned[addr] = true;
        emit Ban(addr);
    }

    function unban(address addr) onlyOwner external {
        banned[addr] = false;
        emit Unban(addr);
    }
}