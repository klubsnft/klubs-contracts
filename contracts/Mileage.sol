pragma solidity ^0.5.6;

import "./klaytn-contracts/ownership/Ownable.sol";
import "./klaytn-contracts/math/SafeMath.sol";
import "./interfaces/IMileage.sol";
import "./interfaces/IMix.sol";

contract Mileage is Ownable, IMileage {
    using SafeMath for uint256;

    mapping(address => uint256) public mileages;
    IMix public mix;

    constructor(IMix _mix) public {
        mix = _mix;
    }

    uint256 public mileagePercent = 100;
    uint256 public onlyKlubsPercent = 50;

    function setMileagePercent(uint256 percent) external onlyOwner {
        require(percent < 9 * 1e3); //max 90%
        mileagePercent = percent;
    }

    function setOnlyKlubsPercent(uint256 percent) external onlyOwner {
        require(percent <= mileagePercent);
        onlyKlubsPercent = percent;
    }

    mapping(address => bool) public whitelist;

    function addToWhitelist(address addr) external onlyOwner {
        whitelist[addr] = true;
        emit AddToWhitelist(addr);
    }

    function removeFromWhitelist(address addr) external onlyOwner {
        whitelist[addr] = false;
        emit RemoveFromWhitelist(addr);
    }

    modifier onlyWhitelist() {
        require(whitelist[msg.sender]);
        _;
    }

    function charge(address user, uint256 amount) external onlyWhitelist {
        mix.transferFrom(msg.sender, address(this), amount);
        mileages[user] = mileages[user].add(amount);
        emit Charge(user, amount);
    }

    function use(address user, uint256 amount) external onlyWhitelist {
        mix.transfer(msg.sender, amount);
        mileages[user] = mileages[user].sub(amount);
        emit Use(user, amount);
    }
}
