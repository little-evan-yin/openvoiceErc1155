const { ethers } = require("hardhat");

async function main() {
    const [deployer, owner, buyer] = await ethers.getSigners();
    console.log("Deploying contracts with the account: ", deployer.address);
    console.log("NFT creator address: ", owner.address);
    console.log("Buyer address: ", buyer.address);  

    console.log("registry address: ", process.env.REG_ADDRESS);   // registry address 通过环境变量传入
    console.log("NFT contract address: ", process.env.NFT_ADDRESS);

    const { chainId } = await ethers.provider.getNetwork();

    // mint
    // get signature first!
    // 流程：
    // 1. 用户挂单的时候，组建datajson，先让用户签名，将签名数据保留在数据库中
    const orderTypes = {
        OpenVoice: [
            { name: 'tokenId', type: 'uint256' },
            { name: 'contract', type: 'address' },
            { name: 'price', type: 'uint256' },
            { name: 'creator', type: 'address' },
            { name: 'royaltyFraction', type: 'uint96' },
            { name: 'seller', type: 'address' },
        ]
    }

    const domain = {
        name: 'OpenVoice',
        version: '1.0.0',
        chainId,
        verifyingContract: process.env.REG_ADDRESS
    }

    const tokenId = '50930204793815341472647614845042490728161331526673935029629296842683499675658';
    const contractAddress = process.env.NFT_ADDRESS;
    const defaultRoyaltyFraction = 100;    // 1%
    const typedValue = {
        'tokenId': tokenId,
        'contract': contractAddress,
        'price': 10000000,
        'creator': owner.address,
        'royaltyFraction': defaultRoyaltyFraction,
        'seller': owner.address
    }

    const signature = await owner._signTypedData(
        domain,
        orderTypes,
        typedValue
    )
    
    console.log({ registry: process.env.REG_ADDRESS, signature });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });