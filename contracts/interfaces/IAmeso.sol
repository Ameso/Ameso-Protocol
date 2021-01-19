// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

interface IAmeso {
    function createJob(bytes memory _ipfsID, address _employer, uint256 _tip) external; 
}