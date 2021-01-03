pragma solidity ^0.7.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import '@openzeppelin/contracts/math/SafeMath.sol';


/// @title nWork application
/// @author Simon Liu
/// nWork allows holders get rewarded for doing work
/// 1. Contractors get paid per task. Base reward + optional tip from employer.
/// 2. Employers list jobs. Must offer base fee determined by curators (a percentage is burned). Employers can tip contractor and curator. 
/// 3. Curators check work of contractors. To enroll, the curator must deposit x tokens. They earn salary (minted), must remain productive or else salary is burned.  
/// 4. PolicyMakers are stakers that determine the base fee for each listing. Also determines salary of curators. 
/// 5. Contract owner (multisig) can check policy makers by minting new coins and dilute policy makers percentage. This shouldn't happen frequently. Is this too much power?

/// How to disincentivize bad behavior:
/// 1. Contractors: before payout, curators will review the work of the contractors. Contractors won't want to spam contract because they have to pay eth gas.
/// 2. Employers: must pay to list jobs
/// 3. Curators: salary determined by policy makers. Can get salary cut if inactive or acting maliciously (determined by policy makers). 
/// 4. PolicyMakers: need quorum before action. Last resort, multi sig wallet can mint new coins to dilute majority vote.
/// 5. Multi Sig Wallet Owner: All other parties dump the coin and render token useless.

/// How to transfer "job data" to blockchain
/// Using chainlink, we determine the official frontend location 
/// This will be initially set by the contract owner. Can be changed with governance token reach quorum.
/// All other information will be stored using ethereum's ipfs. Expensive?

///////////// EDITS 

/// nWork allows holders get rewarded for doing work
/// 1. Contractors get paid per task. Base reward + optional tip from employer.
///    Contractors can also review tasks of other jobs. Trustworthiness is determined by time in contract & social score.
/// 2. Employers list jobs. Must offer base fee determined by curators (a percentage is burned). Employers can tip contractor. 
/// 3. PolicyMakers are stakers that determine the base fee for each listing.
/// 4. Contract owner (multisig) can check policy makers by minting new coins and dilute policy makers percentage. This shouldn't happen frequently. Is this too much power?

/// How to disincentivize bad behavior:
/// 1. Contractors: before payout, curators will review the work of the contractors. Contractors won't want to spam contract because they have to pay eth gas.
///    The longer the contractor has been working, the more trustworth their reviewship.
/// 2. Employers: must pay to list jobs
/// 3. PolicyMakers: need quorum before action. Last resort, multi sig wallet can mint new coins to dilute majority vote.
/// 4. Multi Sig Wallet Owner: All other parties dump the coin and render token useless.

/// How to transfer "job data" to blockchain
/// Store official front end domain name as variable 
/// This will be initially set by the contract owner. Can be changed with governance token reach quorum.
/// All other information will be stored using ethereum's ipfs

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

    // -- State --
    bytes32 private DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    address minter;

    uint256 public mintingAllowedAfter;

    uint256 public minimumTimeBetweenMints = 30 days;

    // Cap on the percentage of totalSupply that can be minted at each mint
    uint8 public constant mintCap = 2;

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
     * @param minter_ The address of the new minter
     */
    function setMinter(address minte external {
        require(msg.sender == minter, "NWK::setMinter: only the minter can change the minter address");
        emit MinterChanged(minter, minter_);
        minter = minter_;
    }

    /**
     * @dev mint coins to treasury only when stakeholders approve
     */
    function mint(uint256 _amount) external {
        require(msg.sender == minter, "NWK::mint: only the treasury can mint");
        require(block.timestamp >= mintingAllowedAfter, "NWK::mint: minting not allowed yet");

        // record the mint
        mintingAllowedAfter = SafeMath.add(block.timestamp, minimumTimeBetweenMints);
        require(_amount <= SafeMath.div(SafeMath.mul(totalSupply(), mintCap), 100), "NWK::mint: exceeded mint cap");

        _mint(msg.sender, _amount);
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