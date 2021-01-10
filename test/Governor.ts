import chai, { expect } from 'chai'
import { Contract, constants } from 'ethers'
import { solidity, MockProvider, createFixtureLoader } from 'ethereum-waffle'

import { nWorkFixture } from './fixture'
import { DELAY } from './utils'

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

    it('Test governance voting feature by changing admin for treasury to governance contract', async () => {

    });

});
