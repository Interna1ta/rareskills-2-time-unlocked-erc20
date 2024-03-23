// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {MyERC20} from "../src/MyERC20.sol";
import {TimeUnlockedERC20} from "../src/TimeUnlockedERC20.sol";

contract TimeUnlockedERC20Test is Test {
    MyERC20 public erc20;
    TimeUnlockedERC20 public timeUnlockedERC20;
    uint256 public constant NUM_SECONDS_ONE_DAY = 86_400;
    address public OWNER = makeAddr("OWNER");
    function setUp() public {
        erc20 = new MyERC20();
        timeUnlockedERC20 = new TimeUnlockedERC20();
    }

    function testCreateDeposit(uint256 depositAmount) public {
        vm.startPrank(OWNER);
        vm.assume(depositAmount < 100_000_000 && depositAmount > 0);
        erc20.mint(OWNER, depositAmount);
        erc20.approve(address(timeUnlockedERC20), depositAmount);
        uint8 decimals = erc20.decimals();
        timeUnlockedERC20.createDeposit(OWNER, address(erc20), depositAmount);
        (uint256 amount, ) = timeUnlockedERC20.s_userToTokenToDeposit(
            OWNER,
            address(erc20)
        );
        assertEq(amount, multiplyByDecimals(decimals, depositAmount));
        vm.stopPrank();
    }

    function testWithdraw(uint256 amount) public {
        vm.assume(amount < 100_000_000 && amount > 0);
        vm.startPrank(OWNER);
        erc20.mint(OWNER, amount);
        erc20.approve(address(timeUnlockedERC20), amount);
        uint256 beforeDepositTimestamp = block.timestamp;
        timeUnlockedERC20.createDeposit(OWNER, address(erc20), amount);
        vm.warp(beforeDepositTimestamp + 1);
        (
            uint256 amountBeforeWithdraw,
            uint256 depositTimestamp
        ) = timeUnlockedERC20.s_userToTokenToDeposit(OWNER, address(erc20));

        uint256 expectedAmount = amountBeforeWithdraw -
            (amountBeforeWithdraw /
                ((block.timestamp - depositTimestamp)) /
                NUM_SECONDS_ONE_DAY);

        timeUnlockedERC20.withdraw(address(erc20));

        (uint256 actualAmount, ) = timeUnlockedERC20.s_userToTokenToDeposit(
            OWNER,
            address(erc20)
        );

        assertEq(expectedAmount, actualAmount);
        vm.stopPrank();
    }

    function multiplyByDecimals(
        uint8 _decimals,
        uint256 _amount
    ) internal pure returns (uint256) {
        return _amount * (10 ** _decimals);
    }
}
