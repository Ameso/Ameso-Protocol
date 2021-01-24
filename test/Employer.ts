import { ethers, waffle } from "hardhat"
import { expect, use } from "chai"
import { solidity } from "ethereum-waffle"
import { DEVAMT, TREASURYAMT, mineBlock, DELAY } from "./utils";

use(solidity)

describe('Test Ameso Token', () => {    
    const provider = waffle.provider
    let amesoInstance, governor, amesoApp, treasury, employer
    let AmesoFactory, treasuryFactory, governorFactory, amesoFactory, employerFactory
    let admin, user1, user2, user3
    let firstProposalID = 1
    const abi = new ethers.utils.AbiCoder()
    let snapShotId

    before(async () => {
        snapShotId = await provider.send('evm_snapshot', [1])
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

            // ADMIN NONCE 0 
            amesoInstance = await AmesoFactory.deploy(user1.address, user2.address, DEVAMT, TREASURYAMT, latestBlock.timestamp + 60)
        })

        it('Can deploy treasury', async () => {
            // figure out governor contract's future contract address
            // http://ethereum.stackexchange.com/questions/760/how-is-the-address-of-an-ethereum-contract-computed

            let governorAddress = ethers.utils.getContractAddress({ from: admin.address, nonce: 3 })
            treasuryFactory = await ethers.getContractFactory("Treasury")

            let amesoAppAddress = ethers.utils.getContractAddress({ from: admin.address, nonce: 2 })

            // ADMIN NONCE 1 
            treasury = await treasuryFactory.deploy(governorAddress, amesoAppAddress,  DELAY)
       })

        it('Can deploy AmesoApp', async () => {
            amesoFactory = await ethers.getContractFactory("Ameso")

            // ADMIN NONCE 2 
            let employerAddress = ethers.utils.getContractAddress({ from: admin.address, nonce: 4 })
            amesoApp = await amesoFactory.deploy(treasury.address, amesoInstance.address, employerAddress)
        })

        it('Can deploy governance contract', async () => {
            governorFactory = await ethers.getContractFactory("Governor")

            // ADMIN NONCE 3 
            governor = await governorFactory.deploy(treasury.address, amesoInstance.address, amesoApp.address)
        })

        it('Can deploy employer contract', async () => {
            employerFactory = await ethers.getContractFactory("Employer")

            // ADMIN NONCE 4
            employer = await employerFactory.deploy(amesoApp.address)
        })
    })

    describe('Creating a job', () => {
        it('Create a job', async () => {
            let minContractors = 10
            let maxContractors = 100
            let extraEnrollDelay = 0
            let jobLengthBlocks = 28800
            let tip = 0

            await employer.connect(user1).createJob("JobID", 
                                                minContractors,
                                                maxContractors,
                                                extraEnrollDelay,
                                                jobLengthBlocks,
                                                tip)
        })
    })
})