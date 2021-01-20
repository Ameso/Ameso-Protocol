// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import '@openzeppelin/contracts/math/SafeMath.sol';
import './interfaces/IAmesoToken.sol';
import './interfaces/ITreasury.sol';
import 'hardhat/console.sol';

contract Ameso {
    using SafeMath for uint256;
    
    // -- State --
    mapping (address => bool) employers;

    // The ipfs hash of the job is the key
    mapping (string => Job) public jobs;

    uint256 public jobCount;

    // fee that employer must pay to list job
    // TO DO : per employee or whole job listing?
    uint256 public baseFee;

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

        // Contractors enrolled in the job
        mapping (address => bool) contractors;

        // Reviewers enrolled in the job
        mapping (address => bool) reviewers;

        // Canceled job
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
        Active,
        Canceled,
        Expired,
        Completed
    }

    constructor(address _treasury, address _ams) {
        treasury = ITreasury(_treasury);
        ams = IAmesoToken(_ams);
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
     * @param _ipfsID The ipfs hash 
     */
    function jobState(string memory _ipfsID) public view returns (JobState){
        require(bytes(_ipfsID).length > 0, 'Ameso::jobState: ipfs ID does not exist');

        Job storage job = jobs[_ipfsID];

        if (job.canceled) {
            return JobState.Canceled;
        }
    }

    /**
     * @dev
     * @param _ipfsID Unique ID that points to storage in ipfs
     * @param _employer Address of the employer
     * @param _tip Optional tip
     */
    function createJob(
        string memory _ipfsID, 
        address _employer,
        uint256 _tip
    ) public {
        require(msg.sender == employerHub, 'Ameso::createJob: must be called by the employerHub');
        // all other checks handled by the employer hub
        
        // keep track of payments in treasury
        treasury.payListing(_ipfsID, _employer, baseFee, _tip);

        jobCount++;
        Job storage newJob = jobs[_ipfsID];
        
    }

    function removeJob() public {

    }

    function reviewJob() public {

    }

    function payReviewers() public {
        // Can only be called by the treasury
        //require(msg.sender == treasury, "Ameso::payReviewers: only treasury can call this function");

        // Check 
    }
}
