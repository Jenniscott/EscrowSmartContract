// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/EscrowSmartContract.sol"; // Adjust path as needed

contract EscrowEmergencyWithdrawTest is Test {
    Escrow public escrow;
    address payable public admin;

     event EmergencyWithdraw(address indexed admin, uint256 amount);

    function setUp() public {
        admin = payable(address(this)); // test contract is the admin
        escrow = new Escrow(); // constructor sets admin = msg.sender
        vm.deal(address(escrow), 1 ether); // fund the contract for the test
    }

    function testEmergencyWithdraw() public {
        uint256 contractBalance = address(escrow).balance;

        // Expect the EmergencyWithdraw event with admin address and contract balance
        vm.expectEmit(true, true, true, true); // true for indexed arguments (admin)
       emit EmergencyWithdraw(admin, contractBalance);

        escrow.emergencyWithdraw();

        assertEq(address(escrow).balance, 0, "Contract should have 0 balance after withdrawal");
        assertEq(address(admin).balance, contractBalance, "Admin should receive full balance");
    }

    function testRevertWhenNoFunds() public {
        // Deploy a new contract with 0 balance
        Escrow freshEscrow = new Escrow();

        // Expect revert with message "No funds to withdraw"
        vm.expectRevert("No funds to withdraw");
        freshEscrow.emergencyWithdraw();
    }

    function testFuzzEmergencyWithdraw(uint96 amount) public {
        // Limit fuzz input to reasonable range to avoid out-of-gas issues
        vm.assume(amount > 0 && amount < 100 ether);

        address freshAdmin = address(0xABCD);
        vm.startPrank(freshAdmin);
        Escrow freshEscrow = new Escrow();
        vm.deal(address(freshEscrow), amount);

        // Expect the EmergencyWithdraw event with the freshAdmin and amount
        vm.expectEmit(true, true, true, true); // true for indexed arguments (admin)
        emit EmergencyWithdraw(freshAdmin, amount);

        freshEscrow.emergencyWithdraw();

        assertEq(address(freshEscrow).balance, 0);
        assertEq(freshAdmin.balance, amount);

        vm.stopPrank();
    }
}
