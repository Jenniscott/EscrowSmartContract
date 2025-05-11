pragma solidity ^0.8.6;

contract Escrow {
    address public admin;
    mapping(uint256 => address) public participantIds;
    mapping(address => uint256) public participantIdsByAddress;
    mapping(address => uint256) public balances;
    mapping(address => bool) public whitelist;
    uint256 public participantCount;
    
    event Deposit(address indexed participant, uint256 amount);
    event Distribution(uint256 indexed participantId, address indexed participant, uint256 amount);
    event Whitelisted(address indexed participant, uint256 participantId);
    event RemovedFromWhitelist(address indexed participant);
    event BatchWhitelisted(uint256 count);
    event EmergencyWithdraw(address indexed admin, uint256 amount);
    
    constructor() {
        admin = msg.sender;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }
    
    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], "Address not whitelisted");
        _;
    }
    
    function addParticipants(address[] memory _participants) public onlyAdmin {
        for (uint i = 0; i < _participants.length; i++) {
            if (!whitelist[_participants[i]]) {
                participantCount++;
                whitelist[_participants[i]] = true;
                participantIds[participantCount] = _participants[i];
                participantIdsByAddress[_participants[i]] = participantCount;
                emit Whitelisted(_participants[i], participantCount);
            }
        }
        emit BatchWhitelisted(_participants.length);
    }
    
    function removeFromWhitelist(address _participant) public onlyAdmin {
        require(whitelist[_participant], "Address not whitelisted");
        whitelist[_participant] = false;
        emit RemovedFromWhitelist(_participant);
    }
    
    function depositFunds() public payable onlyWhitelisted {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    
    function distribute(uint256 _participantId, uint256 _amount) public onlyAdmin {
        address payable participant = payable(participantIds[_participantId]);
        require(participant != address(0), "Invalid participant ID");
        require(_amount > 0, "Distribution amount must be greater than 0");
        require(_amount <= address(this).balance, "Insufficient contract balance");
        (bool success, ) = participant.call{value: _amount}("");
        require(success, "Transfer failed");
        emit Distribution(_participantId, participant, _amount);
    }
    
    function emergencyWithdraw() public onlyAdmin {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        (bool success, ) = payable(admin).call{value: balance}("");
        require(success, "Transfer failed");
        emit EmergencyWithdraw(admin, balance);
    }
    
    function getParticipant(uint256 _participantId) public view returns (address) {
        return participantIds[_participantId];
    }
    
    function getParticipantId(address _participant) public view returns (uint256) {
        return participantIdsByAddress[_participant];
    }
    
    function getBalance(address _participant) public view returns (uint256) {
        return balances[_participant];
    }
    
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}