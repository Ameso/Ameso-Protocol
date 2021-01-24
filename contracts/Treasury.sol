// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import '@openzeppelin/contracts/math/SafeMath.sol';
import './interfaces/IAmesoToken.sol';
import './Timelock.sol';

contract Treasury is Timelock{
    using SafeMath for uint256;

    modifier onlyAmeso() {
        require(msg.sender == amsApp, "Call must come from the Ameso contract");
        _;
    }

    // -- State --
    address amsApp; 

    IAmesoToken public ams;

    // Job payments
    mapping(string => uint256) public jobHoldings;

    constructor(address _admin, address _ameso, uint _delay) Timelock(_admin, _delay) {
        amsApp = _ameso;    
    }

    /**
     * 
     */
    function payListing(string memory _ipfsID, address _employer, uint256 _baseFee, uint256 _tip) public {

    }

    /**
     * 
     */
    function payout(
        address _to,
        uint256 _amt
    ) public 
        onlyAmeso
    {
        ams.transfer(_to, _amt);
    }

}