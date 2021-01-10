const nWorkToken = artifacts.require("nWorkToken.sol");
const truffleAssert = require('truffle-assertions');
const { advanceBlock, takeSnapshot, revertToSnapShot, getCurrentEpochTime, DEVAMT, TREASURYAMT } = require('./utils.js');
 

function timeout(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}


contract("nWorkToken", async addresses => {
    const [admin, user1, user2, user3, user4, _] = addresses;
    let nWorkInstance = null;
    
    it('Can deploy nWork token', async () => {
        nWorkInstance = await nWorkToken.new(user1, user2, DEVAMT, TREASURYAMT, getCurrentEpochTime())
        let totalSupply = await nWorkInstance.totalSupply();
        assert(totalSupply.toString() === (DEVAMT + TREASURYAMT).toString(), "Incorrect total supply: " + totalSupply.toString());
    });

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

        await nWorkInstance.mint(user2, 1, {from: user2});
        let newTreasuryBalance = await nWorkInstance.balanceOf(user2);
        assert(newTreasuryBalance.toString() === "750000001", "Incorrect treasury balance: " + newTreasuryBalance.toString());

        // should not allow mint again. Too soon
        await truffleAssert.reverts(
            nWorkInstance.mint(user2, 1, {from: user2}),
            "NWK::mint: minting not allowed yet"
        )

        await revertToSnapShot(snapShotId.result);
    });

    it('Cannot mint too much tokens', async () => {
        let snapShotId = await takeSnapshot();

        // should not be able to mint past 2 percent
        await truffleAssert.reverts(
            nWorkInstance.mint(user2, ((DEVAMT + TREASURYAMT) * 2 / 100) + 1, {from: user2}),
            "NWK::mint: exceeded mint cap"
        );
        
        await nWorkInstance.mint(user2, (DEVAMT + TREASURYAMT) * 2 / 100, {from: user2});

        await revertToSnapShot(snapShotId.result);
    });

    it('Can change the minter', async () => {
        let snapShotId = await takeSnapshot();

        await nWorkInstance.setMinter(user3, {from: user2});

        // user2 shouldn't be minter anymore
        await truffleAssert.reverts(
            nWorkInstance.mint(user2, 100, {from: user2}),
            "NWK::mint: only the treasury can mint"
        )

        await nWorkInstance.mint(user2, 100, {from: user3});

        // user3 should still have 0 and user2 should have all balance
        let user3TreasuryBal = await nWorkInstance.balanceOf(user3);
        let user2TreasuryBal = await nWorkInstance.balanceOf(user2);

        assert(user3TreasuryBal.toString() === "0", "User3 incorrect balance: " + user3TreasuryBal.toString());
        assert(user2TreasuryBal.toString() === "750000100", "User2 incorrect balance: " + user2TreasuryBal.toString());

        await revertToSnapShot(snapShotId.result);
    });

    it('Should not be able to mint too often', async () => {
        
    });

    it('User can set allowance to -1 to indicate infinite spending', async () => {

    });

    it('Simple allowance to allow another user to spend my tokens', async () => {
        await nWorkInstance.approve(user3, 1000, {from: user1});

        let allowedAmount = await nWorkInstance.allowance(user1, user3);

        let user1Bal = await nWorkInstance.balanceOf(user1);

        assert(allowedAmount.toString() === "1000", "Incorrect allowance amount: ")

        // once approved, user3 should be able to spend tokens.
        // only the recipient (user3) should be able to execute the transferFrom
        await truffleAssert.fails(
            nWorkInstance.transferFrom(user1, user3, 1000, {from: admin})
        )
        await nWorkInstance.transferFrom(user1, user3, 1000, {from: user3});

        let user3NewBal = await nWorkInstance.balanceOf(user3);

        assert(user3NewBal.toString() === "1000", "User3 does not have the correct balance: " + user3NewBal.toString());

        let user1NewBal = await nWorkInstance.balanceOf(user1);

        assert(user1NewBal.toString() === "249999000", "User1 did not have their balance removed: " + user1NewBal.toString());
    });

    it('What happens with negative allowance', async () => {

    });

    it('User should not be able to spend more than allowed tokens', async () => {
    });

    it('Use the permit function to allow another address to spend my tokens', async () => {

    });

    it('Try get prior votes', async () => {
        newBlock = await web3.eth.getBlock('latest')

        await truffleAssert.reverts(
            nWorkInstance.getPriorVotes(user2, newBlock.number),
            "NWK::getPriorVotes: not yet determined"
        )

        let numVotes = await nWorkInstance.getPriorVotes(user2, newBlock.number - 1)
        assert(numVotes.toString() == "0", "Should be 0 initially. Received: " + numVotes.toString())

        let res = await nWorkInstance.numCheckpoints(user2)
        let res2 = await nWorkInstance.checkpoints(user2, 0)
        
        console.log(res2)
    });
});
