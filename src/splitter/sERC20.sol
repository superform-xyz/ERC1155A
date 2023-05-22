/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/access/AccessControl.sol";

import {ERC20} from "solmate/tokens/ERC20.sol";

contract sERC20 is ERC20 {

    address public immutable positionsSplitter;

    modifier onlyPositionSplitter {
        if (msg.sender != positionsSplitter) {
            revert("sERC20: Only PositionSplitter");
        }
        _;
    }

    bytes32 public constant POSITIONS_SPLITTER_ROLE =
        keccak256("POSITIONS_SPLITTER_ROLE");

    constructor(string memory name_, string memory symbol_, uint8 decimals_) ERC20(name_, symbol_, decimals_) {
        positionsSplitter = msg.sender;
    }

    /// @dev Functions could be open (at least burn) and just pass call to SuperRouter
    function mint(address owner, uint256 amount)
        external
        onlyPositionSplitter
    {
        _mint(owner, amount);
    }

    function burn(address owner, uint256 amount)
        external
        onlyPositionSplitter
    {
        _burn(owner, amount);
    }
}