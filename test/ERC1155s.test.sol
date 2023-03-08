// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "../src/mocks/MockERC1155s.sol";

contract ERC1155s__Test is Test {
    MockERC1155s public SuperShares;
    uint256 public constant THOUSAND_E18 = 1000 ether;
    address public alice = address(0x2137);
    address public bob = address(0x0997);

    function setUp() public {
        SuperShares = new MockERC1155s();
        SuperShares.mint(alice, 1, THOUSAND_E18, "");
    }

    /// Case 1: AllApproval + safeTransferFrom (standard 1155)
    /// Case 2: SingleApproval + _safeTransferFrom (1155s) +++
    /// Case 3: AllApproval + _safeTransferFrom (fails) +++
    /// Case 4: SingleApproval + safeTransferFrom (fails) +++
    /// SingleApprove can only be used with _safeTransferFrom, approvals are separated

    function testSetApprovalForOne() public {
        uint256 allowAmount = (THOUSAND_E18 / 2);

        vm.prank(alice);
        /// alice approves 500 of id 1 to bob
        SuperShares.setApprovalForOne(bob, 1, allowAmount);

        uint256 bobAllowance = SuperShares.allowance(alice, bob, 1);
        assertEq(bobAllowance, allowAmount);

        vm.prank(bob);
        /// bob can only transfer 500 of id 1 by calling specific function, _safeTransferFrom
        SuperShares._safeTransferFrom(alice, bob, 1, bobAllowance, "");

        uint256 bobBalance = SuperShares.balanceOf(bob, 1);
        assertEq(bobBalance, bobAllowance);
    }

    function testFailApprovalForOne() public {
        uint256 allowAmount = (THOUSAND_E18 / 2);

        vm.prank(alice);
        SuperShares.setApprovalForOne(bob, 1, allowAmount);

        vm.prank(bob);
        /// bob can't transfer single approve id
        SuperShares.safeTransferFrom(alice, bob, 1, allowAmount, "");
    }

    function testFailAllApprovalForOne() public {
        uint256 allowAmount = (THOUSAND_E18 / 2);

        vm.prank(alice);
        /// alice approves everything for bob
        SuperShares.setApprovalForAll(bob, true);

        vm.prank(bob);
        /// bob still can't transfer single approve id
        SuperShares._safeTransferFrom(alice, bob, 1, allowAmount, "");
    }
}
