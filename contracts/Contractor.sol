// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import '@openzeppelin/contracts/math/SafeMath.sol';
import './interfaces/IAmeso.sol';
import './interfaces/IAmesoToken.sol';
import 'hardhat/console.sol';

contract Contractor {
    using SafeMath for uint256;

    IAmeso public amsApp;

    constructor(address _amsApp) {
        amsApp = IAmeso(_amsApp);
    }

    /**
     * @dev Enrolls in a job
     *
     */ 
    function enrollJob(string memory _cid) public {
        require(amsApp.jobExists(_cid), "Contractor::enrollJob: Invalid ipfs ID");
        require(amsApp.jobState(_cid) == 2); // Enrolling status

        amsApp.enrollJob(_cid, msg.sender);
    }

    /**
     * @dev Leave job
     */
    function leaveJob(string memory _cid) public {
        require(amsApp.jobExists(_cid), "Contractor::cancelJob: Invalid ipfs ID");
        uint256 jobStatus = amsApp.jobState(_cid);
        require(jobStatus == 2 || jobStatus == 3); // Enrolling status

        amsApp.cancelJob(_cid, msg.sender);
    }
}