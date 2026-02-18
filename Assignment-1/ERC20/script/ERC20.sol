// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.33;

import {Script} from "forge-std/Script.sol";
import {ERC20} from "../src/ERC20.sol";

contract ERC20Script is Script {
    ERC20 public erc20;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        erc20 = new ERC20();

        vm.stopBroadcast();
    }
}
