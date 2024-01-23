// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Script } from "forge-std/Script.sol";

import "forge-std/console.sol";

import "src/test/mocks/MockERC1155A.sol";

contract DeployTestERC1155A is Script {
    address public deployedContract;

    function deploy() external {
        vm.startBroadcast();
        MockERC1155A erc1155a = new MockERC1155A("Example", "EXM");
        erc1155a.mint(0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92, 1, 100, "" "");
        deployedContract = address(erc1155a);
        vm.stopBroadcast();
        console.log("Deployed contract at: %s", deployedContract);
    }
}
