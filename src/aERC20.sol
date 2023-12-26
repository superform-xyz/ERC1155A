// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IaERC20 } from "./interfaces/IaERC20.sol";
import { ERC20 } from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/// @title aERC20
/// @dev ERC20 tokens out of 1155A
/// @author Zeropoint Labs
contract aERC20 is ERC20, IaERC20 {

    //////////////////////////////////////////////////////////////
    //                         CONSTANTS                        //
    //////////////////////////////////////////////////////////////

    address public immutable ERC1155A;
    uint8 private immutable TOKEN_DECIMALS;

    //////////////////////////////////////////////////////////////
    //                       MODIFIERS                          //
    //////////////////////////////////////////////////////////////

    modifier onlyTokenTransmuter() {
        if (msg.sender != ERC1155A) {
            revert ONLY_ERC1155A();
        }
        _;
    }

    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    constructor(string memory name_, string memory symbol_, uint8 decimals_) ERC20(name_, symbol_) {
        ERC1155A = msg.sender;
        TOKEN_DECIMALS = decimals_;
    }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// inheritdoc IaERC20
    function decimals() public view override returns (uint8) {
        return TOKEN_DECIMALS;
    }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// inheritdoc IaERC20
    function mint(address owner, uint256 amount) external override onlyTokenTransmuter {
        _mint(owner, amount);
    }

    /// inheritdoc IaERC20
    function burn(address owner, address operator, uint256 amount) external override onlyTokenTransmuter {
        if (owner != operator) _spendAllowance(owner, operator, amount);

        _burn(owner, amount);
    }
}
