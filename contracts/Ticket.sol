// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Ticket is ERC721URIStorage, AccessControl, ReentrancyGuard {
    // Roles
    bytes32 public constant MANAGEMENT_ROLE = keccak256("MANAGEMENT_ROLE");
    

    // Ticket structure
    enum TicketType { Daily, Weekly, Monthly, Quarterly }

    struct Ticket {
        uint256 id;
        TicketType ticketType;
        uint256 expiration;
        uint256 price;
        address owner;
    }



    // State variables
    uint256 public nextTicketId;
    mapping(uint256 => Ticket) public tickets; // ticketId -> Ticket
    mapping(TicketType => uint256) public ticketPrices; // TicketType -> Price
    mapping(TicketType => uint256) public ticketDurations; // TicketType -> Duration
    
    address public Admin;

    // Events
    event TicketPurchased(address indexed customer, uint256 ticketId, TicketType ticketType);
    event TicketPriceUpdated(TicketType ticketType, uint256 newPrice);
    event TicketDurationUpdated(TicketType ticketType, uint256 newDuration);
    event FundsWithdrawn(address indexed management, uint256 amount);

    constructor() ERC721("BusTicket", "BTKT") {
        Admin = msg.sender;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MANAGEMENT_ROLE, msg.sender);

        // Set initial prices and durations
        ticketPrices[TicketType.Daily] = 0.0001 ether;
        ticketPrices[TicketType.Weekly] = 0.0005 ether;
        ticketPrices[TicketType.Monthly] = 0.0018 ether;
        ticketPrices[TicketType.Quarterly] = 0.005 ether;

        ticketDurations[TicketType.Daily] = 1 days;
        ticketDurations[TicketType.Weekly] = 7 days;
        ticketDurations[TicketType.Monthly] = 30 days;
        ticketDurations[TicketType.Quarterly] = 90 days;
    }

    // Purchase ticket

    function purchaseTicket(TicketType ticketType) external payable nonReentrant {
        uint256 price = ticketPrices[ticketType];
        require(msg.value >= price, "Insufficient payment");

        uint256 expiration = block.timestamp + ticketDurations[ticketType];
        uint256 ticketId = nextTicketId++;

        tickets[ticketId] = Ticket({
            id: ticketId,
            ticketType: ticketType,
            expiration: expiration,
            price: price,
            owner: msg.sender
        });

        _safeMint(msg.sender, ticketId);
        _setTokenURI(ticketId, generateTicketMetadata(ticketId, ticketType, expiration));

        emit TicketPurchased(msg.sender, ticketId, ticketType);
    }

    // Update ticket price (Management only)
    function updateTicketPrice(TicketType ticketType, uint256 newPrice) external onlyRole(MANAGEMENT_ROLE) {
        ticketPrices[ticketType] = newPrice;
        emit TicketPriceUpdated(ticketType, newPrice);
    }

    // Update ticket duration (Management only)
    function updateTicketDuration(TicketType ticketType, uint256 newDuration) external onlyRole(MANAGEMENT_ROLE) {
        ticketDurations[ticketType] = newDuration;
        emit TicketDurationUpdated(ticketType, newDuration);
    }

    // Withdraw funds (Management only)
    function withdrawFunds() external onlyRole(MANAGEMENT_ROLE) nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        payable(msg.sender).transfer(balance);
        emit FundsWithdrawn(msg.sender, balance);
    }

    // Check ticket validity
    function isTicketValid(uint256 ticketId) external view returns (bool) {
        Ticket memory ticket = tickets[ticketId];
        require(ticket.owner == msg.sender, "Not the owner of this ticket");
        return block.timestamp <= ticket.expiration;
    }

   function refundAmount(uint256 ticketId) external nonReentrant {
    Ticket storage ticket = tickets[ticketId];
    
    
    require(ticket.owner == msg.sender, "You are not the owner of this ticket");

    
    require(block.timestamp <= ticket.expiration, "Ticket has already expired");

    
    uint256 remainingTime = ticket.expiration - block.timestamp;
    uint256 totalDuration = ticketDurations[ticket.ticketType];
    uint256 refund = (ticket.price * remainingTime) / totalDuration;

    // Prevent double refunds
    require(refund > 0, "No refundable amount remaining");
    ticket.expiration = block.timestamp; // Mark the ticket as expired

    payable(msg.sender).transfer(refund);
}


    // Override supportsInterface for AccessControl
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}