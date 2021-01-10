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

getCurrentEpochTime = () => {
    return Math.round(Date.now()/1000);
}

const DELAY = 60 * 60 * 24 * 2;

const DEVAMT = 250000000;

const TREASURYAMT = 750000000; 

module.exports = {
    shouldThrow,
    getCurrentEpochTime,
    advanceBlock,
    takeSnapshot,
    revertToSnapShot,
    DELAY,
    DEVAMT,
    TREASURYAMT
}
