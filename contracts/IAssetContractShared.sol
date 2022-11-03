// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IAssetContractShared {
    function mint(
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