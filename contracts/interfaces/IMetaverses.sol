pragma solidity ^0.5.6;

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

    event ProposeItem(uint256 indexed id, address indexed addr, ItemType itemType, address indexed proposer);
    event AddItem(uint256 indexed id, address indexed addr, ItemType itemType);
    event SetItemEnumerable(uint256 indexed id, address indexed addr, bool enumerable);
    event SetItemTotalSupply(uint256 indexed id, address indexed addr, uint256 totalSupply);
    event SetItemExtra(uint256 indexed id, address indexed addr, string extra);

    function addMetaverse(string calldata extra) external;
    function metaverseCount() view external returns (uint256);

    function managerCount(uint256 id) view external returns (uint256);
    function managers(uint256 id, uint256 index) view external returns (address);
    function managerMetaversesCount(address manager) view external returns (uint256);
    function managerMetaverses(address manager, uint256 index) view external returns (uint256);

    function existsManager(uint256 id, address manager) view external returns (bool);
    function addManager(uint256 id, address manager) external;
    function removeManager(uint256 id, address manager) external;

    function extras(uint256 id) view external returns (string memory);
    function setExtra(uint256 id, string calldata extra) external;

    function royalties(uint256 id) view external returns (address receiver, uint256 royalty);
    function setRoyalty(uint256 id, address receiver, uint256 royalty) external;

    function onlyKlubsMembership(uint256 id) view external returns (bool);
    function mileageMode(uint256 id) view external returns (bool);
    function mileageOn(uint256 id) external;
    function mileageOff(uint256 id) external;
    function banned(uint256 id) view external returns (bool);

    function proposeItem(uint256 id, address addr, ItemType itemType) external;
    function itemProposalCount() view external returns (uint256);

    function itemAddrCount(uint256 id) view external returns (uint256);
    function itemAddrs(uint256 id, uint256 index) view external returns (address);
    function itemAdded(uint256 id, address addr) view external returns (bool);
    function itemAddedBlocks(uint256 id, address addr) view external returns (uint256);
    function itemTypes(uint256 id, address addr) view external returns (ItemType);

    function addItem(uint256 id, address addr, ItemType itemType, string calldata extra) external;
    function passProposal(uint256 proposalId, string calldata extra) external;
    function removeProposal(uint256 proposalId) external;

    function itemEnumerables(uint256 id, address addr) view external returns (bool);
    function setItemEnumerable(uint256 id, address addr, bool enumerable) external;
    function itemTotalSupplies(uint256 id, address addr) view external returns (uint256);
    function setItemTotalSupply(uint256 id, address addr, uint256 totalSupply) external;
    function getItemTotalSupply(uint256 id, address addr) view external returns (uint256);

    function itemExtras(uint256 id, address addr) view external returns (string memory);
    function setItemExtra(uint256 id, address addr, string calldata extra) external;
}
