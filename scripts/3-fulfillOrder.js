const { ethers } = require("hardhat");

async function main() {
    const [deployer, owner, buyer] = await ethers.getSigner();
    console.log("Deploying contracts with the account: ", deployer.address);
    console.log("NFT creator address: ", owner.address);
    console.log("Buyer address: ", buyer.address);  

    console.log("registry address: ", process.env.ADDRESS);   // registry address 通过环境变量传入
    console.log("NFT contract address: ", process.env.NFT_ADDRESS);
    console.log("signature: ", process.env.SIGNATURE);

    const registry = (await attach('LazyMintWith712', process.env.ADDRESS)).connect(buyer);
    const tokenId = 107620024739658412805886307570881852509861757131837649177597025795553282228234;
    const contractAddress = process.env.NFT_ADDRESS;
    const defaultRoyaltyFraction = 100;

    // 2. 买家购买时，从数据库中获取签名数据，并组装好同样的datajson，向LazyMintWith712发起mint交易（验证签名）
    const tx = await registry.mintNFT(buyer.address, tokenId, 1, '0x', contractAddress, defaultRoyaltyFraction, process.env.SIGNATURE);
    const receipt = await tx.wait();
    
    console.log(receipt)

    // transfer
    // 分两种，一种是用户直接tranfer，不走平台售卖逻辑，此时直接调用AssetContractShared中的safetransfer方法
    // 二、买家转卖，走平台逻辑，同样需要走mint中的挂单、签名、验签流程，但是调用的方法从 mint() 变为 transfer() 
    const to2 = "";
    await nft.safeTransferFrom(to, to2, id, 1, "");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });