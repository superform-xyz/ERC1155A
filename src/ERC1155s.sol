/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {ERC1155} from "solmate/tokens/ERC1155.sol";
import {Strings} from "openzeppelin-contracts/utils/Strings.sol";

/**
 * @title ERC1155S
 * @dev ERC1155S is a SuperForm specific extension for ERC1155.
 * 1. Single id approve capability
 *    - Set approve for single id for specified amount
 *    - Use safeTransferFrom() for regular allApproved ids
 *    - Use _safeTransferFrom() for extended singleApproved id
 * Using standard ERC1155 setApprovalForAll overrides setApprovalForOne
 * 2. Metadata build out of baseURI and vaultId uint value into https address
 */

abstract contract ERC1155s is ERC1155 {
    /// @notice Event emitted when single id approval is set
    event ApprovalForOne(
        address indexed owner,
        address indexed spender,
        uint256 id,
        uint256 amount
    );

    /// @notice ERC20-like mapping for single id approvals
    mapping(address owner => mapping(address spender => mapping(uint256 id => uint256 amount)))
        private _allowances;

    ///////////////////////////////////////////////////////////////////////////
    ///                     SIGNLE APPROVE SECTION                          ///
    ///////////////////////////////////////////////////////////////////////////

    /// @notice Public function for setting single id approval
    /// @dev Works only with _safeTransferFrom() function
    function setApprovalForOne(
        address spender,
        uint256 id,
        uint256 amount
    ) public virtual {
        address owner = msg.sender;
        _setApprovalForOne(owner, spender, id, amount);
    }

    /// @notice Public getter for existing single id approval
    /// @dev Re-adapted from ERC20
    function allowance(
        address owner,
        address spender,
        uint256 id
    ) public view virtual returns (uint256) {
        return _allowances[owner][spender][id];
    }

    /// @notice Public function for increasing single id approval amount
    /// @dev Re-adapted from ERC20
    function increaseAllowance(
        address spender,
        uint256 id,
        uint256 addedValue
    ) public virtual returns (bool) {
        address owner = msg.sender;
        _setApprovalForOne(
            owner,
            spender,
            id,
            allowance(owner, spender, id) + addedValue
        );
        return true;
    }

    /// @notice Public function for decreasing single id approval amount
    /// @dev Re-adapted from ERC20
    function decreaseAllowance(
        address spender,
        uint256 id,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        address owner = msg.sender;
        uint256 currentAllowance = allowance(owner, spender, id);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _setApprovalForOne(
                owner,
                spender,
                id,
                currentAllowance - subtractedValue
            );
        }

        return true;
    }

    /// @notice Transfer singleApproved id with this function
    /// @dev This function will only accept single-approved Ids and fail for everything else
    /// @dev Caller is expected to know which function to call, worse that can happen is revert
    /// @dev BatchTransfer should still operate only with ApproveForAll
    /// @dev Checking for set of approvals makes intended use of batch transfer pointless
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(
            msg.sender == from || _allowances[from][msg.sender][id] >= amount,
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

    /// @notice Internal function for setting single id approval
    /// @dev Used for fine-grained control over approvals with increase/decrease allowance
    function _setApprovalForOne(
        address owner,
        address spender,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender][id] = amount;
        emit ApprovalForOne(owner, spender, id, amount);
    }

    ///////////////////////////////////////////////////////////////////////////
    ///                        METADATA SECTION                             ///
    ///////////////////////////////////////////////////////////////////////////

    /// @notice See {IERC721Metadata-tokenURI}.
    /// @dev Compute return string from baseURI set for this contract and unique vaultId
    function uri(
        uint256 superFormId
    ) public view virtual override returns (string memory) {
        return
            string(abi.encodePacked(_baseURI(), Strings.toString(superFormId)));
    }

    /// @notice Used to construct return url
    /// NOTE: add setter?
    function _baseURI() internal pure returns (string memory) {
        return "https://api.superform.xyz/superposition/";
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
