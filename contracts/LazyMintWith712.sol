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
        bytes memory _data
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

    function creator(uint256 _id) view external returns (address);

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
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data,
        address _contract,
        uint96 _feeNumerator,
        bytes calldata _signature
    ) payable external {
        // price for each item
        uint256 perPrice = msg.value / _quantity;
        address _creator = nftContract.creator(_id);
        VerifyInfo memory vinfo;
        vinfo._tokenId = _id;
        vinfo._contract = _contract;
        vinfo._price = perPrice;
        vinfo._creator = _creator;
        vinfo._royaltyFraction = _feeNumerator;
        vinfo._seller = _creator;
        bytes32 digest = _hash(vinfo);
        require(_verify(digest, _signature, _creator), "Invalid signature");

        if (_feeNumerator == nftContract.defaultRoyaltyFraction()) {
            nftContract.mint(_to, _id, _quantity, _data);
        } else {
            nftContract.mintWithRoyalty(_to, _id, _quantity, _data, _feeNumerator);
        }
         // pay for each other
        uint256 royaltyAmount = 0;
        tokenTransfer(_creator, msg.value, royaltyAmount, address(0));
    }

    // safetransfer
    function transferNFT(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data,  
        address _contract,
        bytes calldata _signature     
    ) payable external {
        // price for each item
        uint256 perPrice = msg.value / _amount;
        address _creator = nftContract.creator(_id);
        (address royaltyReceiver, uint256 _royaltyFraction) = nftContract.royaltyInfo(_id, 10000);
        uint96 royaltyFraction = uint96(_royaltyFraction);
        VerifyInfo memory vinfo;
        vinfo._tokenId = _id;
        vinfo._contract = _contract;
        vinfo._price = perPrice;
        vinfo._creator = _creator;
        vinfo._royaltyFraction = royaltyFraction;
        vinfo._seller = _from;
        bytes32 digest = _hash(vinfo);
        require(_verify(digest, _signature, _from), "Invalid signature");

        nftContract.safeTransferFrom(_from, _to, _id, _amount, _data);
        // pay for each other
        (, uint256 royaltyAmount) = nftContract.royaltyInfo(_id, msg.value);
        tokenTransfer(_from, msg.value, royaltyAmount, royaltyReceiver);
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

    function _verify(bytes32 digest, bytes memory signature, address publicAddress) internal view returns (bool) {
        return (publicAddress == ECDSA.recover(digest, signature));
    }
}