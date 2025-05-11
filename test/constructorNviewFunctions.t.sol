// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "forge-std/Test.sol";
import "../src/EscrowSmartContract.sol";

contract EscrowConstructorTest is Test {
    Escrow public escrow;
    address public admin;
    address public participant1;
    address public participant2;
    
    function setUp() public {
        admin = address(this);
        escrow = new Escrow();

        participant1 = address(0x1);
        participant2 = address(0x2);
        
        vm.deal(participant1, 100 ether);
        vm.deal(participant2, 100 ether);
        
        escrow = new Escrow();
        
        // Add participants to whitelist
        address[] memory participants = new address[](2);
        participants[0] = participant1;
        participants[1] = participant2;
        escrow.addParticipants(participants);
        
        // Deposit some funds
        vm.prank(participant1);
        escrow.depositFunds{value: 5 ether}();
    }
    
    function testConstructor() public {
        assertEq(escrow.admin(), admin);
    }
    
    
    function testGetParticipant() public {
        uint256 participantId = escrow.getParticipantId(participant1);
        assertEq(escrow.getParticipant(participantId), participant1);
    }
    
    function testGetParticipantId() public {
        uint256 participantId = escrow.getParticipantId(participant1);
        assertTrue(participantId > 0);
    }
    
    function testGetBalance() public {
        assertEq(escrow.getBalance(participant1), 5 ether);
        assertEq(escrow.getBalance(participant2), 0);
    }
    
    function testGetContractBalance() public {
        assertEq(escrow.getContractBalance(), 5 ether);
    }
}