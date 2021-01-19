import { ethers, waffle } from "hardhat"
import { expect, use } from "chai"
import { solidity } from "ethereum-waffle"
import { DEVAMT, TREASURYAMT, DELAY, mineBlock } from "./utils";


describe("Governor", () => {
    const provider = waffle.provider
    let amesoInstance, governor, amesoApp, treasury
    let AmesoFactory, treasuryFactory, governorFactory, amesoFactory
    let admin, user1, user2, user3
    let firstProposalID = 1
    const abi = new ethers.utils.AbiCoder()
    let snapShotId

    before(async () => {
        snapShotId = await provider.send('evm_snapshot', [2])
    })

    after(async () => {
        await provider.send('evm_revert', [snapShotId])
    })

    describe('Deployment of contracts', () => {
        it('Assign signers', async () => {
            [admin, user1, user2, user3] = await ethers.getSigners()
        })

        it('Can deploy AmesoToken', async () => {
            let latestBlock = await provider.getBlock('latest')
            AmesoFactory = await ethers.getContractFactory("AmesoToken")

            // ADMIN NONCE 1
            amesoInstance = await AmesoFactory.deploy(user1.address, user2.address, DEVAMT, TREASURYAMT, latestBlock.timestamp + 60)
        })

        it('Can deploy treasury', async () => {
            // figure out governor contract's future contract address
            // http://ethereum.stackexchange.com/questions/760/how-is-the-address-of-an-ethereum-contract-computed

            let governorAddress = ethers.utils.getContractAddress({ from: admin.address, nonce: 3 })
            treasuryFactory = await ethers.getContractFactory("Treasury")

            // ADMIN NONCE 2
            treasury = await treasuryFactory.deploy(governorAddress, DELAY)
            await treasury.setPending
       })

        it('Can deploy AmesoApp', async () => {
            amesoFactory = await ethers.getContractFactory("Ameso")

            // ADMIN NONCE 3
            amesoApp = await amesoFactory.deploy(treasury.address, amesoInstance.address)
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
            let calldatas = [abi.encode(["uint256"], [DELAY + 1])]
            let description = "Trying to change delay"
            let signatures = ["setDelay(uint256)"]

            await governor.connect(user1).propose(target, values, signatures, calldatas, description)

            // check the proposal is stored
            // there should only be one proposal so far
            let numProp = await governor.proposalCount()
            expect(numProp).to.be.equal(1)

            // getting state of proposal that does not exist should fail
            await expect(governor.state(1000))
                .to.be.revertedWith('Governor::state: invalid proposal id')

            // the proposal should be in a pending state since it voting starts in the next block
            expect(await governor.state(1))
                .to.be.equal(0)

            // user should not be able to send proposal again
            await expect(governor.connect(user1).propose(target, values, signatures, calldatas, description))
                .to.be.revertedWith('Governor::propose: one live proposal per proposer, found an already pending proposal')
         
            // increment the block so we can start accepting votes
            let latestBlock = await provider.getBlock('latest')
            await mineBlock(provider, latestBlock.timestamp + 15)

            // state of the proposal should now be "ACTIVE(1)""
            expect(await governor.state(1))
                .to.be.equal(1)
        })
    })

    describe('Testing voting feature', () => {
        it('Transfer some tokens to user3 for voting', async () => {
            // send 1000 AMS tokens to user3
            await amesoInstance.connect(user2).transfer(user3.address, ethers.utils.parseEther("1000"))

            expect(await amesoInstance.balanceOf(user3.address))
                .to.be.equal(ethers.utils.parseEther("1000"))

            // user3 self delegates votes so account has voting power
            await amesoInstance.connect(user3).delegate(user3.address)

            // check voting power
            let latest = await provider.getBlock('latest')
            await mineBlock(provider, latest.timestamp + 15)
            latest = await provider.getBlock('latest')
            expect(await amesoInstance.connect(user3).getPriorVotes(user3.address, latest.number-1))
                .to.be.equal(ethers.utils.parseEther("1000"))
        })

        it('Test Prior Voting Power', async () => {
            await governor.connect(user3).castVote(firstProposalID, true)

            // try double voting
            await expect(governor.connect(user3).castVote(firstProposalID, false))
                .to.be.revertedWith('Governor::_castVote: voter already voted')

            // there should be user2 votes in favor of the proposal
            let proposal = await governor.proposals(firstProposalID)
            let startBlock = proposal.startBlock

            let user3PriorVotes = await amesoInstance.getPriorVotes(user3.address, startBlock)
            expect(proposal.forVotes).to.be.equal(user3PriorVotes)
        })

        it('Try casting vote with castVoteBySig', async () => {

        })

        it('Test successfully quorum', async () => {
            // vote with user1 (voting for own proposal)
            // this should meet quorum
            await governor.connect(user1).castVote(firstProposalID, true)
            let proposal = await governor.proposals(firstProposalID)
            let user1PriorVotes = await amesoInstance.getPriorVotes(user1.address, proposal.startBlock)

            expect(proposal.forVotes)
                .to.be.equal(user1PriorVotes)

            // advance past the end of voting period
            let block = await provider.getBlock('latest')
            let reqNumMines = proposal.endBlock.sub(block.number).add(1).toNumber()
            let blockTime = block.timestamp
            while(reqNumMines > 0) {
                blockTime++
                await mineBlock(provider, blockTime)
                reqNumMines--
            }

            // proposal succeeded
            expect(await governor.state(firstProposalID))
                .to.be.equal(4)
        })
    })

    describe("Execution of successful proposal", () => {
        it('Queue the successful proposal', async () => {
            await governor.connect(user1).queue(firstProposalID)
        })

        it('Execute a failed transaction', async () => {

        })

        it('Execute the queued transaction', async () => {
            let res = await treasury.delay()
            let proposal = await governor.proposals(firstProposalID)
            await mineBlock(provider, proposal.eta.toNumber() + 10)
            await governor.connect(user1).execute(firstProposalID)

            // should have executed setDelay to 1 second
            expect(await treasury.delay())
                .to.be.equal(DELAY + 1)
        })
    })
})
