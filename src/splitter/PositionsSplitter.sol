/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import "../IERC1155s.sol";
import {sERC20} from "./sERC20.sol";

/// @title Positions Splitter | WIP / EXPERIMENTAL
/// @dev allows users to split all or individual vaultIds of SuperFormERC1155 into ERC20
abstract contract PositionsSplitter {
    
    IERC1155s public sERC1155;
    uint256 public syntheticTokenID;

    event Wrapped(address user, uint256 id, uint256 amount);
    event WrappedBatch(address user, uint256[] ids, uint256[] amounts);
    event Unwrapped(address user, uint256 id, uint256 amount);
    event UnwrappedBatch(address user, uint256[] ids, uint256[] amounts);

    /// @dev SuperRouter synthethic underlying ERC1155 vaultId => wrapped ERC20
    /// @dev vaultId => wrappedERC1155idERC20
    mapping(uint256 vaultId => sERC20) public synthethicTokenId;


    /// @dev Access Control should be re-thinked
    constructor(IERC1155s superFormLp) {
        sERC1155 = superFormLp;
    }

    /// @notice superFormId given here needs to be the same as superFormId on Source!
    /// @dev Make sure its set for existing vaultIds only
    /// @dev Ideally, this should be only called by SuperPositions (or other privileged contract)
    function registerWrapper(
        uint256 superFormId,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) external virtual returns (sERC20) {
        synthethicTokenId[superFormId] = new sERC20(name, symbol, decimals);
        /// @dev convienience for testing, prob no reason to return interface here
        return synthethicTokenId[superFormId];
    }

    /*///////////////////////////////////////////////////////////////
                            MULTIPLE ID OPERATIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Use ERC1155 BatchTransfer to wrap multiple ERC1155 ids into separate ERC20
    /// Easier to wrap than to wrapBack because of ERC1155 beauty!
    function wrapBatch(
        uint256[] memory vaultIds,
        uint256[] memory amounts
    ) external virtual {

        /// @dev Use ERC1155 BatchTransfer to lower costs
        sERC1155.safeBatchTransferFrom(
            msg.sender,
            address(this),
            vaultIds,
            amounts,
            ""
        );

        // Note: Hook to SuperRouter, optional if we want to do something there
        // Note: Maybe relevant in future for omnichain-token
        // sERC1155.unwrap(msg.sender, vaultIds, amounts);

        for (uint256 i = 0; i < vaultIds.length; i++) {
            synthethicTokenId[vaultIds[i]].mint(msg.sender, amounts[i]);
        }

        emit WrappedBatch(msg.sender, vaultIds, amounts);
    }

    /// @notice We are not supporting wrapBack to ERC1155 with multiple ERC20 at once.
    /// Note: Its problematic to do so as ERC20 do not support batch ops (in contrary to ERC1155)
    /// Requires unbouded for loop and within it each allowance check needs to pass
    /// otherwise, we risk failing in the middle of transaction.

    /*///////////////////////////////////////////////////////////////
                            SINGLE ID OPERATIONS
    //////////////////////////////////////////////////////////////*/

    /// ERC20.transfer()
    function wrap(uint256 vaultId, uint256 amount) external virtual {
        /// @dev singleId approval required for this call to succeed
        /// Note: User needs to approve SharesSplitter first
        sERC1155.safeTransferFrom(
            msg.sender,
            address(this),
            vaultId,
            amount,
            ""
        );

        // Note: Hook to SuperRouter, optional if we want to do something there
        // Note: Maybe relevant in future for omnichain-token
        // sERC1155.unwrap(msg.sender, vaultId, amount);

        synthethicTokenId[vaultId].mint(msg.sender, amount);
        emit Wrapped(msg.sender, vaultId, amount);
    }


    /// @dev Callback to SuperRouter from here to re-mint ERC1155 on SuperRouter
    function unwrap(uint256 vaultId, uint256 amount) external virtual {
        sERC20 token = synthethicTokenId[vaultId];

        /// TODO: Test and validate
        /// @dev No need to transfer to contract, we can burn for msg.sender
        token.burn(msg.sender, amount);

        /// @dev Hack to help with contract size limit on Source
        uint256[] memory vaultIds = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);
        vaultIds[0] = vaultId;
        amounts[0] = amount;

        sERC1155.safeBatchTransferFrom(
            address(this),
            msg.sender,
            vaultIds,
            amounts,
            bytes("")
        );

        emit Unwrapped(msg.sender, vaultId, amount);
    }

    /*///////////////////////////////////////////////////////////////
                            ERC1155 HOOKS
    //////////////////////////////////////////////////////////////*/

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}
