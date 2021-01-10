import chai, { expect } from 'chai'
import { Contract, Wallet, providers } from 'ethers'
import { solidity, deployContract } from 'ethereum-waffle'

import nWorkToken from '../artifacts/contracts/nWorkToken.sol/nWorkToken.json'
import nWork from '../artifacts/contracts/nWork.sol/nWork.json'
import Governor from '../artifacts/contracts/Governor.sol/Governor.json'
import Treasury from '../artifacts/contracts/Treasury.sol/Treasury.json'

import { DELAY } from './utils'

export async function nWorkFixture (
    [owner, user1, user2]: Wallet[],
    provider: providers.Web3Provider  
) {
    // deploy NWK, sending the total supply to the deployer
    const { timestamp: now } = await provider.getBlock('latest')
    const nwk = await deployContract(owner, nWorkToken, [user1.address, user2.address, 250000000, 750000000, now + 60 * 60]) 

    // deploy treasury, controlled by what will be the governor
    const governorAddress = Contract.getContractAddress({ from: owner.address, nonce: 1})
    const treasury = await deployContract(owner, Treasury, [governorAddress, DELAY])

    // deploy nWorkCore
    const nWorkApp = await deployContract(owner, nWork, [treasury.address])

    // deploy Governance
    const governor = await deployContract(owner, Governor, [treasury.address, nwk.address, nWorkApp.address])

    return { nwk, treasury, governor, nWorkApp }
}
