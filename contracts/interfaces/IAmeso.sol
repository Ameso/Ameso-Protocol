// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

interface IAmeso {
    function jobState(string memory _ipfsID) external view returns (uint);
    function createJob(string memory _ipfsID, address _employer, uint256 _tip) external; 
}