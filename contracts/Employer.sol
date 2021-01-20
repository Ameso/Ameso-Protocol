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
        uint256 _tip
    ) public {
        amsApp.createJob(_ipfsHash, msg.sender, _tip);
    }

    /**
     * @dev Cancel the job 
     */
    function cancelJob(
        string memory _ipfsHash
    ) public {
        //require(amsApp.jobExists(_ipfsHash));
        //require(msg.sender == am)
    }
}