// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {IGovernable} from "../interfaces/IGovernable.sol";

contract Governable is IGovernable {
    address public override gov;                                 // contract manager
    mapping(address => bool) public override AZTMinters;        // sAZT token minter

    constructor(address _gov) {
        gov = _gov;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "G_O0");
        _;
    }

    /// @notice manager address update func
    /// @param newGov the new manager address
    function transferGov(address newGov) external override onlyGov {
        require(newGov != address(0), "G_T0");
        gov = newGov;

        emit GovSettled(newGov);
    }

    /// @notice add sAZT minter ,only manager
    /// @param minter new minter
    function addAZTMinter(address minter) external override onlyGov {
        require(minter != address(0), "G_A1");
        AZTMinters[minter] = true;

        emit AZTMinterAdded(minter);
    }

    /// @notice remove sAZT minter ,only manager
    /// @param minter deprecated minter
    function removeAZTMinter(address minter) external override onlyGov {
        require(minter != address(0), "G_R1");
        AZTMinters[minter] = false;

        emit AZTMinterRemoved(minter);
    }
}
