import { ethers, waffle } from "hardhat"
import { expect, use } from "chai"
import { solidity } from "ethereum-waffle"
import { DEVAMT, TREASURYAMT, mineBlock } from "./utils";


describe("Governor", () => {
    const provider = waffle.provider
    let amesoInstance, governor, nWorkApp
    let AmesoABI, governorABI, nWorkAppABI
    let admin, user1, user2, user3, minter
    let firstProposalID;

    describe('Deployment of contracts', () => {
        /*
        it('Can deploy nWorkToken', async () => {
            amesoInstance = await AmesoToken.new(user1, user2, DEVAMT, TREASURYAMT, getCurrentEpochTime())
        })

        it('Can deploy treasury', async () => {
            treasury = await Treasury.new(admin, DELAY);
        })

        it('Can deploy nWorkApp', async () => {
            nWorkApp = await NWorkApp.new(treasury.address);
        })

        it('Can deploy governance contract', async () => {
            governor = await Governor.new(treasury.address, nWorkInstance.address, nWorkApp.address)
        })*/
    })
   
    describe('Proper quorum and proposal thresholds', async () => {
        /*
        it('Governance contract has the correct quorum: 30million', async () => {
            let quorum = await governor.quorumVotes();

            assert(quorum.toString() === web3.utils.toWei("30000000", "ether"), `Incorrect quorum amount: ${quorum.toString()}`)
        })

        it('Governance contract has the correct proposal threshold', async () => {
            let threshold = await governor.proposalThreshold();

            assert(threshold.toString() === web3.utils.toWei("1000000", "ether"), `Incorrect threshold: ${threshold.toString()}`);
        })*/
    })

    describe('Create proposal', async () => {
        it('Sending delegates and creating proposal', async () => {
            /*
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
            let calldatas = [web3.utils.asciiToHex('Test')]
            let description = "Trying to change admin of treasury (New governor). We will change the quorum votes in the new contract"

			let signatures = [web3.eth.abi.encodeFunctionSignature({
                name: 'setPendingAdmin',
                type: 'function',
                inputs: [{
                    type: 'address',
                    name: 'pendingAdmin_'
                }]
            })]

            let votingPeriod = await governor.votingPeriod()

            let proposeTx = await governor.propose(target, values, signatures, calldatas, description, {from: user1})

            truffleAssert.eventEmitted(proposeTx, 'ProposalCreated', (ev) => {
                return ev.id == 1 && ev.proposer == user1 && ev.startBlock == proposeTx.receipt.blockNumber + 1 && ev.endBlock + votingPeriod
            })

            // should return id one
            let id = proposeTx.logs[0].args.id
            assert(id.toString() === "1", `Incorrect proposal id: ${id.toString()}`)
            firstProposalID = id

            // check the proposal is stored
            // there should only be one proposal so far
            let numProp = await governor.proposalCount()
            assert(numProp.toString() === "1", `Incorrect proposal count: ${numProp.toString()}`)

            // getting state of proposal that does not exist should fail
            await truffleAssert.reverts(
                governor.state(1000),
                'Governor::state: invalid proposal id'
            )

            // user should not be able to send proposal again
            res = await governor.propose(target, values, signatures, calldatas, description, {from: user1})
            id = res.logs[0].args.id

            res = await governor.latestProposalIds(user1)
            //console.log(res.toString())

            // the proposal should be accepting votes
            let proposalState = await governor.state(firstProposalID)
            let proposalState2 = await governor.state(2)

            //console.log(proposalState.toString(), proposalState2.toString())

            let tmp = await governor.proposals(0)
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

            // firstProposalID should have the function signature to change the admin
            
            // vote for the proposal. Try those without any tokens
        })
    })*/
})
