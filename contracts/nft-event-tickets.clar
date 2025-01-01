;; This smart contract implements a non-fungible token (NFT)-based event ticketing system. 
;; Key Features:
;; - Minting single or batch event tickets, each uniquely identified and linked to metadata via a URI.
;; - Transferring tickets between users, ensuring only the rightful owner can initiate the transfer.
;; - Burning (revoking) tickets, rendering them non-transferable and marking them as invalid.
;; - Updating ticket metadata while maintaining ownership integrity.
;; - Read-only functions for retrieving ticket details, such as owner, metadata URI, burn status, and the last issued ticket ID.
;; - Comprehensive error handling and validation for secure, robust operations.
;; This contract is built using Clarity and adheres to principles of transparency, immutability, and accountability.


;; Constants for error codes and maximum URI length. These constants help to standardize error handling in the contract.
(define-constant err-owner-only (err u100))               ;; Error if the caller is not the ticket owner
(define-constant err-not-ticket-owner (err u101))          ;; Error if the caller is not the ticket owner
(define-constant err-ticket-exists (err u102))             ;; Error if the ticket already exists
(define-constant err-ticket-not-found (err u103))          ;; Error if the ticket cannot be found
(define-constant err-invalid-uri (err u104))              ;; Error if the URI provided is invalid
(define-constant err-already-burned (err u105))           ;; Error if the ticket has already been burned
(define-constant max-uri-length u256)                     ;; Maximum allowed length for URI

;; Data Variables
(define-non-fungible-token event-ticket uint)            ;; NFT token representing unique event tickets
(define-data-var last-ticket-id uint u0)                   ;; Tracks the latest ticket ID issued

;; Maps to store ticket URIs and burned ticket status.
(define-map ticket-uri uint (string-ascii 256))            ;; Map ticket ID to its URI (metadata of the ticket)
(define-map burned-tickets uint bool)                      ;; Track if a ticket has been burned (revoked)

;; Private Helper Functions

;; Checks if a URI is valid by confirming its length is within the allowed range.
;; Returns true if valid, false otherwise.
(define-private (is-valid-uri (uri (string-ascii 256)))
    (let ((uri-length (len uri)))
        (and (>= uri-length u1) (<= uri-length max-uri-length))))

;; Verifies whether the sender is the owner of the specified ticket.
;; Returns true if the sender owns the ticket, false otherwise.
(define-private (is-ticket-owner (ticket-id uint) (sender principal))
    (is-eq sender (unwrap! (nft-get-owner? event-ticket ticket-id) false)))

;; Checks if a ticket is burned by looking it up in the burned-tickets map.
;; Returns true if burned, false otherwise.
(define-private (is-ticket-burned (ticket-id uint))
    (default-to false (map-get? burned-tickets ticket-id)))

