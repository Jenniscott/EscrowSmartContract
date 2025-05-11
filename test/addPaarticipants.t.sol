// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "forge-std/Test.sol";
import "../src/EscrowSmartContract.sol";

contract EscrowAddParticipantsTest is Test {
    Escrow public escrow;
    address public admin;
    address public participant1;
    address public participant2;
    address public nonWhitelisted;

     mapping(address => bool) seen;
    event Whitelisted(address indexed participant, uint256 participantId);
    event BatchWhitelisted(uint256 count);
    
    function setUp() public {
        admin = address(this);
        participant1 = address(0x1);
        participant2 = address(0x2);
        nonWhitelisted = address(0x3);
        
        escrow = new Escrow();
    }
    
    function testAddParticipants() public {
        address[] memory newParticipants = new address[](2);
        newParticipants[0] = participant1;
        newParticipants[1] = participant2;
        
        uint256 initialCount = escrow.participantCount();
        
        vm.expectEmit(true, false, false, true);
        emit Whitelisted(participant1, initialCount + 1);
        
        vm.expectEmit(true, false, false, true);
        emit Whitelisted(participant2, initialCount + 2);
        
        vm.expectEmit(false, false, false, true);
        emit BatchWhitelisted(2);
        
        escrow.addParticipants(newParticipants);
        
        assertTrue(escrow.whitelist(participant1));
        assertTrue(escrow.whitelist(participant2));
        assertEq(escrow.participantCount(), initialCount + 2);
        assertEq(escrow.participantIds(initialCount + 1), participant1);
        assertEq(escrow.participantIds(initialCount + 2), participant2);
        assertEq(escrow.participantIdsByAddress(participant1), initialCount + 1);
        assertEq(escrow.participantIdsByAddress(participant2), initialCount + 2);
    }
    
    function testAddParticipantsNoDuplicates() public {
        // First add a participant
        address[] memory newParticipants = new address[](1);
        newParticipants[0] = participant1;
        escrow.addParticipants(newParticipants);
        
        uint256 initialCount = escrow.participantCount();
        
        // Try to add the same participant again
        escrow.addParticipants(newParticipants);
        
        // Check that the count didn't increase
        assertEq(escrow.participantCount(), initialCount);
    }
    
    function testAddParticipantsNonAdmin() public {
        address[] memory newParticipants = new address[](1);
        newParticipants[0] = nonWhitelisted;
        
        vm.prank(participant1);
        vm.expectRevert("Only admin can perform this action");
        escrow.addParticipants(newParticipants);
    }
    
     function testFuzz_AddParticipants(address[] calldata _participants) public {
        // Filter out zero addresses
        address[] memory filteredParticipants = new address[](_participants.length);
        uint256 filteredCount = 0;
        
        for (uint256 i = 0; i < _participants.length; i++) {
            if (_participants[i] != address(0)) {
                filteredParticipants[filteredCount] = _participants[i];
                filteredCount++;
            }
        }
        
        // Create a new array with the filtered addresses
        address[] memory validParticipants = new address[](filteredCount);
        for (uint256 i = 0; i < filteredCount; i++) {
            validParticipants[i] = filteredParticipants[i];
        }
        
        uint256 initialCount = escrow.participantCount();
        escrow.addParticipants(validParticipants);
        
        // Count unique participants
      
        uint256 uniqueCount = 0;
        
        for (uint256 i = 0; i < validParticipants.length; i++) {
            if (!seen[validParticipants[i]]) {
                seen[validParticipants[i]] = true;
                uniqueCount++;
            }
        }
        
        // Check that the count increased correctly
        assertLe(escrow.participantCount(), initialCount + uniqueCount);
    }
}