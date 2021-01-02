const yWorkToken = artifacts.require("yWorkToken.sol");

async function shouldThrow(promise) {
    try {
        await promise;
        assert(true);
    }
    catch (err) {
        return;
    }
    assert(false, "The contract did not throw.");
}

advanceBlock = async () => {
    return new Promise((resolve, reject) => {
        web3.currentProvider.send({
            jsonrpc: "2.0",
            method: "evm_mine",
            id: new Date().getTime()
        }, async (err, result) => {
            if (err) { return reject(err); }
            const newBlockHash = await web3.eth.getBlock('latest').hash;
            return resolve(newBlockHash)
        });
    });
}

takeSnapshot = () => {
    return new Promise((resolve, reject) => {
        web3.currentProvider.send({
            jsonrpc: '2.0',
            method: 'evm_snapshot',
            id: new Date().getTime()
        }, (err, snapshotId) => {
            if (err) { return reject(err) }
            return resolve(snapshotId)
        });
    });
}

revertToSnapShot = (id) => {
    return new Promise((resolve, reject) => {
        web3.currentProvider.send({
            jsonrpc: '2.0',
            method: 'evm_revert',
            params: [id],
            id: new Date().getTime()
        }, (err, result) => {
            if (err) { return reject(err) }
            return resolve(result)
        });
    });
}
  

function timeout(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}


contract("yWorkToken", async addresses => {
    const [admin, user1, user2, user3, user4, _] = addresses;
    let yWorkInstance = null;
    
    // number of tokens to give to devs
    const devAmount = 250000000;

    // number of tokens to give to treasury
    const treasuryAmount = 750000000;

    const totalSupply = devAmount + treasuryAmount;

    it('Can deploy yWork token', async () => {
        // might need to increase how much to add. "Proper mint permissions" test keeps on adding and changing testnet time 
        let canMintTime = (parseInt(Date.now()/1000, 10)) + 1;
        yWorkInstance = await yWorkToken.new(user1, user2, devAmount, treasuryAmount, canMintTime);
        let totalSupply = await yWorkInstance.totalSupply();
        assert(totalSupply.toString() === totalSupply.toString(), "Incorrect total supply: " + totalSupply.toString());
    });

    it('Proper minting permissions and test basic minting', async () => {
        let snapShotId = await takeSnapshot();

        let newBlock = await web3.eth.getBlock('latest');

        // advance blockchain time so we can start minting (check allowmintafter time in contract)
        await timeout(2000);
        await advanceBlock();

        newBlock = await web3.eth.getBlock('latest');

        // try to mint even though address is not minter
        // deployer (admin in this case) isn't the one that becomes the minter by default
        await shouldThrow(yWorkInstance.mint(10, {from: admin})); 

        await yWorkInstance.mint(1, {from: user2});
        let newTreasuryBalance = await yWorkInstance.balanceOf(user2);
        assert(newTreasuryBalance.toString() === "750000001", "Incorrect treasury balance: " + newTreasuryBalance.toString());

        // should not allow mint again. Too soon
        await shouldThrow(yWorkInstance.mint(1, {from: user2}));

        await revertToSnapShot(snapShotId.result);
    });

    it('Cannot mint too much tokens', async () => {
        let snapShotId = await takeSnapshot();

        // should not be able to mint past 2 percent
        await shouldThrow(yWorkInstance.mint(20000001, {from: user2}));
        
        await yWorkInstance.mint(20000000, {from: user2});

        await revertToSnapShot(snapShotId.result);
    });

    it('Can change the minter', async () => {
        let snapShotId = await takeSnapshot();

        await yWorkInstance.setMinter(user3, {from: user2});

        // user2 shouldn't be minter anymore
        await shouldThrow(yWorkInstance.mint(100, {from: user2}));

        await yWorkInstance.mint(100, {from: user3});

        // make sure that user3 has the correct mint amount, the old balance of the previous minter stays the same
        let user3TreasuryBal = await yWorkInstance.balanceOf(user3);

        assert(user3TreasuryBal.toString() === "100", "User3 incorrect balance: " + user3TreasuryBal.toString());

        await revertToSnapShot(snapShotId.result);
    });

    it('Should not be able to mint too often', async () => {

    });

    it('Use the permit function to allow another address to spend my tokens', async () => {

    });
});