// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import '@openzeppelin/contracts/math/SafeMath.sol';
import './interfaces/IAmesoToken.sol';
import './interfaces/ITreasury.sol';
import 'hardhat/console.sol';

contract Ameso {
    using SafeMath for uint256;

    modifier onlyTreasury() {
        require(msg.sender == address(treasury));
        _;
    }

    modifier onlyEmployer() {
        require(msg.sender == employer, "Call must come from employer contract");
        _;
    }

    modifier onlyReviewer() {
        require(msg.sender == reviewer, "Call must come from reviewer contract");
        _;
    }

    modifier onlyContractor() {
        require(msg.sender == contractor, "Call must come from contractor contract");
        _;
    }

    // -- State --
    mapping (address => bool) employers;

    // The ipfs hash of the job is the key
    mapping (string => Job) public jobs;

    uint256 public jobCount;

    // fee that employer must pay to list job
    // TO DO : per employee or whole job listing?
    uint256 public baseFee = 1e18;

    uint256 public maxContractors = 1000000;

    uint256 public minContractors = 1;

    uint256 public contractorPercentage = 75;

    // minimum delay before the job can enroll contractors
    // assume 15s block times
    uint256 public minEnrollDelay = 240;

    // Contract containing actions related to employers
    address public employer;

    // Contract containing actions related to reviewers
    address public reviewer;

    // Contract containing actions related to reviewers
    address public contractor;

    ITreasury public treasury;

    IAmesoToken public ams;

    struct Job {
        // Unique id for each job
        string ipfsID;

        // Creator of the job listing
        address employer;

        // Fee paid at the time of job creation
        uint256 fee; 

        // Tip paid at the time of job creation
        uint256 tip;

        // Max contractors per job
        uint256 maxContractors;

        // Min contractors per job
        uint256 minContractors;

        // The block when the job listing will open
        uint256 startBlock;

        // The block when the job listing will close
        uint256 endBlock;

        // Canceled job
        bool canceled;

        // Cancellation Block
        uint256 cancelBlock;

        // Approval Count
        uint256 approvalCount;

        // Reviewer Count
        uint256 reviewerCount;

        // Contractor Count
        uint256 contractorCount;

        address[] contractors; 

        address[] reviewers;

        // Contractors enrolled in the job
        mapping (address => ContractorReceipt) contractorReceipts;
    }

    struct ContractorReceipt {
        // time of contractor enrollment
        uint256 enrollBlock;

        // ipfs id where work is stored
        string workId;

        // cancellation of job
        bool cancelled;

        ReviewerReceipt[] reviewers;

        // reviewers for the contractor's work
        mapping (address => ReviewerReceipt) reviewerReceipts;
    }

    struct ReviewerReceipt {
        // time of reviewer enrollment
        uint256 enrollBlock;

        // ipfs id where review work is stored
        string workId;

        // approval of the contractor's work
        bool approval;

        // cancellation of review
        bool cancelled;
    }

    // Possible states that the Contractor may be in for a specific job
    enum ContractorJobState {
        Canceled,
        Pending,
        Completed
    }

    // Possible states that the job may be in
    enum JobState {
        Pending, // Enrollment has closed and job is about to start
        Canceled,
        Enrolling,
        Queued,
        PrematureCompletion,
        Completed,
        InProgress,
        Paid
    }

    // -- Events --
    
    // An event emitted when a job has been created
    event JobListed(string cid);

    // An event emitted when a job has been cancelled
    event JobCanceled(string cid);

    // An event emitted when a job has been paid
    event Payout(string cid);
    
    // An event emitted when a job has been paid
    event PromptDelete();

    // An event emitted when a contractor enrolls in a job
    event Enrollment(address contractor, string cid);

    constructor(address _treasury, address _ams, address _employer) {
        treasury = ITreasury(_treasury);
        ams = IAmesoToken(_ams);
        employer = _employer;
    }

    /**
     * @dev Change the maxContractors
     */
    function setMaxContractors(uint256 _max) public onlyTreasury {
    }

    /**
     * @dev Change the base fee 
     */
    function setBaseFee(uint256 _baseFee) public onlyTreasury {
        require(_baseFee > 0, "Ameso::setBaseFee: fee has to be greater than 0");
        baseFee = _baseFee;
    }

    /**
     * @dev Review calls this function to approve/disapprove job done by contractor
     */
    function reviewJob(
        string memory _ipfsID,
        bool _approve
    ) public
        onlyReviewer
    {
        // Add caller to mapping of reviewers


        // Caller cannot review a job multiple times

    }

    function enrollJob(string memory _cid, address contractor) public onlyContractor {
        // most checks done on Contractor contract
        Job storage job = jobs[_cid];
        job.contractorCount++;

        // create receipt for enrollment 
        require(job.contractorReceipts[contractor].enrollBlock == 0, "Ameso::enrollJob: contractor already enrolled in job");
        ContractorReceipt storage newReceipt = job.contractorReceipts[contractor];
        newReceipt.enrollBlock = block.number;
        newReceipt.cancelled = false;

        emit Enrollment(contractor, _cid);
    }

    function leaveJob(string memory _cid, address contractor) public onlyContractor {
        // most checks done on Contractor contract
        Job storage job = jobs[_cid];

        require(job.contractorReceipts[contractor].enrollBlock > 0, "Ameso::leaveJob: contractor is not part of job");
        ContractorReceipt storage receipt = job.contractorReceipts[contractor];
    }

    /**
     * @dev Get the current state of the job
     * @param _ipfsID The ipfs hash 
     */
    function jobState(string memory _ipfsID) public view returns (JobState){
        require(bytes(_ipfsID).length > 0, 'Ameso::jobState: ipfs ID does not exist');

        Job storage job = jobs[_ipfsID];

        if (job.canceled && job.cancelBlock < job.startBlock) {
            return JobState.Canceled;
        } else if (job.canceled && job.cancelBlock >= job.startBlock) {
            return JobState.PrematureCompletion;
        } else if (block.number <= job.startBlock && job.contractorCount < job.maxContractors) {
            return JobState.Enrolling;
        } else if (block.number <= job.startBlock) {
            return JobState.Pending;
        } 
    }

    /**
     * @dev Checks if job exists
     */
    function jobExists(string memory _ipfsID) public view returns (bool) {
        require(bytes(_ipfsID).length > 0, "Ameso::jobExists: no ipfs ID provided");

        if(bytes(jobs[_ipfsID].ipfsID).length > 0) {
            return true;
        }

        return false;
    }

    /**
     * @dev
     * @param _ipfsID Unique ID that points to storage in ipfs
     * @param _employer Address of the employer
     * @param _minContractors Minimum number of contractors 
     * @param _maxContractors Maximum number of contractors
     * @param _tip Optional tip paid to the contractor(s)
     */
    function createJob(
        string memory _ipfsID, 
        address _employer,
        uint256 _minContractors,
        uint256 _maxContractors,
        uint256 _extraEnrollDelay,
        uint256 _jobLength,
        uint256 _tip
    ) public 
       onlyEmployer
    {
        // all other checks handled by the employer hub
        // keep track of payments in treasury
        treasury.payListing(_ipfsID, _employer, baseFee, _tip);

        uint256 delay = SafeMath.add(_extraEnrollDelay, minEnrollDelay);
        uint256 startBlock = SafeMath.add(block.number, delay);
        uint256 endBlock = SafeMath.add(startBlock, _jobLength);

        jobCount++;
        Job storage newJob = jobs[_ipfsID];

        newJob.ipfsID = _ipfsID; 
        newJob.employer = _employer;
        newJob.minContractors = _minContractors;
        newJob.maxContractors = _maxContractors;
        newJob.startBlock = startBlock;
        newJob.endBlock = endBlock;
        newJob.canceled = false;

        emit JobListed(_ipfsID);
    }

    /**
     * @dev 
     */
    function cancelJob(
        string memory _ipfsID,
        address _employer
    ) public
        onlyEmployer 
    {
        require(jobState(_ipfsID) == JobState.Pending || jobState(_ipfsID) == JobState.Enrolling, "Ameso::cancelJob: Job must be pending or enrolling"); 

        Job storage selectedJob = jobs[_ipfsID];
        selectedJob.cancelBlock = block.number;
        selectedJob.canceled = true;
    }

    /**
     * @dev Returns number of approved work for a given job
     */
    function getApproved(string memory _ipfsID) public view returns (uint256) {
        Job storage job = jobs[_ipfsID];
        return job.approvalCount;
    }

    /**
     * @dev 
     */
    function payout(string memory _ipfsID) public {
        require(jobState(_ipfsID) == JobState.Completed || jobState(_ipfsID) == JobState.PrematureCompletion, "Ameso::payout: Can only be paid when job is completed");
        Job storage job = jobs[_ipfsID];

        uint256 contractorPool = (job.fee + job.tip) * contractorPercentage/100;
        uint256 reviewerPool = (job.fee + job.tip) * (1 - contractorPercentage/100);

        uint256 individualAmt = contractorPool / job.approvalCount;
        uint256 individualReviewerAmt = reviewerPool / job.reviewerCount;

        for (uint256 i = 0; i < job.approvalCount; i++) {
            address to = job.contractors[i];
            treasury.payout(to, individualAmt);
        }

        for (uint256 i = 0; i < job.reviewerCount; i++) {
            address to = job.reviewers[i];
            treasury.payout(to, individualReviewerAmt);
        }
         
        emit Payout(_ipfsID);
    }
}
