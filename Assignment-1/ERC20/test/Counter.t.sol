// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.33;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "../src/ERC20.sol";

contract ERC20Test is Test {
    ERC20 internal token;

    function setUp() public {
        token = new ERC20();
    }

    function testInitialSupplyMintedToDeployer() public view {
        assertEq(token.balanceOf(address(this)), token.totalSupply());
    }
}
