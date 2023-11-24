/// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import { MockERC1155A } from "./mocks/MockERC1155A.sol";
import { aERC20 } from "../aERC20.sol";

import { IERC1155A } from "../interfaces/IERC1155A.sol";

import { IERC20Errors } from "openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol";

contract ERC1155ATest is Test {
    MockERC1155A public MockedERC1155A;
    uint256 public constant THOUSAND_E18 = 1000 ether;

    address public deployer = address(0x777);
    address public alice = address(0x2137);
    address public bob = address(0x0997);

    function setUp() public {
        MockedERC1155A = new MockERC1155A();
        MockedERC1155A.mint(alice, 1, THOUSAND_E18, "");
        MockedERC1155A.mint(alice, 2, THOUSAND_E18, "");
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
        MockedERC1155A.setApprovalForOne(bob, 1, allowAmount);

        uint256 bobAllowance = MockedERC1155A.allowance(alice, bob, 1);
        assertEq(bobAllowance, allowAmount);

        vm.prank(bob);
        /// @dev bob can only transfer 500 of id 1 by calling specific function, safeTransferFrom
        MockedERC1155A.safeTransferFrom(alice, bob, 1, bobAllowance, "");

        uint256 bobBalance = MockedERC1155A.balanceOf(bob, 1);
        assertEq(bobBalance, bobAllowance);

        /// @dev allowance should decrease to 0
        bobAllowance = MockedERC1155A.allowance(alice, bob, 1);
        assertEq(bobAllowance, 0);
    }

    function testApprovalForAllWithTransferSingle() public {
        uint256 transferAmount = (THOUSAND_E18 / 2);
        uint256 allowSingle = (THOUSAND_E18 / 4);

        vm.startPrank(alice);

        MockedERC1155A.setApprovalForAll(bob, true);
        /// @dev Set also approval for one, but smaller than (allowed >= amount) check
        /// @dev We want transfer to execute using mass approval
        /// @dev If we allow amount bigger than requested for transfer, safeTransferFrom will execute on single
        /// allowance
        MockedERC1155A.setApprovalForOne(bob, 1, allowSingle);
        uint256 bobAllowance = MockedERC1155A.allowance(alice, bob, 1);
        assertEq(bobAllowance, allowSingle);

        vm.stopPrank();

        vm.startPrank(bob);

        /// @dev succeds because bob is approved for all
        MockedERC1155A.safeTransferFrom(alice, bob, 1, transferAmount, "");
        uint256 bobBalance = MockedERC1155A.balanceOf(bob, 1);
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
        MockedERC1155A.setApprovalForOne(bob, 1, allowSingle);
        uint256 bobAllowance = MockedERC1155A.allowance(alice, bob, 1);
        assertEq(bobAllowance, allowSingle);
        vm.stopPrank();

        vm.startPrank(bob);
        /// @dev fails because bob is approved for all, but not enough allowance
        MockedERC1155A.safeTransferFrom(alice, bob, 1, transferAmount, "");
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
        MockedERC1155A.batchMint(alice, ids, amounts, "");
        MockedERC1155A.setApprovalForAll(bob, true);
        vm.stopPrank();

        vm.startPrank(bob);
        MockedERC1155A.safeBatchTransferFrom(alice, bob, ids, amounts, "");
    }

    function testSingleAllowanceIncrease() public {
        uint256 allowAmount = (THOUSAND_E18 / 2);

        vm.startPrank(alice);
        /// @dev alice approves 50 of id 1 to bob
        MockedERC1155A.setApprovalForOne(bob, 1, allowAmount);

        uint256 bobMaxAllowance = MockedERC1155A.allowance(alice, bob, 1);
        MockedERC1155A.increaseAllowance(bob, 1, allowAmount);
        assertEq(bobMaxAllowance, allowAmount);

        vm.stopPrank();
        vm.prank(bob);
        /// @dev bob transfers initial allowance amount, but not increased amount
        MockedERC1155A.safeTransferFrom(alice, bob, 1, bobMaxAllowance, "");
        uint256 bobBalance = MockedERC1155A.balanceOf(bob, 1);
        assertEq(bobBalance, bobMaxAllowance);
        uint256 bobExistingAllowance = MockedERC1155A.allowance(alice, bob, 1);
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

        MockedERC1155A.setApprovalForMany(bob, ids, allowAmounts);

        uint256 bobMaxAllowanceToken1 = MockedERC1155A.allowance(alice, bob, 1);
        uint256 bobMaxAllowanceToken2 = MockedERC1155A.allowance(alice, bob, 2);
        MockedERC1155A.increaseAllowanceForMany(bob, ids, allowAmounts);

        assertEq(bobMaxAllowanceToken1, allowAmount1);
        assertEq(bobMaxAllowanceToken2, allowAmount2);

        vm.stopPrank();
        vm.prank(bob);

        allowAmounts[0] = bobMaxAllowanceToken1;
        allowAmounts[1] = bobMaxAllowanceToken2;

        /// @dev bob transfers initial allowance amount, but not increased amount
        MockedERC1155A.safeBatchTransferFrom(alice, bob, ids, allowAmounts, "");
        uint256 bobBalance1 = MockedERC1155A.balanceOf(bob, 1);
        assertEq(bobBalance1, bobMaxAllowanceToken1);

        uint256 bobBalance2 = MockedERC1155A.balanceOf(bob, 2);
        assertEq(bobBalance2, bobMaxAllowanceToken2);

        uint256 bobExistingAllowance1 = MockedERC1155A.allowance(alice, bob, 1);
        uint256 bobExistingAllowance2 = MockedERC1155A.allowance(alice, bob, 2);
        /// @dev Bob still has 500 tokens to spend from increased allowance
        assertEq(bobExistingAllowance1, allowAmount1);
        assertEq(bobExistingAllowance2, allowAmount2);
    }

    function testTokenURI() public {
        string memory url = "https://uri.com/1";
        string memory returned = MockedERC1155A.uri(1);
        assertEq(url, returned);
    }

    function testAERC20CreationNoIDMinted() public {
        vm.startPrank(deployer);
        vm.expectRevert(IERC1155A.ID_NOT_MINTED_YET.selector);
        aERC20(MockedERC1155A.registerAERC20(10));
    }

    function testAERC20Creation() public {
        vm.startPrank(deployer);
        uint256 id = 3;
        MockedERC1155A.mint(alice, id, THOUSAND_E18, "");
        aERC20 aERC20Token = aERC20(MockedERC1155A.registerAERC20(id));
        vm.stopPrank();
        vm.startPrank(alice);

        MockedERC1155A.transmuteToERC20(alice, id, THOUSAND_E18);
        assertEq(MockedERC1155A.balanceOf(alice, id), 0);

        uint256 aERC20Balance = aERC20Token.balanceOf(alice);
        assertEq(aERC20Balance, THOUSAND_E18);

        aERC20Token.approve(address(MockedERC1155A), aERC20Balance);

        /// NOTE: Test if 1:1 between 1155 and 20 always holds
        MockedERC1155A.transmuteToERC1155A(alice, id, aERC20Balance);

        assertEq(MockedERC1155A.balanceOf(alice, id), THOUSAND_E18);

        assertEq(aERC20Token.balanceOf(address(alice)), 0);
        vm.stopPrank();
    }

    function testAERC20CreationNotRegistered() public {
        vm.startPrank(deployer);
        uint256 id = 3;
        MockedERC1155A.mint(alice, id, THOUSAND_E18, "");

        uint256[] memory ids = new uint256[](1);
        ids[0] = 3;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = THOUSAND_E18;
        vm.stopPrank();
        vm.startPrank(alice);

        vm.expectRevert(IERC1155A.AERC20_NOT_REGISTERED.selector);
        MockedERC1155A.transmuteToERC20(alice, id, THOUSAND_E18);

        vm.expectRevert(IERC1155A.AERC20_NOT_REGISTERED.selector);
        MockedERC1155A.transmuteToERC1155A(alice, id, THOUSAND_E18);

        vm.expectRevert(IERC1155A.AERC20_NOT_REGISTERED.selector);
        MockedERC1155A.transmuteBatchToERC20(alice, ids, amounts);

        vm.expectRevert(IERC1155A.AERC20_NOT_REGISTERED.selector);
        MockedERC1155A.transmuteBatchToERC1155A(alice, ids, amounts);
    }

    function testAERC20CreationSingleApprove() public {
        vm.startPrank(deployer);
        uint256 id = 3;
        MockedERC1155A.mint(alice, id, THOUSAND_E18, "");
        aERC20 aERC20Token = aERC20(MockedERC1155A.registerAERC20(id));
        vm.stopPrank();
        vm.prank(alice);

        MockedERC1155A.setApprovalForOne(bob, id, THOUSAND_E18);

        vm.prank(bob);
        MockedERC1155A.transmuteToERC20(alice, id, THOUSAND_E18);

        assertEq(MockedERC1155A.balanceOf(alice, id), 0);
        assertEq(MockedERC1155A.allowance(alice, bob, id), 0);

        vm.startPrank(alice);

        uint256 aERC20Balance = aERC20Token.balanceOf(alice);
        assertEq(aERC20Balance, THOUSAND_E18);

        aERC20Token.approve(address(bob), aERC20Balance);
        vm.stopPrank();

        vm.prank(bob);
        /// NOTE: Test if 1:1 between 1155 and 20 always holds
        MockedERC1155A.transmuteToERC1155A(alice, id, aERC20Balance);

        assertEq(MockedERC1155A.balanceOf(alice, id), THOUSAND_E18);

        assertEq(aERC20Token.balanceOf(address(alice)), 0);
    }

    function testAERC20CreationSingleApproveNotMade() public {
        vm.startPrank(deployer);
        uint256 id = 3;
        MockedERC1155A.mint(alice, id, THOUSAND_E18, "");
        aERC20 aERC20Token = aERC20(MockedERC1155A.registerAERC20(id));
        vm.stopPrank();
        vm.prank(alice);

        MockedERC1155A.setApprovalForOne(bob, id, THOUSAND_E18);

        vm.prank(bob);
        MockedERC1155A.transmuteToERC20(alice, id, THOUSAND_E18);

        assertEq(MockedERC1155A.balanceOf(alice, id), 0);
        assertEq(MockedERC1155A.allowance(alice, bob, id), 0);

        vm.startPrank(alice);

        uint256 aERC20Balance = aERC20Token.balanceOf(alice);
        assertEq(aERC20Balance, THOUSAND_E18);

        vm.stopPrank();

        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, bob, 0, aERC20Balance));
        MockedERC1155A.transmuteToERC1155A(alice, id, aERC20Balance);
    }

    function testAERC20CreationBatch() public {
        vm.startPrank(deployer);
        uint256[] memory ids = new uint256[](2);
        ids[0] = 3;
        ids[1] = 4;

        MockedERC1155A.mint(alice, ids[0], THOUSAND_E18, "");
        MockedERC1155A.mint(alice, ids[1], THOUSAND_E18, "");

        aERC20 aERC20Token1 = aERC20(MockedERC1155A.registerAERC20(ids[0]));
        aERC20 aERC20Token2 = aERC20(MockedERC1155A.registerAERC20(ids[1]));

        vm.stopPrank();
        vm.startPrank(alice);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = THOUSAND_E18;
        amounts[1] = THOUSAND_E18;

        MockedERC1155A.transmuteBatchToERC20(alice, ids, amounts);

        assertEq(MockedERC1155A.balanceOf(alice, ids[0]), 0);
        assertEq(MockedERC1155A.balanceOf(alice, ids[1]), 0);

        assertEq(aERC20Token1.balanceOf(alice), THOUSAND_E18);
        assertEq(aERC20Token2.balanceOf(alice), THOUSAND_E18);

        /// NOTE: Test if 1:1 between 1155 and 20 always holds
        MockedERC1155A.transmuteBatchToERC1155A(alice, ids, amounts);

        assertEq(MockedERC1155A.balanceOf(alice, ids[0]), THOUSAND_E18);
        assertEq(MockedERC1155A.balanceOf(alice, ids[1]), THOUSAND_E18);

        assertEq(aERC20Token1.balanceOf(address(alice)), 0);
        assertEq(aERC20Token2.balanceOf(address(alice)), 0);
        vm.stopPrank();
    }

    function testAERC20CreationBatchSetApproveForMany() public {
        vm.startPrank(deployer);
        uint256[] memory ids = new uint256[](2);
        ids[0] = 3;
        ids[1] = 4;

        MockedERC1155A.mint(alice, ids[0], THOUSAND_E18, "");
        MockedERC1155A.mint(alice, ids[1], THOUSAND_E18, "");

        aERC20 aERC20Token1 = aERC20(MockedERC1155A.registerAERC20(ids[0]));
        aERC20 aERC20Token2 = aERC20(MockedERC1155A.registerAERC20(ids[1]));

        vm.stopPrank();

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = THOUSAND_E18;
        amounts[1] = THOUSAND_E18;
        vm.prank(alice);

        MockedERC1155A.setApprovalForMany(bob, ids, amounts);

        vm.prank(bob);

        MockedERC1155A.transmuteBatchToERC20(alice, ids, amounts);
        vm.startPrank(alice);

        assertEq(MockedERC1155A.balanceOf(alice, ids[0]), 0);
        assertEq(MockedERC1155A.balanceOf(alice, ids[1]), 0);
        assertEq(MockedERC1155A.allowance(alice, address(MockedERC1155A), ids[0]), 0);
        assertEq(MockedERC1155A.allowance(alice, address(MockedERC1155A), ids[1]), 0);

        assertEq(aERC20Token1.balanceOf(alice), THOUSAND_E18);
        assertEq(aERC20Token2.balanceOf(alice), THOUSAND_E18);

        aERC20Token1.approve(bob, aERC20Token1.balanceOf(alice));
        aERC20Token2.approve(bob, aERC20Token2.balanceOf(alice));
        vm.stopPrank();

        vm.prank(bob);
        /// NOTE: Test if 1:1 between 1155 and 20 always holds
        MockedERC1155A.transmuteBatchToERC1155A(alice, ids, amounts);

        assertEq(MockedERC1155A.balanceOf(alice, ids[0]), THOUSAND_E18);
        assertEq(MockedERC1155A.balanceOf(alice, ids[1]), THOUSAND_E18);

        assertEq(aERC20Token1.balanceOf(address(alice)), 0);
        assertEq(aERC20Token2.balanceOf(address(alice)), 0);
    }

    function testAERC20CreationBatchSetApproveForManyNotMade() public {
        vm.startPrank(deployer);
        uint256[] memory ids = new uint256[](2);
        ids[0] = 3;
        ids[1] = 4;

        MockedERC1155A.mint(alice, ids[0], THOUSAND_E18, "");
        MockedERC1155A.mint(alice, ids[1], THOUSAND_E18, "");

        aERC20 aERC20Token1 = aERC20(MockedERC1155A.registerAERC20(ids[0]));
        aERC20 aERC20Token2 = aERC20(MockedERC1155A.registerAERC20(ids[1]));

        vm.stopPrank();

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = THOUSAND_E18;
        amounts[1] = THOUSAND_E18;
        vm.prank(alice);

        MockedERC1155A.setApprovalForMany(bob, ids, amounts);

        vm.prank(bob);

        MockedERC1155A.transmuteBatchToERC20(alice, ids, amounts);
        vm.startPrank(alice);

        assertEq(MockedERC1155A.balanceOf(alice, ids[0]), 0);
        assertEq(MockedERC1155A.balanceOf(alice, ids[1]), 0);
        assertEq(MockedERC1155A.allowance(alice, address(MockedERC1155A), ids[0]), 0);
        assertEq(MockedERC1155A.allowance(alice, address(MockedERC1155A), ids[1]), 0);

        assertEq(aERC20Token1.balanceOf(alice), THOUSAND_E18);
        assertEq(aERC20Token2.balanceOf(alice), THOUSAND_E18);

        vm.stopPrank();
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, bob, 0, THOUSAND_E18));
        /// NOTE: Test if 1:1 between 1155 and 20 always holds
        MockedERC1155A.transmuteBatchToERC1155A(alice, ids, amounts);
    }

    function testAERC20CreationrAlreadyRegistered() public {
        vm.prank(deployer);
        aERC20 aERC20Token = aERC20(MockedERC1155A.registerAERC20(1));

        vm.prank(deployer);
        vm.expectRevert(IERC1155A.AERC20_ALREADY_REGISTERED.selector);
        aERC20Token = aERC20(MockedERC1155A.registerAERC20(1));
    }
}
