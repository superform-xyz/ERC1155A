/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "../src/mocks/MockERC1155s.sol";

contract ERC1155STest is Test {
    MockERC1155s public SuperShares;
    uint256 public constant THOUSAND_E18 = 1000 ether;
    address public alice = address(0x2137);
    address public bob = address(0x0997);

    function setUp() public {
        SuperShares = new MockERC1155s();
        SuperShares.mint(alice, 1, THOUSAND_E18, "");
    }

    /// @dev All possible approval combinations for ERC1155S
    /// Case 1: AllApproval + NO SingleApproval (standard 1155)
    /// Case 2: AllApproval + SingleApproval (AllApproved tokens decrease SingleApprove too)
    /// Case 3: SingleApproval + NO AllApproval (decrease SingleApprove allowance)
    /// Case 4: SingleApproval + AllApproval (decreases SingleApprove allowance) +++

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
    }

    function testApprovalForAllWithTransferSingle() public {
        uint256 allowAmount = (THOUSAND_E18 / 2);

        vm.prank(alice);
        SuperShares.setApprovalForAll(bob, true);

        vm.prank(bob);
        /// @dev succeds because bob is approved for all
        SuperShares.safeTransferFrom(alice, bob, 1, allowAmount, "");
    }

    function testApprovalForAllPriority() public {
        uint256 allowAmount = (THOUSAND_E18 / 2);
        uint256 approveAmount = (THOUSAND_E18 / 4);

        vm.startPrank(alice);
        /// @dev Alice gives bob approval for 250 tokens
        SuperShares.setApprovalForOne(bob, 1, approveAmount);
        /// @dev Alice also gives bob approvalForAll the tokens
        SuperShares.setApprovalForAll(bob, true);
        vm.stopPrank();
        /// @dev Bob _allowances is equal to 250 tokens
        uint256 bobAllowance = SuperShares.allowance(alice, bob, 1);

        vm.startPrank(bob);
        /// @dev Bob transfers 500 tokens
        SuperShares.safeTransferFrom(alice, bob, 1, allowAmount, "");

        /// @dev Bob allowances are not update because alice is already max approving bob for all tokens
        assertEq(bobAllowance, approveAmount);

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

    function testSingleAllowance() public {
        uint256 allowAmount = (THOUSAND_E18 / 2);

        vm.prank(alice);
        /// @dev alice approves 100 of id 1 to bob
        SuperShares.setApprovalForOne(bob, 1, allowAmount);

        uint256 bobMaxAllowance = SuperShares.allowance(alice, bob, 1);
        assertEq(bobMaxAllowance, allowAmount);

        vm.prank(bob);
        /// @dev bob transfers full allowance amount
        SuperShares.safeTransferFrom(alice, bob, 1, bobMaxAllowance, "");

        uint256 bobBalance = SuperShares.balanceOf(bob, 1);
        assertEq(bobBalance, bobMaxAllowance);        
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

    function testTokenURI() public {
        string memory url = "https://api.superform.xyz/superposition/1";
        string memory returned = SuperShares.uri(1);
        assertEq(url, returned);
    }
}
