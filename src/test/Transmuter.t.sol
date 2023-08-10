/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import {MockTransmuter} from "./mocks/MockTransmuter.sol";
import {MockERC1155A} from "./mocks/MockERC1155A.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {sERC20} from "../transmuter/sERC20.sol";

contract TransmuterTest is Test {
    uint256 public constant THOUSAND_E18 = 1000 ether;

    MockERC1155A public superPositions;
    MockTransmuter public transmuter;
    ERC20 public syntheticERC20Token;

    address public deployer = address(0x777);
    address public alice = address(0x2137);
    address public bob = address(0x0997);

    function setUp() public {
        superPositions = new MockERC1155A();
        superPositions.mint(alice, 1, THOUSAND_E18, "");

        vm.prank(deployer);
        transmuter = new MockTransmuter(superPositions, deployer);
    }

    function testTransmute() public {
        vm.prank(deployer);

        syntheticERC20Token = sERC20(transmuter.registerTransmuter(1, "SuperPosition Id 1", "SS1", 18));

        vm.startPrank(alice);

        superPositions.setApprovalForAll(address(transmuter), true);
        transmuter.transmuteToERC20(1, THOUSAND_E18);
        assertEq(superPositions.balanceOf(alice, 1), 0);
        assertEq(superPositions.balanceOf(address(transmuter), 1), THOUSAND_E18);

        assertEq(syntheticERC20Token.balanceOf(alice), THOUSAND_E18);

        uint256 sERC20Balance = syntheticERC20Token.balanceOf(alice);

        syntheticERC20Token.approve(address(transmuter), sERC20Balance);

        /// NOTE: Test if 1:1 between 1155 and 20 always holds
        transmuter.transmuteToERC1155A(1, sERC20Balance);

        assertEq(superPositions.balanceOf(alice, 1), THOUSAND_E18);

        assertEq(syntheticERC20Token.balanceOf(address(transmuter)), 0);
    }

    function testTransmuterAlreadyRegistered() public {
        vm.prank(deployer);
        syntheticERC20Token = sERC20(transmuter.registerTransmuter(1, "SuperPosition Id 1", "SS1", 18));

        vm.prank(deployer);
        vm.expectRevert();
        syntheticERC20Token = sERC20(transmuter.registerTransmuter(1, "SuperPosition Id 1", "SS1", 18));
    }
}
