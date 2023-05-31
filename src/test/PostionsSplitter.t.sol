/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {PositionsSplitter} from "../splitter/PositionsSplitter.sol";
import {MockPositionsSplitter} from "./mocks/MockPositionsSplitter.sol";
import {MockERC1155s} from "./mocks/MockERC1155s.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {sERC20} from "../splitter/sERC20.sol";

contract PositionsSplitterTest is Test {
    uint256 public constant THOUSAND_E18 = 1000 ether;

    /// TODO: SuperRBAC
    MockERC1155s public superPositions;
    PositionsSplitter public positionsSplitter;
    ERC20 public syntheticERC20Token;

    address public alice = address(0x2137);
    address public bob = address(0x0997);

    function setUp() public {
        superPositions = new MockERC1155s();
        superPositions.mint(alice, 1, THOUSAND_E18, "");

        positionsSplitter = new MockPositionsSplitter(superPositions);
    }

    function testWrapUnwrap() public {
        syntheticERC20Token = sERC20(positionsSplitter.registerWrapper(1, "SuperPosition Id 1", "SS1", 18));

        vm.startPrank(alice);

        superPositions.setApprovalForAll(address(positionsSplitter), true);
        positionsSplitter.wrap(1, THOUSAND_E18);
        assertEq(superPositions.balanceOf(alice, 1), 0);
        assertEq(superPositions.balanceOf(address(positionsSplitter), 1), THOUSAND_E18);

        assertEq(syntheticERC20Token.balanceOf(alice), THOUSAND_E18);

        uint256 sERC20Balance = syntheticERC20Token.balanceOf(alice);

        syntheticERC20Token.approve(address(positionsSplitter), sERC20Balance);

        /// NOTE: Test if 1:1 between 1155 and 20 always holds
        positionsSplitter.unwrap(1, sERC20Balance);

        assertEq(superPositions.balanceOf(alice, 1), THOUSAND_E18);

        assertEq(syntheticERC20Token.balanceOf(address(positionsSplitter)), 0);
    }

    function xtestWrapperAlreadyRegistered() public {
        syntheticERC20Token = sERC20(positionsSplitter.registerWrapper(1, "SuperPosition Id 1", "SS1", 18));

        vm.expectRevert();
        syntheticERC20Token = sERC20(positionsSplitter.registerWrapper(1, "SuperPosition Id 1", "SS1", 18));
    }
}
