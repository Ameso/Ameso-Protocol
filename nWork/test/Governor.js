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
    let firstProposalID;

    describe('Deployment of contracts', async () => {
        it('Can deploy nWorkToken', async () => {
            nWorkInstance = await nWorkToken.new(user1, user2, DEVAMT, TREASURYAMT, getCurrentEpochTime())
        })

        it('Can deploy treasury', async () => {
            treasury = await Treasury.new(admin, DELAY);
        })

        it('Can deploy nWorkApp', async () => {
            nWorkApp = await NWorkApp.new(treasury.address);
        })

        it('Can deploy governance contract', async () => {
            governor = await Governor.new(treasury.address, nWorkInstance.address, nWorkApp.address)
        })
    })
   
    describe('Proper quorum and proposal thresholds', async () => {
        it('Governance contract has the correct quorum: 30million', async () => {
            let quorum = await governor.quorumVotes();

            assert(quorum.toString() === web3.utils.toWei("30000000", "ether"), `Incorrect quorum amount: ${quorum.toString()}`)
        })

        it('Governance contract has the correct proposal threshold', async () => {
            let threshold = await governor.proposalThreshold();

            assert(threshold.toString() === web3.utils.toWei("1000000", "ether"), `Incorrect threshold: ${threshold.toString()}`);
        })
    })

    describe('Create proposal', async () => {
        it('Sending delegates and creating proposal', async () => {
            // use the dev account (user1)
            // dev account should have 250million coins
            // self delegate
            let tx = await nWorkInstance.delegate(user1, {from: user1})
            truffleAssert.eventEmitted(tx, 'DelegateChanged', (ev) => {
                return ev.delegator == user1 && ev.fromDelegate == 0 && ev.toDelegate == user1
            })

            // Timelock (Treasury)
            let target = [treasury.address]
            let values = [0]
            let signatures = ["abcd"]
            let calldatas = [web3.utils.asciiToHex('Test')]
            let description = "Trying to change admin of treasury (New governor). We will change the quorum votes in the new contract"

            let res = await governor.propose(target, values, signatures, calldatas, description, {from: user1})

            // should return id one
            let id = res.logs[0].args.id
            assert(id.toString() === "1", `Incorrect proposal id: ${id.toString()}`)
            firstProposalID = id

            // check the proposal is stored
            // there should only be one proposal so far
            let numProp = await governor.proposalCount()
            assert(numProp.toString() === "1", `Incorrect proposal count: ${numProp.toString()}`)

            tx = await governor.proposals(id.toNumber()-1)
        })
    })

    describe('Testing voting feature', async () => {
        it('Test governance voting feature by changing admin for treasury to governance contract', async () => {
            // set the treasury's new admin to the governance contract

            // not proper way to do it, should raise an error
            await truffleAssert.fails(
                treasury.setPendingAdmin(user1, {from:treasury.address}),
                "sender account not recognized"
            )
        })
    })
})
