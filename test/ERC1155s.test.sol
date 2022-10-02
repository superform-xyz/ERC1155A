// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

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

    function testSetApprovalForOne() public {
        uint256 allowAmount = (THOUSAND_E18 / 2);
        
        vm.prank(alice);
        SuperShares.setApprovalForOne(bob, 1, allowAmount);
        
        uint256 bobAllowance = SuperShares.allowance(alice, bob, 1);
        assertEq(bobAllowance, allowAmount);

        vm.prank(bob);
        SuperShares._safeTransferFrom(alice, bob, 1, bobAllowance, "");
    }

}
