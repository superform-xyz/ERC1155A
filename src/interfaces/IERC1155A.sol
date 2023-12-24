// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IERC1155 } from "openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";

/// @title IERC1155A
/// @author Zeropoint Labs
/// @dev Single/range based id approve capability with conversion to ERC20s
interface IERC1155A is IERC1155 {

    //////////////////////////////////////////////////////////////
    //                          EVENTS                          //
    //////////////////////////////////////////////////////////////

    /// @notice event emitted when single id approval is set
    event ApprovalForOne(address indexed owner, address indexed spender, uint256 id, uint256 amount);

    /// @notice event emitted when an ERC1155A id is transmuted to an aERC20
    event TransmutedToERC20(address indexed user, uint256 id, uint256 amount);

    /// @notice event emitted when an aERC20 is transmuted to an ERC1155 id
    event TransmutedToERC1155A(address indexed user, uint256 id, uint256 amount);

    /// @notice event emitted when multiple ERC1155A ids are transmuted to aERC20s
    event TransmutedBatchToERC20(address indexed user, uint256[] ids, uint256[] amounts);

    /// @notice event emitted when multiple aERC20s are transmuted to ERC1155A ids
    event TransmutedBatchToERC1155A(address indexed user, uint256[] ids, uint256[] amounts);

    //////////////////////////////////////////////////////////////
    //                          ERRORS                          //
    //////////////////////////////////////////////////////////////

    /// @dev thrown if aERC20 was already registered
    error AERC20_ALREADY_REGISTERED();

    /// @dev thrown if aERC20 was not registered
    error AERC20_NOT_REGISTERED();

    /// @dev thrown if allowance amount will be decreased below zero
    error DECREASED_ALLOWANCE_BELOW_ZERO();

    /// @dev thrown if the associated ERC1155A id has not been minted before registering an aERC20
    error ID_NOT_MINTED_YET();

    /// @dev thrown if there is a length mismatch in batch operations
    error LENGTH_MISMATCH();

    /// @dev thrown if transfer is made to address 0
    error TRANSFER_TO_ADDRESS_ZERO();

    /// @dev thrown if address is 0
    error ZERO_ADDRESS();

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @notice Public getter for existing single id total supply
    /// @param id id of the ERC1155 
    function totalSupply(uint256 id) external view returns (uint256);

    /// @notice Public getter to know if a token id exists
    /// @dev determines based on total supply for the id
    /// @param id id of the ERC1155 
    function exists(uint256 id) external view returns (bool);

    /// @notice Public getter for existing single id approval
    /// @param owner address of the owner of the ERC1155A id
    /// @param spender address of the contract to approve
    /// @param id id of the ERC1155A to approve
    function allowance(address owner, address spender, uint256 id) external returns (uint256);

    /// @dev handy helper to check if a AERC20 is registered
    /// @param id id of the ERC1155 
    function aERC20Exists(uint256 id) external view returns (bool);

    /// @notice Public getter for the address of the aErc20 token for a given ERC1155 id
    /// @param id id of the ERC1155 to get the aErc20 token address for
    /// @return aERC20 address of the aErc20 token for the given ERC1155 id
    function getERC20TokenAddress(uint256 id) external view returns (address aERC20);

    /// @dev Compute return string from baseURI set for this contract and unique vaultId
    /// @param id id of the ERC1155 
    function uri(uint256 id) external view returns (string memory);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @notice Public function for setting single id approval
    /// @dev Notice `owner` param, it will always be msg.sender, see _setApprovalForOne()
    /// @param spender address of the contract to approve
    /// @param id id of the ERC1155A to approve
    /// @param amount amount of the ERC1155A to approve
    function setApprovalForOne(address spender, uint256 id, uint256 amount) external;

    /// @notice Public function for setting multiple id approval
    /// @dev extension of sigle id approval
    /// @param spender address of the contract to approve
    /// @param ids ids of the ERC1155A to approve
    /// @param amounts amounts of the ERC1155A to approve
    function setApprovalForMany(address spender, uint256[] memory ids, uint256[] memory amounts) external;

    /// @notice Public function for increasing single id approval amount
    /// @dev Re-adapted from ERC20
    /// @param spender address of the contract to approve
    /// @param id id of the ERC1155A to approve
    /// @param addedValue amount of the allowance to increase by 
    function increaseAllowance(address spender, uint256 id, uint256 addedValue) external returns (bool);

    /// @notice Public function for decreasing single id approval amount
    /// @dev Re-adapted from ERC20
    /// @param spender address of the contract to approve
    /// @param id id of the ERC1155A to approve
    /// @param subtractedValue amount of the allowance to decrease by 
    function decreaseAllowance(address spender, uint256 id, uint256 subtractedValue) external returns (bool);

    /// @notice Public function for increasing multiple id approval amount at once
    /// @dev extension of single id increase allowance
    /// @param spender address of the contract to approve
    /// @param ids ids of the ERC1155A to approve
    /// @param addedValues amounts of the allowance to increase by 
    function increaseAllowanceForMany(
        address spender,
        uint256[] memory ids,
        uint256[] memory addedValues
    )
        external
        returns (bool);

    /// @notice Public function for decreasing multiple id approval amount at once
    /// @dev extension of single id decrease allowance
    /// @param spender address of the contract to approve
    /// @param ids ids of the ERC1155A to approve
    /// @param subtractedValues amounts of the allowance to decrease by 
    function decreaseAllowanceForMany(
        address spender,
        uint256[] memory ids,
        uint256[] memory subtractedValues
    )
        external
        returns (bool);

    /// @param onBehalfOf address of the user on whose behalf this transmutation is happening
    /// @param id id of the ERC20s to transmute to aErc20
    /// @param amount amount of the ERC20s to transmute to aErc20
    function transmuteToERC20(address onBehalfOf, uint256 id, uint256 amount) external;

    /// @param onBehalfOf address of the user on whose behalf this transmutation is happening
    /// @param id id of the ERC20s to transmute to erc1155
    /// @param amount amount of the ERC20s to transmute to erc1155
    function transmuteToERC1155A(address onBehalfOf, uint256 id, uint256 amount) external;

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

    /// @notice payable to allow any implementing cross-chain protocol to be paid for fees for relaying this action to
    /// various chain
    /// @dev should emit any required events inside _registerAERC20 internal function
    /// @param id of the ERC1155 to create a ERC20 for
    function registerAERC20(uint256 id) external payable returns (address);
}
