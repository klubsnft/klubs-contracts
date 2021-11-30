pragma solidity ^0.5.6;

import "./klaytn-contracts/ownership/Ownable.sol";
import "./interfaces/IArtists.sol";

contract Artists is Ownable, IArtists {

    address[] public artists;
    mapping(address => bool) public added;
    mapping(address => uint256) public addedBlocks;

    function artistCount() view external returns (uint256) {
        return artists.length;
    }

    function add() external {
        require(added[msg.sender] != true);

        artists.push(msg.sender);
        added[msg.sender] = true;
        addedBlocks[msg.sender] = block.number;

        emit Add(msg.sender);
    }

    mapping(address => uint256) public royalties;

    function setRoyalty(uint256 royalty) external {
        require(royalty <= 1e3); // max royalty is 10%
        royalties[msg.sender] = royalty;
        emit SetRoyalty(msg.sender, royalty);
    }
    
    mapping(address => string) public extras;

    function setExtra(string calldata extra) external {
        extras[msg.sender] = extra;
        emit SetExtra(msg.sender, extra);
    }

    mapping(address => bool) public banned;

    function ban(address artist) onlyOwner external {
        banned[artist] = true;
        emit Ban(artist);
    }

    function unban(address artist) onlyOwner external {
        banned[artist] = false;
        emit Unban(artist);
    }
}