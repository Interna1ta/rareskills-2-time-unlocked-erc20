// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ERC20} from "../src/ERC20.sol";

contract CounterTest is Test {
    ERC20 public erc20;

    function setUp() public {
        erc20 = new ERC20();
    }

    function testDeposit() public {
        erc20.increment();
        assertEq(erc20.number(), 1);
    }

    function testWithdraw() public {
        erc20.setNumber(x);
        assertEq(erc20.number(), x);
    }
}
