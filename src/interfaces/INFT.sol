// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface INFT {
    event GovSettled(address gov);
    event BaseURISettled(string  uri);
    event StartTimeSettled(uint256 time);
    event EndTimeSettled(uint256 time);
    event Minted(address account, uint256 tokenId);

    function setGov(address _gov) external;

    function setBaseURI(string calldata uri) external;

    function setStartTime(uint256 time) external;

    function setEndTime(uint256 time) external;

    function whiteListMint(address account, bytes32[] calldata merkleProof) external;
}
