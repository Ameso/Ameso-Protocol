// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import '@openzeppelin/contracts/math/SafeMath.sol';
import './Timelock.sol';

contract Treasury is Timelock{

    using SafeMath for uint256;

    constructor() Timelock() {

    }

}