// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import '@openzeppelin/contracts/math/SafeMath.sol';
import './interfaces/IAmeso.sol';
import './interfaces/IAmesoToken.sol';

contract Employer {
    using SafeMath for uint256;

    constructor(address _amsApp) {

    }

    /**
     * @dev Sends a job to the Ameso Application
     * @param _ipfsHash IPFS id of the job 
     *
     */ 
    function createJob(
        string memory _ipfsHash
    ) public {

    }
}