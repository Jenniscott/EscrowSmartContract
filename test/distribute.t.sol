// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "forge-std/Test.sol";
import "../src/EscrowSmartContract.sol";

contract EscrowDistributeTest is Test {
    Escrow public escrow;
    address public admin;
    address public participant1;
    address public participant2;
    address public nonWhitelisted;
    
    event Distribution(uint256 indexed participantId, address indexed participant, uint256 amount);
    
    function setUp() public {
        admin = address(this);
        participant1 = address(0x1);
        participant2 = address(0x2);
        nonWhitelisted = address(0x3);
        
        vm.deal(admin, 100 ether);
        vm.deal(participant1, 100 ether);
        vm.deal(participant2, 100 ether);
        
        escrow = new Escrow();
        
        // Add participants to whitelist
        address[] memory participants = new address[](2);
        participants[0] = participant1;
        participants[1] = participant2;
        escrow.addParticipants(participants);
        
        // Deposit funds to contract
        vm.prank(participant1);
        escrow.depositFunds{value: 10 ether}();
    }
    
    function testDistribute() public {
        uint256 participantId = escrow.getParticipantId(participant1);
        address participant = escrow.getParticipant(participantId);
        uint256 initialBalance = participant.balance;
        
        vm.expectEmit(true, true, false, true);
        emit Distribution(participantId, participant, 2 ether);
        
        escrow.distribute(participantId, 2 ether);
        
        assertEq(participant.balance, initialBalance + 2 ether);
        assertEq(address(escrow).balance, 8 ether);
    }
    
    function testDistributeInvalidId() public {
        uint256 invalidId = 999;
        
        vm.expectRevert("Invalid participant ID");
        escrow.distribute(invalidId, 1 ether);
    }
    
    function testDistributeZeroAmount() public {
        uint256 participantId = escrow.getParticipantId(participant1);
        
        vm.expectRevert("Distribution amount must be greater than 0");
        escrow.distribute(participantId, 0);
    }
    
    function testDistributeInsufficientBalance() public {
        uint256 participantId = escrow.getParticipantId(participant1);
        
        vm.expectRevert("Insufficient contract balance");
        escrow.distribute(participantId, 20 ether);
    }
    
    function testDistributeNonAdmin() public {
        uint256 participantId = escrow.getParticipantId(participant1);
        
        vm.prank(participant1);
        vm.expectRevert("Only admin can perform this action");
        escrow.distribute(participantId, 1 ether);
    }
    
    function testFuzz_Distribute(uint256 amount) public {
        // Bound the amount to avoid overflow and ensure it's greater than 0
        // but less than the deposited amount (10 ether)
        amount = bound(amount, 1, 5 ether);
        
        uint256 participantId = escrow.getParticipantId(participant1);
        address participant = escrow.getParticipant(participantId);
        uint256 initialBalance = participant.balance;
        uint256 initialContractBalance = address(escrow).balance;
        
        escrow.distribute(participantId, amount);
        
        assertEq(participant.balance, initialBalance + amount);
        assertEq(address(escrow).balance, initialContractBalance - amount);
    }
}