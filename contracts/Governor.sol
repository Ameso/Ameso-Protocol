// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/math/SafeMath.sol';
import "hardhat/console.sol";

/**
 * @title Ameso Governance contract
 * @dev All contracts that will be owned by a Governor entity should extend this contract.
 */
contract Governor{
    using SafeMath for uint256;

    string public constant name = "Ameso Governor";

    /// @notice the number of votes in support of a mint required in order for a quorum to be reached
    function quorumVotes() public pure returns (uint) { return 30_000_000e18; } // 3% of total supply

    /// @notice the number of votes required in order for a voter to become a proposer
    function proposalThreshold() public pure returns (uint) { return 1_000_000e18; } // 1% of total supply

    /// @notice The maximum number of actions that can be included in a proposal
    function proposalMaxOperations() public pure returns (uint) { return 10; } // 10 actions

    /// @notice The delay before voting on a proposal may take place, once proposed
    function votingDelay() public pure returns (uint) { return 1; } // 1 block

    /// @notice The duration of voting on a proposal, in blocks
    function votingPeriod() public pure returns (uint) { return 40_320; } // ~7 days in blocks (assuming 15s blocks)
    //function votingPeriod() public pure returns (uint) { return 10; } // for testing 

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

    AmsInterface public ams;

    AmsCoreInterface public AmsApp;

    // Possible states that a proposal may be in
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }


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

        // The block at which voting begins: holders must delegate their votes prior to this block
        uint startBlock;

        // The block at which voting ends: votes must be cast prior to this block
        uint endBlock;

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
        uint256 votes;
    }

    constructor(address _treasury, address _ams, address _amsCore) {
        treasury = TreasuryInterface(_treasury);
        ams = AmsInterface(_ams);
        AmsApp = AmsCoreInterface(_amsCore);
    }

    /**
     * @dev Creates a proposal
     * @param _targets addresses of the contract(s) whom we will call their functions
     * @param _values amount of ether to pass to the targets?
     * @param _signatures bytes to   
     * @param _calldatas transaction data? 
     * @param _description proposal description
     */
    function propose(
        address[] memory _targets,
        uint256[] memory _values,
        string[] memory _signatures,
        bytes[] memory _calldatas,
        string memory _description
    ) public returns (uint256) {
        require(ams.getPriorVotes(msg.sender, SafeMath.sub(block.number, 1)) > proposalThreshold(), "Governor::propose: proposer votes below proposal threshold");
        require(_targets.length == _values.length && _targets.length == _signatures.length && _targets.length == _calldatas.length, "Governor::propose: proposal function information arity mismatch");
        require(_targets.length != 0, "Governor::propose: must provide actions");
        require(_targets.length <= proposalMaxOperations(), "Governor::propose: too many actions");

        uint256 latestProposalId = latestProposalIds[msg.sender];
        if (latestProposalId != 0) {
            ProposalState proposersLatestProposalState = state(latestProposalId);
            require(proposersLatestProposalState != ProposalState.Active, "Governor::propose: one live proposal per proposer, found an already active proposal");
            require(proposersLatestProposalState != ProposalState.Pending, "Governor::propose: one live proposal per proposer, found an already pending proposal");
        }

        uint startBlock = SafeMath.add(block.number, votingDelay());
        uint endBlock = SafeMath.add(startBlock, votingPeriod());

        proposalCount++;
        Proposal storage newProposal = proposals[proposalCount];

        newProposal.id = proposalCount;
        newProposal.proposer = msg.sender;
        newProposal.eta = 0;
        newProposal.targets = _targets;
        newProposal.values = _values;
        newProposal.signatures = _signatures;
        newProposal.calldatas = _calldatas;
        newProposal.startBlock = startBlock;
        newProposal.endBlock = endBlock;
        newProposal.forVotes = 0;
        newProposal.againstVotes = 0;
        newProposal.canceled = false;
        newProposal.executed = false;

        latestProposalIds[newProposal.proposer] = newProposal.id;

        emit ProposalCreated(newProposal.id, msg.sender, _targets, _values, _signatures, _calldatas, startBlock, endBlock, _description);
        return newProposal.id;
    }

    /**
     * @dev Queue successful proposal for execution
     * @param _proposalId The id of the proposal to be executed
     */
    function queue(uint256 _proposalId) public {
        require(state(_proposalId) == ProposalState.Succeeded, "Governor::queue: proposal can only be queued if it is succeeded");
        Proposal storage proposal = proposals[_proposalId];
        uint256 eta = SafeMath.add(block.timestamp, treasury.delay());
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            _queueOrRevert(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], eta);
        }
        proposal.eta = eta;
        emit ProposalQueued(_proposalId, eta);
    }

    function _queueOrRevert(
        address _target,
        uint256 _value,
        string memory _signature,
        bytes memory _data,
        uint256 _eta
    ) internal {
        require(!treasury.queuedTransactions(keccak256(abi.encode(_target, _value, _signature, _data, _eta))), 
            "Governor::_queueOrRevert: proposal action already queued at eta");
        treasury.queueTransaction(_target, _value, _signature, _data, _eta);
    }

    function cancel(uint256 _proposalId) public {
        ProposalState state = state(_proposalId);
        require(state != ProposalState.Executed, "GovernorAlpha::cancel: cannot cancel executed proposal");

        Proposal storage proposal = proposals[_proposalId];
        require(ams.getPriorVotes(proposal.proposer, SafeMath.sub(block.number, 1)) < proposalThreshold(), "GovernorAlpha::cancel: proposer above threshold");

        proposal.canceled = true;
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            treasury.cancelTransaction(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }

        emit ProposalCanceled(_proposalId);
    }

    function getActions(uint256 _proposalId) 
        public 
        view 
        returns (
            address[] memory targets,
            uint256[] memory values,
            string[] memory signatures,
            bytes[] memory calldatas
        )
    {
        Proposal storage p = proposals[_proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

    function getReceipt(
        uint _proposalId,
        address _voter
    ) public 
        view 
        returns (Receipt memory)
    {
        return proposals[_proposalId].receipts[_voter];
    }

    /**
     * @dev This function returns the status of the proposal
     * @param _proposalId The id of the proposal 
     */
    function state(uint256 _proposalId) public view returns (ProposalState) {
        require(proposalCount >= _proposalId && _proposalId > 0, "Governor::state: invalid proposal id");
        Proposal storage proposal = proposals[_proposalId];

        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.number <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < quorumVotes()) {
            return ProposalState.Defeated;
        } else if (proposal.eta == 0) {
            return ProposalState.Succeeded;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.timestamp >= SafeMath.add(proposal.eta, treasury.GRACE_PERIOD())) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }

    /**
     *
     */
    function castVote(uint256 _proposalId, bool _support) public {
        return _castVote(msg.sender, _proposalId, _support);
    }
    
    function castVoteBySig(
        uint _proposalId,
        bool _support,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), _getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(BALLOT_TYPEHASH, _proposalId, _support));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, _v, _r, _s);
        require(signatory != address(0), "Governor::castVoteBySig: invalid signature");
        return _castVote(signatory, _proposalId, _support);
    }

    function _castVote(
        address _voter,
        uint _proposalId,
        bool _support
    ) internal {
        require(state(_proposalId) == ProposalState.Active, "Governor::_castVote: voting is closed");
        Proposal storage proposal = proposals[_proposalId];
        Receipt storage receipt = proposal.receipts[_voter];
        require(receipt.hasVoted == false, "Governor::_castVote: voter already voted");
        uint256 votes = ams.getPriorVotes(_voter, proposal.startBlock);

        if (_support) {
            proposal.forVotes = SafeMath.add(proposal.forVotes, votes);
        } else {
            proposal.againstVotes = SafeMath.add(proposal.againstVotes, votes);
        }

        receipt.hasVoted = true;
        receipt.support = _support;
        receipt.votes = votes;

        emit VoteCast(_voter, _proposalId, _support, votes);
    }

    function _getChainId() internal pure returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}

interface TreasuryInterface {
    function delay() external view returns (uint256);
    function GRACE_PERIOD() external view returns (uint256);
    function queuedTransactions(bytes32 hash) external view returns (bool);
    function queueTransaction(address target, uint256 value, string calldata signature, bytes calldata data, uint256 eta) external returns (bytes32);
    function executeTransaction(address target, uint256 value, string calldata signature, bytes calldata data, uint256 eta) external payable returns (bytes memory);
    function cancelTransaction(address target, uint256 value, string calldata signature, bytes calldata data, uint256 eta) external;
}

interface AmsInterface {
    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint256);
}

interface AmsCoreInterface {
    function takeJob() external view;
}
