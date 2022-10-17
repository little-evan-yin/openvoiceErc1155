const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigner();
    console.log("Deploying contracts with the account: ", deployer.address);

    const NFT = await ethers.getContractFactory("AssetContractShared");
    const nft = await NFT.deploy();
    console.log("NFT contract address: ", nft.address);

    
    // mint
    const to = "";
    const id = "creator - index - maxsupply";
    await nft.mint(to, id, 1, "");

    // transfer
    const to2 = "";
    await nft.safeTransferFrom(to, to2, id, 1, "");
}