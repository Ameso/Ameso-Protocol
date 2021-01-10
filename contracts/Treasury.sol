// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import '@openzeppelin/contracts/math/SafeMath.sol';
import "hardhat/console.sol";

contract Treasury {

    using SafeMath for uint256;

    event NewAdmin(address indexed newAdmin);
    event NewPendingAdmin(address indexed newPendingAdmin);

    // -- State --
    uint256 public constant GRACE_PERIOD = 14 days;
    uint256 public constant MINIMUM_DELAY = 2 days;
    uint256 public constant MAXIMUM_DELAY = 30 days;
    address public admin;

    // if we ever want to change the governance contract
    address public pendingAdmin;

    mapping (address => uint256) stakingBalances;

    uint32 public thawingPeriod;

    /**
     * @param _admin The governance contract
     * @param _delay Delay before we can deploy. Used to allow dependencies to deploy first.
     */
    constructor(address _admin, uint256 _delay) {
        console.log('Deploying');
        console.log(_delay);
        require(_delay >= MINIMUM_DELAY, "Treasury:constructor: Delay must exceed minimum delay");
        require(_delay <= MAXIMUM_DELAY, "Treasury:constructor: Delay must not exceed maximum delay");
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
