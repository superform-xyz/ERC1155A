/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

interface IPositionsSplitter {
    /// @notice id given here needs to be the same as id on Source!
    /// @dev Make sure its set for existing ids only
    /// @dev Ideally, this should be only called by SuperPositions (or other privileged contract)
    /// @param id id of the ERC1155 to wrap
    /// @param name name of the ERC20 to create
    /// @param symbol symbol of the ERC20 to create
    /// @param decimals decimals of the ERC20 to create
    function registerWrapper(
        uint256 id,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) external returns (address);

    /// @notice Use ERC1155 BatchTransfer to wrap multiple ERC1155 ids into separate ERC20
    /// Easier to wrap than to wrapBack because of ERC1155 beauty!
    /// @param ids ids of the ERC1155s to wrap
    /// @param amounts amounts of the ERC1155s to wrap
    function wrapBatch(uint256[] memory ids, uint256[] memory amounts) external;

    /// @param id id of the ERC20s to wrap
    /// @param amount amount of the ERC20s to wrap
    function wrap(uint256 id, uint256 amount) external;

    /// @param id id of the ERC20s to unwrap
    /// @param amount amount of the ERC20s to unwrap
    function unwrap(uint256 id, uint256 amount) external;
}
