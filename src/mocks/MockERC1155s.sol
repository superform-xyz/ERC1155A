// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {ERC1155s} from "../ERC1155s.sol";

/// @notice For test purpouses we open mint()/burn() functions of ERC1155s
contract MockERC1155s is ERC1155s {
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public {
        _mint(to, id, amount, data);
    }

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) public {
        _burn(from, id, amount);
    }
}
