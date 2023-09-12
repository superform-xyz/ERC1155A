/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {IERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";

interface IERC1155A is IERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Event emitted when single id approval is set
    event ApprovalForOne(address indexed owner, address indexed spender, uint256 id, uint256 amount);

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
    function increaseAllowanceForMany(address spender, uint256[] memory ids, uint256[] memory addedValues)
        external
        returns (bool);

    /// @notice Public function for decreasing multiple id approval amount at once
    /// @dev extension of single id decrease allowance
    function decreaseAllowanceForMany(address spender, uint256[] memory ids, uint256[] memory subtractedValues)
        external
        returns (bool);

    /*//////////////////////////////////////////////////////////////
                                METADATA 
    //////////////////////////////////////////////////////////////*/

    /// @dev Compute return string from baseURI set for this contract and unique vaultId
    function uri(uint256 superFormId) external view returns (string memory);

    /*//////////////////////////////////////////////////////////////
                            SUPPLY GETTERS 
    //////////////////////////////////////////////////////////////*/

    /// @notice Public getter for existing single id total supply
    function totalSupply(uint256 id) external view returns (uint256);

    /// @notice Public getter to know if a token id exists
    /// @dev determines based on total supply for the id
    function exists(uint256 id) external view returns (bool);
}
