const { ethers } = require("hardhat");

async function main() {
    const [deployer, owner, seller, buyer] = await ethers.getSigner();
    console.log("Deploying contracts with the account: ", deployer.address);
    console.log("NFT creator address: ", owner.address);
    console.log("seller address: ", seller.address);  
    console.log("buyer address: ", buyer.address);  

    console.log("registry address: ", process.env.REG_ADDRESS);   // registry address 通过环境变量传入
    console.log("NFT contract address: ", process.env.NFT_ADDRESS);

    // typed data didn't change!
    const orderTypes = {
        OpenVoice: [
            { name: 'tokenId', type: 'uint256' },
            { name: 'contract', type: 'address' },
            { name: 'price', type: 'uint256' },
            { name: 'creator', type: 'address' },
            { name: 'royaltyFraction', type: 'uint96' },
            { name: 'seller', type: 'address' }
        ]
    }

    const domain = {
        name: 'OpenVoice',
        version: '1.0.0',
        chainId,
        verifyingContract: process.env.ADDRESS,
        salt: random(1, 100)
    }

    const tokenId = 107620024739658412805886307570881852509861757131837649177597025795553282228234;
    const contractAddress = process.env.NFT_ADDRESS;
    const defaultRoyaltyFraction = 100;    // 1%
    const typedValue = {
        'tokenId': tokenId,
        'contract': contractAddress,
        'price': 20000000,
        'creator': owner.address,
        'royaltyFraction': defaultRoyaltyFraction,
        'seller': seller.address
    }

    const signature = await seller._signTypedData(
        domain,
        orderTypes,
        typedValue
    )
    
    console.log({ registry: registry.address, signature });

    // buy from the seller not the owner!
    const registry = (await attach('LazyMintWith712', process.env.REG_ADDRESS)).connect(buyer);
    const tx = await registry.transferNFT(seller.address, buyer.address, tokenId, 1, '0x', contractAddress, signature);
    const receipt = await tx.wait();

    console.log(receipt);

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });