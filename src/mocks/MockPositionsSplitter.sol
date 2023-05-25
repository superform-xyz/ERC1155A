/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import "../IERC1155s.sol";
import "../splitter/PositionsSplitter.sol";

contract MockPositionsSplitter is PositionsSplitter {

    /// @dev Access Control for RegisterWrapper. SuperRBAC is used by SuperPositions child contract.
    address public admin;

    /// @dev SuperRBAC is used by SuperPositions child contract. Only mocked modifier.
    modifier onlyAdmin() {
        if (msg.sender != admin) {
            revert("onlyAdmin: ACCESS_CONTROL");
        }
        _;
    }
    constructor(IERC1155s superFormLp) PositionsSplitter(superFormLp) {
        admin = msg.sender;
    }

    function registerWrapper(
        uint256 superFormId,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) external onlyAdmin override returns (sERC20) {
        synthethicTokenId[superFormId] = new sERC20(name, symbol, decimals);
        return synthethicTokenId[superFormId];
    }

}