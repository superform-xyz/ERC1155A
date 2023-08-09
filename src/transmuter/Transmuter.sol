/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {IERC1155s} from "../interfaces/IERC1155s.sol";
import {sERC20} from "./sERC20.sol";
import {ITransmuter} from "../interfaces/ITransmuter.sol";

/// @title Transmuter
/// @author Zeropoint Labs.
/// @dev allows users to transmute all or individual ids of ERC1155s into synthetic ERC20s
contract Transmuter is ITransmuter {
    IERC1155s public immutable sERC1155;

    event TransmutedToERC20(address user, uint256 id, uint256 amount);
    event TransmutedBatchToERC20(address user, uint256[] ids, uint256[] amounts);
    event TransmutedToERC1155s(address user, uint256 id, uint256 amount);

    error TRANSMUTER_ALREADY_REGISTERED();

    mapping(uint256 id => address syntheticToken) public synthethicTokenId;

    constructor(IERC1155s erc1155s) {
        sERC1155 = erc1155s;
    }

    /// @inheritdoc ITransmuter
    function registerTransmuter(
        uint256 id,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) external override returns (address) {
        if (synthethicTokenId[id] != address(0)) revert TRANSMUTER_ALREADY_REGISTERED();

        address syntheticToken = address(new sERC20(name, symbol, decimals));
        synthethicTokenId[id] = syntheticToken;
        /// @dev convienience for testing, prob no reason to return interface here
        return synthethicTokenId[id];
    }

    /*///////////////////////////////////////////////////////////////
                            MULTIPLE ID OPERATIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ITransmuter
    function transmuteBatchToERC20(uint256[] memory ids, uint256[] memory amounts) external override {
        /// @dev Use ERC1155 BatchTransfer to lower costs
        sERC1155.safeBatchTransferFrom(msg.sender, address(this), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            sERC20(synthethicTokenId[ids[i]]).mint(msg.sender, amounts[i]);
        }

        emit TransmutedBatchToERC20(msg.sender, ids, amounts);
    }

    /// @notice We are not supporting transmuteBatchToERC1155 with multiple ERC20 at once.
    /// Note: Its problematic to do so as ERC20 do not support batch ops (in contrary to ERC1155)
    /// Requires unbouded for loop and within it each allowance check needs to pass
    /// otherwise, we risk failing in the middle of transaction.

    /*///////////////////////////////////////////////////////////////
                            SINGLE ID OPERATIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ITransmuter
    function transmuteToERC20(uint256 id, uint256 amount) external override {
        /// @dev singleId approval required for this call to succeed
        /// Note: User needs to approve Transmuter first
        sERC1155.safeTransferFrom(msg.sender, address(this), id, amount, "");

        sERC20(synthethicTokenId[id]).mint(msg.sender, amount);
        emit TransmutedToERC20(msg.sender, id, amount);
    }

    /// @inheritdoc ITransmuter
    function transmuteToERC1155s(uint256 id, uint256 amount) external override {
        sERC20 token = sERC20(synthethicTokenId[id]);

        /// @dev No need to transfer to contract, we can burn for msg.sender
        token.burn(msg.sender, amount);

        /// @dev Hack to help with contract size limit on Source
        uint256[] memory ids = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);
        ids[0] = id;
        amounts[0] = amount;

        sERC1155.safeBatchTransferFrom(address(this), msg.sender, ids, amounts, bytes(""));

        emit TransmutedToERC1155s(msg.sender, id, amount);
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
