/// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

interface ITransmuter {
    /// @notice id given here needs to be the same as id on Source!
    /// @dev Make sure its set for existing ids only
    /// @dev Function set to virtual so that implementing protocols may introduce RBAC here or perform other changes
    /// @param id id of the ERC1155 to wrap
    /// @param name name of the ERC20 to create
    /// @param symbol symbol of the ERC20 to create
    /// @param decimals decimals of the ERC20 to create
    function registerTransmuter(
        uint256 id,
        string memory name,
        string memory symbol,
        uint8 decimals
    )
        external
        returns (address);

    /// @notice Use ERC1155 BatchTransfer to transmute multiple ERC1155 ids into separate ERC20
    /// Easier to transmute to 1155A than to transmute back to erc20 because of ERC1155 beauty!
    /// @param ids ids of the ERC1155A to transmute
    /// @param amounts amounts of the ERC1155A to transmute
    function transmuteBatchToERC20(uint256[] memory ids, uint256[] memory amounts) external;

    /// @param id id of the ERC20s to transmute to erc20
    /// @param amount amount of the ERC20s to transmute to erc20
    function transmuteToERC20(uint256 id, uint256 amount) external;

    /// @param id id of the ERC20s to transmute to erc1155
    /// @param amount amount of the ERC20s to transmute to erc1155
    function transmuteToERC1155A(uint256 id, uint256 amount) external;
}
