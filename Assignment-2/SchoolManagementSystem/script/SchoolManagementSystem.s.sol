// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {SchoolManagementSystem} from "../src/SchoolManagementSystem.sol";

contract SchoolManagementSystemScript is Script {
    SchoolManagementSystem public schoolManagementSystem;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        schoolManagementSystem = new SchoolManagementSystem();

        vm.stopBroadcast();
    }
}
