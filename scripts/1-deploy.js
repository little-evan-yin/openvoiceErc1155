const { ethers } = require("hardhat");

async function deploy(name, ...params) {
  const contractFactory = await ethers.getContractFactory(name);
  return await contractFactory.deploy(...params).then(f => f.deployed());
}

async function main() {
    const [deployer, owner, buyer] = await ethers.getSigners();
    console.log("Deploying contracts with the account: ", deployer.address);
    console.log("NFT creator address: ", owner.address);
    console.log("Buyer address: ", buyer.address);

    const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000"

    // 1. deploy nft contract
    const nft = (await deploy('AssetContractShared', "OpenVoice", "OV", "https://likn-matadata.herokuapp.com/api/token/0x{id}", 200, ZERO_ADDRESS)).connect(deployer);
    console.log("NFT contract address: ", nft.address);

    // 2. deploy list contract  
    const registry = (await deploy('LazyMintWith712', 'OpenVoice', nft.address)).connect(deployer);
    console.log("registry contract address: ", registry.address)

    // 3. set proxyAddress
    await nft.setProxyRegistryAddress(registry.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });