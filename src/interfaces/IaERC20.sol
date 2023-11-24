// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/// @title aERC20
/// @author Zeropoint Labs.
/// @dev ERC20 tokens out of 1155a
interface IaERC20 is IERC20 {
    /// @dev allows msg.sender set in constructor to mint
    /// @param owner address of the owner of the tokens
    /// @param amount amount of tokens to mint
    function mint(address owner, uint256 amount) external;

    /// @dev allows msg.sender set in constructor to burn
    /// @param owner address of the owner of the tokens
    /// @param operator address of the operator of the tokens
    function burn(address owner, address operator, uint256 amount) external;
}
