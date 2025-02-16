;; Staking Contract

;; Define fungible token for staking
(define-fungible-token stake-token)

;; Define data structures
(define-map stakes
  { staker: principal }
  { amount: uint, last-stake-time: uint }
)

;; Define constants
(define-constant min-stake-amount u1000)
(define-constant stake-lock-period u144) ;; 1 day in blocks (assuming 10-minute block time)

;; Error codes
(define-constant err-insufficient-stake (err u100))
(define-constant err-stake-locked (err u101))

;; Stake tokens
(define-public (stake (amount uint))
  (let
    (
      (current-stake (default-to { amount: u0, last-stake-time: u0 } (map-get? stakes { staker: tx-sender })))
    )
    (asserts! (>= amount min-stake-amount) err-insufficient-stake)
    (try! (ft-transfer? stake-token amount tx-sender (as-contract tx-sender)))
    (ok (map-set stakes
      { staker: tx-sender }
      { amount: (+ (get amount current-stake) amount), last-stake-time: block-height }
    ))
  )
)

;; Unstake tokens
(define-public (unstake (amount uint))
  (let
    (
      (current-stake (unwrap! (map-get? stakes { staker: tx-sender }) err-insufficient-stake))
    )
    (asserts! (>= (get amount current-stake) amount) err-insufficient-stake)
    (asserts! (>= (- block-height (get last-stake-time current-stake)) stake-lock-period) err-stake-locked)
    (try! (as-contract (ft-transfer? stake-token amount tx-sender tx-sender)))
    (ok (map-set stakes
      { staker: tx-sender }
      { amount: (- (get amount current-stake) amount), last-stake-time: (get last-stake-time current-stake) }
    ))
  )
)

;; Get stake amount for a staker
(define-read-only (get-stake (staker principal))
  (default-to { amount: u0, last-stake-time: u0 } (map-get? stakes { staker: staker }))
)

;; Check if a staker is eligible (has minimum stake)
(define-read-only (is-eligible (staker principal))
  (>= (get amount (get-stake staker)) min-stake-amount)
)

;; Get total staked amount
(define-read-only (get-total-staked)
  (ft-get-balance stake-token (as-contract tx-sender))
)

