pragma solidity ^0.5.6;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address payable private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address payable) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address payable newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address payable newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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

contract Artists is Ownable, IArtists {

    address[] public artists;
    mapping(address => bool) public added;
    mapping(address => uint256) public addedBlocks;

    function artistCount() view external returns (uint256) {
        return artists.length;
    }

    function add() external {
        require(!added[msg.sender]);

        artists.push(msg.sender);
        added[msg.sender] = true;
        addedBlocks[msg.sender] = block.number;

        emit Add(msg.sender);
    }
    
    mapping(address => uint256) public baseRoyalty;

    function setBaseRoyalty(uint256 _baseRoyalty) external {
        require(_baseRoyalty <= 1e3); // max royalty is 10%
        baseRoyalty[msg.sender] = _baseRoyalty;
        emit SetBaseRoyalty(msg.sender, _baseRoyalty);
    }

    mapping(address => string) public extras;

    function setExtra(string calldata extra) external {
        extras[msg.sender] = extra;
        emit SetExtra(msg.sender, extra);
    }

    mapping(address => bool) public onlyKlubsMembership;

    function joinOnlyKlubsMembership(address addr) onlyOwner external {
        onlyKlubsMembership[addr] = true;
        emit JoinOnlyKlubsMembership(addr);
    }

    function exitOnlyKlubsMembership(address addr) onlyOwner external {
        onlyKlubsMembership[addr] = false;
        emit ExitOnlyKlubsMembership(addr);
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