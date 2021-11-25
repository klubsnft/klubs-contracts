pragma solidity ^0.5.6;

interface IArtists {

    event Add(address indexed artist);
    event SetExtra(address indexed addr, string extra);
    event Ban(address indexed addr);
    event Unban(address indexed addr);

    function artistCount() view external returns (uint256);
    function artists(uint256 index) view external returns (address);
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
