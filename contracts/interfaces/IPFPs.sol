pragma solidity ^0.5.6;

interface IPFPs {

    event Propose(address indexed addr, address indexed manager);
    event Add(address indexed addr, address indexed manager);

    event AddManager(address indexed addr, address indexed manager);
    event RemoveManager(address indexed addr, address indexed manager);

    event SetEnumerable(address indexed addr, bool enumerable);
    event SetTotalSupply(address indexed addr, uint256 totalSupply);

    event SetRoyalty(address indexed addr, address receiver, uint256 royalty);
    event SetExtra(address indexed addr, string extra);

    event Ban(address indexed addr);
    event Unban(address indexed addr);

    function propose(address addr) external;

    function addrCount() view external returns (uint256);
    function addrs(uint256 index) view external returns (address);

    function managerCount(address addr) view external returns (uint256);
    function managers(address addr, uint256 index) view external returns (address);

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
}
