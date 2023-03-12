/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {ERC1155} from "solmate/tokens/ERC1155.sol";
import {Strings} from "openzeppelin-contracts/utils/Strings.sol";
import "forge-std/console.sol";

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
        private allowances;

    ///////////////////////////////////////////////////////////////////////////
    ///                     ERC1155-S LOGIC SECTION                         ///
    ///////////////////////////////////////////////////////////////////////////

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual override {
        address operator = msg.sender;
        uint256 allowed = allowances[from][operator][id];

        if (operator == from) {
            _safeTransferFrom(from, to, id, amount, data);
        } else if (allowed >= amount) {
            if (isApprovedForAll[from][operator]) {
                decreaseAllowance(operator, id, amount);
            }
            _safeTransferFrom(from, to, id, amount, data);
        } else if (isApprovedForAll[from][operator]) {
            if (allowed >= amount) {
                decreaseAllowance(operator, id, amount);
            } else if (allowed < amount) {
                _resetAllowance(from, operator, id);
            }
            _safeTransferFrom(from, to, id, amount, data);
        } else {
            revert("NOT_AUTHORIZED");
        }
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) internal {
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

    /// @notice Transfer singleApproved id with this function
    /// @dev If user approvedForAll, function just executes.
    /// @dev If it's singleApproved, function executes and reduces allowance
    /// @dev If it's approvedForAll and singleApproved, function executes and reduces allowance
    /// @dev Overflow on difference between approvedForAll and singleApproved amounts is set to 0
    /// @dev Therefore, approvedForAll amount is always senior to singleApproved amount
    // function safeTransferFrom(
    //     address from,
    //     address to,
    //     uint256 id,
    //     uint256 amount,
    //     bytes calldata data
    // ) public virtual override {
    //     require(
    //         msg.sender == from ||
    //             (allowance(from, msg.sender, id) >= amount) ||
    //             isApprovedForAll[from][msg.sender],
    //         "NOT_AUTHORIZED"
    //     );

    //     uint256 allowed = allowances[from][msg.sender][id];

    //     if (isApprovedForAll[from][msg.sender] && allowed >= amount)
    //         decreaseAllowance(msg.sender, id, amount);

    //     if (!isApprovedForAll[from][msg.sender] && allowed <= amount)
    //         _resetAllowance(from, msg.sender, id);

    //     balanceOf[from][id] -= amount;
    //     balanceOf[to][id] += amount;

    //     emit TransferSingle(msg.sender, from, to, id, amount);

    //     require(
    //         to.code.length == 0
    //             ? to != address(0)
    //             : ERC1155TokenReceiver(to).onERC1155Received(
    //                 msg.sender,
    //                 from,
    //                 id,
    //                 amount,
    //                 data
    //             ) == ERC1155TokenReceiver.onERC1155Received.selector,
    //         "UNSAFE_RECIPIENT"
    //     );
    // }

    ///////////////////////////////////////////////////////////////////////////
    ///                     SIGNLE APPROVE SECTION                          ///
    ///////////////////////////////////////////////////////////////////////////

    /// NOTE: https://eips.ethereum.org/EIPS/eip-1761 (suggested by 1155) - scope-based approvals
    /// NOTE: Overwrite safeTransferFrom to not require setApprovalForAll
    /// NOTE: Add positionSplitter to this set of contracts

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
        return allowances[owner][spender][id];
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

    /// @notice Set given id allowance to 0
    /// @dev Required to coordinate allowance setting with approveAll functionality of ERC-1155
    function _resetAllowance(
        address owner,
        address spender,
        uint256 id
    ) internal virtual returns (bool) {
        _setApprovalForOne(owner, spender, id, 0);
        return true;
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
        allowances[owner][spender][id] = amount;
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
