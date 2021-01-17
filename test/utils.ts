import { ethers } from "hardhat"

export const DELAY = 60 * 60 * 24 * 2

export const DEVAMT = ethers.utils.parseEther("250000000")

export const TREASURYAMT = ethers.utils.parseEther("750000000")

export const getCurrentEpochTime = () => {
    return Math.round(Date.now()/1000)
}

export const mineBlock = async (provider, timestamp: number) => {
    provider.send('evm_mine', [timestamp])
}