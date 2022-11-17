// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./IAssetContractShared.sol";


contract LazyMintWith712 is Initializable, EIP712Upgradeable, AccessControlUpgradeable {
    function initialize(
        string memory name, 
        string memory version, 
        address _nftAddress
    ) public virtual initializer {
        __LazyMintWith712_init(name, version, _nftAddress);
    }

    IAssetContractShared public nftContract;
    address platformAddress;

    // _nftAddress means the nft contract logic address (have to updated if changed !)
    function __LazyMintWith712_init(string memory name, string memory version, address _nftAddress) internal onlyInitializing {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        __EIP712_init_unchained(name, version);
        __LazyMintWith712_init_unchained(_nftAddress);
    }

    function __LazyMintWith712_init_unchained(address _nftAddress) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
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
        uint256 _tokenId,
        address _contract,
        address _creator, 
        uint96 _royaltyFraction, 
        address _seller,
        address _to,
        uint256 _quantity,
        bytes memory _data,
        bytes calldata _signature
    ) payable public {
        bytes32 digest = _hash(_tokenId, _contract, msg.value, _creator, _royaltyFraction, _seller);
        require(ECDSAUpgradeable.recover(digest, _signature) == _creator, "Invalid signature");

        nftContract.mint(_to, _tokenId, _quantity, _data, _royaltyFraction);
        
         // pay for each other
        uint256 royaltyAmount = 0;
        tokenTransfer(_creator, msg.value, royaltyAmount, address(0));
    }

    // safetransfer
    function transferNFT(
        uint256 _tokenId,
        address _contract,
        address _creator, 
        uint96 _royaltyFraction, 
        address _seller,
        address _to,
        uint256 _amount,
        bytes memory _data,
        bytes calldata _signature   
    ) payable public {
        bytes32 digest = _hash(_tokenId, _contract, msg.value, _creator, _royaltyFraction, _seller);
        require(ECDSAUpgradeable.recover(digest, _signature) == _seller, "Invalid signature");

        nftContract.safeTransferFrom(_seller, _to, _tokenId, _amount, _data);
        // pay for each other
        (, uint256 royaltyAmount) = nftContract.royaltyInfo(_tokenId, msg.value);
        tokenTransfer(_seller, msg.value, royaltyAmount, _creator);
    }

    function _hash(uint256 _tokenId, address _contract, uint256 _price, address _creator, uint96 _royaltyFraction, address _seller) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
            keccak256("OpenVoice(uint256 tokenId,address contract,uint256 price,address creator,uint96 royaltyFraction,address seller)"),
            _tokenId,
            _contract,
            _price,
            _creator,
            _royaltyFraction,
            _seller
        )));
    }
}
