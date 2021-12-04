pragma solidity ^0.5.6;

interface IArtists {

    event Add(address indexed artist);
    event SetBaseRoyalty(address indexed artist, uint256 baseRoyalty);
    event SetExtra(address indexed artist, string extra);
    event JoinOnlyKlubsMembership(address indexed artist);
    event ExitOnlyKlubsMembership(address indexed artist);
    event Ban(address indexed artist);
    event Unban(address indexed artist);

    function artistCount() view external returns (uint256);
    function artists(uint256 index) view external returns (address);
    function added(address artist) view external returns (bool);
    function addedBlocks(address artist) view external returns (uint256);

    function add() external;

    function baseRoyalty(address artist) view external returns (uint256);
    function setBaseRoyalty(uint256 _baseRoyalty) external;

    function extras(address artist) view external returns (string memory);
    function setExtra(string calldata extra) external;

    function onlyKlubsMembership(address artist) view external returns (bool);
    function banned(address artist) view external returns (bool);
}
