const Governor = artifacts.require("Governor.sol");
const nWorkToken = artifacts.require("nWorkToken.sol");
const Treasury = artifacts.require("Treasury.sol");
const NWorkApp = artifacts.require("nWork.sol");
const truffleAssert = require('truffle-assertions');
const { toBN, DELAY, DEVAMT, TREASURYAMT, getCurrentEpochTime } = require('./utils.js'); 


contract("Governor", async addresses => {
    const [admin, user1, user2, user3, user4, _] = addresses;
    let nWorkInstance;
    let governor;
    let treasury;
    let nWorkApp;

    it('Can deploy nWorkToken', async () => {
        nWorkInstance = await nWorkToken.new(user1, user2, DEVAMT, TREASURYAMT, getCurrentEpochTime())
    });

    it('Can deploy treasury', async () => {
        treasury = await Treasury.new(admin, DELAY);
    });

    it('Can deploy nWorkApp', async () => {
        nWorkApp = await NWorkApp.new(treasury.address);
    });

    it('Can deploy governance contract', async () => {
        governor = await Governor.new(treasury.address, nWorkInstance.address, nWorkApp.address)
    });

    it('Governance contract has the correct quorum: 30million', async () => {
        let quorum = await governor.quorumVotes();

        assert(quorum.toString() === "30000000", `Incorrect quorum amount: ${quorum.toString()}`)
    });

    it('Governance contract has the correct proposal threshold', async () => {
        let threshold = await governor.proposalThreshold();

        assert(threshold.toString() === "500000", `Incorrect threshold: ${threshold.toString()}`);
    });

    it('Test governance voting feature by changing admin for treasury to governance contract', async () => {
        // set the treasury's new admin to the governance contract

        // not proper way to do it, should raise an error
        await truffleAssert.fails(
            treasury.setPendingAdmin(user1, {from:treasury.address}),
            "sender account not recognized"
        );
 
        // the governor needs to vote to approve

    });
});
