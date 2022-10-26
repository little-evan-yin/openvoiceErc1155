const { ethers } = require("hardhat");

async function main() {
    const [deployer, owner, buyer] = await ethers.getSigner();
    console.log("Deploying contracts with the account: ", deployer.address);
    console.log("NFT creator address: ", owner.address);
    console.log("Buyer address: ", buyer.address);

    // 1. deploy nft contract
    const nft = (await deploy('AssetContractShared', "OpenVoice", "OV", "https://likn-matadata.herokuapp.com/api/token/0x{id}")).connect(deployer);
    console.log("NFT contract address: ", nft.address);

    // 2. deploy list contract  
    const registry = (await deploy('LazyMintWith712', 'OpenVoice', nft.address)).connect(deployer);

    console.log("registry contract address: ", registry.address)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });