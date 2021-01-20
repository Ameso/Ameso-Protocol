// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import '@openzeppelin/contracts/math/SafeMath.sol';
import './Timelock.sol';

contract Treasury is Timelock{
    using SafeMath for uint256;

    // -- State --

    // Job payments
    mapping(string => uint256) public jobHoldings;

    constructor(address _admin, uint _delay) Timelock(_admin, _delay) {}

    /**
     * 
     */
    function payListing(string memory _ipfsID, address _employer, uint256 _baseFee, uint256 _tip) public {

    }

}