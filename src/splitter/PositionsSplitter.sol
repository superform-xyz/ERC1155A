/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import "../IERC1155s.sol";
import {sERC20} from "./sERC20.sol";

/// @title Positions Splitter | WIP / EXPERIMENTAL
/// @dev allows users to split all or individual vaultIds of SuperFormERC1155 into ERC20
contract PositionsSplitter {

    address public immutable admin;

    IERC1155s public sERC1155;
    uint256 public syntheticTokenID;

    event Wrapped(address user, uint256 id, uint256 amount);
    event WrappedBatch(address user, uint256[] ids, uint256[] amounts);
    event Unwrapped(address user, uint256 id, uint256 amount);
    event UnwrappedBatch(address user, uint256[] ids, uint256[] amounts);

    /// @dev SuperRouter synthethic underlying ERC1155 vaultId => wrapped ERC20
    /// @dev vaultId => wrappedERC1155idERC20
    mapping(uint256 vaultId => sERC20) public synthethicTokenId;

    modifier onlyAdmin() {
        if (msg.sender != admin) {
            revert("sERC20: Only PositionSplitter");
        }
        _;
    }

    /// @dev Access Control should be re-thinked
    constructor(IERC1155s superFormLp) {
        admin = msg.sender;
        sERC1155 = superFormLp;
    }

    /// @notice vaultId given here needs to be the same as vaultId on Source!
    /// @dev Make sure its set for existing vaultIds only
    /// @dev Ideally, this should be only called by SuperRouter
    /// TODO: SuperRBAC? Add onlySuperPositions() 
    /// @dev WARNING: vaultId cant be used for mapping, overwrite
    function registerWrapper(
        uint256 vaultId,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) external onlyAdmin returns (sERC20) {
        synthethicTokenId[vaultId] = new sERC20(name, symbol, decimals);
        /// @dev convienience for testing, prob no reason to return interface here
        return synthethicTokenId[vaultId];
    }

    /*///////////////////////////////////////////////////////////////
                            MULTIPLE ID OPERATIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Use ERC1155 BatchTransfer to wrap multiple ERC1155 ids into separate ERC20
    /// Easier to wrap than to wrapBack because of ERC1155 beauty!
    function wrapBatch(uint256[] memory vaultIds, uint256[] memory amounts)
        external
    {
        /// TODO: Add single approval logic! (prep for range approves)
        require(
            sERC1155.isApprovedForAll(msg.sender, address(this)),
            "Error: Insufficient Approval"
        );

        /// @dev Use ERC1155 BatchTransfer to lower costs
        sERC1155.safeBatchTransferFrom(
            msg.sender,
            address(this),
            vaultIds,
            amounts,
            ""
        );

        // Note: Hook to SuperRouter, optional if we want to do something there
        // sERC1155.unwrap(msg.sender, vaultIds, amounts);

        for (uint256 i = 0; i < vaultIds.length; i++) {
            synthethicTokenId[vaultIds[i]].mint(msg.sender, amounts[i]);
        }

        emit WrappedBatch(msg.sender, vaultIds, amounts);
    }

    function wrapBatchFor(
        address user,
        uint256[] memory vaultIds,
        uint256[] memory amounts
    ) external {
        require(
            sERC1155.isApprovedForAll(user, address(this)),
            "Error: Insufficient Approval"
        );

        /// @dev Use ERC1155 BatchTransfer to lower costs
        sERC1155.safeBatchTransferFrom(
            user,
            address(this),
            vaultIds,
            amounts,
            ""
        );

        // Note: Hook to SuperRouter, optional if we want to do something there
        // sERC1155.unwrap(msg.sender, vaultIds, amounts);

        address owner = user;
        for (uint256 i = 0; i < vaultIds.length; i++) {
            synthethicTokenId[vaultIds[i]].mint(owner, amounts[i]);
        }

        emit WrappedBatch(owner, vaultIds, amounts);
    }

    /// @notice Why we are not supporting wrapBack to ERC1155 with multiple ERC20 at once?
    /// Note: Its actually problematic to do so, as ERC20 do not support batch ops (in contrary to ERC1155)
    /// First, it needs for loop, and within this for loop each check (allowance) needs to pass
    /// otherwise, we risk failing in the middle of transaction. Maybe just allow to wrapBack one-by-one?

    /*///////////////////////////////////////////////////////////////
                            SINGLE ID OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function wrap(uint256 vaultId, uint256 amount) external {

        /// TODO: Add single approval logic! (prep for range approves)
        require(
            sERC1155.isApprovedForAll(msg.sender, address(this)),
            "Error: Insufficient Approval"
        );

        /// @dev The only problem to solve is restrict burn on Source,
        /// but should be covered because now SharesSplitter owns tokenId1155
        /// Note: User needs to approve SharesSplitter first
        sERC1155.safeTransferFrom(
            msg.sender,
            address(this),
            vaultId,
            amount,
            ""
        );

        // Note: Hook to SuperRouter, optional if we want to do something there
        // sERC1155.unwrap(msg.sender, vaultId, amount);

        synthethicTokenId[vaultId].mint(msg.sender, amount);
        emit Wrapped(msg.sender, vaultId, amount);
    }

    function wrapFor(
        uint256 vaultId,
        address user,
        uint256 amount
    ) external {

        /// TODO: Add single approval logic! (prep for range approves)
        require(
            sERC1155.isApprovedForAll(msg.sender, address(this)),
            "Error: Insufficient Approval"
        );
        
        sERC1155.safeTransferFrom(
            user,
            address(this),
            syntheticTokenID,
            amount,
            ""
        );

        synthethicTokenId[vaultId].mint(user, amount);
        emit Wrapped(user, vaultId, amount);
    }

    /// @dev Callback to SuperRouter from here to re-mint ERC1155 on SuperRouter
    function unwrap(uint256 vaultId, uint256 amount) external {
        sERC20 token = synthethicTokenId[vaultId];
        require(
            token.allowance(msg.sender, address(this)) >= amount,
            "Error: Insufficient Approval"
        );

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

    function unwrapFor(
        uint256 vaultId,
        address user,
        uint256 amount
    ) external {
        sERC20 token = synthethicTokenId[vaultId];
        require(
            token.allowance(user, address(this)) >= amount,
            "Error: Insufficient Approval"
        );

        /// @dev No need to transfer to contract, we can burn for msg.sender
        token.burn(user, amount);

        /// @dev Hack to help with contract size limit on Source
        uint256[] memory vaultIds = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);
        vaultIds[0] = vaultId;
        amounts[0] = amount;

        /// @dev WIP. wrapBack accepts only arrays, we need to create one
        sERC1155.safeBatchTransferFrom(
            address(this),
            user,
            vaultIds,
            amounts,
            bytes("")
        );
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