pragma solidity ^0.5.6;

interface IPFPProposalHider {

    event Hide(uint256 indexed proposalId);
    event Show(uint256 indexed proposalId);

    function hiding(uint256 proposalId) view external returns (bool);
    function hide(uint256 proposalId) external;
    function show(uint256 proposalId) external;
}
