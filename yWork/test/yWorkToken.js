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

function timeout(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}


contract("yWorkToken", async addresses => {
    const [admin, user1, user2, user3, user4, _] = addresses;
    let yWorkInstance = null;

    it('Can deploy yWork token', async () => {
        // might need to increase how much to add. "Proper mint permissions" test keeps on adding and changing testnet time 
        let canMintTime = (parseInt(Date.now()/1000, 10)) + 1;
        yWorkInstance = await yWorkToken.new(user1, user2, 250000000, 750000000, canMintTime);
        let totalSupply = await yWorkInstance.totalSupply();
        assert(totalSupply.toString() === "1000000000", "Incorrect total supply: " + totalSupply.toString());
    });

    it('Proper minting', async () => {
        // increase current time in eth blockchain
        let result = await web3.currentProvider.send({jsonrpc: "2.0", method: "evm_snapshot", params: [500]});
        console.log(result);

        let newBlock = await web3.eth.getBlock('latest');

        await timeout(2000);
        await advanceBlock();

        newBlock = await web3.eth.getBlock('latest');

        await yWorkInstance.mint(1, {from: user2});
        let newTreasuryBalance = await yWorkInstance.balanceOf(user2);
        assert(newTreasuryBalance.toString() === "750000001", "Incorrect treasury balance: " + newTreasuryBalance);

        shouldThrow(yWorkInstance.mint(1, {from: user2}));
    });

    it('Proper permit permissions', async () => {
        // test permit function
        // try erc20 transferFrom function
    });
});