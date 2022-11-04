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

    console.log("registry address: ", process.env.REG_ADDRESS);      // registry address 通过环境变量传入
    console.log("NFT contract address: ", process.env.NFT_ADDRESS);

    const { chainId } = await ethers.provider.getNetwork();

    const tokenId = '50930204793815341472647614845042490728161331526673935029629296842683499675658';
    const contractAddress = process.env.NFT_ADDRESS;
    const nft = (await attach('AssetContractShared', contractAddress)).connect(owner);

    // mint
    // 流程：
    // 1. 上传metadata.json到ipfs，或其他数据存储平台（可使用moralis ipfs api 也可使用自己的后台接口）
    const metadata = {
        "name": "Quiero Pancakes",
        "attributes": {
            "birthday": "03-04",
            "birth month": "March",
            "zodiac sign": "Pisces"
        },
        "image": "https://birthstamps.herokuapp.com/images/4.png",
        "description": "This is the tokens description"
    }

    const data = [{
        path: "openvoice/0.json",
        content: Buffer.from(JSON.stringify(metadata)).toString('base64')
    }]
    
    const moralisUploadUrl = 'https://deep-index.moralis.io/api/v2/ipfs/uploadFolder'
    const options = {
        method: 'POST',
        url: moralisUploadUrl,
        data: data,
        headers: {
            accept: 'application/json',
            'content-type': 'application/json',
            'X-API-Key': 'test'     
        }
    }

    const res = await axios(options);
    console.log(res.data);

    // 2. 绑定tokenID 和 tokenURI
    const tokenURI = res.data[0].path;
    const tx = await nft.setURI(tokenId, tokenURI)
    const receipt = await tx.wait();
    console.log(receipt)

    // 3. 用户挂单的时候，组建datajson，先让用户签名，将签名数据保留在数据库中
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