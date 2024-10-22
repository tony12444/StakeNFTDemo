// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {IBaseToken} from "../interfaces/IBaseToken.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IGovernable} from "../interfaces/IGovernable.sol";

/**
    test token
*/
contract AZT is ERC20, IBaseToken {
    address public gov;                                                     // manager address

    constructor(address gov_, string memory name_, string memory symbol_) ERC20(name_, symbol_){
        gov = gov_;
    }

    modifier onlyGov() {
        require(msg.sender == IGovernable(gov).gov(), "S_O0");
        _;
    }

    modifier onlyMinter() {
        require(IGovernable(gov).AZTMinters(msg.sender), "S_O1");
        _;
    }

    /// @notice change gov contract address ,only manager
    /// @param _gov new gov contract address
    function setGov(address _gov) external override onlyGov {
        gov = _gov;

        emit GovSettled(_gov);
    }

    /// @notice mint token , only mint by gov
    /// @param account  mint to account address
    /// @param value mint amount
    function mint(address account, uint256 value) external override onlyMinter {
        _mint(account, value);
    }

    /// @notice burn token
    /// @param value burn amount
    function burn(uint256 value) external override {
        _burn(msg.sender, value);
    }
}
