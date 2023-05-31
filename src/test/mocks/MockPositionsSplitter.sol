/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {IERC1155s} from "../../interfaces/IERC1155s.sol";
import {PositionsSplitter} from "../../splitter/PositionsSplitter.sol";
import {sERC20} from "../../splitter/sERC20.sol";

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
}
