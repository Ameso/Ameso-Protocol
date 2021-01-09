import chai, { expect } from 'chai'
import { Contract, Wallet, providers } from 'ethers'
import { solidity, deployContract } from 'ethereum-waffle'

import nWorkToken from '../artifacts/contracts/nWorkToken.sol/nWorkToken.json'

export async function nWorkTokenFixture (
    [owner, user1, user2]: Wallet[],
    provider: providers.Web3Provider  
) {
    // deploy NWK, sending the total supply to the deployer
    const { timestamp: now } = await provider.getBlock('latest')
    const nwk = await deployContract(owner, nWorkToken, [user1.address, user2.address, 250000000, 750000000, now + 60 * 60]) 

    return { nwk }
}
