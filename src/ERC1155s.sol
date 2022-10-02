// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {ERC1155} from "solmate/tokens/ERC1155.sol";

abstract contract ERC1155s is ERC1155 {
    mapping(address => mapping(address => mapping(uint256 => uint256)))
        public allowance;

    function setApprovalForOne(
        address operator,
        uint256 id,
        uint256 amount
    ) public virtual {
        allowance[msg.sender][operator][id] = amount;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual override {
        if (msg.sender == from || isApprovedForAll[from][msg.sender]) {
            _safeTransferFrom(from, to, id, amount, data);
        } else if (
            msg.sender == from || allowance[from][msg.sender][id] >= amount
        ) {
            _safeTransferFrom(from, to, id, amount, data);
        }
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) internal virtual {
        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(
                    msg.sender,
                    from,
                    id,
                    amount,
                    data
                ) == ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /// @notice BatchTransfer should still operate only with ApproveForAll
    /// Checking for set of approvals makes intended use of batch transfer pointless
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}
