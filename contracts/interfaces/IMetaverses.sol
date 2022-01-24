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
