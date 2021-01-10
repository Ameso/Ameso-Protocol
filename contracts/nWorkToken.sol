// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import "@openzeppelin/contracts/cryptography/ECDSA.sol";
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
contract nWorkToken is ERC20 {
    using SafeMath for uint256;

    // -- EIP 712 --
    // All of these contants are hashed together in the constructor. They are a unique identifier for the contract
    // This will be used in the permit function so owners can allow other addresses to spend their tokens
    // This gives the ability to create gasless transactions (EIP2612)
    bytes32 private constant DOMAIN_TYPE_HASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyContract,bytes32 salt)"
    );
    bytes32 private constant DOMAIN_NAME_HASH = keccak256("nWork Token");
    bytes32 private constant DOMAIN_VERSION_HASH = keccak256("0");
    bytes32 private constant DOMAIN_SALT = 0x980cb6eac3e40de8c56a14e3590297fed65690e513fd5c1ef2ced9408b30303f;
    bytes32 private constant PERMIT_TYPE_HASH = keccak256(
        "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
    );

    // -- Events --
    event MinterChanged(address minter, address newMinter);

    // An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    // -- State --
    bytes32 private DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    address minter;

    uint256 public mintingAllowedAfter;

    uint256 public minimumTimeBetweenMints = 30 days;

    // Cap on the percentage of totalSupply that can be minted at each mint
    uint8 public constant mintCap = 2;

    // A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint128 votes;
    }

    // A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    // The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /**
     * @dev Construct a new nWork token
     * @param _account Developer account to initially mint tokens
     * @param _minter The account with minting ability
     * @param _initialSupplyDev Amount to give to the dev account
     * @param _initialSupplyMinter Amount to give to the Treasury
     * @param _mintingAllowedAfter The timestamp after which minting may occur
     */
    constructor(address _account, address _minter, uint256 _initialSupplyDev, uint256 _initialSupplyMinter, uint256 _mintingAllowedAfter) ERC20 ("nWork Token", "NWK") {
        require(_mintingAllowedAfter >= block.timestamp, "NWK::constructor: minting can only begin after deployment");
        
        _mint(_account, _initialSupplyDev);
        emit Transfer(address(0), _account, _initialSupplyDev);

        _mint(_minter, _initialSupplyMinter);
        emit Transfer(address(0), _minter, _initialSupplyMinter);

        minter = _minter;
        emit MinterChanged(address(0), minter);

        mintingAllowedAfter = _mintingAllowedAfter;

        // EIP-712 domain separator
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                DOMAIN_TYPE_HASH,
                DOMAIN_NAME_HASH,
                DOMAIN_VERSION_HASH,
                _getChainID(),
                address(this),
                DOMAIN_SALT
            )
        );
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
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPE_HASH,
                        _owner,
                        _spender,
                        _value,
                        nonces[_owner],
                        _deadline
                    )
                )
            )
        );

        nonces[_owner] = nonces[_owner].add(1);

        address recoveredAddress = ECDSA.recover(digest, abi.encodePacked(_r, _s, _v));
        require(_owner == recoveredAddress, "NWK: invalid permit");
        require(_deadline == 0 || block.timestamp <= _deadline, "NWK: expired permit");

        _approve(_owner, _spender, _value);
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
     * @param _rawAmount The number of tokens to be minted
     */
    function mint(address _dst, uint256 _rawAmount) external {
        require(msg.sender == minter, "NWK::mint: only the treasury can mint");
        require(block.timestamp >= mintingAllowedAfter, "NWK::mint: minting not allowed yet");
        require(_dst != address(0), "NWK::mint: cannot transfer to the zero address");

        // record the mint
        mintingAllowedAfter = SafeMath.add(block.timestamp, minimumTimeBetweenMints);

        // mint the amount
        uint128 amount = SafeCast.toUint128(_rawAmount);
        require(amount <= SafeMath.div(SafeMath.mul(totalSupply(), mintCap), 100), "NWK::mint: exceeded mint cap");

        _mint(_dst, amount);

        // move delegates
    }

     /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param _account The address of the account to check
     * @param _blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address _account, uint _blockNumber) public view returns (uint128) {
        require(_blockNumber < block.number, "NWK::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[_account];
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

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
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

    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint128 oldVotes, uint128 newVotes) internal {
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
