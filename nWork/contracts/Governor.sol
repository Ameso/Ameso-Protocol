// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/math/SafeMath.sol';

/**
 * @title nWork Governance contract
 * @dev All contracts that will be owned by a Governor entity should extend this contract.
 */
contract Governor {
    using SafeMath for uint256;

    /**
     * @dev the number of votes in support of a mint required in order for a quorum to be reached
     */
    function quorumVotes() public pure returns (uint256) { return 30_000_000e18; } // 3% of total supply

    /**
     * @dev the number of votes required in order for a voter to become a proposer
     */
    function proposalThreshold() public pure returns (uint256) { return 500_000e18; } // 0.5% of total supply


    // -- State --

    // The official record of all proposals ever proposed
    mapping (uint => Proposal) public proposals;

    // The latest proposal for each proposer
    mapping (address => uint) public latestProposalIds;

    // The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    // The EIP-712 typehash for the ballot struct used by the contract
    bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,bool support)");

    uint256 public proposalCount;

    TreasuryInterface public treasury;

    NwkInterface public nwk;

    NwkCoreInterface public nwkApp;

    // -- Events --

    // An event emitted when a new proposal is created
    event ProposalCreated(uint256 id, address proposer, address[] targets, uint[] values, string[] signatures, bytes[] calldatas, uint256 startBlock, uint256 endBlock, string description);

    // An event emitted when a vote has been cast on a proposal
    event VoteCast(address voter, uint256 proposalId, bool support, uint256 votes);

    // An event emitted when a proposal has been canceled
    event ProposalCanceled(uint256 id);

    // An event emitted when a proposal has been queued in the Timelock
    event ProposalQueued(uint256 id, uint256 eta);

    // An event emitted when a proposal has been executed in the Timelock
    event ProposalExecuted(uint256 id);

    struct Proposal {
        // Unique id for looking up a proposal
        uint256 id;

        // Creator of the proposal;
        address proposer;

        // The timestamp that the proposal will be available for execution, set once the vote succeeds
        uint256 eta;

        // The ordered list of target addresses for calls to be made
        address[] targets;

        // The ordered list of values (i.e. msg.value) to be passed to the calls to be made
        uint256[] values;

        // The ordered list of function signatures to be called
        string[] signatures;

        // The ordered list of calldata to be passed to each call
        bytes[] calldatas;

        // Current number of votes in favor of this proposal
        uint256 forVotes;

        // Current number of votes in opposition to this proposal
        uint256 againstVotes;

        // Flag marking whether the proposal has been canceled
        bool canceled;

        // Flag marking whether the proposal has been executed
        bool executed;

        // Receipts of ballots for the entire set of voters
        mapping (address => Receipt) receipts;
    }

    // Ballot receipt record for a voter
    struct Receipt {
        // Whether or not a vote has been cast
        bool hasVoted;

        // Whether or not the voter supports the proposal
        bool support;

        // The number of votes the voter had, which were cast
        uint96 votes;
    }


    constructor(address _treasury, address _nwk, address _nwkCore) {
        treasury = TreasuryInterface(_treasury);
        nwk = NwkInterface(_nwk);
        nwkApp = NwkCoreInterface(_nwkCore);
    }

        /*
    function proNpose() public returns (uint256) {
        require(nwk.getPriorVotes(msg.sender, SafeMath.sub(block.number, 1)) > proposalThreshold(), "Governor::propose: proposer votes below proposal threshold");
		require(targets.length == values.length && targets.length == signatures.length && targets.length == calldatas.length, "Governor::propose: proposal function information arity mismatch");

    }
    */
}

interface TreasuryInterface {
    function executeTransaction(address target, uint256 value, string calldata signature, bytes calldata data, uint256 eta) external payable returns (bytes memory);
}

interface NwkInterface {

}

interface NwkCoreInterface {

}