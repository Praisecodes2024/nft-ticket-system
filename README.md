# Clarity 2.0 Event Ticket Smart Contract

## Overview
This smart contract provides a robust framework for managing event tickets as non-fungible tokens (NFTs) using Clarity 2.0. It supports minting, transferring, burning, and updating metadata of tickets, ensuring security, ownership integrity, and operational flexibility.

## Features
- **NFT-Based Tickets:** Event tickets are represented as NFTs for secure and verifiable ownership.
- **Minting:** Single or batch minting of tickets with unique URIs (metadata).
- **Ownership Management:** Transfer tickets securely between users.
- **Burning Tickets:** Permanently revoke tickets to prevent misuse.
- **Metadata Updates:** Update ticket details with new URIs.
- **Read-Only Queries:** Retrieve ticket URIs, ownership, and status (burned or active).

## Error Handling
Standardized error codes for improved debugging and user feedback:
- `err-owner-only (u100)`: Caller is not the ticket owner.
- `err-not-ticket-owner (u101)`: Caller does not own the ticket.
- `err-ticket-exists (u102)`: Ticket already exists.
- `err-ticket-not-found (u103)`: Ticket not found.
- `err-invalid-uri (u104)`: Provided URI is invalid.
- `err-already-burned (u105)`: Ticket has already been burned.

## Data Structures
- **NFT:** `event-ticket` represents the tickets.
- **Data Variables:**
  - `last-ticket-id`: Tracks the latest issued ticket ID.
  - `ticket-uri`: Maps ticket IDs to URIs for metadata storage.
  - `burned-tickets`: Tracks burned (revoked) tickets.

## Core Functions
### Public Functions
1. **Mint Ticket:**  
   - `mint-ticket(uri)`  
   - Mints a single ticket with the provided metadata URI.
2. **Batch Mint Tickets:**  
   - `batch-mint-tickets(uris)`  
   - Mints up to 100 tickets in a single operation.
3. **Burn Ticket:**  
   - `burn-ticket(ticket-id)`  
   - Revokes a ticket permanently (only by the owner).
4. **Transfer Ticket:**  
   - `transfer-ticket(ticket-id, sender, recipient)`  
   - Transfers ownership to a recipient.
5. **Update Ticket URI:**  
   - `update-ticket-uri(ticket-id, new-uri)`  
   - Updates the metadata URI of the ticket.

### Read-Only Functions
1. **Get Ticket URI:**  
   - `get-ticket-uri(ticket-id)`  
   - Retrieves the metadata URI of a ticket.
2. **Get Owner:**  
   - `get-owner(ticket-id)`  
   - Checks the owner of a ticket.
3. **Get Last Ticket ID:**  
   - `get-last-ticket-id()`  
   - Fetches the most recently issued ticket ID.
4. **Is Burned:**  
   - `is-burned(ticket-id)`  
   - Verifies if a ticket has been burned.

## Deployment and Usage
- Deploy the smart contract on a Clarity 2.0-compatible blockchain.
- Use the provided functions to manage event tickets securely and efficiently.

## Contributing
Contributions are welcome! Please submit issues or pull requests to enhance the contract's functionality or address bugs.

## License
This project is licensed under the MIT License. See the LICENSE file for details.
