// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

contract Treasury {

    event NewAdmin(address indexed newAdmin);
    event NewPendingAdmin(address indexed newPendingAdmin);

    address public admin;

    // if we ever want to change the governance contract
    address public pendingAdmin;

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
