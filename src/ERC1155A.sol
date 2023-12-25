// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IERC1155A } from "./interfaces/IERC1155A.sol";
import { IaERC20 } from "./interfaces/IaERC20.sol";
import { Strings } from "openzeppelin-contracts/contracts/utils/Strings.sol";
import { IERC165 } from "openzeppelin-contracts/contracts/interfaces/IERC165.sol";
import { IERC1155 } from "openzeppelin-contracts/contracts/interfaces/IERC1155.sol";
import { IERC1155MetadataURI } from "openzeppelin-contracts/contracts/interfaces/IERC1155MetadataURI.sol";
import { IERC1155Errors } from "openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol";
import { IERC1155Receiver } from "openzeppelin-contracts/contracts/token/ERC1155/IERC1155Receiver.sol";

/// @title ERC1155A
/// @dev Single/range based id approve capability with conversion to ERC20s
/// @author Zeropoint Labs
abstract contract ERC1155A is IERC1155A, IERC1155Errors {

    //////////////////////////////////////////////////////////////
    //                         CONSTANTS                        //
    //////////////////////////////////////////////////////////////

    bytes private constant EMPTY_BYTES = bytes("");

    //////////////////////////////////////////////////////////////
    //                     STATE VARIABLES                      //
    //////////////////////////////////////////////////////////////

    /// @dev ERC20-like mapping for single id supply.
    mapping(uint256 => uint256) private _totalSupply;

    /// @dev ERC20-like mapping for single id approvals.
    mapping(address owner => mapping(address operator => mapping(uint256 id => uint256 amount))) private allowances;

    /// @dev Implementation copied from solmate/ERC1155
    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    /// @dev Implementation copied from solmate/ERC1155
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /// @dev mapping of token ids to aErc20 token addresses
    mapping(uint256 id => address aErc20Token) public aErc20TokenId;

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    // Basic Token Information
    // --------------------------

    /// @inheritdoc IERC1155A
    function totalSupply(uint256 id) external view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /// @inheritdoc IERC1155A
    function exists(uint256 id) external view virtual returns (bool) {
        return _totalSupply[id] != 0;
    }

    /// @inheritdoc IERC1155
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

        for (uint256 i; i < owners.length; ++i) {
            balances[i] = balanceOf[owners[i]][ids[i]];
        }
    }

    // Allowance and Approval Checking
    // --------------------------------

    /// @inheritdoc IERC1155A
    function allowance(address owner, address operator, uint256 id) public view virtual returns (uint256) {
        return allowances[owner][operator][id];
    }

    // aERC20 Token Management
    // ------------------------

    /// @inheritdoc IERC1155A
    function aERC20Exists(uint256 id) external view virtual returns (bool) {
        return aErc20TokenId[id] != address(0);
    }

    /// @inheritdoc IERC1155A
    function getERC20TokenAddress(uint256 id) external view virtual override returns (address) {
        return aErc20TokenId[id];
    }
    
    // Metadata and Interface Support
    // ------------------------------

    /// @inheritdoc IERC1155A
    function uri(uint256 id) public view virtual returns (string memory) {
        return string.concat(_baseURI(), Strings.toString(id));
    }

    /// @dev return interface checks
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId // ERC165 Interface ID for ERC165
            || interfaceId == type(IERC1155).interfaceId // ERC165 Interface ID for ERC1155
            || interfaceId == type(IERC1155MetadataURI).interfaceId; // ERC165 Interface ID for ERC1155MetadataURI
    }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    // Token Approval Management
    // --------------------------

    /// @inheritdoc IERC1155A
    function setApprovalForOne(address operator, uint256 id, uint256 amount) public virtual {
        _setAllowance(msg.sender, operator, id, amount, true);
    }

    /// @inheritdoc IERC1155A
    function setApprovalForMany(address operator, uint256[] memory ids, uint256[] memory amounts) public virtual {
        uint256 idsLength = ids.length;
        if (idsLength != amounts.length) revert LENGTH_MISMATCH();

        for (uint256 i; i < idsLength; ++i) {
            _setAllowance(msg.sender, operator, ids[i], amounts[i], true);
        }
    }

    /// @inheritdoc IERC1155
    function setApprovalForAll(address operator, bool approved) public virtual {
        if (operator == address(0)) revert ZERO_ADDRESS();
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // Allowance Modification
    // -----------------------

   /// @inheritdoc IERC1155A
    function increaseAllowance(address operator, uint256 id, uint256 addedValue) public virtual returns (bool) {
        _setAllowance(msg.sender, operator, id, allowance(msg.sender, operator, id) + addedValue, true);
        return true;
    }

    /// @inheritdoc IERC1155A
    function decreaseAllowance(address operator, uint256 id, uint256 subtractedValue) public virtual returns (bool) {
        return _decreaseAllowance(msg.sender, operator, id, subtractedValue, true);
    }

    /// @inheritdoc IERC1155A
    function increaseAllowanceForMany(
        address operator,
        uint256[] calldata ids,
        uint256[] calldata addedValues
    )
        public
        virtual
        returns (bool)
    {
        uint256 idsLength = ids.length;
        if (idsLength != addedValues.length) revert LENGTH_MISMATCH();

        for (uint256 i; i < idsLength; ++i) {
            _setAllowance(msg.sender, operator, ids[i], allowance(msg.sender, operator, ids[i]) + addedValues[i], true);
        }

        return true;
    }

    /// @inheritdoc IERC1155A
    function decreaseAllowanceForMany(
        address operator,
        uint256[] calldata ids,
        uint256[] calldata subtractedValues
    )
        public
        virtual
        returns (bool)
    {
        uint256 idsLength = ids.length;
        if (idsLength != subtractedValues.length) revert LENGTH_MISMATCH();

        for (uint256 i; i < idsLength; ++i) {
            _decreaseAllowance(msg.sender, operator, ids[i], subtractedValues[i], true);
        }

        return true;
    }

    // Token Transfer Functions
    // -------------------------

    /// @notice see {IERC1155-safeTransferFrom}
    /// @dev adds supports for user to not have called setApprovalForAll
    /// @dev single id approval is senior in execution flow
    /// @dev if approved for all, function executes without reducing allowance
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

        /// @dev message sender is not from and is not approved for all
        if (from != operator && !isApprovedForAll[from][operator]) {
            _decreaseAllowance(from, operator, id, amount, false);
            _safeTransferFrom(from, to, id, amount);
        } else {
            /// @dev message sender is from || is approved for all
            _safeTransferFrom(from, to, id, amount);
        }

        emit TransferSingle(operator, from, to, id, amount);
        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /// @notice see {IERC1155-safeBatchTransferFrom}
    /// @dev adds supports for user to not have called setApprovalForAll
    /// @dev single id approvals are senior in execution flow
    /// @dev if approved for all, function executes without reducing allowance
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

        uint256 len = ids.length;
        if (len != amounts.length) revert LENGTH_MISMATCH();

        address operator = msg.sender;

        /// @dev case to handle single id / multi id approvals
        if (operator != from && !isApprovedForAll[from][operator]) {
            uint256 id;
            uint256 amount;

            for (uint256 i; i < len; ++i) {
                id = ids[i];
                amount = amounts[i];

                _decreaseAllowance(from, operator, id, amount, false);
                _safeTransferFrom(from, to, id, amount);
            }
        } else {
            for (uint256 i; i < len; ++i) {
                _safeTransferFrom(from, to, ids[i], amounts[i]);
            }
        }

        emit TransferBatch(operator, from, to, ids, amounts);
        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    // Token Transmutation
    // --------------------

    /// @inheritdoc IERC1155A
    function transmuteToERC20(address owner, uint256 id, uint256 amount, address receiver) external override {
        if (owner == address(0) || receiver == address(0)) revert ZERO_ADDRESS();
        /// @dev an approval is needed to burn
        _burn(owner, msg.sender, id, amount);

        address aERC20Token = aErc20TokenId[id];
        if (aERC20Token == address(0)) revert AERC20_NOT_REGISTERED();

        IaERC20(aERC20Token).mint(receiver, amount);
        emit TransmutedToERC20(owner, id, amount,receiver);
    }

    /// @inheritdoc IERC1155A
    function transmuteToERC1155A(address owner, uint256 id, uint256 amount, address receiver) external override {
        if (owner == address(0) || receiver == address(0)) revert ZERO_ADDRESS();

        address aERC20Token = aErc20TokenId[id];
        if (aERC20Token == address(0)) revert AERC20_NOT_REGISTERED();

        /// @dev an approval is needed to burn
        IaERC20(aERC20Token).burn(owner, msg.sender, amount);
        _mint(receiver, msg.sender, id, amount, EMPTY_BYTES);

        emit TransmutedToERC1155A(owner, id, amount, receiver);
    }

    /// @inheritdoc IERC1155A
    function transmuteBatchToERC20(
        address owner,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        address receiver
    )
        external
        override
    {
        if (owner == address(0) || receiver == address(0)) revert ZERO_ADDRESS();

        uint256 idsLength = ids.length; // Saves MLOADs.
        if (idsLength != amounts.length) revert LENGTH_MISMATCH();

        /// @dev an approval is needed to burn
        _batchBurn(owner, msg.sender, ids, amounts);

        for (uint256 i; i < idsLength; ++i) {
            address aERC20Token = aErc20TokenId[ids[i]];
            if (aERC20Token == address(0)) revert AERC20_NOT_REGISTERED();

            IaERC20(aERC20Token).mint(receiver, amounts[i]);
        }

        emit TransmutedBatchToERC20(owner, ids, amounts,receiver);
    }

    /// @inheritdoc IERC1155A
    function transmuteBatchToERC1155A(
        address owner,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        address receiver
    )
        external
        override
    {
        if (owner == address(0) || receiver == address(0)) revert ZERO_ADDRESS();

        uint256 idsLength = ids.length; // Saves MLOADs.
        if (idsLength != amounts.length) revert LENGTH_MISMATCH();

        uint256 id;
        uint256 amount;

        for (uint256 i; i < ids.length; ++i) {
            id = ids[i];
            amount = amounts[i];

            address aERC20Token = aErc20TokenId[id];
            if (aERC20Token == address(0)) revert AERC20_NOT_REGISTERED();
            /// @dev an approval is needed on each aERC20 to burn
            IaERC20(aERC20Token).burn(owner, msg.sender, amount);
        }

        _batchMint(receiver, msg.sender, ids, amounts, EMPTY_BYTES);

        emit TransmutedBatchToERC1155A(owner, ids, amounts, receiver);
    }

    // aERC20 Registration
    // --------------------

    /// @inheritdoc IERC1155A
    function registerAERC20(uint256 id) external payable override returns (address) {
        if (_totalSupply[id] == 0) revert ID_NOT_MINTED_YET();
        if (aErc20TokenId[id] != address(0)) revert AERC20_ALREADY_REGISTERED();

        address aErc20Token = _registerAERC20(id);

        aErc20TokenId[id] = aErc20Token;
        return aErc20TokenId[id];
    }

    //////////////////////////////////////////////////////////////
    //                  INTERNAL FUNCTIONS                      //
    //////////////////////////////////////////////////////////////

    // Token Transfer and Balance Management
    // --------------------------------------

    /// @notice Internal safeTranferFrom function called after all checks from the public function are done
    /// @dev Notice `operator` param. It's msg.sender to the safeTransferFrom function. Function is specific to
    /// @dev singleId approve logic.
    function _safeTransferFrom(address from, address to, uint256 id, uint256 amount) internal virtual {
        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;
    }

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
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes memory data
    )
        internal
        virtual
    {
        uint256 idsLength = ids.length; // Saves MLOADs.
        if (idsLength != amounts.length) revert LENGTH_MISMATCH();

        uint256 id;
        uint256 amount;
        for (uint256 i; i < idsLength; ++i) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[to][id] += amount;
            _totalSupply[id] += amount;
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);
        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /// @dev Implementation copied from solmate/ERC1155 and adapted with operator logic
    function _burn(address from, address operator, uint256 id, uint256 amount) internal virtual {
        // Check if the msg.sender is the owner or is approved for all tokens
        if (operator != from && !isApprovedForAll[from][operator]) {
            _decreaseAllowance(from, operator, id, amount, false);
        }

        // Update the balances and total supply
        _safeTransferFrom(from, address(0), id, amount);
        _totalSupply[id] -= amount;

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /// @dev Implementation copied from solmate/ERC1155 and adapted with operator logic
    function _batchBurn(
        address from,
        address operator,
        uint256[] calldata ids,
        uint256[] calldata amounts
    )
        internal
        virtual
    {
        uint256 idsLength = ids.length; // Saves MLOADs.
        if (idsLength != amounts.length) revert LENGTH_MISMATCH();

        uint256 id;
        uint256 amount;
        /// @dev case to handle single id / multi id approvals
        if (operator != from && !isApprovedForAll[from][operator]) {
            for (uint256 i; i < idsLength; ++i) {
                id = ids[i];
                amount = amounts[i];

                _decreaseAllowance(from, operator, id, amount, false);
                _safeTransferFrom(from, address(0), id, amount);
                _totalSupply[ids[i]] -= amounts[i];
            }
        } else {
            for (uint256 i; i < idsLength; ++i) {
                id = ids[i];
                amount = amounts[i];

                _safeTransferFrom(from, address(0), id, amount);
                _totalSupply[ids[i]] -= amounts[i];
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    // Allowance and Approval Handling
    // --------------------------------

    /// @notice Internal function for decreasing single id approval amount
    /// @dev Only to be used by address(this)
    /// @dev Notice `owner` param, only contract functions should be able to define it
    /// @dev Re-adapted from ERC20
    function _decreaseAllowance(
        address owner,
        address operator,
        uint256 id,
        uint256 subtractedValue,
        bool emitEvent
    )
        internal
        virtual
        returns (bool)
    {
        uint256 currentAllowance = allowance(owner, operator, id);
        if (currentAllowance < subtractedValue) revert DECREASED_ALLOWANCE_BELOW_ZERO();
        _setAllowance(owner, operator, id, currentAllowance - subtractedValue, emitEvent);

        return true;
    }

    /// @notice Internal function for setting single id approval
    /// @dev Used for fine-grained control over approvals with increase/decrease allowance
    /// @dev Notice `owner` param, only contract functions should be able to define it
    function _setAllowance(
        address owner,
        address operator,
        uint256 id,
        uint256 amount,
        bool emitEvent
    )
        internal
        virtual
    {
        if (owner == address(0)) revert ZERO_ADDRESS();
        if (operator == address(0)) revert ZERO_ADDRESS();

        allowances[owner][operator][id] = amount;

        if (emitEvent) {
            emit ApprovalForOne(owner, operator, id, amount);
        }
    }

    // ERC1155A Transfer Checks
    // ------------------------

    /// @dev Implementation copied from openzeppelin-contracts/ERC1155 with new custom error logic
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
        if (to.code.length != 0) {
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
        if (to.code.length != 0) {
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

    // aERC20 Token Creation
    // ----------------------

    /// @dev allows a developer to integrate their logic to create an aERC20
    function _registerAERC20(uint256 id) internal virtual returns (address aErc20Token);

    // Metadata and URI Handling
    // --------------------------

    /// @dev Used to construct return url
    function _baseURI() internal view virtual returns (string memory);
}
