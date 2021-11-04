pragma solidity ^0.5.6;

interface IPFPs {

    event AddPFP(
        address addr,
        address manager,
        bool mintable,
        bool enumerable,
        uint256 totalSupply
    );

    function pfpAddrs(uint256 index) external returns (address);
    function pfpAddrCount() external returns (uint256);
    function pfps(address addr) external returns (
        address manager,
        bool mintable,
        bool enumerable,
        uint256 totalSupply
    );

    function passed(address addr) external returns (bool);
    function addPFP(
        address addr,
        bool mintable,
        bool enumerable,
        uint256 totalSupply
    ) external;
}
