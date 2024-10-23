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

    function test_SetBaseURI() external {
        address admin = address(0x1234);
        vm.startPrank(admin);
        string memory uri = "ss";
        nft.setBaseURI(uri);
        vm.stopPrank();
        string memory newUriFromContract = nft.baseURI();

        assertEq(newUriFromContract, uri, "test result: fail3");
    }

    function testFail_SetBaseURI() external {
        string memory uri = "ss";
        nft.setBaseURI(uri);
        string memory newUriFromContract = nft.baseURI();

        assertEq(newUriFromContract, uri, "test result: fail4");
    }

    function test_SetStartTime() external {
        address admin = address(0x1234);
        vm.startPrank(admin);
        nft.setStartTime(10);
        vm.stopPrank();
        uint256 newStartTime = nft.startTime();

        assertEq(newStartTime, 10, "test result: fail5");
    }

    function testFail_SetStartTime() external {
        nft.setStartTime(10);
        uint256 newStartTime = nft.startTime();

        assertEq(newStartTime, 10, "test result: fail6");
    }

    function test_SetEndTime() external {
        address admin = address(0x1234);
        vm.startPrank(admin);
        nft.setEndTime(20);
        vm.stopPrank();
        uint256 newEndTime = nft.endTime();

        assertEq(newEndTime, 20, "test result: fail7");
    }

    function testFail_SetEndTime() external {
        nft.setEndTime(20);
        uint256 newEndTime = nft.endTime();

        assertEq(newEndTime, 20, "test result: fail8");
    }

    function test_WhiteListMint() external {
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

        address ownerOfTokenId = nft.ownerOf(1);

        assertEq(ownerOfTokenId, minter, "test result: fail9");
    }

    function testFail_MintWithOutWhiteList() external {
        address admin = address(0x1234);

        vm.startPrank(admin);
        nft.setStartTime(block.timestamp);
        nft.setEndTime(block.timestamp + 3600);
        vm.stopPrank();

        //set white list address
        // white list address address(1),address(4),address(2),address(3),address(4),address(5)
        address minter = address(6);

        bytes32[] memory proofs = new bytes32[](3);
        proofs[0] = 0x5b70e80538acdabd6137353b0f9d8d149f4dba91e8be2e7946e409bfdbe685b9;
        proofs[1] = 0xf95c14e6953c95195639e8266ab1a6850864d59a829da9f9b13602ee522f672b;
        proofs[2] = 0x421df1fa259221d02aa4956eb0d35ace318ca24c0a33a64c1af96cf67cf245b6;

        vm.prank(minter);
        nft.whiteListMint(minter, proofs);

        address ownerOfTokenId = nft.ownerOf(1);

        assertEq(ownerOfTokenId, minter, "test result: fail9");
    }

    function testFail_MintWithMinted() external {
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

        address ownerOfTokenId = nft.ownerOf(1);

        assertEq(ownerOfTokenId, minter, "test result: fail9");

        // mint nft repeat
        vm.prank(minter);
        nft.whiteListMint(minter, proofs);
    }
}
