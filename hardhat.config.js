require("@nomicfoundation/hardhat-toolbox");
require('@openzeppelin/hardhat-upgrades');

const INFURA_API_KEY = '0101';
const MNEMONIC = '012';
const accountDeploy = '048199a56b68b7f33da4c6c789537585d29dfb92dc66c3b0bda646b80e1099cd';
const accountOwner = '6a42ab02075932d74967b6e617adff235a5c02ecd8137d96442abcefab16f2c8'
const accountBuyer = '3d1789e9a4f00f0633fa4403ca4f93fbd542113af9fec84d2d5f6a9e989a501f'

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  defaultNetwork: "goerli",
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    hardhat: {
      allowUnlimitedContractSize: true,
      chainId: 1337
    },
    goerli: {
      url: `https://goerli.infura.io/v3/${INFURA_API_KEY}`,
      accounts: {
        mnemonic: MNEMONIC,
        path: "m/44'/60'/0'/0",
        initialIndex: 0,
        count: 10,
        passphrase: ""
      },
      allowUnlimitedContractSize: true
    },
    etmp: {
      url: `https://rpc.pioneer.etm.network/`,
      accounts: [accountDeploy, accountOwner, accountBuyer]
    }
  }
};
