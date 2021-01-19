import { ethers, waffle } from "hardhat"
import { expect, use } from "chai"
import { solidity } from "ethereum-waffle"
import { DEVAMT, TREASURYAMT, mineBlock, DELAY } from "./utils";

use(solidity)

describe('Test Ameso Token', () => {    
    const provider = waffle.provider
    let amesoInstance, governor, amesoApp, treasury
    let AmesoFactory, treasuryFactory, governorFactory, amesoFactory
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
})