pragma solidity ^0.5.6;

import "../klaytn-contracts/ownership/Ownable.sol";
import "../klaytn-contracts/token/KIP37/KIP37Token.sol";

contract TestERC1155 is KIP37Token(""), Ownable {
    function isTokenExistent(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }
}
