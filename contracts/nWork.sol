// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import '@openzeppelin/contracts/math/SafeMath.sol';

contract nWork {
    using SafeMath for uint256;
    
    mapping (string => Job) jobs;
    uint256 public jobCount;
	address public treasury;

    struct Job {
        // Unique id for each job
        string ipfsID;

        // Creator of the job listing
        address employer;

        // Max contractors per job
        uint256 maxContractors;

        // Min contractors per job
        uint256 minContractors;

        // Contractors enrolled in the job
        mapping (address => bool) contractors;

        // Reviewers enrolled in the job
        mapping (address => bool) reviewers;
    }

    struct Review {
        address reviewer;
    }

    // Possible states that the Contractor may be in for a specific job
    enum ContractorJobState {
        Cancelled,
        Pending,
        Completed
    }

    // Possible states that the job may be in
    enum JobState {
        Active,
        Canceled,
        Expired,
        Completed
    }

    constructor(address _treasury) {
        treasury = _treasury;
    }

    /**
     * @dev Review calls this function to approve/disapprove job done by contractor
     */
    function reviewJob(string memory _ipfsID, bool _approve) public {
        // Add caller to mapping of reviewers

        // Caller cannot review a job multiple times

    }

    function takeJob(string memory _ipfsID) public {
        // Cannot have too many contractors for a job. Limit created by employer
    }

    /**
     * @dev Get the current state of the job
     */
    function getJobState(string memory _ipfsID) public view returns (JobState){
    }

    /**
     * @dev
     * @param _ipfsID Unique ID that points to storage in ipfs
     */
    function createJob(string memory _ipfsID, uint256 _baseFee, uint256 _tip) public {
        // Has to pay a minimum base fee

        // Optional tip that will be paid to reviewer 

    }

    function removeJob() public {

    }

    function reviewJob() public {

    }

    function payReviewers() public {
        // Can only be called by the treasury
        require(msg.sender == treasury, "nWork::payReviewers: only treasury can call this function");

        // Check 
    }
}
