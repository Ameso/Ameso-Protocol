import chai, { expect } from 'chai'
import { BigNumber, Contract, constants, utils } from 'ethers'
import { solidity, MockProvider, createFixtureLoader, deployContract } from 'ethereum-waffle'

import { nWorkFixture } from './fixture'
import nWorkToken from '../artifacts/contracts/nWorkToken.sol/nWorkToken.json'
import Treasury from '../artifacts/contracts/Treasury.sol/Treasury.json'
import { mineBlock, TREASURYBAL, DEVBAL } from './utils'

chai.use(solidity);

describe("Treasury Contract", function() {
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
    let treasury : Contract

    beforeEach(async () => {
        const fixture = await loadFixture(nWorkFixture)
        nwk = fixture.nwk
        treasury = fixture.treasury
    });

    it('nwk deployment', async () => {
        const treasuryBalance = await nwk.balanceOf(user2.address)
        const totalSupply = await nwk.totalSupply()
        expect(treasuryBalance).to.be.eq(TREASURYBAL)
    });
})
