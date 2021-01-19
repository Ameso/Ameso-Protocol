// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

interface IAmesoToken {
    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint256);
}