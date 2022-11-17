const { ethers, upgrades } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account: ", deployer.address);

    const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000"

    // 1. deploy nft contract [ get logic address]
    const name = "OpenVoice"
    const symbol = "OV"
    const templateURI = "https://likn-matadata.herokuapp.com/api/token/0x{id}"
    const royaltyFraction = 200
    const proxyRegistryAddress = ZERO_ADDRESS

    const NFT = await ethers.getContractFactory('AssetContractShared');
    const nft = await NFT.deploy();
    await nft.deployed();
    console.log("NFT logic contract address: ", nft.address);

    // 2. deploy nft proxy contract
    const nftProxy = await upgrades.deployProxy(NFT, [name, symbol, templateURI, royaltyFraction, proxyRegistryAddress]);
    await nftProxy.deployed();
    console.log("NFT proxy contract address: ", nftProxy.address);

    // 3. deploy sell contract  
    const REGISTRY = await ethers.getContractFactory('LazyMintWith712');
    const registry = await REGISTRY.deploy();
    await registry.deployed();
    console.log("LazyMintWith712 logic contract address: ", registry.address);

    // 4. deploy sell proxy contract 
    const version = "1.0.0";
    const registryProxy = await upgrades.deployProxy(REGISTRY, [name, version, nftProxy.address]);
    await registryProxy.deployed();
    console.log("LazyMintWith712 proxy contract address: ", registryProxy.address);

    // 3. set sell logic contract address 
    await nftProxy.setProxyRegistryAddress(registryProxy.address)  
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });