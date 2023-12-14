// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IERC1155A } from "./interfaces/IERC1155A.sol";
import { Strings } from "openzeppelin-contracts/contracts/utils/Strings.sol";
import { IERC1155Errors } from "openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol";
import { IERC1155Receiver } from "openzeppelin-contracts/contracts/token/ERC1155/IERC1155Receiver.sol";
import { IaERC20 } from "./interfaces/IaERC20.sol";

/**
 * @title ERC1155A
 * @dev ERC1155A is a proposed extension for ERC1155.
 * @dev Hybrid solmate/openzeppelin implementation, follows ERC1155 standard interface
 *
 * 1. Single id approve capability
 * 2. Allowance management for single id approve
 * 3. Metadata build out of baseURI and id uint value into offchain metadata address
 * 4. Range based approvals
 * 5. Converting to ERC20s back and forth (called AERC20)
 *
 */
abstract contract ERC1155A is IERC1155A, IERC1155Errors {
    /*//////////////////////////////////////////////////////////////
                             ERC1155a STORAGE
    //////////////////////////////////////////////////////////////*/
    /// @notice ERC20-like mapping for single id supply.
    mapping(uint256 => uint256) public _totalSupply;

    /// @notice ERC20-like mapping for single id approvals.
    mapping(address owner => mapping(address operator => mapping(uint256 id => uint256 amount))) private allowances;

    /// @dev Implementation copied from solmate/ERC1155
    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    /// @dev Implementation copied from solmate/ERC1155
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /// @dev mapping of token ids to aErc20 token addresses
    mapping(uint256 id => address aErc20Token) public aErc20TokenId;

    ///////////////////////////////////////////////////////////////////////////
    ///                     ERC1155-A LOGIC SECTION                         ///
    ///////////////////////////////////////////////////////////////////////////

    /// @notice Transfer singleApproved id with this function
    /// @dev If caller is owner of ids, transfer just executes.
    /// @dev If caller singleApproved >= transferAmount, function executes and reduces allowance (even if
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
        if (from == address(0) || to == address(0)) revert ZERO_ADDRESS();

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
        } else if (isApprovedForAll[from][operator]) {
            /// NOTE: We don't decrease individual allowance here.
            /// NOTE: Spender effectively has unlimited allowance because of isApprovedForAll
            /// NOTE: We leave allowance management to token owners

            /// @dev make transfer
            _safeTransferFrom(operator, from, to, id, amount, data);

            /// @dev operator is not an owner of ids or not enough of allowance, or is not approvedForAll
        } else if (allowed >= amount) {
            /// @dev decrease allowance
            _decreaseAllowance(from, operator, id, amount);
            /// @dev make transfer
            _safeTransferFrom(operator, from, to, id, amount, data);

            /// @dev operator is approved for all tokens
        } else {
            revert NOT_AUTHORIZED();
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @dev Implementation copied from solmate/ERC1155
    function setApprovalForAll(address operator, bool approved) public virtual {
        if (operator == address(0)) revert ZERO_ADDRESS();
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @dev Implementation copied from solmate/ERC1155
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
        if (from == address(0) || to == address(0)) revert ZERO_ADDRESS();

        bool singleApproval;
        uint256 len = ids.length;

        if (len != amounts.length) revert LENGTH_MISMATCH();

        /// @dev case to handle single id / multi id approvals
        if (msg.sender != from && !isApprovedForAll[from][msg.sender]) {
            singleApproval = true;
        }

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i; i < len; ++i) {
            id = ids[i];
            amount = amounts[i];

            if (singleApproval) {
                if (allowance(from, msg.sender, id) < amount) revert NOT_ENOUGH_ALLOWANCE();
                allowances[from][to][id] -= amount;
            }

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(msg.sender, from, to, ids, amounts, data);
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
        if (owners.length != ids.length) revert LENGTH_MISMATCH();

        balances = new uint256[](owners.length);

        for (uint256 i = 0; i < owners.length; ++i) {
            balances[i] = balanceOf[owners[i]][ids[i]];
        }
    }

    ///////////////////////////////////////////////////////////////////////////
    ///                     SINGLE APPROVE SECTION                          ///
    ///////////////////////////////////////////////////////////////////////////

    /// inheritdoc IERC1155A
    function setApprovalForOne(address spender, uint256 id, uint256 amount) public virtual {
        _setApprovalForOne(msg.sender, spender, id, amount);
    }

    /// inheritdoc IERC1155A
    function allowance(address owner, address spender, uint256 id) public view virtual returns (uint256) {
        return allowances[owner][spender][id];
    }

    /// inheritdoc IERC1155A
    function increaseAllowance(address spender, uint256 id, uint256 addedValue) public virtual returns (bool) {
        _setApprovalForOne(msg.sender, spender, id, allowance(msg.sender, spender, id) + addedValue);
        return true;
    }

    /// inheritdoc IERC1155A
    function decreaseAllowance(address spender, uint256 id, uint256 subtractedValue) public virtual returns (bool) {
        return _decreaseAllowance(msg.sender, spender, id, subtractedValue);
    }

    ///////////////////////////////////////////////////////////////////////////
    ///                     MULTI APPROVE SECTION                           ///
    ///////////////////////////////////////////////////////////////////////////

    /// inheritdoc IERC1155A
    function setApprovalForMany(address spender, uint256[] memory ids, uint256[] memory amounts) public virtual {
        uint256 idsLength = ids.length;
        if (idsLength != amounts.length) revert LENGTH_MISMATCH();

        for (uint256 i; i < idsLength; ++i) {
            _setApprovalForOne(msg.sender, spender, ids[i], amounts[i]);
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
        uint256 idsLength = ids.length;
        if (idsLength != addedValues.length) revert LENGTH_MISMATCH();

        for (uint256 i; i < idsLength; ++i) {
            _setApprovalForOne(msg.sender, spender, ids[i], allowance(msg.sender, spender, ids[i]) + addedValues[i]);
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
        uint256 idsLength = ids.length;
        if (idsLength != subtractedValues.length) revert LENGTH_MISMATCH();

        for (uint256 i; i < idsLength; ++i) {
            _decreaseAllowance(msg.sender, spender, ids[i], subtractedValues[i]);
        }

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                    AERC20 AND TRANSMUTE LOGIC 
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IERC1155A
    function registerAERC20(uint256 id) external payable virtual override returns (address) {
        if (_totalSupply[id] == 0) revert ID_NOT_MINTED_YET();
        if (aErc20TokenId[id] != address(0)) revert AERC20_ALREADY_REGISTERED();

        address aErc20Token = _registerAERC20(id);

        aErc20TokenId[id] = aErc20Token;
        return aErc20TokenId[id];
    }

    /// @inheritdoc IERC1155A
    function transmuteBatchToERC20(address owner, uint256[] memory ids, uint256[] memory amounts) external override {
        if (owner == address(0)) revert ZERO_ADDRESS();

        uint256 idsLength = ids.length; // Saves MLOADs.
        if (idsLength != amounts.length) revert LENGTH_MISMATCH();

        /// @dev an approval is needed to burn
        _batchBurn(owner, msg.sender, ids, amounts);

        for (uint256 i = 0; i < idsLength; ++i) {
            address aERC20Token = aErc20TokenId[ids[i]];
            if (aERC20Token == address(0)) revert AERC20_NOT_REGISTERED();

            IaERC20(aERC20Token).mint(owner, amounts[i]);
        }

        emit TransmutedBatchToERC20(owner, ids, amounts);
    }

    /// @inheritdoc IERC1155A
    function transmuteBatchToERC1155A(
        address owner,
        uint256[] memory ids,
        uint256[] memory amounts
    )
        external
        override
    {
        if (owner == address(0)) revert ZERO_ADDRESS();

        uint256 idsLength = ids.length; // Saves MLOADs.
        if (idsLength != amounts.length) revert LENGTH_MISMATCH();

        for (uint256 i = 0; i < idsLength; ++i) {
            address aERC20Token = aErc20TokenId[ids[i]];
            if (aERC20Token == address(0)) revert AERC20_NOT_REGISTERED();
            /// @dev an approval is needed on each aERC20 to burn
            IaERC20(aERC20Token).burn(owner, msg.sender, amounts[i]);
        }

        _batchMint(owner, msg.sender, ids, amounts, bytes(""));

        emit TransmutedBatchToERC1155A(owner, ids, amounts);
    }

    /// @inheritdoc IERC1155A
    function transmuteToERC20(address owner, uint256 id, uint256 amount) external override {
        if (owner == address(0)) revert ZERO_ADDRESS();
        /// @dev an approval is needed to burn
        _burn(owner, msg.sender, id, amount);

        address aERC20Token = aErc20TokenId[id];
        if (aERC20Token == address(0)) revert AERC20_NOT_REGISTERED();

        IaERC20(aERC20Token).mint(owner, amount);
        emit TransmutedToERC20(owner, id, amount);
    }

    /// @inheritdoc IERC1155A
    function transmuteToERC1155A(address owner, uint256 id, uint256 amount) external override {
        if (owner == address(0)) revert ZERO_ADDRESS();

        address aERC20Token = aErc20TokenId[id];
        if (aERC20Token == address(0)) revert AERC20_NOT_REGISTERED();

        /// @dev an approval is needed to burn
        IaERC20(aERC20Token).burn(owner, msg.sender, amount);
        _mint(owner, msg.sender, id, amount, bytes(""));

        emit TransmutedToERC1155A(owner, id, amount);
    }

    function getERC20TokenAddress(uint256 id) external view virtual override returns (address) {
        return aErc20TokenId[id];
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

    /// @dev handy helper to check if a AERC20 is registered
    function aERC20Exists(uint256 id) external view virtual returns (bool) {
        return aErc20TokenId[id] != address(0);
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
    /// @dev singleId approve logic.
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

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /// @notice Internal function for decreasing single id approval amount
    /// @dev Only to be used by address(this)
    /// @dev Notice `owner` param, only contract functions should be able to define it
    /// @dev Re-adapted from ERC20
    function _decreaseAllowance(
        address owner,
        address operator,
        uint256 id,
        uint256 subtractedValue
    )
        internal
        virtual
        returns (bool)
    {
        uint256 currentAllowance = allowance(owner, operator, id);
        if (currentAllowance < subtractedValue) revert DECREASED_ALLOWANCE_BELOW_ZERO();
        _setApprovalForOne(owner, operator, id, currentAllowance - subtractedValue);

        return true;
    }

    /// @notice Internal function for setting single id approval
    /// @dev Used for fine-grained control over approvals with increase/decrease allowance
    /// @dev Notice `owner` param, only contract functions should be able to define it
    function _setApprovalForOne(address owner, address operator, uint256 id, uint256 amount) internal virtual {
        if (owner == address(0)) revert ZERO_ADDRESS();
        if (operator == address(0)) revert ZERO_ADDRESS();

        allowances[owner][operator][id] = amount;
        emit ApprovalForOne(owner, operator, id, amount);
    }

    /// @dev Used to construct return url
    function _baseURI() internal view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @dev Implementation copied from solmate/ERC1155 and adapted with operator logic
    function _mint(address to, address operator, uint256 id, uint256 amount, bytes memory data) internal virtual {
        balanceOf[to][id] += amount;
        _totalSupply[id] += amount;

        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /// @dev Implementation copied from solmate/ERC1155 and adapted with operator logic
    function _batchMint(
        address to,
        address operator,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        virtual
    {
        uint256 idsLength = ids.length; // Saves MLOADs.

        if (idsLength != amounts.length) revert LENGTH_MISMATCH();

        for (uint256 i = 0; i < idsLength; ++i) {
            balanceOf[to][ids[i]] += amounts[i];
            _totalSupply[ids[i]] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /// @dev Implementation copied from solmate/ERC1155 and adapted with operator logic
    function _batchBurn(
        address from,
        address operator,
        uint256[] memory ids,
        uint256[] memory amounts
    )
        internal
        virtual
    {
        bool singleApproval;
        uint256 idsLength = ids.length; // Saves MLOADs.

        if (operator != from && !isApprovedForAll[from][operator]) {
            singleApproval = true;
        }

        if (idsLength != amounts.length) revert LENGTH_MISMATCH();

        for (uint256 i = 0; i < idsLength; ++i) {
            if (singleApproval) {
                if (allowance(from, operator, ids[i]) < amounts[i]) revert NOT_ENOUGH_ALLOWANCE();
                allowances[from][operator][ids[i]] -= amounts[i];
            }

            balanceOf[from][ids[i]] -= amounts[i];
            _totalSupply[ids[i]] -= amounts[i];
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    /// @dev Implementation copied from solmate/ERC1155 and adapted with operator logic
    function _burn(address from, address operator, uint256 id, uint256 amount) internal virtual {
        // Check if the msg.sender is the owner or is approved for all tokens
        if (operator != from && !isApprovedForAll[from][operator]) {
            // If not, then check if the msg.sender has sufficient allowance
            if (allowance(from, operator, id) < amount) revert NOT_ENOUGH_ALLOWANCE();
            allowances[from][operator][id] -= amount; // Deduct the burned amount from the allowance
        }

        // Update the balances and total supply
        balanceOf[from][id] -= amount;
        _totalSupply[id] -= amount;

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /// @dev allows a developer to integrate their logic to create an aERC20
    function _registerAERC20(uint256 id) internal virtual returns (address aErc20Token);

    /// @dev Implementation copied from openzeppelin-contracts/ERC1155 with new custom error logic and revert on
    /// transfer to address 0
    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    )
        private
    {
        if (to.code.length > 0) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, value, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    // Tokens rejected
                    revert ERC1155InvalidReceiver(to);
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    // non-ERC1155Receiver implementer
                    revert ERC1155InvalidReceiver(to);
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            if (to == address(0)) revert TRANSFER_TO_ADDRESS_ZERO();
        }
    }

    /// @dev Implementation copied from openzeppelin-contracts/ERC1155 with new custom error logic  and revert on
    /// transfer to address 0
    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    )
        private
    {
        if (to.code.length > 0) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, values, data) returns (bytes4 response)
            {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    // Tokens rejected
                    revert ERC1155InvalidReceiver(to);
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    // non-ERC1155Receiver implementer
                    revert ERC1155InvalidReceiver(to);
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            if (to == address(0)) revert TRANSFER_TO_ADDRESS_ZERO();
        }
    }
}
