const { ethers } = require("hardhat");

async function attach(name, address) {
  const contractFactory = await ethers.getContractFactory(name);
  return contractFactory.attach(address);
}

async function main() {
    const [deployer, owner, buyer] = await ethers.getSigners();
    console.log("Deploying contracts with the account: ", deployer.address);
    console.log("NFT creator address: ", owner.address);
    console.log("Buyer address: ", buyer.address);  

    console.log("registry address: ", process.env.REG_ADDRESS);   // registry address 通过环境变量传入
    console.log("NFT contract address: ", process.env.NFT_ADDRESS);
    console.log("signature: ", process.env.SIGNATURE);

    const registry = (await attach('LazyMintWith712', process.env.REG_ADDRESS)).connect(buyer);
    const tokenId = '50930204793815341472647614845042490728161331526673935029629296842683499675658';
    const contractAddress = process.env.NFT_ADDRESS;
    const nft = (await attach('AssetContractShared', contractAddress)).connect(buyer);
    const creator = await nft.creator(tokenId);
    const defaultRoyaltyFraction = 100;

    // 2. 买家购买时，从数据库中获取签名数据，并组装好同样的datajson，向LazyMintWith712发起mint交易（验证签名）
    const price = 10000000;
    // price 参数直接通过交易中的value传递
    const tx = await registry.mintNFT(tokenId, contractAddress, creator, defaultRoyaltyFraction, owner.address, buyer.address, 1, '0x', process.env.SIGNATURE, {value: price});
    const receipt = await tx.wait();
    
    console.log(receipt)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });