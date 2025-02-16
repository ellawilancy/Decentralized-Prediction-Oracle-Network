;; Data Feed Contract

;; Define data structures
(define-map data-feeds
  { feed-id: uint }
  { description: (string-ascii 256), latest-value: int, last-updated: uint, aggregator: principal }
)

(define-map data-points
  { feed-id: uint, timestamp: uint }
  { value: int, reporter: principal }
)

;; Define data variables
(define-data-var next-feed-id uint u1)

;; Error codes
(define-constant err-unauthorized (err u401))
(define-constant err-feed-not-found (err u404))

;; Create a new data feed
(define-public (create-feed (description (string-ascii 256)))
  (let
    (
      (feed-id (var-get next-feed-id))
    )
    (map-set data-feeds
      { feed-id: feed-id }
      { description: description, latest-value: 0, last-updated: u0, aggregator: tx-sender }
    )
    (var-set next-feed-id (+ feed-id u1))
    (ok feed-id)
  )
)

;; Report data for a feed
(define-public (report-data (feed-id uint) (value int))
  (let
    (
      (feed (unwrap! (map-get? data-feeds { feed-id: feed-id }) err-feed-not-found))
    )
    (map-set data-points
      { feed-id: feed-id, timestamp: block-height }
      { value: value, reporter: tx-sender }
    )
    (map-set data-feeds
      { feed-id: feed-id }
      (merge feed { latest-value: value, last-updated: block-height })
    )
    (ok true)
  )
)

;; Get latest data for a feed
(define-read-only (get-latest-data (feed-id uint))
  (map-get? data-feeds { feed-id: feed-id })
)

;; Get historical data point
(define-read-only (get-data-point (feed-id uint) (timestamp uint))
  (map-get? data-points { feed-id: feed-id, timestamp: timestamp })
)

;; Update feed aggregator
(define-public (update-aggregator (feed-id uint) (new-aggregator principal))
  (let
    (
      (feed (unwrap! (map-get? data-feeds { feed-id: feed-id }) err-feed-not-found))
    )
    (asserts! (is-eq tx-sender (get aggregator feed)) err-unauthorized)
    (ok (map-set data-feeds
      { feed-id: feed-id }
      (merge feed { aggregator: new-aggregator })
    ))
  )
)

