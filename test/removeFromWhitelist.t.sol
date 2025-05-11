// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "forge-std/Test.sol";
import "../src/EscrowSmartContract.sol";

contract EscrowRemoveFromWhitelistTest is Test {
    Escrow public escrow;
    address public admin;
    address public participant1;
    address public participant2;
    address public nonWhitelisted;
    
    event RemovedFromWhitelist(address indexed participant);
    
    function setUp() public {
        admin = address(this);
        participant1 = address(0x1);
        participant2 = address(0x2);
        nonWhitelisted = address(0x3);
        
        escrow = new Escrow();
        
        // Add participants to whitelist
        address[] memory participants = new address[](2);
        participants[0] = participant1;
        participants[1] = participant2;
        escrow.addParticipants(participants);
    }
    
    function testRemoveFromWhitelist() public {
        assertTrue(escrow.whitelist(participant1));
        
        vm.expectEmit(true, false, false, false);
        emit RemovedFromWhitelist(participant1);
        
        escrow.removeFromWhitelist(participant1);
        
        assertFalse(escrow.whitelist(participant1));
    }
    
    function testRemoveFromWhitelistNonAdmin() public {
        vm.prank(participant1);
        vm.expectRevert("Only admin can perform this action");
        escrow.removeFromWhitelist(participant2);
    }
    
    function testRemoveNonWhitelistedAddress() public {
        vm.expectRevert("Address not whitelisted");
        escrow.removeFromWhitelist(nonWhitelisted);
    }
    
    function testFuzz_RemoveFromWhitelist(address _participant) public {
        // Skip if address is zero
        vm.assume(_participant != address(0));
        
        // Add the participant to whitelist first
        address[] memory newParticipants = new address[](1);
        newParticipants[0] = _participant;
        escrow.addParticipants(newParticipants);
        
        // Now remove from whitelist
        escrow.removeFromWhitelist(_participant);
        
        assertFalse(escrow.whitelist(_participant));
    }
}