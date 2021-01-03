// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import '@openzeppelin/contracts/math/SafeMath.sol';

contract nWork {
    using SafeMath for uint256;

    struct Job {
        // Unique id for each job
        string ipfsID;

        // Creator of the job listing
        address employer;

        // Max contractors per job
        uint256 maxContractors;
    }

    mapping (string => Job) jobs;
	address treasury;

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
     * @dev
     * @param _ipfsID Unique ID that points to storage in ipfs
     */
    function createJob(string memory _ipfsID, uint256 _baseFee, uint256 _tip) public {
        // Has to pay a minimum base fee

        // Optional tip that will be paid to reviewer 

    }

    function removeJob() public {

    }

    function payReviewers() public {
        // Can only be called by the treasury
        require(msg.sender == treasury, "nWork::payReviewers: only treasury can call this function");
    }
}
