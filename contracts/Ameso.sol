// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import '@openzeppelin/contracts/math/SafeMath.sol';
import './interfaces/IAmesoToken.sol';
import './interfaces/ITreasury.sol';
import 'hardhat/console.sol';

contract Ameso {
    using SafeMath for uint256;

    modifier onlyController() {
        require(msg.sender == address(treasury));
        _;
    }

    modifier onlyEmployerHub() {
        require(msg.sender == employerHub, "Call must come from employer hub contract");
        _;
    }

    
    // -- State --
    mapping (address => bool) employers;

    // The ipfs hash of the job is the key
    mapping (string => Job) public jobs;

    uint256 public jobCount;

    // fee that employer must pay to list job
    // TO DO : per employee or whole job listing?
    uint256 public baseFee;

    uint256 public maxContractors = 1000000;

    uint256 public minContractors = 1;

    // minimum delay before the job can enroll contractors
    // assume 15s block times
    uint256 public minEnrollDelay = 240;

    // Contract containing actions related to employers
    address public employerHub;

	ITreasury public treasury;

    IAmesoToken public ams;

    struct Job {
        // Unique id for each job
        string ipfsID;

        // Creator of the job listing
        address employer;

        // Max contractors per job
        uint256 maxContractors;

        // Min contractors per job
        uint256 minContractors;

        // Amount of time given to each contractor to finish job
        uint256 allocatedTime;

        // The block when the job listing will open
        uint256 startBlock;

        // The block when the job listing will close
        uint256 endBlock;

        // Canceled job
        bool canceled;

        // Contractors enrolled in the job
        mapping (address => ContractorReceipt) contractorReceipts;

        // Reviewers enrolled in the job
        mapping (address => ReviewerReceipt) reviewerReceipts;
    }

    struct ContractorReceipt {
        // time of contractor enrollment
        uint256 enrollTime;

        // cancellation of job
        bool canceled;
    }

    struct ReviewerReceipt {
        // time of reviewer enrollment
        uint256 enrollTime;

        // cancellation of review
        bool canceled;
    }

    // Possible states that the Contractor may be in for a specific job
    enum ContractorJobState {
        Canceled,
        Pending,
        Completed
    }

    // Possible states that the job may be in
    enum JobState {
        Pending,
        Canceled,
        Enrolling,
        Queued,
        Completed
    }

    // -- Events --
    
    // An event emitted when a job has been created
    event JobListed(string ipfsID);

    // An event emitted when a job has been cancelled
    event JobCanceled(string ipfsID);

    constructor(address _treasury, address _ams, address _employer) {
        treasury = ITreasury(_treasury);
        ams = IAmesoToken(_ams);
        employerHub = _employer;
    }

    /**
     * @dev Change the maxContractors
     */
    function setMaxContractors(uint256 _max) public onlyController {
    }

    /**
     * @dev Change the base fee 
     */
    function setBaseFee(uint256 _baseFee) public onlyController {
    }

    /**
     * @dev Review calls this function to approve/disapprove job done by contractor
     */
    function reviewJob(string memory _ipfsID, bool _approve) public {
        // Add caller to mapping of reviewers

        // Caller cannot review a job multiple times

    }

    function enrollJob(string memory _ipfsID) public {
        // Cannot have too many contractors for a job. Limit created by employer
    }

    /**
     * @dev Get the current state of the job
     * @param _ipfsID The ipfs hash 
     */
    function jobState(string memory _ipfsID) public view returns (JobState){
        require(bytes(_ipfsID).length > 0, 'Ameso::jobState: ipfs ID does not exist');

        Job storage job = jobs[_ipfsID];

        if (job.canceled) {
            return JobState.Canceled;
        } else if (block.number <= startBlock) {
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
       onlyEmployerHub
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

    function cancelJob(
        string memory _ipfsID,
        address _employer
    ) public
        onlyEmployerHub 
    {
        JobState state = jobState(_ipfsID);
        require(state == JobState.Pending || state == JobState.Enrolling, "Ameso::cancelJob: Job must be pending or enrolling"); 

        Job storage selectedJob = jobs[_ipfsID];
        selectedJob.canceled = true;
    }

    function reviewJob() public {

    }

    function payReviewers() public {
        // Can only be called by the treasury
        //require(msg.sender == treasury, "Ameso::payReviewers: only treasury can call this function");

        // Check 
    }
}
