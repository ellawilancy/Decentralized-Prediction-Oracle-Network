;; Reward Distribution Contract

;; Define fungible token for rewards
(define-fungible-token reward-token)

;; Define data structures
(define-map rewards
  { staker: principal }
  { amount: uint, last-claim: uint }
)

;; Define constants
(define-constant reward-period u144) ;; 1 day in blocks (assuming 10-minute block time)
(define-constant reward-rate u100) ;; 1% daily reward rate (in basis points)

;; Error codes
(define-constant err-not-eligible (err u300))
(define-constant err-too-early (err u301))

;; Distribute rewards
(define-public (distribute-rewards)
  (let
    (
      (total-staked (contract-call? .staking get-total-staked))
      (reward-amount (/ (* total-staked reward-rate) u10000))
    )
    (try! (ft-mint? reward-token reward-amount (as-contract tx-sender)))
    (ok true)
  )
)

;; Claim rewards
(define-public (claim-rewards)
  (let
    (
      (staker tx-sender)
      (current-rewards (default-to { amount: u0, last-claim: u0 } (map-get? rewards { staker: staker })))
      (stake-info (contract-call? .staking get-stake staker))
    )
    (asserts! (contract-call? .staking is-eligible staker) err-not-eligible)
    (asserts! (>= (- block-height (get last-claim current-rewards)) reward-period) err-too-early)
    (let
      (
        (new-rewards (calculate-rewards (get amount stake-info) (- block-height (get last-claim current-rewards))))
      )
      (try! (as-contract (ft-transfer? reward-token new-rewards tx-sender staker)))
      (ok (map-set rewards
        { staker: staker }
        { amount: (+ (get amount current-rewards) new-rewards), last-claim: block-height }
      ))
    )
  )
)

;; Calculate rewards
(define-private (calculate-rewards (stake-amount uint) (blocks uint))
  (let
    (
      (periods (/ blocks reward-period))
    )
    (/ (* stake-amount reward-rate periods) u10000)
  )
)

;; Get unclaimed rewards for a staker
(define-read-only (get-unclaimed-rewards (staker principal))
  (let
    (
      (current-rewards (default-to { amount: u0, last-claim: u0 } (map-get? rewards { staker: staker })))
      (stake-info (contract-call? .staking get-stake staker))
    )
    (+ (get amount current-rewards)
       (calculate-rewards (get amount stake-info) (- block-height (get last-claim current-rewards))))
  )
)

