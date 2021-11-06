pragma solidity ^0.5.6;

import "./klaytn-contracts/ownership/Ownable.sol";
import "./klaytn-contracts/token/KIP17/IKIP17.sol";
import "./klaytn-contracts/token/KIP17/KIP17Mintable.sol";
import "./klaytn-contracts/token/KIP17/IKIP17Enumerable.sol";
import "./interfaces/IPFPs.sol";

contract PFPs is Ownable, IPFPs {

    struct PFP {
        address manager;
        bool mintable;
        bool enumerable;
        uint256 totalSupply;
    }
    address[] public pfpAddrs;
    mapping(address => PFP) public pfps;
    mapping(address => bool) public passed;

    function pfpAddrCount() external returns (uint256) {
        return pfpAddrs.length;
    }

    function setPFP(
        address addr,
        bool mintable,
        bool enumerable,
        uint256 totalSupply
    ) external {
        require(msg.sender == owner());

        address manager = pfps[addr].manager;
        require(
            manager == address(0) ||
            manager == msg.sender
        );

        pfps[addr] = PFP({
            manager: msg.sender,
            mintable: mintable,
            enumerable: enumerable,
            totalSupply: totalSupply
        });

        if (mintable == true && KIP17Mintable(addr).isMinter(msg.sender) == true) {
            passed[addr] = true;
            if (pfps[addr].manager == address(0)) {
                pfpAddrs.push(addr);
            }
        }

        emit SetPFP(addr, msg.sender, mintable, enumerable, totalSupply);
    }

    function getTotalSupply(address addr) view external returns (uint256) {
        PFP memory pfp = pfps[addr];
        if (pfp.enumerable == true) {
            return IKIP17Enumerable(addr).totalSupply();
        } else {
            return pfp.totalSupply;
        }
    }

    function pass(address addr) onlyOwner external {
        passed[addr] = true;
        if (pfps[addr].manager == address(0)) {
            pfpAddrs.push(addr);
        }
    }

    function unpass(address addr) onlyOwner external {
        passed[addr] = false;
    }
}