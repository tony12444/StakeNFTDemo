// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import {NFT} from "../src/tokens/NFT.sol";
import {AZT} from "../src/tokens/AZT.sol";
import {Governable} from "../src/gov/Governable.sol";
import {NFTReward} from "../src/NFTReward.sol";

contract NFTTest is Test {
    using stdStorage for StdStorage;

    bytes32 public tmpRoot = 0xa7a6b1cb6d12308ec4818baac3413fafa9e8b52cdcd79252fa9e29c9a2f8aff1;
    string public baseUri = "https://www.google.com";

    Governable public gov;
    NFTReward public reward;
    AZT public azt;
    NFT public nft;

    function setUp() public {
        address admin = address(0x1234);
        gov = new Governable(admin);
        azt = new AZT(address(gov), "AZT", "AZT");
        nft = new NFT(address(gov), 10000, tmpRoot, "DEMO", "DEMO");
        reward = new NFTReward(address(gov), address(azt), address(nft));

        // contract config
        vm.startPrank(admin);

        gov.addAZTMinter(address(reward));

        nft.setBaseURI(baseUri);
        // precision 1e4
        reward.setInterestRate(1e3);

        vm.stopPrank();
    }

    function test_SetGov() external {
        address admin = address(0x1234);
        vm.startPrank(admin);
        nft.setGov(address(1));
        vm.stopPrank();
        address newGovFromContract = nft.gov();

        assertEq(newGovFromContract, address(1), "test result: fail1");
    }

    function testFail_SetGov() external {
        nft.setGov(address(1));
        address newGovFromContract = nft.gov();

        assertEq(newGovFromContract, address(1), "test result: fail2");
    }

    function test_SetInterestRate() external {
        address admin = address(0x1234);
        vm.startPrank(admin);
        reward.setInterestRate(10);
        vm.stopPrank();
        uint256 newInterestRate = reward.interestRate();

        assertEq(newInterestRate, 10, "test result: fail3");
    }

    function testFail_SetInterestRate() external {
        reward.setInterestRate(10);
        vm.stopPrank();
        uint256 newInterestRate = reward.interestRate();

        assertEq(newInterestRate, 10, "test result: fail4");
    }

    function test_WithdrawToken() external {
        address admin = address(0x1234);
        uint256 mintAmount = 10 * 1e18;
        vm.prank(address(reward));
        azt.mint(address(reward), 10 * 1e18);
        vm.prank(admin);
        reward.withdrawToken(address(azt), address(1), mintAmount);
        uint256 balanceOfAddress1 = azt.balanceOf(address(1));

        assertEq(mintAmount, balanceOfAddress1, "test result: fail5");
    }

    function testFail_WithdrawToken() external {
        address admin = address(0x1234);
        uint256 mintAmount = 10 * 1e18;
        vm.prank(address(reward));
        azt.mint(address(reward), 10 * 1e18);
        reward.withdrawToken(address(azt), address(1), mintAmount);
        uint256 balanceOfAddress1 = azt.balanceOf(address(1));

        assertEq(mintAmount, balanceOfAddress1, "test result: fail6");
    }

    function test_Stake() external {
        address admin = address(0x1234);

        vm.startPrank(admin);
        nft.setStartTime(block.timestamp);
        nft.setEndTime(block.timestamp + 3600);
        vm.stopPrank();

        //set white list address
        // white list address address(1),address(4),address(2),address(3),address(4),address(5)
        address minter = address(4);

        bytes32[] memory proofs = new bytes32[](3);
        proofs[0] = 0x5b70e80538acdabd6137353b0f9d8d149f4dba91e8be2e7946e409bfdbe685b9;
        proofs[1] = 0xf95c14e6953c95195639e8266ab1a6850864d59a829da9f9b13602ee522f672b;
        proofs[2] = 0x421df1fa259221d02aa4956eb0d35ace318ca24c0a33a64c1af96cf67cf245b6;

        vm.prank(minter);
        nft.whiteListMint(minter, proofs);

        // approve
        vm.prank(minter);
        nft.setApprovalForAll(address(reward), true);

        // stake
        vm.prank(minter);
        reward.stake(1);

        assertEq(address(reward), nft.ownerOf(1), "test result: fail7");
        assertEq(nft.balanceOf(minter), 0, "test result: fail8");
        assertEq(azt.balanceOf(address(reward)), 1000 * 1e18, "test result: fail9");
    }

    function testFail_Stake() external {
        address admin = address(0x1234);

        vm.startPrank(admin);
        nft.setStartTime(block.timestamp);
        nft.setEndTime(block.timestamp + 3600);
        vm.stopPrank();

        //set white list address
        // white list address address(1),address(4),address(2),address(3),address(4),address(5)
        address minter = address(4);

        bytes32[] memory proofs = new bytes32[](3);
        proofs[0] = 0x5b70e80538acdabd6137353b0f9d8d149f4dba91e8be2e7946e409bfdbe685b9;
        proofs[1] = 0xf95c14e6953c95195639e8266ab1a6850864d59a829da9f9b13602ee522f672b;
        proofs[2] = 0x421df1fa259221d02aa4956eb0d35ace318ca24c0a33a64c1af96cf67cf245b6;

        vm.prank(minter);
        nft.whiteListMint(minter, proofs);

        // approve
        //vm.prank(minter);
        //nft.setApprovalForAll(address(reward), true);

        // stake
        vm.prank(minter);
        reward.stake(1);

        assertEq(address(reward), nft.ownerOf(1), "test result: fail7");
        assertEq(nft.balanceOf(minter), 0, "test result: fail8");
    }

    function testFail_StakeRepeat() external {
        address admin = address(0x1234);

        vm.startPrank(admin);
        nft.setStartTime(block.timestamp);
        nft.setEndTime(block.timestamp + 3600);
        vm.stopPrank();

        //set white list address
        // white list address address(1),address(4),address(2),address(3),address(4),address(5)
        address minter = address(4);

        bytes32[] memory proofs = new bytes32[](3);
        proofs[0] = 0x5b70e80538acdabd6137353b0f9d8d149f4dba91e8be2e7946e409bfdbe685b9;
        proofs[1] = 0xf95c14e6953c95195639e8266ab1a6850864d59a829da9f9b13602ee522f672b;
        proofs[2] = 0x421df1fa259221d02aa4956eb0d35ace318ca24c0a33a64c1af96cf67cf245b6;

        vm.prank(minter);
        nft.whiteListMint(minter, proofs);

        // approve
        vm.prank(minter);
        nft.setApprovalForAll(address(reward), true);

        // stake
        vm.prank(minter);
        reward.stake(1);

        // fail to stake
        vm.prank(minter);
        reward.stake(1);
    }

    function test_unStake() external {
        address admin = address(0x1234);

        vm.startPrank(admin);
        nft.setStartTime(block.timestamp);
        nft.setEndTime(block.timestamp + 3600);
        vm.stopPrank();

        //set white list address
        // white list address address(1),address(4),address(2),address(3),address(4),address(5)
        address minter = address(4);

        bytes32[] memory proofs = new bytes32[](3);
        proofs[0] = 0x5b70e80538acdabd6137353b0f9d8d149f4dba91e8be2e7946e409bfdbe685b9;
        proofs[1] = 0xf95c14e6953c95195639e8266ab1a6850864d59a829da9f9b13602ee522f672b;
        proofs[2] = 0x421df1fa259221d02aa4956eb0d35ace318ca24c0a33a64c1af96cf67cf245b6;

        vm.prank(minter);
        nft.whiteListMint(minter, proofs);

        // approve
        vm.prank(minter);
        nft.setApprovalForAll(address(reward), true);

        // stake
        vm.prank(minter);
        reward.stake(1);

        // un stake
        vm.prank(minter);
        reward.unStake(1, address(100));

        assertEq(nft.ownerOf(1), address(100), "test result: fail9");
        assertEq(azt.balanceOf(address(100)), 1000 * 1e18, "test result: fail10");
    }

    function testFail_unStake() external {
        address admin = address(0x1234);

        vm.startPrank(admin);
        nft.setStartTime(block.timestamp);
        nft.setEndTime(block.timestamp + 3600);
        vm.stopPrank();

        //set white list address
        // white list address address(1),address(4),address(2),address(3),address(4),address(5)
        address minter = address(4);

        bytes32[] memory proofs = new bytes32[](3);
        proofs[0] = 0x5b70e80538acdabd6137353b0f9d8d149f4dba91e8be2e7946e409bfdbe685b9;
        proofs[1] = 0xf95c14e6953c95195639e8266ab1a6850864d59a829da9f9b13602ee522f672b;
        proofs[2] = 0x421df1fa259221d02aa4956eb0d35ace318ca24c0a33a64c1af96cf67cf245b6;

        vm.prank(minter);
        nft.whiteListMint(minter, proofs);

        // approve
        vm.prank(minter);
        nft.setApprovalForAll(address(reward), true);

        // stake
        vm.prank(minter);
        reward.stake(1);

        // un stake
        vm.prank(address(100));
        reward.unStake(1, address(100));

        assertEq(nft.ownerOf(1), address(100), "test result: fail9");
    }

    function test_ReStake() external {
        address admin = address(0x1234);

        vm.startPrank(admin);
        nft.setStartTime(block.timestamp);
        nft.setEndTime(block.timestamp + 3600);
        vm.stopPrank();

        //set white list address
        // white list address address(1),address(4),address(2),address(3),address(4),address(5)
        address minter = address(4);

        bytes32[] memory proofs = new bytes32[](3);
        proofs[0] = 0x5b70e80538acdabd6137353b0f9d8d149f4dba91e8be2e7946e409bfdbe685b9;
        proofs[1] = 0xf95c14e6953c95195639e8266ab1a6850864d59a829da9f9b13602ee522f672b;
        proofs[2] = 0x421df1fa259221d02aa4956eb0d35ace318ca24c0a33a64c1af96cf67cf245b6;

        vm.prank(minter);
        nft.whiteListMint(minter, proofs);

        // approve
        vm.prank(minter);
        nft.setApprovalForAll(address(reward), true);

        // stake
        vm.prank(minter);
        reward.stake(1);

        // un stake
        vm.prank(minter);
        reward.unStake(1, minter);

        // re stake
        vm.prank(minter);
        azt.approve(address(reward), 1000 * 1e18);

        vm.prank(minter);
        reward.stake(1);

        assertEq(address(reward), nft.ownerOf(1), "test result: fail10");
        assertEq(nft.balanceOf(minter), 0, "test result: fail11");
        assertEq(azt.balanceOf(address(reward)), 1000 * 1e18, "test result: fail12");
    }

    function testFail_ReStake() external {
        address admin = address(0x1234);

        vm.startPrank(admin);
        nft.setStartTime(block.timestamp);
        nft.setEndTime(block.timestamp + 3600);
        vm.stopPrank();

        //set white list address
        // white list address address(1),address(4),address(2),address(3),address(4),address(5)
        address minter = address(4);

        bytes32[] memory proofs = new bytes32[](3);
        proofs[0] = 0x5b70e80538acdabd6137353b0f9d8d149f4dba91e8be2e7946e409bfdbe685b9;
        proofs[1] = 0xf95c14e6953c95195639e8266ab1a6850864d59a829da9f9b13602ee522f672b;
        proofs[2] = 0x421df1fa259221d02aa4956eb0d35ace318ca24c0a33a64c1af96cf67cf245b6;

        vm.prank(minter);
        nft.whiteListMint(minter, proofs);

        // approve
        vm.prank(minter);
        nft.setApprovalForAll(address(reward), true);

        // stake
        vm.prank(minter);
        reward.stake(1);

        // un stake
        vm.prank(minter);
        reward.unStake(1, minter);

        // re stake
        // vm.prank(minter);
        // azt.approve(address(reward), 1000 * 1e18);

        vm.prank(minter);
        reward.stake(1);

        assertEq(address(reward), nft.ownerOf(1), "test result: fail10");
        assertEq(nft.balanceOf(minter), 0, "test result: fail11");
        assertEq(azt.balanceOf(address(reward)), 1000 * 1e18, "test result: fail12");
    }

    function test_Claim() external {
        address admin = address(0x1234);

        vm.startPrank(admin);
        nft.setStartTime(block.timestamp);
        nft.setEndTime(block.timestamp + 3600);
        vm.stopPrank();

        //set white list address
        // white list address address(1),address(4),address(2),address(3),address(4),address(5)
        address minter = address(4);

        bytes32[] memory proofs = new bytes32[](3);
        proofs[0] = 0x5b70e80538acdabd6137353b0f9d8d149f4dba91e8be2e7946e409bfdbe685b9;
        proofs[1] = 0xf95c14e6953c95195639e8266ab1a6850864d59a829da9f9b13602ee522f672b;
        proofs[2] = 0x421df1fa259221d02aa4956eb0d35ace318ca24c0a33a64c1af96cf67cf245b6;

        vm.prank(minter);
        nft.whiteListMint(minter, proofs);

        // approve
        vm.prank(minter);
        nft.setApprovalForAll(address(reward), true);

        // stake
        vm.prank(minter);
        reward.stake(1);


        vm.warp(block.timestamp + 2 days);

        vm.prank(minter);
        reward.claim(1, minter);

        uint256 rewardClaimed = azt.balanceOf(minter);

        assertEq(rewardClaimed, 1000 * 1e18 * ((1 + 0.1)**2) - 1000 * 1e18, "test result: fail13");
    }

    function testFail_Claim() external {
        address admin = address(0x1234);

        vm.startPrank(admin);
        nft.setStartTime(block.timestamp);
        nft.setEndTime(block.timestamp + 3600);
        vm.stopPrank();

        //set white list address
        // white list address address(1),address(4),address(2),address(3),address(4),address(5)
        address minter = address(4);

        bytes32[] memory proofs = new bytes32[](3);
        proofs[0] = 0x5b70e80538acdabd6137353b0f9d8d149f4dba91e8be2e7946e409bfdbe685b9;
        proofs[1] = 0xf95c14e6953c95195639e8266ab1a6850864d59a829da9f9b13602ee522f672b;
        proofs[2] = 0x421df1fa259221d02aa4956eb0d35ace318ca24c0a33a64c1af96cf67cf245b6;

        vm.prank(minter);
        nft.whiteListMint(minter, proofs);

        // approve
        vm.prank(minter);
        nft.setApprovalForAll(address(reward), true);

        // stake
        vm.prank(minter);
        reward.stake(1);


        vm.warp(block.timestamp + 1 days);

        vm.prank(address(10));
        reward.claim(1, minter);

        uint256 rewardClaimed = azt.balanceOf(minter);

        assertEq(rewardClaimed, 1000 * 1e18 * (1 + 0.1) - 1000 * 1e18, "test result: fail13");
    }

}
