pragma solidity ^0.5.6;

import "./klaytn-contracts/ownership/Ownable.sol";
import "./interfaces/IPFPProposalHider.sol";

contract PFPProposalHider is Ownable, IPFPProposalHider {

    mapping(uint256 => bool) public hiding;

    function hide(uint256 proposalId) onlyOwner external {
        hiding[proposalId] = true;
        emit Hide(proposalId);
    }

    function show(uint256 proposalId) onlyOwner external {
        hiding[proposalId] = false;
        emit Show(proposalId);
    }
}
