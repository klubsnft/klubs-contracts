pragma solidity ^0.5.6;

import "./klaytn-contracts/token/KIP17/KIP17Full.sol";
import "./klaytn-contracts/token/KIP17/KIP17Burnable.sol";
import "./klaytn-contracts/token/KIP17/KIP17Pausable.sol";
import "./klaytn-contracts/ownership/Ownable.sol";
import "./klaytn-contracts/math/SafeMath.sol";
import "./interfaces/IArtists.sol";

contract Arts is Ownable, KIP17Full("Klubs Arts", "ARTS"), KIP17Burnable, KIP17Pausable {
    using SafeMath for uint256;

    event SetBaseURI(string baseURI);
    event Ban(uint256 indexed id);
    event Unban(uint256 indexed id);

    IArtists public artists;

    constructor(IArtists _artists) public {
        artists = _artists;
    }

    string public baseURI = "https://api.klu.bs/arts/";

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
        emit SetBaseURI(_baseURI);
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "KIP17Metadata: URI query for nonexistent token");
        
        if (tokenId == 0) {
            return string(abi.encodePacked(baseURI, "0"));
        }

        string memory idstr;
        
        uint256 temp = tokenId;
        uint256 digits;
        while (temp != 0) {
            digits += 1;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (tokenId != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(tokenId % 10)));
            tokenId /= 10;
        }
        idstr = string(buffer);

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, idstr)) : "";
    }

    modifier artistWhitelist() {
        require(artists.added(msg.sender) && !artists.banned(msg.sender));
        _;
    }

    mapping(uint256 => address) public artToArtist;
    mapping(address => uint256[]) public artistArts;

    function mint() public artistWhitelist {
        uint256 id = totalSupply();
        _mint(msg.sender, id);
        artToArtist[id] = msg.sender;
        artistArts[msg.sender].push(id);
    }

    function artistArtCount(address artist) external view returns (uint256) {
        return artistArts[artist].length;
    }

    mapping(uint256 => bool) private _banned;

    function ban(uint256 id) onlyOwner external {
        _banned[id] = true;
        emit Ban(id);
    }

    function unban(uint256 id) onlyOwner external {
        _banned[id] = false;
        emit Unban(id);
    }

    function isBanned(uint256 id) external view returns (bool) {
        return _banned[id] || artists.banned(artToArtist[id]);
    }
}
