// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import '@openzeppelin/contracts/math/SafeMath.sol';

contract Treasury {

    using SafeMath for uint256;

    event NewAdmin(address indexed newAdmin);
    event NewPendingAdmin(address indexed newPendingAdmin);

    // -- State --

    address public admin;

    // if we ever want to change the governance contract
    address public pendingAdmin;

    mapping (address => uint256) stakingBalances;

    uint32 public thawingPeriod;

    /**
     * @param _admin The governance contract
     */
    constructor(address _admin) {
        admin = _admin;
    }

    function acceptAdmin() public {
        require(msg.sender == pendingAdmin, "Treasury::acceptAdmin: Call must come from pendingAdmin.");
        admin = msg.sender;
        pendingAdmin = address(0);

        emit NewAdmin(admin);
    }

    function setPendingAdmin(address _pendingAdmin) public {
        require(msg.sender == address(this), "Treasury::setPendingAdmin: Call must come from Treasury.");
        pendingAdmin = _pendingAdmin; 

        emit NewPendingAdmin(pendingAdmin);
    }

    /**
     * @dev The treasury will execute functions only if the Governance contract allows of it
     */
    function executeTransaction() public {
        require(msg.sender == admin, "Treasury::executeTransaction: Call must come from admin."); 
    }
}
