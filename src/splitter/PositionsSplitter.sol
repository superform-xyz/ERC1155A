/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {IERC1155s} from "../interfaces/IERC1155s.sol";
import {sERC20} from "./sERC20.sol";

/// @title Positions Splitter
/// @author Zeropoint Labs.
/// @dev allows users to split all or individual ids of ERC1155s into ERC20
abstract contract PositionsSplitter {
    IERC1155s public sERC1155;
    uint256 public syntheticTokenID;

    event Wrapped(address user, uint256 id, uint256 amount);
    event WrappedBatch(address user, uint256[] ids, uint256[] amounts);
    event Unwrapped(address user, uint256 id, uint256 amount);
    event UnwrappedBatch(address user, uint256[] ids, uint256[] amounts);

    /// @dev SuperRouter synthethic underlying ERC1155 id => wrapped ERC20
    /// @dev id => wrappedERC1155idERC20
    mapping(uint256 id => sERC20) public synthethicTokenId;

    /// @dev Access Control should be re-thinked
    constructor(IERC1155s superFormLp) {
        sERC1155 = superFormLp;
    }

    /// @notice superFormId given here needs to be the same as superFormId on Source!
    /// @dev Make sure its set for existing ids only
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
    function wrapBatch(uint256[] memory ids, uint256[] memory amounts) external virtual {
        /// @dev Use ERC1155 BatchTransfer to lower costs
        sERC1155.safeBatchTransferFrom(msg.sender, address(this), ids, amounts, "");

        // Note: Hook to SuperRouter, optional if we want to do something there
        // Note: Maybe relevant in future for omnichain-token
        // sERC1155.unwrap(msg.sender, ids, amounts);

        for (uint256 i = 0; i < ids.length; i++) {
            synthethicTokenId[ids[i]].mint(msg.sender, amounts[i]);
        }

        emit WrappedBatch(msg.sender, ids, amounts);
    }

    /// @notice We are not supporting wrapBack to ERC1155 with multiple ERC20 at once.
    /// Note: Its problematic to do so as ERC20 do not support batch ops (in contrary to ERC1155)
    /// Requires unbouded for loop and within it each allowance check needs to pass
    /// otherwise, we risk failing in the middle of transaction.

    /*///////////////////////////////////////////////////////////////
                            SINGLE ID OPERATIONS
    //////////////////////////////////////////////////////////////*/

    /// ERC20.transfer()
    function wrap(uint256 id, uint256 amount) external virtual {
        /// @dev singleId approval required for this call to succeed
        /// Note: User needs to approve SharesSplitter first
        sERC1155.safeTransferFrom(msg.sender, address(this), id, amount, "");

        // Note: Hook to SuperRouter, optional if we want to do something there
        // Note: Maybe relevant in future for omnichain-token
        // sERC1155.unwrap(msg.sender, id, amount);

        synthethicTokenId[id].mint(msg.sender, amount);
        emit Wrapped(msg.sender, id, amount);
    }

    /// @dev Callback to SuperRouter from here to re-mint ERC1155 on SuperRouter
    function unwrap(uint256 id, uint256 amount) external virtual {
        sERC20 token = synthethicTokenId[id];

        /// TODO: Test and validate
        /// @dev No need to transfer to contract, we can burn for msg.sender
        token.burn(msg.sender, amount);

        /// @dev Hack to help with contract size limit on Source
        uint256[] memory ids = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);
        ids[0] = id;
        amounts[0] = amount;

        sERC1155.safeBatchTransferFrom(address(this), msg.sender, ids, amounts, bytes(""));

        emit Unwrapped(msg.sender, id, amount);
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
