// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

interface IAmeso {
    function minContractors() external view returns (uint256);
    function maxContractors() external view returns (uint256);
    function minEnrollDelay() external view returns (uint256);
    function jobExists(string memory _ipfsID) external view returns (bool);
    function jobState(string memory _ipfsID) external view returns (uint256);
    function createJob(string memory _ipfsID, 
                        address _employer,
                        uint256 _minContractors,
                        uint256 _maxContractors,
                        uint256 _extraEnrollDelay,
                        uint256 _jobLength,
                        uint256 _tip) external; 
    function cancelJob(string memory _ipfsID, address _employer) external;
}