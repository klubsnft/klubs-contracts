pragma solidity ^0.5.6;

interface IMileage {
    event AddToWhitelist(address indexed addr);
    event RemoveFromWhitelist(address indexed addr);
    event Charge(address indexed user, uint256 amount);
    event Use(address indexed user, uint256 amount);

    function mileages(address user) external view returns (uint256);
    function mileagePercent() external view returns (uint256);
    function onlyKlubsPercent() external view returns (uint256);
    function whitelist(address addr) external view returns (bool);
    function charge(address user, uint256 amount) external;
    function use(address user, uint256 amount) external;
}
