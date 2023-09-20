/// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {MockERC1155A} from "./mocks/MockERC1155A.sol";

contract ERC1155ATest is Test {
    MockERC1155A public SuperShares;
    uint256 public constant THOUSAND_E18 = 1000 ether;
    address public alice = address(0x2137);
    address public bob = address(0x0997);

    function setUp() public {
        SuperShares = new MockERC1155A();
        SuperShares.mint(alice, 1, THOUSAND_E18, "");
        SuperShares.mint(alice, 2, THOUSAND_E18, "");
    }

    /// @dev All possible approval combinations for ERC1155A
    /// Case 1: AllApproval + NO SingleApproval (standard 1155)
    /// Case 2: AllApproval + SingleApproval (AllApproved tokens decrease SingleApprove too)
    /// Case 3: SingleApproval + NO AllApproval (decrease SingleApprove allowance)
    /// Case 4: SingleApproval + AllApproval (decreases SingleApprove allowance) +++
    /// Case 5: MultipleApproval

    function testSetApprovalForOne() public {
        uint256 allowAmount = (THOUSAND_E18 / 2);

        vm.prank(alice);
        /// @dev alice approves 500 of id 1 to bob
        SuperShares.setApprovalForOne(bob, 1, allowAmount);

        uint256 bobAllowance = SuperShares.allowance(alice, bob, 1);
        assertEq(bobAllowance, allowAmount);

        vm.prank(bob);
        /// @dev bob can only transfer 500 of id 1 by calling specific function, safeTransferFrom
        SuperShares.safeTransferFrom(alice, bob, 1, bobAllowance, "");

        uint256 bobBalance = SuperShares.balanceOf(bob, 1);
        assertEq(bobBalance, bobAllowance);

        /// @dev allowance should decrease to 0
        bobAllowance = SuperShares.allowance(alice, bob, 1);
        assertEq(bobAllowance, 0);
    }

    function testApprovalForAllWithTransferSingle() public {
        uint256 transferAmount = (THOUSAND_E18 / 2);
        uint256 allowSingle = (THOUSAND_E18 / 4);

        vm.startPrank(alice);

        SuperShares.setApprovalForAll(bob, true);
        /// @dev Set also approval for one, but smaller than (allowed >= amount) check
        /// @dev We want transfer to execute using mass approval
        /// @dev If we allow amount bigger than requested for transfer, safeTransferFrom will execute on single
        /// allowance
        SuperShares.setApprovalForOne(bob, 1, allowSingle);
        uint256 bobAllowance = SuperShares.allowance(alice, bob, 1);
        assertEq(bobAllowance, allowSingle);

        vm.stopPrank();

        vm.startPrank(bob);

        /// @dev succeds because bob is approved for all
        SuperShares.safeTransferFrom(alice, bob, 1, transferAmount, "");
        uint256 bobBalance = SuperShares.balanceOf(bob, 1);
        assertEq(bobBalance, transferAmount);
        /// @dev allowance unchanged because bob is approved for all
        assertEq(bobAllowance, allowSingle);
    }

    function testFailNotEnoughSingleAllowance() public {
        uint256 transferAmount = (THOUSAND_E18 / 2);
        /// 500
        uint256 allowSingle = (THOUSAND_E18 / 4);
        /// 250

        vm.startPrank(alice);
        SuperShares.setApprovalForOne(bob, 1, allowSingle);
        uint256 bobAllowance = SuperShares.allowance(alice, bob, 1);
        assertEq(bobAllowance, allowSingle);
        vm.stopPrank();

        vm.startPrank(bob);
        /// @dev fails because bob is approved for all, but not enough allowance
        SuperShares.safeTransferFrom(alice, bob, 1, transferAmount, "");
    }

    function testSafeBatchTransferFrom() public {
        uint256 allowAmount = (THOUSAND_E18 / 2);

        uint256[] memory ids = new uint256[](4);
        uint256[] memory amounts = new uint256[](4);
        ids[0] = 2;
        ids[1] = 3;
        ids[2] = 4;
        ids[3] = 5;
        amounts[0] = allowAmount;
        amounts[1] = allowAmount;
        amounts[2] = allowAmount;
        amounts[3] = allowAmount;

        vm.startPrank(alice);
        SuperShares.batchMint(alice, ids, amounts, "");
        SuperShares.setApprovalForAll(bob, true);
        vm.stopPrank();

        vm.startPrank(bob);
        SuperShares.safeBatchTransferFrom(alice, bob, ids, amounts, "");
    }

    function testSingleAllowanceIncrease() public {
        uint256 allowAmount = (THOUSAND_E18 / 2);

        vm.startPrank(alice);
        /// @dev alice approves 50 of id 1 to bob
        SuperShares.setApprovalForOne(bob, 1, allowAmount);

        uint256 bobMaxAllowance = SuperShares.allowance(alice, bob, 1);
        SuperShares.increaseAllowance(bob, 1, allowAmount);
        assertEq(bobMaxAllowance, allowAmount);

        vm.stopPrank();
        vm.prank(bob);
        /// @dev bob transfers initial allowance amount, but not increased amount
        SuperShares.safeTransferFrom(alice, bob, 1, bobMaxAllowance, "");
        uint256 bobBalance = SuperShares.balanceOf(bob, 1);
        assertEq(bobBalance, bobMaxAllowance);
        uint256 bobExistingAllowance = SuperShares.allowance(alice, bob, 1);
        /// @dev Bob still has 500 tokens to spend from increased allowance
        assertEq(bobExistingAllowance, allowAmount);
    }

    function testMultiAllowanceIncrease() public {
        uint256 allowAmount1 = (THOUSAND_E18 / 2);
        uint256 allowAmount2 = (THOUSAND_E18 / 3);

        vm.startPrank(alice);

        /// @dev alice approves allowAmount1 and allowAmount2 of id 1 & 2 to bob
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256[] memory allowAmounts = new uint256[](2);
        allowAmounts[0] = allowAmount1;
        allowAmounts[1] = allowAmount2;

        SuperShares.setApprovalForMany(bob, ids, allowAmounts);

        uint256 bobMaxAllowanceToken1 = SuperShares.allowance(alice, bob, 1);
        uint256 bobMaxAllowanceToken2 = SuperShares.allowance(alice, bob, 2);
        SuperShares.increaseAllowanceForMany(bob, ids, allowAmounts);

        assertEq(bobMaxAllowanceToken1, allowAmount1);
        assertEq(bobMaxAllowanceToken2, allowAmount2);

        vm.stopPrank();
        vm.prank(bob);

        allowAmounts[0] = bobMaxAllowanceToken1;
        allowAmounts[1] = bobMaxAllowanceToken2;

        /// @dev bob transfers initial allowance amount, but not increased amount
        SuperShares.safeBatchTransferFrom(alice, bob, ids, allowAmounts, "");
        uint256 bobBalance1 = SuperShares.balanceOf(bob, 1);
        assertEq(bobBalance1, bobMaxAllowanceToken1);

        uint256 bobBalance2 = SuperShares.balanceOf(bob, 2);
        assertEq(bobBalance2, bobMaxAllowanceToken2);

        uint256 bobExistingAllowance1 = SuperShares.allowance(alice, bob, 1);
        uint256 bobExistingAllowance2 = SuperShares.allowance(alice, bob, 2);
        /// @dev Bob still has 500 tokens to spend from increased allowance
        assertEq(bobExistingAllowance1, allowAmount1);
        assertEq(bobExistingAllowance2, allowAmount2);
    }

    function testTokenURI() public {
        string memory url = "https://api.superform.xyz/superposition/1";
        string memory returned = SuperShares.uri(1);
        assertEq(url, returned);
    }
}
