const { ethers } = require("hardhat");

async function attach(name, address) {
  const contractFactory = await ethers.getContractFactory(name);
  return contractFactory.attach(address);
}

async function main() {
    const [deployer, owner, buyer] = await ethers.getSigners();
    console.log("Deploying contracts with the account: ", deployer.address);
    console.log("NFT creator address: ", owner.address);
    console.log("seller address: ", buyer.address);  
    console.log("buyer address: ", owner.address);  

    console.log("registry address: ", process.env.REG_ADDRESS);   // registry address 通过环境变量传入
    console.log("NFT contract address: ", process.env.NFT_ADDRESS);

    const { chainId } = await ethers.provider.getNetwork();

    // typed data didn't change!
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

    const tokenId = '25268102393833623659465216594422475168297195417170346890848025712765042639424';
    const contractAddress = process.env.NFT_ADDRESS;
    const defaultRoyaltyFraction = 10;    // 1%
    const typedValue = {
        'tokenId': tokenId,
        'contract': contractAddress,
        'price': '10260000000000000',
        'creator': owner.address,
        'royaltyFraction': defaultRoyaltyFraction,
        'seller': buyer.address
    }

    console.log(typedValue)

    const signature = await buyer._signTypedData(
        domain,
        orderTypes,
        typedValue
    )
    
    console.log({ registry: process.env.REG_ADDRESS, signature });

    // buy from the seller not the owner!
    const registry = (await attach('LazyMintWith712', process.env.REG_ADDRESS)).connect(owner);

    const price = '10260000000000000'
    // price 参数直接通过交易中的value传递
    const tx = await registry.transferNFT(tokenId, contractAddress, owner.address, defaultRoyaltyFraction, buyer.address, owner.address, 1, '0x', signature, {value: price});
    const receipt = await tx.wait();

    console.log(receipt);

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });