import chai, { expect } from 'chai'
import { BigNumber, Contract, constants, utils } from 'ethers'
import { solidity, MockProvider, createFixtureLoader, deployContract } from 'ethereum-waffle'

import { nWorkTokenFixture } from './nWorkTokenFixture'
import nWorkToken from '../artifacts/contracts/nWorkToken.sol/nWorkToken.json'
import { mineBlock } from './utils'

chai.use(solidity);

describe("nWork Token Contract", function() {
    const provider = new MockProvider({
        ganacheOptions: {
            hardfork: 'istanbul',
            mnemonic: 'horn horn horn horn horn horn horn horn horn horn horn horn',
            gasLimit: 9999999,
        },
    })

    const [owner, user1, user2, user3, user4, _] = provider.getWallets()
    const loadFixture = createFixtureLoader([owner, user1, user2], provider)

    let nwk : Contract

    beforeEach(async () => {
        const fixture = await loadFixture(nWorkTokenFixture)
        nwk = fixture.nwk
    });

    it("Check Total Supply is equal to 1billion", async () => {
        expect(await nwk.totalSupply()).to.equal(1000000000);
    });
    
    it('Correct minting', async () => {
        const { timestamp: now } = await provider.getBlock('latest')
        nwk = await deployContract(owner, nWorkToken, [user1.address, user2.address, 250000000, 750000000, now + 60 * 60])

        await expect(nwk.connect(user2).mint(user2.address, 1)).to.be.revertedWith('NWK::mint: minting not allowed yet')

        let timestamp = await nwk.mintingAllowedAfter()
        await mineBlock(provider, timestamp.toString())

        await expect(nwk.connect(user1).mint(user1.address, 1)).to.be.revertedWith('NWK::mint: only the treasury can mint')
        await expect(nwk.connect(user2).mint('0x0000000000000000000000000000000000000000', 1)).to.be.revertedWith('NWK::mint: cannot transfer to the zero address')

        await nwk.connect(user2).mint(user1.address, 1)
        expect(await nwk.balanceOf(user1.address)).to.equal(250000001)

        // try to mint again.. should be too soon
        await expect(nwk.connect(user2).mint(user1.address, 1)).to.be.revertedWith('NWK::mint: minting not allowed yet')

        // should allow minting again after waiting period
        timestamp = await nwk.mintingAllowedAfter()
        await mineBlock(provider, timestamp.toString())

        await nwk.connect(user2).mint(user1.address,1)
        expect(await nwk.balanceOf(user1.address)).to.equal(250000002)
    });

    it('Can mint up to 2 percent', async () => {
    });

    it('Can change minter', async () => {

    });

    it('Test simple allowance to allow another user to spend my tokens', async () => {

    });

    it('User should not be able to spend more than allowed tokens', async () => {
    });

    it('Use the permit function to allow another address to spend my tokens', async () => {

    });

    it('Test getting prior votes', async () => {
    });
})
