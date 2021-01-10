import { providers, BigNumber } from 'ethers'

export const DELAY = 60 * 60 * 24 * 2

export const DEVBAL = 250000000

export const TREASURYBAL = 750000000

export async function mineBlock(provider: providers.Web3Provider, timestamp: number): Promise<void> {
    return provider.send('evm_mine', [timestamp])
}
