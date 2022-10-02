// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../src/ERC1155s.sol";

contract ERC1155s__Test is Test {
    ERC1155s public SuperShares;


    function setUp() public {
       SuperShares = new ERC1155s();
    }

    function testSafeTransferFrom() public {
        // counter.increment();
        // assertEq(counter.number(), 1);
    }

}
