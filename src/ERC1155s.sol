/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {ERC1155} from "solmate/tokens/ERC1155.sol";


/// @title ERC-1155S is a SuperForm specific extension for ERC1155.
/// 1. Single id approve capability
///     - Set approve for single id for specified amount
///     - Use safeTransferFrom() for regular allApproved ids
///     - Use _safeTransferFrom() for extended singleApproved id
/// Using standard ERC1155 setApprovalForAll overrides setApprovalForOne
/// 2. Metadata build out of baseURI and vaultId uint value into https address
abstract contract ERC1155s is ERC1155 {
    event ApprovalForOne(
        address indexed owner,
        address indexed operator,
        uint256 id,
        uint256 amount
    );

    /// @notice Mapping for single approved ids
    /// @dev owner => operator => id => amount
    mapping(address => mapping(address => mapping(uint256 => uint256)))
        public allowance;

    /// @notice Approve specified id for arbitrary amount of tokens
    /// @dev will work only with _safeTransferFrom()
    function setApprovalForOne(
        address operator,
        uint256 id,
        uint256 amount
    ) public virtual {
        allowance[msg.sender][operator][id] = amount;

        emit ApprovalForOne(msg.sender, operator, id, amount);
    }

    /// @notice Transfer singleApproved id with this function
    /// This function will only accept single-approved Ids and fail for everything else
    /// Caller is expected to know which function to call, worse that can happen is revert
    /// BatchTransfer should still operate only with ApproveForAll
    /// Checking for set of approvals makes intended use of batch transfer pointless
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(
            msg.sender == from || allowance[from][msg.sender][id] >= amount,
            "NOT_AUTHORIZED"
        );
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

    ///////////////////////////////////////////////////////////////////////////
    ///                        METADATA SECTION                             ///
    ///////////////////////////////////////////////////////////////////////////

    /// @dev See {IERC721Metadata-tokenURI}.
    /// compute return string from baseURI set for this contract and unique vaultId
    function uri(uint256 vaultId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return string(abi.encodePacked(_baseURI(), toString(vaultId)));
    }

    /// @dev used to construct return url
    /// NOTE: add setter?
    function _baseURI() internal pure returns (string memory) {
        return "https://api.superform.xyz/superposition/";
    }

    /// Inspired by OraclizeAPI's implementation - MIT licence
    /// https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
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
