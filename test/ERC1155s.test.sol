/// SPDX-License-Identifier: Apache-2.0
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
    /// Case 2: SingleApproval + safeTransferFrom (1155s) +++
    /// Case 3: AllApproval + safeTransferFrom (fails) +++
    /// Case 4: SingleApproval + safeTransferFrom (fails) +++
    /// SingleApprove can only be used with safeTransferFrom, approvals are separated

    function testSetApprovalForOne() public {
        uint256 allowAmount = (THOUSAND_E18 / 2);

        vm.prank(alice);
        /// alice approves 500 of id 1 to bob
        SuperShares.setApprovalForOne(bob, 1, allowAmount);

        uint256 bobAllowance = SuperShares.allowance(alice, bob, 1);
        assertEq(bobAllowance, allowAmount);

        vm.prank(bob);
        /// bob can only transfer 500 of id 1 by calling specific function, safeTransferFrom
        SuperShares.safeTransferFrom(alice, bob, 1, bobAllowance, "");

        uint256 bobBalance = SuperShares.balanceOf(bob, 1);
        assertEq(bobBalance, bobAllowance);
    }

    function testApprovalForAllWithTransferSingle() public {
        uint256 allowAmount = (THOUSAND_E18 / 2);

        vm.prank(alice);
        SuperShares.setApprovalForAll(bob, true);

        vm.prank(bob);
        /// succeds because bob is approved for all
        SuperShares.safeTransferFrom(alice, bob, 1, allowAmount, "");
    }

    function testApprovalForAllWithTransferSingleReduceAllowances() public {
        uint256 allowAmount = (THOUSAND_E18 / 2);
        uint256 approveAmount = (THOUSAND_E18 / 4);

        vm.prank(alice);
        /// @dev Alice gives bob approval for 250 tokens
        SuperShares.setApprovalForOne(bob, 1, approveAmount);
        /// @dev Alice also gives bob approvalForAll the tokens
        SuperShares.setApprovalForAll(bob, true);
        ///  isApprovedForAll[msg.sender][operator] = approved;
        /// @dev Bob _allowances is equal to 250 tokens
        uint256 bobAllowance = SuperShares.allowance(alice, bob, 1);

        vm.prank(bob);
        /// @dev Bob transfers 500 tokens
        SuperShares.safeTransferFrom(alice, bob, 1, allowAmount, "");

        uint256 bobUpdatedAllowance = SuperShares.allowance(alice, bob, 1);
        /// @dev Bob allowance is reduced to 0 (500 transfered from ApproveAll, 250 existing allowance)
        assertEq(bobUpdatedAllowance, 0);
    }

    function testIncreaseAllowance() public {
        uint256 allowAmount = (THOUSAND_E18 / 2);

        vm.prank(alice);
        /// alice approves 100 of id 1 to bob
        SuperShares.setApprovalForOne(bob, 1, allowAmount);

        uint256 bobMaxAllowance = SuperShares.allowance(alice, bob, 1);
        assertEq(bobMaxAllowance, allowAmount);

        vm.prank(bob);
        /// bob transfers full allowance amount
        SuperShares.safeTransferFrom(alice, bob, 1, bobMaxAllowance, "");

        uint256 bobBalance = SuperShares.balanceOf(bob, 1);
        assertEq(bobBalance, bobMaxAllowance);        
    }

    function testTokenURI() public {
        string memory url = "https://api.superform.xyz/superposition/1";
        string memory returned = SuperShares.uri(1);
        console.log("uri value for vaultId 1", returned);
        assertEq(url, returned);
    }
}
