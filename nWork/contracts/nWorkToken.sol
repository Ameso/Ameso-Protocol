// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/SafeCast.sol';


/// @title nWork application
/// @author Simon Liu & Donald Liu

/**
 * @title nWorkToken contract
 * @dev This is the implementation of the ERC20 nWork Token.
 * The implementation exposes a Permit() function to allow for a spender to send a signed message
 * and approve funds to a spender following EIP2612 to make integration with other contracts easier.
 * EIP2612 describes how to use EIP712 for the Permit() function.
 *
 */
contract nWorkToken {
    using SafeMath for uint256;

    // The EIP-712 typehash for the contract's domain
    bytes32 private constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyContract)");

    /// The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// The EIP-712 typehash for the permit struct used by the contract
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");


    // -- Events --
    event MinterChanged(address minter, address newMinter);

    // An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    // An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    // The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 amount);

    // The standard EIP-20 approval event
    event Approval(address indexed owner, address indexed spender, uint256 amount);


    // -- State --

    // EIP-20 token name for this token
    string public constant name = "nWork";

    // EIP-20 token symbol for this token
    string public constant symbol = "NWK";

    // EIP-20 token decimals for this token
    uint8 public constant decimals = 18;

    uint256 public totalSupply = 1_000_000_000e18; // 1 billion NWK 

    bytes32 private DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    address minter;

    uint256 public mintingAllowedAfter;

    uint256 public minimumTimeBetweenMints = 30 days;

    // A record of each accounts delegate
    mapping (address => address) public delegates;

    // Cap on the percentage of totalSupply that can be minted at each mint
    uint8 public constant mintCap = 2;

    // Allowance amounts on behalf of others
    mapping (address => mapping (address => uint256)) internal allowances;

    // Official record of token balances for each account
    mapping (address => uint256) internal balances;

    // A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    // A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint256 => Checkpoint)) public checkpoints;

    // The number of checkpoints for each account
    mapping (address => uint256) public numCheckpoints;

    /**
     * @dev Construct a new nWork token
     * @param _account Developer account to initially mint tokens
     * @param _minter The account with minting ability
     * @param _initialSupplyDev Amount to give to the dev account
     * @param _initialSupplyMinter Amount to give to the Treasury
     * @param _mintingAllowedAfter The timestamp after which minting may occur
     */
    constructor(address _account, address _minter, uint256 _initialSupplyDev, uint256 _initialSupplyMinter, uint256 _mintingAllowedAfter) {
        require(_mintingAllowedAfter >= block.timestamp, "NWK::constructor: minting can only begin after deployment");

        balances[_account] = _initialSupplyDev;
        emit Transfer(address(0), _account, _initialSupplyDev);

        balances[_minter] = _initialSupplyMinter;
        emit Transfer(address(0), _minter, _initialSupplyMinter);

        minter = _minter;
        emit MinterChanged(address(0), minter);

        mintingAllowedAfter = _mintingAllowedAfter;
    }

    /**
     * @dev Change the minter address
     * @param _minter The address of the new minter
     */
    function setMinter(address _minter) external {
        require(msg.sender == minter, "NWK::setMinter: only the minter can change the minter address");
        emit MinterChanged(minter, _minter);
        minter = _minter;
    }

    /**
     * @dev Mint new tokens
     * @param _dst The address of the destination accoutn
     * @param _amount The number of tokens to be minted
     */
    function mint(address _dst, uint256 _amount) external {
        require(msg.sender == minter, "NWK::mint: only the treasury can mint");
        require(block.timestamp >= mintingAllowedAfter, "NWK::mint: minting not allowed yet");
        require(_dst != address(0), "NWK::mint: cannot transfer to the zero address");

        // record the mint
        mintingAllowedAfter = SafeMath.add(block.timestamp, minimumTimeBetweenMints);

        // mint the amount
        require(_amount <= SafeMath.div(SafeMath.mul(totalSupply, mintCap), 100), "NWK::mint: exceeded mint cap");
        totalSupply = SafeMath.add(totalSupply, _amount);

        // transfer the amount to the recipient
        balances[_dst] = SafeMath.add(balances[_dst], _amount);
        emit Transfer(address(0), _dst, _amount);

        // move delegates
        _moveDelegates(address(0), delegates[_dst], _amount);
    }

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param _account The address of the account holding the funds
     * @param _spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address _account, address _spender) external view returns (uint256) {
        return allowances[_account][_spender];
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param _spender The address of the account which may transfer tokens
     * @param _amount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address _spender, uint256 _amount) external returns (bool) {
        allowances[msg.sender][_spender] = _amount;

        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /**
     * @dev Approve token allowance by validating a message signed by the holder.
     * @param _owner Address of the token holder
     * @param _spender Address of the approved spender
     * @param _value Amount of tokens to approve the spender
     * @param _deadline Expiration time of the signed permit
     * @param _v Signature version
     * @param _r Signature r value
     * @param _s Signature s value
     */
    function permit(address _owner, address _spender, uint256 _value, uint256 _deadline, uint8 _v, bytes32 _r, bytes32 _s) external {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), _getChainID(), address(this)));
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, _owner, _spender, _value, nonces[_owner]++, _deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address recoveredAddress = ecrecover(digest, _v, _r, _s);
        require(_owner != address(0), "NWK::permit: invalid signature");
        require(_owner == recoveredAddress, "NWK::permit: unauthorized");
        require(_deadline == 0 || block.timestamp <= _deadline, "NWK::permit: expired permit");

        allowances[_owner][_spender] = _value;

        emit Approval(_owner, _spender, _value);
    }

    
    /**
     * @notice Get the number of tokens held by the `account`
     * @param _account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address _account) external view returns (uint) {
        return balances[_account];
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param _dst The address of the destination account
     * @param _amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address _dst, uint256 _amount) external returns (bool) {
        _transferTokens(msg.sender, _dst, _amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param _src The address of the source account
     * @param _dst The address of the destination account
     * @param _amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(address _src, address _dst, uint _amount) external returns (bool) {
        address spender = msg.sender;
        uint256 spenderAllowance = allowances[_src][spender];

        if (spender != _src && spenderAllowance != uint256(-1)) {
            uint256 newAllowance = SafeMath.sub(spenderAllowance, _amount);
            allowances[_src][spender] = newAllowance;

            emit Approval(_src, spender, newAllowance);
        }

        _transferTokens(_src, _dst, _amount);
        return true;
    }

    /**
     * @dev Delegate votes from `msg.sender` to `delegatee`
     * @param _delegatee The address to delegate votes to
     */
    function delegate(address _delegatee) public {
        return _delegate(msg.sender, _delegatee);
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number. Counts the delegated votes as voting power.
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param _account The address of the account to check
     * @param _blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address _account, uint _blockNumber) public view returns (uint256) {
        require(_blockNumber < block.number, "NWK::getPriorVotes: not yet determined");
 
        uint256 nCheckpoints = numCheckpoints[_account];

        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[_account][nCheckpoints - 1].fromBlock <= _blockNumber) {
            return checkpoints[_account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[_account][0].fromBlock > _blockNumber) {
            return 0;
        }

        uint256 lower = 0;
        uint256 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint256 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[_account][center];
            if (cp.fromBlock == _blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < _blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[_account][lower].votes;
    }
   
    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint256 delegatorBalance = balances[delegator];
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _transferTokens(address src, address dst, uint256 amount) internal {
        require(src != address(0), "NWK::_transferTokens: cannot transfer from the zero address");
        require(dst != address(0), "NWK::_transferTokens: cannot transfer to the zero address");

        balances[src] = SafeMath.sub(balances[src], amount);
        balances[dst] = SafeMath.add(balances[dst], amount);
        emit Transfer(src, dst, amount);

        _moveDelegates(delegates[src], delegates[dst], amount);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint256 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = SafeMath.sub(srcRepOld, amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint256 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = SafeMath.add(dstRepOld, amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint256 nCheckpoints, uint256 oldVotes, uint256 newVotes) internal {
        uint32 blockNumber = SafeCast.toUint32(block.number);

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    /**
     * @dev Get the running network chain ID.
     * @return The chain ID
     */
    function _getChainID() private pure returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

} 
