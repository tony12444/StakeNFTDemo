// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface INFTReward {
    event GovSettled(address gov);
    event InterestRateSettled(uint256 rate);
    event WithdrawToken(address token, address dst, uint256 amount);
    event Staked(address account, uint256 tokenId);
    event UnStaked(address account, uint256 tokenId, address receiver, uint256 amountToOwner);
    event Claimed(address account, uint256 tokenId, address receiver, uint256 amount);

    function setGov(address _gov) external;

    function setInterestRate(uint256 rate) external;

    function withdrawToken(address token, address dst, uint256 amount) external;

    function stake(uint256 tokenId) external;

    function unStake(uint256 tokenId, address receiver) external;

    function claim(uint256 tokenId, address receiver) external;

    function claimable(uint256 tokenId) external view returns (uint256);
}
