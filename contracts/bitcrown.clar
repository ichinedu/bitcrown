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