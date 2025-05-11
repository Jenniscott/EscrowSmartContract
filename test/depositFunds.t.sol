// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "forge-std/Test.sol";
import "../src/EscrowSmartContract.sol";

contract EscrowDepositFundsTest is Test {
    Escrow public escrow;
    address public admin;
    address public participant1;
    address public participant2;
    address public nonWhitelisted;
    
    event Deposit(address indexed participant, uint256 amount);
    
    function setUp() public {
        admin = address(this);
        participant1 = address(0x1);
        participant2 = address(0x2);
        nonWhitelisted = address(0x3);
        
        vm.deal(participant1, 100 ether);
        vm.deal(participant2, 100 ether);
        vm.deal(nonWhitelisted, 100 ether);
        
        escrow = new Escrow();
        
        // Add participants to whitelist
        address[] memory participants = new address[](2);
        participants[0] = participant1;
        participants[1] = participant2;
        escrow.addParticipants(participants);
    }
    
    function testDepositFunds() public {
        vm.prank(participant1);
        
        vm.expectEmit(true, false, false, true);
        emit Deposit(participant1, 1 ether);
        
        escrow.depositFunds{value: 1 ether}();
        
        assertEq(escrow.balances(participant1), 1 ether);
        assertEq(address(escrow).balance, 1 ether);
    }
    
    function testDepositFundsZeroAmount() public {
        vm.prank(participant1);
        
        vm.expectRevert("Deposit amount must be greater than 0");
        escrow.depositFunds{value: 0}();
    }
    
    function testDepositFundsNonWhitelisted() public {
        vm.prank(nonWhitelisted);
        
        vm.expectRevert("Address not whitelisted");
        escrow.depositFunds{value: 1 ether}();
    }
    
    function testFuzz_DepositFunds(uint256 amount) public {
        // Bound the amount to avoid overflow and ensure it's greater than 0
        amount = bound(amount, 1, 50 ether);
        
        vm.deal(participant1, amount);
        vm.prank(participant1);
        
        escrow.depositFunds{value: amount}();
        
        assertEq(escrow.balances(participant1), amount);
        assertEq(address(escrow).balance, amount);
    }
}