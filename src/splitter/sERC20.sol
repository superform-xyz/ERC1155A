/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {ERC20} from "solmate/tokens/ERC20.sol";

/// @title sERC20
/// @author Zeropoint Labs.
/// @dev Synthetic ERC20 positions out of 1155s
contract sERC20 is ERC20 {
    address public immutable positionsSplitter;

    modifier onlyPositionSplitter() {
        if (msg.sender != positionsSplitter) {
            revert("sERC20: Only PositionSplitter");
        }
        _;
    }

    constructor(string memory name_, string memory symbol_, uint8 decimals_) ERC20(name_, symbol_, decimals_) {
        positionsSplitter = msg.sender;
    }

    function mint(address owner, uint256 amount) external onlyPositionSplitter {
        _mint(owner, amount);
    }

    function burn(address owner, uint256 amount) external onlyPositionSplitter {
        _burn(owner, amount);
    }
}
