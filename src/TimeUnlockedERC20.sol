// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.21;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error TimeUnlockedERC20__AmountNotEnough(string message);
error TimeUnlockedERC20__WithoutDeposit(string message);
error TimeUnlockedERC20__NotEnoughMoney(string message);
error TimeUnlockedERC20__DepositFailed(string message);
error TimeUnlockedERC20__PaymentFailed(string message);

contract TimeUnlockedERC20 {
    mapping(address => mapping(address => Deposit))
        public s_userToTokenToDeposit;
    uint256 public constant NUM_SECONDS_ONE_DAY = 86_400;

    struct Deposit {
        uint256 amount;
        uint256 timestamp;
    }

    event DepositCreated(
        address indexed receiver,
        address token,
        uint256 amount,
        uint256 timestamp
    );
    event DepositWithdrawn(
        address indexed receiver,
        address token,
        uint256 amount,
        uint256 timestamp
    );

    function createDeposit(
        address _receiver,
        address _token,
        uint256 _amount
    ) external payable {
        if (_amount <= 0) {
            revert TimeUnlockedERC20__AmountNotEnough(
                "Amount must be greater than 0"
            );
        }

        bool ok = transferMoney(msg.sender, address(this), _amount, _token);

        if (!ok) {
            revert TimeUnlockedERC20__DepositFailed("Deposit failed");
        }

        s_userToTokenToDeposit[_receiver][_token].amount += _amount;
        s_userToTokenToDeposit[_receiver][_token].timestamp = block.timestamp;

        emit DepositCreated(_receiver, _token, _amount, block.timestamp);
    }

    function withdraw(address _token) public {
        if (s_userToTokenToDeposit[msg.sender][_token].amount == 0) {
            revert TimeUnlockedERC20__WithoutDeposit(
                "You don't have a deposit"
            );
        }

        uint256 timePassed = (block.timestamp -
            s_userToTokenToDeposit[msg.sender][_token].timestamp) /
            NUM_SECONDS_ONE_DAY;
        uint256 amountToWithdraw = s_userToTokenToDeposit[msg.sender][_token]
            .amount / timePassed;

        if (
            s_userToTokenToDeposit[msg.sender][_token].amount < amountToWithdraw
        ) {
            revert TimeUnlockedERC20__NotEnoughMoney(
                "You have no enough money to withdraw"
            );
        }

        bool ok = transferMoney(
            address(this),
            msg.sender,
            amountToWithdraw,
            _token
        );

        if (!ok) {
            revert TimeUnlockedERC20__PaymentFailed("Payment failed");
        }

        s_userToTokenToDeposit[msg.sender][_token].amount -= amountToWithdraw;

        emit DepositWithdrawn(
            msg.sender,
            _token,
            amountToWithdraw,
            block.timestamp
        );
    }

    function transferMoney(
        address _from,
        address _to,
        uint256 _amountToWithdraw,
        address _token
    ) private returns (bool ok) {
        try IERC20(_token).transferFrom(_from, _to, _amountToWithdraw) returns (
            bool
        ) {
            return true;
        } catch {
            return false;
        }
    }
}
