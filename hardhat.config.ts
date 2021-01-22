import "@nomiclabs/hardhat-waffle";
import "hardhat-gas-reporter";

export default {
  solidity: "0.7.3",
  networks: {
    localhost: {
      url: "http://localhost:7545"
    }
  },
  mocha: {
    timeout: 40000
  },
  gasReporter: {
  }
}

