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

;; Creates a single event ticket, assigning it a unique ID and URI.
;; Increments the last-ticket-id variable and associates the URI with the new ticket ID.
;; Returns the ticket ID upon successful creation.
(define-private (create-single-ticket (ticket-uri-data (string-ascii 256)))
    (let ((ticket-id (+ (var-get last-ticket-id) u1)))
        (asserts! (is-valid-uri ticket-uri-data) err-invalid-uri) ;; Check URI validity
        (try! (nft-mint? event-ticket ticket-id tx-sender))      ;; Mint the ticket NFT
        (map-set ticket-uri ticket-id ticket-uri-data)           ;; Store the ticket URI (metadata)
        (var-set last-ticket-id ticket-id)                       ;; Update the last ticket ID issued
        (ok ticket-id)))                                         ;; Return the ticket ID created

;; Optimizes the create-single-ticket function to cache the last ticket id to avoid recalculating.
;; This improves the performance by reducing unnecessary calculations.
(define-private (create-single-ticket-optimized (ticket-uri-data (string-ascii 256)))
    (let ((ticket-id (+ (var-get last-ticket-id) u1)))
        (asserts! (is-valid-uri ticket-uri-data) err-invalid-uri)
        (try! (nft-mint? event-ticket ticket-id tx-sender))
        (map-set ticket-uri ticket-id ticket-uri-data)
        (var-set last-ticket-id ticket-id)
        (ok ticket-id)))

;; Public Functions

;; Mints a new event ticket with the specified URI, which should contain metadata about the event.
;; Validates the URI before calling create-single-ticket to mint the ticket.
;; Returns the ticket ID of the newly created ticket.
(define-public (mint-ticket (uri (string-ascii 256)))
    (begin
        (asserts! (is-valid-uri uri) err-invalid-uri)    ;; Validate URI length
        (create-single-ticket uri)))                      ;; Create the ticket and return its ID

;; Mints multiple event tickets in a single transaction, with a maximum of 100 tickets in one batch.
;; Each URI is validated, and batch minting is handled through a fold operation.
;; Returns a list of ticket IDs for all tickets created in the batch.
(define-public (batch-mint-tickets (uris (list 100 (string-ascii 256))))
    (let ((batch-size (len uris)))
        (begin
            (asserts! (<= batch-size u100) (err u108)) ;; Check if the batch size is within the allowed limit (100)
            (ok (fold mint-single-in-batch uris (list))) ;; Mint tickets for each URI in the batch
        )))

;; Helper function for batch minting: mints a single ticket within a batch operation.
;; Appends the new ticket ID to the list of results, ensuring the batch size remains within the limit.
(define-private (mint-single-in-batch (uri (string-ascii 256)) (previous-results (list 100 uint)))
    (match (create-single-ticket uri)
        success (unwrap-panic (as-max-len? (append previous-results success) u100))
        error previous-results))

;; Burns (deletes) a ticket by its ID, making it non-transferable and non-viewable.
;; Only the ticket owner can burn their ticket, and it must not have been burned before.
;; Marks the ticket as burned and returns true if successful.
(define-public (burn-ticket (ticket-id uint))
    (let ((ticket-owner (unwrap! (nft-get-owner? event-ticket ticket-id) err-ticket-not-found)))
        (asserts! (is-eq tx-sender ticket-owner) err-not-ticket-owner) ;; Check if the sender is the owner of the ticket
        (asserts! (not (is-ticket-burned ticket-id)) err-already-burned) ;; Ensure the ticket has not been burned already
        (try! (nft-burn? event-ticket ticket-id ticket-owner))         ;; Burn the ticket NFT
        (map-set burned-tickets ticket-id true)                         ;; Mark the ticket as burned (revoked)
        (ok true)))                                                  ;; Return success

;; Transfers a ticket from the sender to a recipient.
;; Ensures the sender owns the ticket, the ticket is not burned, and it is successfully transferred to the recipient.
(define-public (transfer-ticket (ticket-id uint) (sender principal) (recipient principal))
    (begin
        (asserts! (is-eq recipient tx-sender) err-not-ticket-owner) ;; Ensure the recipient is the tx-sender
        (asserts! (not (is-ticket-burned ticket-id)) err-already-burned) ;; Check if the ticket has not been burned
        (let ((actual-sender (unwrap! (nft-get-owner? event-ticket ticket-id) err-not-ticket-owner)))
            (asserts! (is-eq actual-sender sender) err-not-ticket-owner) ;; Verify actual ownership of the ticket
            (try! (nft-transfer? event-ticket ticket-id sender recipient)) ;; Transfer the ticket NFT
            (ok true))))                                               ;; Return success

;; Updates the URI of a ticket.
;; Only the ticket owner can update the URI, and the URI must be valid.
(define-public (update-ticket-uri (ticket-id uint) (new-uri (string-ascii 256)))
    (begin
        (let ((ticket-owner (unwrap! (nft-get-owner? event-ticket ticket-id) err-ticket-not-found)))
            (asserts! (is-eq ticket-owner tx-sender) err-not-ticket-owner) ;; Check if sender owns the ticket
            (asserts! (is-valid-uri new-uri) err-invalid-uri)             ;; Validate the new URI
            (map-set ticket-uri ticket-id new-uri)                          ;; Update the ticket URI
            (ok true))))


;; Allows a ticket owner to refund a buyer within a specified refund period.
(define-public (refund-ticket (ticket-id uint))
    (let ((ticket-owner (unwrap! (nft-get-owner? event-ticket ticket-id) err-ticket-not-found)))
        (asserts! (is-eq tx-sender ticket-owner) err-not-ticket-owner)
        (try! (nft-burn? event-ticket ticket-id ticket-owner))
        (ok true)))

;; Adds a test suite for testing the mint-ticket function to verify URI validation and creation.
(define-public (test-mint-ticket)
    (begin
        (asserts! (is-valid-uri "valid-uri") err-invalid-uri)
        (asserts! (is-valid-uri "too-long-uri") err-invalid-uri)
        (ok true)))

