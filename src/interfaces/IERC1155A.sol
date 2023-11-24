// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IERC1155 } from "openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";

interface IERC1155A is IERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Event emitted when single id approval is set
    event ApprovalForOne(address indexed owner, address indexed spender, uint256 id, uint256 amount);
    event TransmutedBatchToERC20(address user, uint256[] ids, uint256[] amounts);
    event TransmutedBatchToERC1155A(address user, uint256[] ids, uint256[] amounts);
    event TransmutedToERC20(address user, uint256 id, uint256 amount);
    event TransmutedToERC1155A(address user, uint256 id, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    /// @dev for batch operations, if there is a length mismatch
    error LENGTH_MISMATCH();

    /// @dev operator is not an owner of ids or not enough of allowance, or is not approvedForAll
    error NOT_AUTHORIZED();

    /// @dev if allowance is lower than amount for the operation
    error NOT_ENOUGH_ALLOWANCE();

    /// @dev Thrown when AERC20 was already registered
    error AERC20_ALREADY_REGISTERED();

    /// @dev Thrown when AERC20 was not registered
    error AERC20_NOT_REGISTERED();

    /// @dev allowance amount cannot be decreased below zero
    error DECREASED_ALLOWANCE_BELOW_ZERO();

    /// @dev address is 0
    error ZERO_ADDRESS();

    /// @dev forbids transfers to address 0
    error TRANSFER_TO_ADDRESS_ZERO();

    /// @dev forbids registering a saErc20 if no associated erc1155a has been minted yet first
    error ID_NOT_MINTED_YET();
    /*//////////////////////////////////////////////////////////////
                              SINGLE APPROVE
    //////////////////////////////////////////////////////////////*/

    /// @notice Public function for setting single id approval
    /// @dev Notice `owner` param, it will always be msg.sender, see _setApprovalForOne()
    function setApprovalForOne(address spender, uint256 id, uint256 amount) external;

    /// @notice Public getter for existing single id approval
    /// @dev Re-adapted from ERC20
    function allowance(address owner, address spender, uint256 id) external returns (uint256);

    /// @notice Public function for increasing single id approval amount
    /// @dev Re-adapted from ERC20
    function increaseAllowance(address spender, uint256 id, uint256 addedValue) external returns (bool);

    /// @notice Public function for decreasing single id approval amount
    /// @dev Re-adapted from ERC20
    function decreaseAllowance(address spender, uint256 id, uint256 subtractedValue) external returns (bool);

    /*//////////////////////////////////////////////////////////////
                              MULTI APPROVE
    //////////////////////////////////////////////////////////////*/

    /// @notice Public function for setting multiple id approval
    /// @dev extension of sigle id approval
    function setApprovalForMany(address spender, uint256[] memory ids, uint256[] memory amounts) external;

    /// @notice Public function for increasing multiple id approval amount at once
    /// @dev extension of single id increase allowance
    function increaseAllowanceForMany(
        address spender,
        uint256[] memory ids,
        uint256[] memory addedValues
    )
        external
        returns (bool);

    /// @notice Public function for decreasing multiple id approval amount at once
    /// @dev extension of single id decrease allowance
    function decreaseAllowanceForMany(
        address spender,
        uint256[] memory ids,
        uint256[] memory subtractedValues
    )
        external
        returns (bool);

    /*//////////////////////////////////////////////////////////////
                    AERC20 AND TRANSMUTE LOGIC 
    //////////////////////////////////////////////////////////////*/

    /// @dev Function set to virtual so that implementing protocols may introduce RBAC here or perform other changes
    /// @notice payable to allow any implementing cross-chain protocol to be paid for fees for relaying this action to
    /// various chain
    /// @param id of the ERC1155 to create a ERC20 for
    function registerAERC20(uint256 id) external payable returns (address);

    /// @notice Use transmuteBatchToERC20 to transmute multiple ERC1155 ids into separate ERC20
    /// Easier to transmute to 1155A than to transmute back to aErc20 because of ERC1155 beauty!
    /// @param onBehalfOf address of the user on whose behalf this transmutation is happening
    /// @param ids ids of the ERC1155A to transmute
    /// @param amounts amounts of the ERC1155A to transmute
    function transmuteBatchToERC20(address onBehalfOf, uint256[] memory ids, uint256[] memory amounts) external;

    /// @notice Use transmuteBatchToERC1155A to transmute multiple ERC20 ids into separate ERC1155
    /// @param onBehalfOf address of the user on whose behalf this transmutation is happening
    /// @param ids ids of the ERC20 to transmute
    /// @param amounts amounts of the ERC20 to transmute
    function transmuteBatchToERC1155A(address onBehalfOf, uint256[] memory ids, uint256[] memory amounts) external;

    /// @param onBehalfOf address of the user on whose behalf this transmutation is happening
    /// @param id id of the ERC20s to transmute to aErc20
    /// @param amount amount of the ERC20s to transmute to aErc20
    function transmuteToERC20(address onBehalfOf, uint256 id, uint256 amount) external;

    /// @param onBehalfOf address of the user on whose behalf this transmutation is happening
    /// @param id id of the ERC20s to transmute to erc1155
    /// @param amount amount of the ERC20s to transmute to erc1155
    function transmuteToERC1155A(address onBehalfOf, uint256 id, uint256 amount) external;

    /// @notice Public getter for the address of the aErc20 token for a given ERC1155 id
    /// @param id id of the ERC1155 to get the aErc20 token address for
    /// @return aERC20 address of the aErc20 token for the given ERC1155 id
    function getERC20TokenAddress(uint256 id) external view returns (address aERC20);

    /*//////////////////////////////////////////////////////////////
                                METADATA 
    //////////////////////////////////////////////////////////////*/

    /// @dev Compute return string from baseURI set for this contract and unique vaultId
    function uri(uint256 id) external view returns (string memory);

    /*//////////////////////////////////////////////////////////////
                            SUPPLY GETTERS 
    //////////////////////////////////////////////////////////////*/

    /// @notice Public getter for existing single id total supply
    function totalSupply(uint256 id) external view returns (uint256);

    /// @notice Public getter to know if a token id exists
    /// @dev determines based on total supply for the id
    function exists(uint256 id) external view returns (bool);

    /// @dev handy helper to check if a AERC20 is registered
    /// @param id of the ERC1155 to check if a AERC20 exists for
    function aERC20Exists(uint256 id) external view returns (bool);
}
