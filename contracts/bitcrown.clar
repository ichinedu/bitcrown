;; Title: BitCrown Protocol - Sovereign Bitcoin Liquidity Engine
;;
;; Summary: Advanced Bitcoin-collateralized lending protocol that transforms idle 
;; sBTC holdings into productive capital through intelligent yield strategies and 
;; over-collateralized lending markets built natively on Stacks Layer-2.
;;
;; Description: BitCrown represents the evolution of Bitcoin DeFi, offering institutional-grade 
;; lending infrastructure where Bitcoin holders maintain custody while accessing deep liquidity 
;; pools. Through sophisticated risk management, dynamic interest curves, and yield optimization 
;; algorithms, users can deposit sBTC collateral to unlock STX loans or provide STX liquidity 
;; to capture enhanced yields. The protocol features automated liquidation protection, real-time 
;; solvency monitoring, and capital-efficient lending ratios, creating a trustless financial 
;; primitive that preserves Bitcoin's security model while enabling modern DeFi capabilities.
;;

;; ERROR CONSTANTS

(define-constant ERR_INVALID_WITHDRAW_AMOUNT (err u100))
(define-constant ERR_EXCEEDED_MAX_BORROW (err u101))
(define-constant ERR_CANNOT_BE_LIQUIDATED (err u102))
(define-constant ERR_INSUFFICIENT_BALANCE (err u104))
(define-constant ERR_ZERO_AMOUNT (err u105))
(define-constant ERR_PRICE_FEED_ERROR (err u106))
(define-constant ERR_CONTRACT_CALL_FAILED (err u107))
(define-constant ERR_UNAUTHORIZED (err u108))

;; PROTOCOL CONSTANTS

(define-constant LOAN_TO_VALUE_RATIO u70) ;; 70% maximum LTV for safety
(define-constant ANNUAL_INTEREST_RATE u10) ;; 10% base borrowing APR
(define-constant LIQUIDATION_THRESHOLD u80) ;; 80% liquidation trigger
(define-constant LIQUIDATOR_REWARD_RATE u10) ;; 10% liquidation bonus
(define-constant SECONDS_PER_YEAR u31556952) ;; Precise year calculation
(define-constant BASIS_POINTS u10000) ;; Precision for yield math
(define-constant CONTRACT_OWNER tx-sender) ;; Protocol governance

;; PROTOCOL STATE VARIABLES

;; Global liquidity metrics
(define-data-var total-sbtc-collateral uint u0)
(define-data-var total-stx-deposits uint u1)
(define-data-var total-stx-borrows uint u0)

;; Interest accrual mechanics
(define-data-var last-interest-update uint u0)
(define-data-var cumulative-yield-index uint u0)

;; Price oracle and controls
(define-data-var sbtc-price-in-stx uint u50000)
(define-data-var protocol-paused bool false)

;; USER POSITION DATA STRUCTURES

;; sBTC collateral positions
(define-map user-collateral-positions
  { account: principal }
  { sbtc-amount: uint }
)

;; STX lending deposits with yield tracking
(define-map user-deposit-positions
  { account: principal }
  {
    stx-amount: uint,
    yield-index-snapshot: uint,
  }
)

;; Active borrowing positions
(define-map user-borrow-positions
  { account: principal }
  {
    stx-amount: uint,
    last-interest-accrual: uint,
  }
)

;; PRICE ORACLE FUNCTIONS

;; Retrieve current sBTC/STX exchange rate
(define-read-only (get-sbtc-price-in-stx)
  (ok (var-get sbtc-price-in-stx))
)

;; Admin function for price updates (production would use Chainlink/Pyth)
(define-public (update-sbtc-price (new-price uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (> new-price u0) ERR_ZERO_AMOUNT)
    (var-set sbtc-price-in-stx new-price)
    (ok true)
  )
)

;; PROTOCOL ADMINISTRATION

(define-public (pause-protocol)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (var-set protocol-paused true)
    (ok true)
  )
)

(define-public (unpause-protocol)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (var-set protocol-paused false)
    (ok true)
  )
)

;; LIQUIDITY PROVISION FUNCTIONS

;; Deposit STX to earn lending yields
(define-public (deposit-stx (amount uint))
  (let (
      (caller tx-sender)
      (existing-deposit (map-get? user-deposit-positions { account: caller }))
      (current-deposit (default-to u0 (get stx-amount existing-deposit)))
    )
    (asserts! (not (var-get protocol-paused)) ERR_UNAUTHORIZED)
    (asserts! (> amount u0) ERR_ZERO_AMOUNT)

    (update-interest-accrual)
    (try! (stx-transfer? amount caller (as-contract tx-sender)))

    (map-set user-deposit-positions { account: caller } {
      stx-amount: (+ current-deposit amount),
      yield-index-snapshot: (var-get cumulative-yield-index),
    })

    (var-set total-stx-deposits (+ (var-get total-stx-deposits) amount))
    (ok true)
  )
)

;; Withdraw STX deposits plus accrued yields
(define-public (withdraw-stx (amount uint))
  (let (
      (caller tx-sender)
      (user-deposit (unwrap! (map-get? user-deposit-positions { account: caller })
        ERR_INSUFFICIENT_BALANCE
      ))
      (deposited-amount (get stx-amount user-deposit))
      (earned-yield (unwrap! (calculate-pending-yield caller) ERR_CONTRACT_CALL_FAILED))
      (total-available (+ deposited-amount earned-yield))
      (withdrawal-amount (if (> amount total-available)
        total-available
        amount
      ))
    )
    (asserts! (not (var-get protocol-paused)) ERR_UNAUTHORIZED)
    (asserts! (> amount u0) ERR_ZERO_AMOUNT)
    (asserts! (>= total-available amount) ERR_INVALID_WITHDRAW_AMOUNT)

    (update-interest-accrual)

    (let ((remaining-deposit (if (>= deposited-amount amount)
        (- deposited-amount amount)
        u0
      )))
      (if (is-eq remaining-deposit u0)
        (map-delete user-deposit-positions { account: caller })
        (map-set user-deposit-positions { account: caller } {
          stx-amount: remaining-deposit,
          yield-index-snapshot: (var-get cumulative-yield-index),
        })
      )

      (var-set total-stx-deposits
        (if (>= (var-get total-stx-deposits) amount)
          (- (var-get total-stx-deposits) amount)
          u0
        ))

      (try! (as-contract (stx-transfer? withdrawal-amount tx-sender caller)))
      (ok true)
    )
  )
)

;; Calculate pending yield for depositor
(define-read-only (calculate-pending-yield (account principal))
  (let (
      (user-deposit (map-get? user-deposit-positions { account: account }))
      (yield-snapshot (default-to u0 (get yield-index-snapshot user-deposit)))
      (stx-amount (default-to u0 (get stx-amount user-deposit)))
      (current-yield-index (var-get cumulative-yield-index))
    )
    (if (> current-yield-index yield-snapshot)
      (let ((yield-delta (- current-yield-index yield-snapshot)))
        (ok (/ (* stx-amount yield-delta) BASIS_POINTS))
      )
      (ok u0)
    )
  )
)