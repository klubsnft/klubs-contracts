pragma solidity ^0.5.6;

interface IArtists {

    event Add(address indexed artist);
    event SetExtra(address indexed artist, string extra);
    event Ban(address indexed artist);
    event Unban(address indexed artist);

    function artistCount() view external returns (uint256);
    function artists(uint256 index) view external returns (address);
    function added(address artist) view external returns (bool);
    function addedBlocks(address artist) view external returns (uint256);

    function add() external;

    function extras(address artist) view external returns (string memory);
    function setExtra(string calldata extra) external;

    function banned(address artist) view external returns (bool);
}
