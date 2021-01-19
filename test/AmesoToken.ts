import { ethers, waffle } from "hardhat"
import { expect, use } from "chai"
import { solidity } from "ethereum-waffle"
import { DEVAMT, TREASURYAMT, mineBlock } from "./utils";

use(solidity)

describe('Test Ameso Token', () => {    
    const provider = waffle.provider
    let amesoInstance
    let amesoABI
    let admin, user1, user2, user3, minter

    describe('Basic deployment', () => {
        it('Can deploy Ameso token', async () => {
            [admin, user1, user2, user3] = await ethers.getSigners()
            amesoABI = await ethers.getContractFactory("AmesoToken")
            let latestBlock = await provider.getBlock('latest')
            amesoInstance = await amesoABI.deploy(user1.address, user2.address, DEVAMT, TREASURYAMT, latestBlock.timestamp + 60)

            minter = user2

            let totalSupply = await amesoInstance.totalSupply()
            expect(totalSupply).to.equal(DEVAMT.add(TREASURYAMT), `Incorrect total supply: ${totalSupply}`)
        })
    })

    describe('Minting', () => {
        it('Proper minting permissions and test basic minting', async () => {
            // advance blockchain time so we can start minting (check allowmintafter time in contract)
            let latestBlock = await provider.getBlock('latest')
            await mineBlock(provider, latestBlock.timestamp + 60)

            // try to mint even though address is not minter
            // deployer (admin in this case) isn't the one that becomes the minter by default
            await expect(amesoInstance.mint(user1.address, 10))
                .to.be.revertedWith("AMS::mint: only the treasury can mint")

            await amesoInstance.connect(minter).mint(minter.address, 1)
            let newTreasuryBalance = await amesoInstance.balanceOf(minter.address)
            expect(newTreasuryBalance).to.equal(TREASURYAMT.add(1), `Incorrect treasury balance: ${newTreasuryBalance.toString()}`)

            // should not allow mint again. Too soon
            await expect(amesoInstance.connect(minter).mint(minter.address, 1))
                .to.be.revertedWith("AMS::mint: minting not allowed yet")
        })

        it('Cannot mint too much tokens', async () => {
            // mineBlock to allow minting again
            let latestBlock = await provider.getBlock('latest')
            await mineBlock(provider, latestBlock.timestamp + 60 * 60 * 60 * 24 * 30)

            // should not be able to mint past 2 percent
            await expect(amesoInstance.connect(minter).mint(minter.address, DEVAMT.add(TREASURYAMT).mul(2).div(100).add(1)))
                .to.be.revertedWith("AMS::mint: exceeded mint cap")
            
            await amesoInstance.connect(minter).mint(minter.address, DEVAMT.add(TREASURYAMT).mul(2).div(100))
        })

        it('Can change the minter', async () => {
            // mineBlock to allow minting again
            let latestBlock = await provider.getBlock('latest')
            await mineBlock(provider, latestBlock.timestamp + 60 * 60 * 60 * 24 * 30)

            let ogMinter = minter
            await amesoInstance.connect(minter).setMinter(user3.address)
            minter = user3

            await expect(amesoInstance.connect(ogMinter).mint(ogMinter.address, 100))
                .to.be.revertedWith("AMS::mint: only the treasury can mint")

            await amesoInstance.connect(minter).mint(minter.address, 100)
        })
    })

    describe('Allowance without permit', () => {
        it('User can set allowance to -1 to indicate unlimited spending', async () => {

        })

        it('Simple allowance to allow another user to spend my tokens', async () => {
            let thousandAMStokens = ethers.utils.parseEther('1000')
            let initialUser3Bal = await amesoInstance.balanceOf(user3.address)
            await amesoInstance.connect(user1).approve(user3.address, thousandAMStokens)
            let allowedAmount = await amesoInstance.allowance(user1.address, user3.address)
            let user1Bal = await amesoInstance.balanceOf(user1.address)

            expect(allowedAmount).to.be.equal(thousandAMStokens, `Incorrect allowance amount: ${allowedAmount.toString()}`)

            // once approved, user3 should be able to spend tokens.
            // only the recipient (user3) should be able to execute the transferFrom
            await expect(
                amesoInstance.connect(admin).transferFrom(user1.address, user3.address, thousandAMStokens)
            ).to.be.reverted

            await amesoInstance.connect(user3).transferFrom(user1.address, user3.address, thousandAMStokens)
            let user3NewBal = await amesoInstance.balanceOf(user3.address);

            expect(user3NewBal).to.be.equal(initialUser3Bal.add(thousandAMStokens), `User3 does not have the correct balance: ${user3NewBal.toString()}`)

            let user1NewBal = await amesoInstance.balanceOf(user1.address);

            expect(user1NewBal).to.be.equal(DEVAMT.sub(thousandAMStokens), `User1 did not have their balance removed: ${user1NewBal.toString()}`)
        })

        it('User should not be able to spend more than allowed tokens', async () => {

        })

        it('What happens with negative allowance', async () => {

        })
    })
     

    describe('Allowance with permit', () => {
        it('Use the permit function to allow another address to spend my tokens', async () => {

        })
    })

    describe('Delegation', async () => {
        it('Delegating (non mint)', async () => {
            let user2VotingPower = await amesoInstance.balanceOf(user2.address)

            await expect(amesoInstance.connect(user2).delegate(admin.address))
                .to.emit(amesoInstance, 'DelegateChanged')
                .withArgs(user2.address, "0x0000000000000000000000000000000000000000", admin.address)

            let myDelegate = await amesoInstance.connect(admin).delegates(user2.address)

            expect(myDelegate).to.be.equal(admin.address) 

            // Checkpoint created from delegating
            let adminNumChkPt = await amesoInstance.numCheckpoints(admin.address) 
            expect(adminNumChkPt).to.be.equal(1)
            let adminChkPt = await amesoInstance.checkpoints(admin.address, 0)
            expect(adminChkPt.votes).to.be.equal(user2VotingPower)
        })

        it('Delegating (after mint)', async () => {
            // mineBlock to allow minting again
            let latestBlock = await provider.getBlock('latest')
            await mineBlock(provider, latestBlock.timestamp + 60 * 60 * 60 * 24 * 30)

            let beforeNumChkPnt = await amesoInstance.numCheckpoints(minter.address)

            await amesoInstance.connect(minter).mint(minter.address, 99) 
        
            let numChkPnt = await amesoInstance.numCheckpoints(minter.address)
            //////////// TO DO
        })
    })

})