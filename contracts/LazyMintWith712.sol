// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface IAssetContractShared {
    function mint(
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data,
        uint96 _feeNumerator
    ) external;

    function mintWithRoyalty(
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data,
        uint96 _feeNumerator
    ) external;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) external;

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) view external returns (address, uint256);

    function defaultRoyaltyFraction() view external returns (uint96);
}

struct VerifyInfo {
    uint256 _tokenId;
    address _contract; 
    uint256 _price;
    address _creator; 
    uint96 _royaltyFraction; 
    address _seller;
}

contract LazyMintWith712 is EIP712, AccessControl {
    IAssetContractShared nftContract;
    address platformAddress;

    constructor(string memory name, address _nftAddress) EIP712(name, "1.0.0") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        nftContract = IAssetContractShared(_nftAddress);
    }

    function setPlatFormAddress(address _platformAddress) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
        platformAddress = _platformAddress;
    }

    function tokenTransfer(address seller, uint256 amount, uint256 royaltyAmount, address royaltyReceiver) internal {
        uint256 platformAmt = amount * 1 / 4;       // marketplace platform fee
        uint256 sellerAmt = amount - platformAmt;   // seller's money 
        bool success = false;
        if (royaltyAmount > 0) {
            sellerAmt = amount - royaltyAmount - platformAmt;
            (success, ) = payable(royaltyReceiver).call{value: royaltyAmount}("");
            require(success, "Failed to send money");
        }
        // transfer money to creator
        (success, ) = payable(seller).call{value: sellerAmt}("");
        require(success, "Failed to send money");
        // transfer money to platform
        (success, ) = payable(platformAddress).call{value: platformAmt}("");
        require(success, "Failed to send money");
    }

    // lazymint
    function mintNFT(
        VerifyInfo memory vinfo,
        address _to,
        uint256 _quantity,
        bytes memory _data,
        bytes calldata _signature
    ) payable public {
        bytes32 digest = _hash(vinfo);
        require(ECDSA.recover(digest, _signature) == vinfo._creator, "Invalid signature");

        nftContract.mint(_to, vinfo._tokenId, _quantity, _data, vinfo._royaltyFraction);
        
         // pay for each other
        uint256 royaltyAmount = 0;
        tokenTransfer(vinfo._creator, msg.value, royaltyAmount, address(0));
    }

    // safetransfer
    function transferNFT(
        VerifyInfo memory vinfo,
        address _to,
        uint256 _amount,
        bytes memory _data,
        bytes calldata _signature   
    ) payable public {
        bytes32 digest = _hash(vinfo);
        require(ECDSA.recover(digest, _signature) == vinfo._seller, "Invalid signature");

        nftContract.safeTransferFrom(vinfo._seller, _to, vinfo._tokenId, _amount, _data);
        // pay for each other
        (, uint256 royaltyAmount) = nftContract.royaltyInfo(vinfo._tokenId, msg.value);
        tokenTransfer(vinfo._seller, msg.value, royaltyAmount, vinfo._creator);
    }

    function _hash(VerifyInfo memory vinfo) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
            keccak256("OpenVoice(uint256 tokenId,address contract,uint256 price,address creator,uint96 royaltyFraction,address seller)"),
            vinfo._tokenId,
            vinfo._contract,
            vinfo._price,
            vinfo._creator,
            vinfo._royaltyFraction,
            vinfo._seller
        )));
    }
}
