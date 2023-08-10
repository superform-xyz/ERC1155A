/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {IERC1155A} from "../../interfaces/IERC1155A.sol";
import {Transmuter} from "../../transmuter/Transmuter.sol";
import {sERC20} from "../../transmuter/sERC20.sol";

/// @notice For test purpouses we open mint()/burn() functions of ERC1155s
contract MockTransmuter is Transmuter {
    address deployer;
    error NOT_DEPLOYER();

    constructor(IERC1155A erc1155a, address deployer_) Transmuter(erc1155a) {
        deployer = deployer_;
    }

    function registerTransmuter(
        uint256 id,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) external override returns (address) {
        if (msg.sender != deployer) revert NOT_DEPLOYER();
        if (synthethicTokenId[id] != address(0)) revert TRANSMUTER_ALREADY_REGISTERED();

        address syntheticToken = address(new sERC20(name, symbol, decimals));
        synthethicTokenId[id] = syntheticToken;
        /// @dev convienience for testing, prob no reason to return interface here
        return synthethicTokenId[id];
    }
}
