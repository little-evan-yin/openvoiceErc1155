const { ethers, upgrades } = require("hardhat")


async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account: ", deployer.address);

    // export old nft & sell proxy contract address
    console.log("nft proxy contract address: ", NFT_ADDRESS)
    console.log("sell proxy contract address: ", REG_ADDRESS)

    // deploy updated logic contract
    const NFTV2 = await ethers.getContractFactory("AssetContractSharedV2.sol")
    const nft = await NFTV2.deploy()
    console.log("NFTv2 logic contract address: ", nft.address)

    const nftProxy = await upgrades.upgradeProxy(NFT_ADDRESS, NFTV2);
    console.log("nft contract updated!")


    // deploy udpated sell contract
    const REGISTRYV2 = await ethers.getContractFactory("LazyMintWith712V2.sol")
    const registryV2 = await REGISTRYV2.deploy()
    console.log("LazyMintWith712V2 logic contract address: ", registryV2.address)

    const registryProxy = await upgrades.upgradeProxy(REG_ADDRESS, REGISTRYV2)
    console.log("sell contract updated!")

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });