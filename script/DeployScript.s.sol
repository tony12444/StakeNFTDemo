// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Script.sol";
import {AZT} from "../src/tokens/AZT.sol";
import {NFT} from "../src/tokens/NFT.sol";
import {Governable} from "../src/gov/Governable.sol";
import {NFTReward} from "../src/NFTReward.sol";

contract DeployScript is Script {
    address public tmpGov = 0x0444C019C90402033fF8246BCeA440CeB9468C88;
    bytes32 public tmpRoot = 0;
    uint256 public starTime = 0;
    uint256 public endTime = 0;
    string public baseUri = "https://www.google.com";

    function run() external {
        uint256 deployKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployKey);

        // 1.deploy contract
        Governable gov = new Governable(tmpGov);
        AZT azt = new AZT(address(gov), "AZT", "AZT");
        NFT nft = new NFT(address(gov), 10000, tmpRoot, "DEMO", "DEMO");
        NFTReward reward = new NFTReward(address(gov), address(azt), address(nft));

        // 2.contract config
        gov.addAZTMinter(address(reward));

        nft.setBaseURI(baseUri);
        nft.setStartTime(starTime);
        nft.setEndTime(endTime);
        // precision 1e4
        reward.setInterestRate(1e3);

        vm.stopBroadcast();

    }
}
