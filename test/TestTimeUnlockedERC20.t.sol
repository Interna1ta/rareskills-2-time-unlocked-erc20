// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {MyERC20} from "../src/MyERC20.sol";
import {TimeUnlockedERC20} from "../src/TimeUnlockedERC20.sol";

contract TimeUnlockedERC20Test is Test {
    MyERC20 public erc20;
    TimeUnlockedERC20 public timeUnlockedERC20;
    address public OWNER = makeAddr("OWNER");
    function setUp() public {
        vm.prank(OWNER);
        erc20 = new MyERC20();

        timeUnlockedERC20 = new TimeUnlockedERC20();
    }

    function testcreateDeposit() public {
        vm.startPrank(OWNER);
        erc20.mint(OWNER, 100);
        erc20.approve(address(timeUnlockedERC20), 100);
        uint8 decimals = erc20.decimals();
        timeUnlockedERC20.createDeposit(OWNER, address(erc20), 100);
        (uint256 amount, ) = timeUnlockedERC20.s_userToTokenToDeposit(
            OWNER,
            address(erc20)
        );
        assertEq(amount, multiplyByDecimals(decimals, 100));
    }

    function testwithdraw() public {
        vm.startPrank(OWNER);
        erc20.mint(OWNER, 100);
        erc20.approve(address(timeUnlockedERC20), 1000);
        uint8 decimals = erc20.decimals();
        uint256 beforeDepositTimestamp = block.timestamp;
        timeUnlockedERC20.createDeposit(OWNER, address(erc20), 100);
        vm.warp(beforeDepositTimestamp + 1);
        timeUnlockedERC20.withdraw(address(erc20));
        (uint256 amount, ) = timeUnlockedERC20.s_userToTokenToDeposit(
            OWNER,
            address(erc20)
        );
        assert(amount <= multiplyByDecimals(decimals, 100));
    }
    
    function multiplyByDecimals(
        uint8 _decimals,
        uint256 _amount
    ) internal pure returns (uint256) {
        return _amount * (10 ** _decimals);
    }
}
