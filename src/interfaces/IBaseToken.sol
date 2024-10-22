// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface IBaseToken {
    event GovSettled(address gov);

    function setGov(address _gov) external;

    function mint(address account, uint256 value) external;

    function burn(uint256 value) external;
}
