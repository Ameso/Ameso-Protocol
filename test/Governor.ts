import { ethers, waffle } from "hardhat"
import { expect, use } from "chai"
import { solidity } from "ethereum-waffle"
import { DEVAMT, TREASURYAMT, DELAY, mineBlock } from "./utils";


describe("Governor", () => {
    const provider = waffle.provider
    let amesoInstance, governor, amesoApp, treasury
    let AmesoFactory, treasuryFactory, governorFactory, amesoFactory
    let admin, user1, user2, user3
    let firstProposalID;

    describe('Deployment of contracts', () => {
        it('Assign signers', async () => {
            [admin, user1, user2, user3] = await ethers.getSigners()
        })

        it('Can deploy AmesoToken', async () => {
            let latestBlock = await provider.getBlock('latest')
            AmesoFactory = await ethers.getContractFactory("AmesoToken")
            amesoInstance = await AmesoFactory.deploy(user1.address, user2.address, DEVAMT, TREASURYAMT, latestBlock.timestamp + 60)
        })

        it('Can deploy treasury', async () => {
            treasuryFactory = await ethers.getContractFactory("Treasury")
            treasury = await treasuryFactory.deploy(admin.address, DELAY)
        })

        it('Can deploy AmesoApp', async () => {
            amesoFactory = await ethers.getContractFactory("Ameso")
            amesoApp = await amesoFactory.deploy(treasury.address)
        })

        it('Can deploy governance contract', async () => {
            governorFactory = await ethers.getContractFactory("Governor")
            governor = await governorFactory.deploy(treasury.address, amesoInstance.address, amesoApp.address)
        })
    })
   
    describe('Proper quorum and proposal thresholds', () => {
        it('Governance contract has the correct quorum: 30million', async () => {
            let quorum = await governor.quorumVotes()
            expect(quorum).to.be.equal(ethers.utils.parseEther("30000000"))
        })

        it('Governance contract has the correct proposal threshold', async () => {
            let threshold = await governor.proposalThreshold();
            expect(threshold).to.be.equal(ethers.utils.parseEther("1000000"))
        })
    })

    describe('Create proposal', () => {
        it('Sending delegates and creating proposal', async () => {
            // use the dev account (user1)
            // dev account should have 250million coins
            // self delegate
            await expect(amesoInstance.connect(user1).delegate(user1.address))
                .to.emit(amesoInstance, 'DelegateChanged')
                .withArgs(user1.address, '0x0000000000000000000000000000000000000000', user1.address)

            // Timelock (Treasury)
            let target = [treasury.address]
            let values = [0]
            let calldatas = [user3.address]
            let description = "Trying to change admin of treasury (New governor). We will change the quorum votes in the new contract"
            let signatures = ["setPendingAdmin(address)"]

            await governor.connect(user1).propose(target, values, signatures, calldatas, description)

            // check the proposal is stored
            // there should only be one proposal so far
            let numProp = await governor.proposalCount()
            expect(numProp).to.be.equal(1)

            // getting state of proposal that does not exist should fail
            await expect(governor.state(1000))
                .to.be.revertedWith('Governor::state: invalid proposal id')

            // user should not be able to send proposal again
            await expect(governor.connect(user1).propose(target, values, signatures, calldatas, description))
                .to.be.revertedWith('Governor::propose: one live proposal per proposer, found an already pending proposal')
         
            // increment the block so we can start accepting votes
            let latestBlock = await provider.getBlock('latest')
            await mineBlock(provider, latestBlock.timestamp + 15)
        })
    })

    /*
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
