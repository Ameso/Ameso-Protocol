// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import '@openzeppelin/contracts/math/SafeMath.sol';
import './interfaces/IAmeso.sol';
import './interfaces/IAmesoToken.sol';
import 'hardhat/console.sol';

contract Employer {
    using SafeMath for uint256;

    IAmeso public amsApp;

    constructor(address _amsApp) {
        amsApp = IAmeso(_amsApp);
    }

    /**
     * @dev Sends a job to the Ameso Application
     * @param _ipfsHash IPFS id of the job 
     * @param _tip Optional tip for contractors
     *
     */ 
    function createJob(
        string memory _ipfsHash,
        uint256 _minContractors,
        uint256 _maxContractors,
        uint256 _extraEnrollDelay,
        uint256 _jobLength,
        uint256 _tip
    ) public {
        require(_minContractors >= amsApp.minContractors(), "Employer::createJob: Invalid minimum number of contractors");
        require(_maxContractors <= amsApp.maxContractors(), "Employer::createJob: Invalid maximum number of contractors");
        require(_minContractors <= _maxContractors, "Employer::createJob: Minimum number of contracts must be less than or equal to Maximum number");
        require(_extraEnrollDelay >= 0, "Employer::createJob: Invalid extra enrollment delay");
        require(_jobLength > amsApp.minEnrollDelay(), "Employer::createJob: Length of job must be greater than minimum enrollment delay");

        amsApp.createJob(_ipfsHash, msg.sender, _minContractors, _maxContractors, _extraEnrollDelay, _jobLength, _tip);
    }

    /**
     * @dev Cancel the job 
     */
    function cancelJob(
        string memory _ipfsID
    ) public {
        require(amsApp.jobExists(_ipfsID), "Employer::cancelJob: Invalid ipfs ID");

        amsApp.cancelJob(_ipfsID, msg.sender);
    }
}