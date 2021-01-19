// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import '@openzeppelin/contracts/math/SafeMath.sol';
import './interfaces/IAmesoToken.sol';
import 'hardhat/console.sol';

contract Ameso {
    using SafeMath for uint256;
    
    // -- State --
    mapping (address => bool) employers;
    mapping (string => Job) jobs;
    uint256 public jobCount;

    // fee that employer must pay to list job
    // TO DO : per employee or whole job listing?
    uint256 public baseFee;

    // Contract containing actions related to employers
    address public employerHub;

	address public treasury;

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

    constructor(address _treasury, address _ams) {
        treasury = _treasury;
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
     */
    function getJobState(string memory _ipfsID) public view returns (JobState){
    }

    /**
     * @dev
     * @param _ipfsID Unique ID that points to storage in ipfs
     * @param _employer Address of the employer
     * @param _tip Optional tip
     */
    function createJob(
        bytes memory _ipfsID, 
        address _employer,
        uint256 _tip
    ) public {
        require(msg.sender == employerHub, 'Ameso::createJob: must be called by the employerHub');
        
        ams.transferFrom(_employer, treasury, baseFee);

        // Optional tip that will be paid to reviewer 

    }

    function removeJob() public {

    }

    function reviewJob() public {

    }

    function payReviewers() public {
        // Can only be called by the treasury
        require(msg.sender == treasury, "Ameso::payReviewers: only treasury can call this function");

        // Check 
    }
}
