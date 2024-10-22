// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface IGovernable {

    event GovSettled(address newGov);
    event AZTMinterAdded(address minter);
    event AZTMinterRemoved(address minter);

    function gov() external view returns (address);

    function AZTMinters(address minter) external view returns (bool);

    function transferGov(address newGov) external;

    function addAZTMinter(address minter) external;

    function removeAZTMinter(address minter) external;
}
