const nWorkToken = artifacts.require("nWorkToken.sol");
const truffleAssert = require('truffle-assertions');
const { toBN, advanceBlock, takeSnapshot, revertToSnapShot, getCurrentEpochTime, DEVAMT, TREASURYAMT } = require('./utils.js');
 

contract("nWorkToken", async addresses => {
    const [admin, user1, user2, user3, user4, _] = addresses;
    let nWorkInstance = null;
    let minter;
    
    describe('Basic deployment', async () => {    
        it('Can deploy nWork token', async () => {
            minter = user2; 
            nWorkInstance = await nWorkToken.new(user1, minter, DEVAMT, TREASURYAMT, getCurrentEpochTime())
            let totalSupply = await nWorkInstance.totalSupply();
            assert(totalSupply.toString() === DEVAMT.add(TREASURYAMT).toString(), `Incorrect total supply: ${totalSupply.toString()}`);
        })
    })

    describe('Minting', async () => {
        it('Proper minting permissions and test basic minting', async () => {
            let snapShotId = await takeSnapshot();

            // advance blockchain time so we can start minting (check allowmintafter time in contract)
            await advanceBlock();

            newBlock = await web3.eth.getBlock('latest');

            // try to mint even though address is not minter
            // deployer (admin in this case) isn't the one that becomes the minter by default
            await truffleAssert.reverts(
                nWorkInstance.mint(user1, 10, {from: admin}),
                "NWK::mint: only the treasury can mint"
            ); 

            await nWorkInstance.mint(user2, 1, {from: minter});
            let newTreasuryBalance = await nWorkInstance.balanceOf(user2);
            assert(newTreasuryBalance.toString() === TREASURYAMT.add(toBN(1)).toString(), `Incorrect treasury balance: ${newTreasuryBalance.toString()}`);

            // should not allow mint again. Too soon
            await truffleAssert.reverts(
                nWorkInstance.mint(user2, 1, {from: minter}),
                "NWK::mint: minting not allowed yet"
            )

            await revertToSnapShot(snapShotId.result);
        });

        it('Cannot mint too much tokens', async () => {
            let snapShotId = await takeSnapshot();

            // should not be able to mint past 2 percent
            await truffleAssert.reverts(
                nWorkInstance.mint(user2, DEVAMT.add(TREASURYAMT).mul(toBN(2)).div(toBN(100)).add(toBN(1)), {from: minter}),
                "NWK::mint: exceeded mint cap"
            );
            
            await nWorkInstance.mint(user2, DEVAMT.add(TREASURYAMT).mul(toBN(2)).div(toBN(100)), {from: minter});

            await revertToSnapShot(snapShotId.result);
        });

        it('Can change the minter', async () => {
            let snapShotId = await takeSnapshot();

            await nWorkInstance.setMinter(user3, {from: minter});

            await truffleAssert.reverts(
                nWorkInstance.mint(user2, 100, {from: minter}),
                "NWK::mint: only the treasury can mint"
            )

            await nWorkInstance.mint(user2, 100, {from: user3});

            // user3 should still have 0 and user2 should have all balance
            let user3TreasuryBal = await nWorkInstance.balanceOf(user3);
            let user2TreasuryBal = await nWorkInstance.balanceOf(user2);

            assert(user3TreasuryBal.toString() === "0", `User3 incorrect balance: ${user3TreasuryBal.toString()}`);
            assert(user2TreasuryBal.toString() === TREASURYAMT.add(toBN(100)).toString(), "User2 incorrect balance: " + user2TreasuryBal.toString());

            await revertToSnapShot(snapShotId.result);
        });

    })

    describe('Allowance without permit', async () => {
        it('User can set allowance to -1 to indicate infinite spending', async () => {

        })

        it('Simple allowance to allow another user to spend my tokens', async () => {
            let thousandNWKtokens = web3.utils.toWei('1000', 'ether');

            await nWorkInstance.approve(user3, thousandNWKtokens, {from: user1});

            let allowedAmount = await nWorkInstance.allowance(user1, user3);

            let user1Bal = await nWorkInstance.balanceOf(user1);

            assert(allowedAmount.toString() === thousandNWKtokens, `Incorrect allowance amount: ${allowedAmount.toString()}`)

            // once approved, user3 should be able to spend tokens.
            // only the recipient (user3) should be able to execute the transferFrom
            await truffleAssert.fails(
                nWorkInstance.transferFrom(user1, user3, thousandNWKtokens, {from: admin})
            )
            await nWorkInstance.transferFrom(user1, user3, thousandNWKtokens, {from: user3});

            let user3NewBal = await nWorkInstance.balanceOf(user3);

            assert(user3NewBal.toString() === thousandNWKtokens, `User3 does not have the correct balance: ${user3NewBal.toString()}`);

            let user1NewBal = await nWorkInstance.balanceOf(user1);

            assert(user1NewBal.toString() === DEVAMT.sub(toBN(thousandNWKtokens)).toString(), `User1 did not have their balance removed: ${user1NewBal.toString()}`);
        })

        it('User should not be able to spend more than allowed tokens', async () => {
        })   

        it('What happens with negative allowance', async () => {

        })
    })
   
    describe('Allowance with permit', async () => {
        it('Use the permit function to allow another address to spend my tokens', async () => {

        })
    }) 

    describe('Delegation', async () => {
        it('Delegating (non mint)', async () => {
            let snapShotId = await takeSnapshot()

            let tx = await nWorkInstance.delegate(admin, {from: user2})

            truffleAssert.eventEmitted(tx, 'DelegateChanged', (ev) => {
                return ev.delegator == user2 && ev.fromDelegate == 0 && ev.toDelegate == admin
            })

            let myDelegate = await nWorkInstance.delegates(user2)

            assert(myDelegate === admin, `Incorrect delegator, return : ${myDelegate} , should be: ${admin}`) 

            // Checkpoint created from delegating
            let adminNumChkPt = await nWorkInstance.numCheckpoints(admin) 
            assert(adminNumChkPt.toString() === "1", `Incorrect number of checkpoints : ${adminNumChkPt.toString()}`)
            let adminChkPt = await nWorkInstance.checkpoints(admin, 0)
            assert(adminChkPt.votes.toString() === TREASURYAMT.toString(), `Incorrect number of votes delegated: ${adminChkPt.votes.toString()}`)
            
            await revertToSnapShot(snapShotId.result)
        })

        it('Delegating (after mint)', async () => {
            let beforeNumChkPnt = await nWorkInstance.numCheckpoints(minter)

            await nWorkInstance.mint(minter, 99, {from: minter}) 
		
            let numChkPnt = await nWorkInstance.numCheckpoints(minter)

            //////////// TO DO
        });

    })

    describe('Voting', async () => {
        it('Try get prior votes', async () => {
            newBlock = await web3.eth.getBlock('latest')

            await truffleAssert.reverts(
                nWorkInstance.getPriorVotes(user2, newBlock.number),
                "NWK::getPriorVotes: not yet determined"
            )

            let numVotes = await nWorkInstance.getPriorVotes(user2, newBlock.number - 1)
            assert(numVotes.toString() == "0", `Should be 0 initially. Received: ${numVotes.toString()}`)

            ////////// TO DO
        })
    }) 
})
