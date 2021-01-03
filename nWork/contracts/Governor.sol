pragma solidity ^0.7.0;

import '@openzeppelin/contracts/math/SafeMath.sol';

/**
 * @title nWork Governance contract
 * @dev All contracts that will be owned by a Governor entity should extend this contract.
 */
contract Governor {
    using SafeMath for uint256;

    struct Proposal {
        // Unique id for looking up a proposal
        uint256 id;

        // Creator of the proposal;
        address proposer;

        // The timestamp that the proposal will be available for execution, set once the vote succeeds
        uint eta;

        // Current number of votes in favor of this proposal
        uint forVotes;

        // Current number of votes in opposition to this proposal
        uint againstVotes;

        // Flag marking whether the proposal has been canceled
        bool canceled;

        // Flag marking whether the proposal has been executed
        bool executed;

        // Receipts of ballots for the entire set of voters
        //mapping (address => Receipt) receipts;
    }

    // -- State --

    uint256 public proposalCount;
    TreasuryInterface public treasury;
    NwkInterface public nwk;
    NwkCoreInterface public nwkApp;

    // -- Events --

    event NewPendingOwnership(address indexed from, address indexed to);
    event NewOwnership(address indexed from, address indexed to);

    constructor(address _treasury, address _nwk, address _nwkCore) {
        treasury = TreasuryInterface(_treasury);
        nwk = NwkInterface(_nwk);
        nwkApp = NwkCoreInterface(_nwkCore);
    }

    /**
     * @dev the number of votes in support of a mint required in order for a quorum to be reached
     */
    function quorumVotes() public pure returns (uint256) { return 40_000_000e18; } // 4% of total supply

    /**
     * @dev the number of votes required in order for a voter to become a proposer
     */
    function proposalThreshold() public pure returns (uint256) { return 500_000e18; } // 0.5% of total supply

    /*
    function proNpose() public returns (uint256) {
        require(nwk.getPriorVotes(msg.sender, SafeMath.sub(block.number, 1)) > proposalThreshold(), "Governor::propose: proposer votes below proposal threshold");
		require(targets.length == values.length && targets.length == signatures.length && targets.length == calldatas.length, "Governor::propose: proposal function information arity mismatch");

    }
    */
}

interface TreasuryInterface {
    function executeTransaction(address target, uint value, string calldata signature, bytes calldata data, uint eta) external payable returns (bytes memory);
}

interface NwkInterface {

}

interface NwkCoreInterface {

}