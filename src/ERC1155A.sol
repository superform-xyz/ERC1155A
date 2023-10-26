/// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import { IERC1155A } from "./interfaces/IERC1155A.sol";
import { Strings } from "openzeppelin-contracts/contracts/utils/Strings.sol";
import { sERC20 } from "./sERC20.sol";

/**
 * @title ERC1155A
 * @dev ERC1155A is a proposed extension for ERC1155.
 * @dev Adapted solmate implementation, follows ERC1155 standard interface
 *
 * 1. Single id approve capability
 * 2. Allowance management for single id approve
 * 3. Metadata build out of baseURI and id uint value into offchain metadata address
 *
 */
abstract contract ERC1155A is IERC1155A {
    /*//////////////////////////////////////////////////////////////
                             ERC1155a STORAGE
    //////////////////////////////////////////////////////////////*/
    /// @notice ERC20-like mapping for single id supply.
    mapping(uint256 => uint256) public _totalSupply;

    /// @notice ERC20-like mapping for single id approvals.
    mapping(address owner => mapping(address spender => mapping(uint256 id => uint256 amount))) private allowances;

    /// @dev Implementation copied from solmate/ERC1155
    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    /// @dev Implementation copied from solmate/ERC1155
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /// @dev mapping of token ids to synthetic token addresses
    mapping(uint256 id => address syntheticToken) public synthethicTokenId;

    ///////////////////////////////////////////////////////////////////////////
    ///                     ERC1155-A LOGIC SECTION                         ///
    ///////////////////////////////////////////////////////////////////////////

    /// @notice Transfer singleApproved id with this function
    /// @dev If caller is owner of ids, transfer just executes.
    /// @dev If caller singleApproved > transferAmount, function executes and reduces allowance (even if
    /// setApproveForAll is true)
    /// @dev If caller singleApproved < transferAmount && isApprovedForAll, function executes without reducing allowance
    /// (full trust assumed)
    /// @dev If caller only approvedForAll, function executes without reducing allowance (full trust assumed)
    /// @dev SingleApprove is senior in execution flow, but isApprovedForAll is senior in allowance management
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    )
        public
        virtual
        override
    {
        address operator = msg.sender;
        uint256 allowed = allowances[from][operator][id];

        /// NOTE: This function order makes it more costly to use isApprovedForAll but cheaper to user single approval
        /// and owner transfer

        /// @dev operator is an owner of ids
        if (operator == from) {
            /// @dev no need to self-approve
            /// @dev make transfer
            _safeTransferFrom(operator, from, to, id, amount, data);

            /// @dev operator allowance is higher than requested amount
        } else if (allowed >= amount) {
            /// @dev decrease allowance
            _decreaseAllowance(from, operator, id, amount);
            /// @dev make transfer
            _safeTransferFrom(operator, from, to, id, amount, data);

            /// @dev operator is approved for all tokens
        } else if (isApprovedForAll[from][operator]) {
            /// NOTE: We don't decrease individual allowance here.
            /// NOTE: Spender effectively has unlimited allowance because of isApprovedForAll
            /// NOTE: We leave allowance management to token owners

            /// @dev make transfer
            _safeTransferFrom(operator, from, to, id, amount, data);

            /// @dev operator is not an owner of ids or not enough of allowance, or is not approvedForAll
        } else {
            revert("NOT_AUTHORIZED");
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @dev Implementation copied from solmate/ERC1155
    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @dev Implementation copied from solmate/ERC1155
    /// @dev Ignores single id approvals. Works only with setApprovalForAll.
    /// @dev Assumption is that BatchTransfers are supposed to be gas-efficient
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    )
        public
        virtual
        override
    {
        bool singleApproval;
        uint256 len = ids.length;

        require(len == amounts.length, "LENGTH_MISMATCH");

        /// @dev case to handle single id / multi id approvals
        if (msg.sender != from && !isApprovedForAll[from][msg.sender]) {
            singleApproval = true;
        }

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i; i < len;) {
            id = ids[i];
            amount = amounts[i];

            if (singleApproval) {
                require(allowance(from, msg.sender, id) >= amount, "NOT_AUTHORIZED");
                allowances[from][to][id] -= amount;
            }

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data)
                    == ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /// @dev Implementation copied from solmate/ERC1155
    function balanceOfBatch(
        address[] calldata owners,
        uint256[] calldata ids
    )
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    ///////////////////////////////////////////////////////////////////////////
    ///                     SIGNLE APPROVE SECTION                          ///
    ///////////////////////////////////////////////////////////////////////////

    /// inheritdoc IERC1155A
    function setApprovalForOne(address spender, uint256 id, uint256 amount) public virtual {
        address owner = msg.sender;
        _setApprovalForOne(owner, spender, id, amount);
    }

    /// inheritdoc IERC1155A
    function allowance(address owner, address spender, uint256 id) public view virtual returns (uint256) {
        return allowances[owner][spender][id];
    }

    /// inheritdoc IERC1155A
    function increaseAllowance(address spender, uint256 id, uint256 addedValue) public virtual returns (bool) {
        address owner = msg.sender;
        unchecked {
            _setApprovalForOne(owner, spender, id, allowance(owner, spender, id) + addedValue);
        }
        return true;
    }

    /// inheritdoc IERC1155A
    function decreaseAllowance(address spender, uint256 id, uint256 subtractedValue) public virtual returns (bool) {
        address owner = msg.sender;
        return _decreaseAllowance(owner, spender, id, subtractedValue);
    }

    ///////////////////////////////////////////////////////////////////////////
    ///                     MULTI APPROVE SECTION                           ///
    ///////////////////////////////////////////////////////////////////////////

    /// inheritdoc IERC1155A
    function setApprovalForMany(address spender, uint256[] memory ids, uint256[] memory amounts) public virtual {
        address owner = msg.sender;

        for (uint256 i; i < ids.length;) {
            _setApprovalForOne(owner, spender, ids[i], amounts[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// inheritdoc IERC1155A
    function increaseAllowanceForMany(
        address spender,
        uint256[] memory ids,
        uint256[] memory addedValues
    )
        public
        virtual
        returns (bool)
    {
        address owner = msg.sender;
        uint256 id;
        for (uint256 i; i < ids.length;) {
            id = ids[i];
            unchecked {
                _setApprovalForOne(owner, spender, id, allowance(owner, spender, id) + addedValues[i]);
                ++i;
            }
        }

        return true;
    }

    /// inheritdoc IERC1155A
    function decreaseAllowanceForMany(
        address spender,
        uint256[] memory ids,
        uint256[] memory subtractedValues
    )
        public
        virtual
        returns (bool)
    {
        address owner = msg.sender;

        for (uint256 i; i < ids.length;) {
            _decreaseAllowance(owner, spender, ids[i], subtractedValues[i]);

            unchecked {
                ++i;
            }
        }

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                    SERC20 AND TRANSMUTE LOGIC 
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IERC1155A
    function registerSERC20(
        uint256 id,
        string memory name,
        string memory symbol
    )
        external
        virtual
        override
        returns (address)
    {
        if (synthethicTokenId[id] != address(0)) revert SYNTHETIC_ERC20_ALREADY_REGISTERED();

        address syntheticToken = address(new sERC20(name, symbol));
        synthethicTokenId[id] = syntheticToken;

        return synthethicTokenId[id];
    }

    /// @inheritdoc IERC1155A
    function transmuteBatchToERC20(
        address onBehalfOf,
        uint256[] memory ids,
        uint256[] memory amounts
    )
        external
        override
    {
        /// @dev an approval is needed to burn
        _batchBurn(onBehalfOf, ids, amounts);

        for (uint256 i = 0; i < ids.length;) {
            sERC20(synthethicTokenId[ids[i]]).mint(onBehalfOf, amounts[i]);
            unchecked {
                ++i;
            }
        }

        emit TransmutedBatchToERC20(onBehalfOf, ids, amounts);
    }

    /// @inheritdoc IERC1155A
    function transmuteBatchToERC1155A(
        address onBehalfOf,
        uint256[] memory ids,
        uint256[] memory amounts
    )
        external
        override
    {
        for (uint256 i = 0; i < ids.length;) {
            /// @dev an approval is needed on each sERC20 to burn
            sERC20(synthethicTokenId[ids[i]]).burn(onBehalfOf, msg.sender, amounts[i]);
            unchecked {
                ++i;
            }
        }

        _batchMint(onBehalfOf, ids, amounts, bytes(""));

        emit TransmutedBatchToERC1155A(onBehalfOf, ids, amounts);
    }

    /// @inheritdoc IERC1155A
    function transmuteToERC20(address onBehalfOf, uint256 id, uint256 amount) external override {
        /// @dev an approval is needed to burn
        _burn(onBehalfOf, id, amount);

        sERC20(synthethicTokenId[id]).mint(onBehalfOf, amount);
        emit TransmutedToERC20(onBehalfOf, id, amount);
    }

    /// @inheritdoc IERC1155A
    function transmuteToERC1155A(address onBehalfOf, uint256 id, uint256 amount) external override {
        /// @dev an approval is needed to burn
        sERC20(synthethicTokenId[id]).burn(onBehalfOf, msg.sender, amount);

        _mint(onBehalfOf, id, amount, bytes(""));

        emit TransmutedToERC1155A(onBehalfOf, id, amount);
    }

    ///////////////////////////////////////////////////////////////////////////
    ///                        METADATA SECTION                             ///
    ///////////////////////////////////////////////////////////////////////////

    /// @notice See {IERC721Metadata-tokenURI}.
    /// @dev Compute return string from baseURI set for this contract and unique id
    function uri(uint256 id) public view virtual returns (string memory) {
        return string(abi.encodePacked(_baseURI(), Strings.toString(id)));
    }

    ///////////////////////////////////////////////////////////////////////////
    ///                        SUPPLY GETTERS                               ///
    ///////////////////////////////////////////////////////////////////////////

    /// @notice See {IERC1155A-totalSupply}
    function totalSupply(uint256 id) external view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /// @notice See {IERC1155A-exists}
    function exists(uint256 id) external view virtual returns (bool) {
        return _totalSupply[id] > 0;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @dev Implementation copied from solmate/ERC1155
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == 0x01ffc9a7 // ERC165 Interface ID for ERC165
            || interfaceId == 0xd9b67a26 // ERC165 Interface ID for ERC1155
            || interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*///////////////////////////////////////////////////////////////
                            INTERNAL OPERATIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Internal safeTranferFrom function called after all checks from the public function are done
    /// @dev Notice `operator` param. It's msg.sender to the safeTransferFrom function. Function is specific to
    /// SuperForm singleId approve logic.
    function _safeTransferFrom(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    )
        internal
        virtual
    {
        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(operator, from, to, id, amount);
        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(operator, from, id, amount, data)
                    == ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /// @notice Internal function for decreasing single id approval amount
    /// @dev Only to be used by address(this)
    /// @dev Notice `owner` param, only contract functions should be able to define it
    /// @dev Re-adapted from ERC20
    function _decreaseAllowance(
        address owner,
        address spender,
        uint256 id,
        uint256 subtractedValue
    )
        internal
        virtual
        returns (bool)
    {
        uint256 currentAllowance = allowance(owner, spender, id);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _setApprovalForOne(owner, spender, id, currentAllowance - subtractedValue);
        }

        return true;
    }

    /// @notice Internal function for setting single id approval
    /// @dev Used for fine-grained control over approvals with increase/decrease allowance
    /// @dev Notice `owner` param, only contract functions should be able to define it
    function _setApprovalForOne(address owner, address spender, uint256 id, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        allowances[owner][spender][id] = amount;
        emit ApprovalForOne(owner, spender, id, amount);
    }

    /// @dev Used to construct return url
    function _baseURI() internal view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @dev Implementation copied from solmate/ERC1155
    function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal virtual {
        balanceOf[to][id] += amount;
        _totalSupply[id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data)
                    == ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /// @dev Implementation copied from solmate/ERC1155
    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        virtual
    {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength;) {
            balanceOf[to][ids[i]] += amounts[i];
            _totalSupply[ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data)
                    == ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /// @dev Implementation copied from solmate/ERC1155
    function _batchBurn(address from, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        bool singleApproval;
        uint256 idsLength = ids.length; // Saves MLOADs.

        /// @dev case to handle single id / multi id approvals
        if (msg.sender != from && !isApprovedForAll[from][msg.sender]) {
            singleApproval = true;
        }

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < idsLength;) {
            id = ids[i];
            amount = amounts[i];

            if (singleApproval) {
                require(allowance(from, msg.sender, id) >= amount, "NOT_AUTHORIZED");
                allowances[from][msg.sender][id] -= amount;
            }

            balanceOf[from][id] -= amount;
            _totalSupply[id] -= amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    /// @dev Implementation copied from solmate/ERC1155
    function _burn(address from, uint256 id, uint256 amount) internal virtual {
        // Check if the msg.sender is the owner or is approved for all tokens
        if (msg.sender != from && !isApprovedForAll[from][msg.sender]) {
            // If not, then check if the msg.sender has sufficient allowance
            require(allowance(from, msg.sender, id) >= amount, "NOT_AUTHORIZED");
            allowances[from][msg.sender][id] -= amount; // Deduct the burned amount from the allowance
        }

        // Update the balances and total supply
        balanceOf[from][id] -= amount;
        _totalSupply[id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    )
        external
        virtual
        returns (bytes4)
    {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}
