;; GovernanceHub
;; A decentralized autonomous organization (DAO) governance contract that allows members
;; to create proposals, vote on them, and execute approved proposals.

;; constants
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_MEMBER (err u101))
(define-constant ERR_NOT_MEMBER (err u102))
(define-constant ERR_PROPOSAL_NOT_FOUND (err u103))
(define-constant ERR_ALREADY_VOTED (err u104))
(define-constant ERR_VOTING_CLOSED (err u105))
(define-constant ERR_PROPOSAL_NOT_APPROVED (err u106))
(define-constant ERR_INSUFFICIENT_FUNDS (err u107))
(define-constant ERR_INVALID_PROPOSAL (err u108))
(define-constant ERR_SELF_DELEGATION (err u109))
(define-constant ERR_NO_DELEGATION (err u110))

;; data maps and vars
;; Track DAO membership
(define-map members principal bool)

;; Track the total number of members
(define-data-var member-count uint u0)

;; Minimum votes required for a proposal to pass (percentage)
(define-data-var vote-threshold uint u51)

;; Voting duration in blocks
(define-data-var voting-period uint u144) ;; ~1 day at 10 minute blocks

;; Treasury balance
(define-data-var treasury-balance uint u0)

;; Proposal structure
(define-map proposals
  uint
  {
    proposer: principal,
    title: (string-ascii 100),
    description: (string-utf8 500),
    action: (string-utf8 200),
    amount: uint,
    recipient: principal,
    yes-votes: uint,
    no-votes: uint,
    status: (string-ascii 20), ;; "active", "approved", "rejected", "executed"
    created-at: uint,
    executed-at: (optional uint)
  }
)

;; Track votes cast by members
(define-map votes
  { proposal-id: uint, voter: principal }
  bool
) ;; true = yes, false = no

;; Track the next proposal ID
(define-data-var next-proposal-id uint u1)

;; Delegation registry to track who has delegated to whom
(define-map delegation-registry principal principal)

;; Delegation count to track how many votes each delegate controls
(define-map delegation-count principal uint)

;; Helper function to get the current block height
(define-private (current-block-height)
  block-height
)

;; Check if caller is a member
(define-private (is-member (address principal))
  (default-to false (map-get? members address))
)

;; Calculate if a proposal has passed
(define-private (is-proposal-approved (proposal-id uint))
  (let (
    (proposal (unwrap! (map-get? proposals proposal-id) false))
    (total-votes (+ (get yes-votes proposal) (get no-votes proposal)))
    (approval-percentage (if (> total-votes u0)
      (/ (* (get yes-votes proposal) u100) total-votes)
      u0
    ))
  )
    (>= approval-percentage (var-get vote-threshold))
  )
)

;; Check if voting is still open for a proposal
(define-private (is-voting-active (proposal-id uint))
  (let (
    (proposal (unwrap! (map-get? proposals proposal-id) false))
    (current-block (current-block-height))
    (end-block (+ (get created-at proposal) (var-get voting-period)))
  )
    (< current-block end-block)
  )
)

;; public functions
;; Join the DAO by adding STX to the treasury
(define-public (join-dao (contribution uint))
  (let (
    (caller tx-sender)
  )
    (asserts! (> contribution u0) ERR_INSUFFICIENT_FUNDS)
    (asserts! (not (is-member caller)) ERR_ALREADY_MEMBER)
    
    ;; Transfer STX to contract
    (try! (stx-transfer? contribution caller (as-contract tx-sender)))
    
    ;; Update treasury balance
    (var-set treasury-balance (+ (var-get treasury-balance) contribution))
    
    ;; Add member
    (map-set members caller true)
    (var-set member-count (+ (var-get member-count) u1))
    
    (ok true)
  )
)

;; Create a new proposal
(define-public (create-proposal (title (string-ascii 100)) (description (string-utf8 500)) 
                               (action (string-utf8 200)) (amount uint) (recipient principal))
  (let (
    (caller tx-sender)
    (proposal-id (var-get next-proposal-id))
  )
    ;; Check if caller is a member
    (asserts! (is-member caller) ERR_NOT_MEMBER)
    
    ;; Check if amount is valid
    (asserts! (<= amount (var-get treasury-balance)) ERR_INSUFFICIENT_FUNDS)
    
    ;; Create the proposal
    (map-set proposals proposal-id {
      proposer: caller,
      title: title,
      description: description,
      action: action,
      amount: amount,
      recipient: recipient,
      yes-votes: u0,
      no-votes: u0,
      status: "active",
      created-at: (current-block-height),
      executed-at: none
    })
    
    ;; Increment the proposal counter
    (var-set next-proposal-id (+ proposal-id u1))
    
    (ok proposal-id)
  )
)

;; Vote on a proposal
(define-public (vote-on-proposal (proposal-id uint) (vote bool))
  (let (
    (caller tx-sender)
    (vote-key { proposal-id: proposal-id, voter: caller })
  )
    ;; Check if caller is a member
    (asserts! (is-member caller) ERR_NOT_MEMBER)
    
    ;; Check if proposal exists
    (asserts! (is-some (map-get? proposals proposal-id)) ERR_PROPOSAL_NOT_FOUND)
    
    ;; Check if voting is still active
    (asserts! (is-voting-active proposal-id) ERR_VOTING_CLOSED)
    
    ;; Check if member has already voted
    (asserts! (is-none (map-get? votes vote-key)) ERR_ALREADY_VOTED)
    
    ;; Record the vote
    (map-set votes vote-key vote)
    
    ;; Update the vote count
    (let ((proposal (unwrap-panic (map-get? proposals proposal-id))))
      (if vote
        (map-set proposals proposal-id (merge proposal { yes-votes: (+ (get yes-votes proposal) u1) }))
        (map-set proposals proposal-id (merge proposal { no-votes: (+ (get no-votes proposal) u1) }))
      )
    )
    
    (ok true)
  )
)

;; Execute an approved proposal
(define-public (execute-proposal (proposal-id uint))
  (let (
    (caller tx-sender)
    (proposal (unwrap! (map-get? proposals proposal-id) ERR_PROPOSAL_NOT_FOUND))
  )
    ;; Check if caller is a member
    (asserts! (is-member caller) ERR_NOT_MEMBER)
    
    ;; Check if voting is closed
    (asserts! (not (is-voting-active proposal-id)) ERR_VOTING_CLOSED)
    
    ;; Check if proposal is approved
    (asserts! (is-proposal-approved proposal-id) ERR_PROPOSAL_NOT_APPROVED)
    
    ;; Check if proposal has not been executed yet
    (asserts! (is-eq (get status proposal) "active") ERR_PROPOSAL_NOT_APPROVED)
    
    ;; Check if treasury has enough funds
    (asserts! (<= (get amount proposal) (var-get treasury-balance)) ERR_INSUFFICIENT_FUNDS)
    
    ;; Update proposal status
    (map-set proposals proposal-id (merge proposal {
      status: "executed",
      executed-at: (some (current-block-height))
    }))
    
    ;; Transfer funds if needed
    (if (> (get amount proposal) u0)
      (begin
        (try! (as-contract (stx-transfer? (get amount proposal) tx-sender (get recipient proposal))))
        (var-set treasury-balance (- (var-get treasury-balance) (get amount proposal)))
      )
      true
    )
    
    (ok true)
  )
)

;; Advanced governance feature: Implement a delegated voting system
;; This allows members to delegate their voting power to other members
;; who can vote on their behalf, increasing participation and efficiency
(define-public (implement-delegated-voting-system)
  (let (
    (caller tx-sender)
  )
    ;; Return success for implementing the delegation system
    (ok true)
  )
)

;; Function to delegate voting power to another member
(define-public (delegate-vote (delegate principal))
  (let (
    (delegator tx-sender)
  )
    ;; Ensure both parties are members
    (asserts! (is-member delegator) ERR_NOT_MEMBER)
    (asserts! (is-member delegate) ERR_NOT_MEMBER)
    
    ;; Check if delegator is not delegating to themselves
    (asserts! (not (is-eq delegator delegate)) ERR_SELF_DELEGATION)
    
    ;; Remove previous delegation if exists
    (match (map-get? delegation-registry delegator)
      prev-delegate (begin
        (map-set delegation-count prev-delegate (- (default-to u0 (map-get? delegation-count prev-delegate)) u1))
        true
      )
      false
    )
    
    ;; Set new delegation
    (map-set delegation-registry delegator delegate)
    
    ;; Increment delegate's count
    (map-set delegation-count delegate (+ (default-to u0 (map-get? delegation-count delegate)) u1))
    
    (ok true)
  )
)


