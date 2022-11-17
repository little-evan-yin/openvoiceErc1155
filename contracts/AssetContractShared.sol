// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "./AssetContract.sol";
import "./TokenIdentifiers.sol";

/**
 * @title AssetContractShared
 * OpenSea shared asset contract - A contract for easily creating custom assets on OpenSea
 */
contract AssetContractShared is AssetContract, ReentrancyGuardUpgradeable, ERC2981Upgradeable {
    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _templateURI,
        uint96 _royaltyFraction,
        address _proxyRegistryAddress
    ) public virtual initializer {
        __AssetContractShared_init(_name, _symbol, _templateURI, _royaltyFraction, _proxyRegistryAddress);
    }

    using TokenIdentifiers for uint256;

    event CreatorChanged(uint256 indexed _id, address indexed _creator);

    mapping(uint256 => address) internal _creatorOverride;
    
    uint96 public defaultRoyaltyFraction;

    /**
     * @dev Require msg.sender to be the creator of the token id
     */
    modifier creatorOnly(uint256 _id) {
        require(
            _isCreatorOrProxy(_id, _msgSender()),
            "AssetContractShared#creatorOnly: ONLY_CREATOR_ALLOWED"
        );
        _;
    }

    /**
     * @dev Require the caller to own the full supply of the token
     */
    modifier onlyFullTokenOwner(uint256 _id) {
        require(
            _ownsTokenAmount(_msgSender(), _id, _id.tokenMaxSupply()),
            "AssetContractShared#onlyFullTokenOwner: ONLY_FULL_TOKEN_OWNER_ALLOWED"
        );
        _;
    }

    function __AssetContractShared_init(
        string memory _name,
        string memory _symbol,
        string memory _templateURI,
        uint96 _royaltyFraction,
        address _proxyRegistryAddress
    ) internal onlyInitializing {
        __AssetContract_init(_name, _symbol, _templateURI, _proxyRegistryAddress);
        defaultRoyaltyFraction = _royaltyFraction;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155Upgradeable, ERC2981Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            interfaceId == type(IERC2981Upgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function whosSender() public view returns(address) {
        return _msgSender();
    }

    /**
     * mint: only owner or proxy address can call
     */
    function mint(
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data,
        uint96 _feeNumerator
    ) public nonReentrant creatorOnly(_id) {
        _mint(_to, _id, _quantity, _data);
        (address receiver, ) = royaltyInfo(_id, 1);
        if (receiver == address(0)) {
            _setTokenRoyalty(_id, _id.tokenCreator(), _feeNumerator);     // 设置该用户版权税
        }
    }

    function batchMint(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _quantities,
        bytes memory _data
    ) public override nonReentrant {
        for (uint256 i = 0; i < _ids.length; i++) {
            require(
                _isCreatorOrProxy(_ids[i], _msgSender()),
                "AssetContractShared#_batchMint: ONLY_CREATOR_ALLOWED"
            );
        }
        _batchMint(_to, _ids, _quantities, _data);
    }

    /////////////////////////////////
    // CONVENIENCE CREATOR METHODS //
    /////////////////////////////////

    function setDefaultRoyaltyFraciton(uint96 _royaltyFraction) public onlyOwnerOrProxy {
        defaultRoyaltyFraction = _royaltyFraction;
    }

    function setProxyRegistryAddress(address _address) public onlyOwnerOrProxy {
        proxyRegistryAddress = _address;
    }

    /**
     * @dev Will update the URI for the token
     * @param _id The token ID to update. msg.sender must be its creator, the uri must be impermanent,
     *            and the creator must own all of the token supply
     * @param _uri New URI for the token.
     */
    function setURI(uint256 _id, string memory _uri)
        public
        override
        creatorOnly(_id)
        onlyImpermanentURI(_id)
        onlyFullTokenOwner(_id)
    {
        _setURI(_id, _uri);
    }

    /**
     * @dev setURI, but permanent
     */
    function setPermanentURI(uint256 _id, string memory _uri)
        public
        override
        creatorOnly(_id)
        onlyImpermanentURI(_id)
        onlyFullTokenOwner(_id)
    {
        _setPermanentURI(_id, _uri);
    }

    /**
     * @dev Change the creator address for given token
     * @param _to   Address of the new creator
     * @param _id  Token IDs to change creator of
     */
    function setCreator(uint256 _id, address _to) public creatorOnly(_id) {
        require(
            _to != address(0),
            "AssetContractShared#setCreator: INVALID_ADDRESS."
        );
        _creatorOverride[_id] = _to;
        emit CreatorChanged(_id, _to);
    }

    /**
     * @dev Get the creator for a token
     * @param _id   The token id to look up
     */
    function creator(uint256 _id) public view returns (address) {
        if (_creatorOverride[_id] != address(0)) {
            return _creatorOverride[_id];
        } else {
            return _id.tokenCreator();
        }
    }

    /**
     * @dev Get the maximum supply for a token
     * @param _id   The token id to look up
     */
    function maxSupply(uint256 _id) public pure returns (uint256) {
        return _id.tokenMaxSupply();
    }

    // Override ERC1155Tradable for birth events
    function _origin(uint256 _id) internal pure override returns (address) {
        return _id.tokenCreator();
    }

    function _requireMintable(address _address, uint256 _id) internal view {
        require(
            _isCreatorOrProxy(_id, _address),
            "AssetContractShared#_requireMintable: ONLY_CREATOR_ALLOWED"
        );
    }

    function _remainingSupply(uint256 _id)
        internal
        view
        override
        returns (uint256)
    {
        return maxSupply(_id) - totalSupply(_id);
    }

    function _isCreatorOrProxy(uint256 _id, address _address)
        internal
        view
        override
        returns (bool)
    {
        address creator_ = creator(_id);
        return creator_ == _address || proxyRegistryAddress == _address;
    }

    function createMintEvent(uint256 _id) public {
        emit TransferSingle(_msgSender(), address(0), _id.tokenCreator(), _id, _id.tokenMaxSupply());
    }
}