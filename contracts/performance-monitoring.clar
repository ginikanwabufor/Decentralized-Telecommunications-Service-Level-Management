;; Performance Monitoring Contract
;; Tracks telecommunications service performance metrics

;; Constants
(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_INVALID_METRIC (err u201))
(define-constant ERR_PROVIDER_NOT_FOUND (err u202))

;; Data Variables
(define-data-var next-metric-id uint u1)

;; Data Maps
(define-map performance-metrics
  { metric-id: uint }
  {
    provider-id: uint,
    metric-type: (string-ascii 30),
    value: uint,
    timestamp: uint,
    reporter: principal
  }
)

(define-map provider-performance
  { provider-id: uint, metric-type: (string-ascii 30) }
  {
    total-reports: uint,
    average-value: uint,
    last-updated: uint
  }
)

;; Public Functions
(define-public (report-performance (provider-id uint) (metric-type (string-ascii 30)) (value uint))
  (let ((metric-id (var-get next-metric-id)))
    (map-set performance-metrics
      { metric-id: metric-id }
      {
        provider-id: provider-id,
        metric-type: metric-type,
        value: value,
        timestamp: block-height,
        reporter: tx-sender
      }
    )
    (update-provider-average provider-id metric-type value)
    (var-set next-metric-id (+ metric-id u1))
    (ok metric-id)
  )
)

;; Private Functions
(define-private (update-provider-average (provider-id uint) (metric-type (string-ascii 30)) (new-value uint))
  (match (map-get? provider-performance { provider-id: provider-id, metric-type: metric-type })
    existing-data
    (let (
      (total-reports (+ (get total-reports existing-data) u1))
      (current-average (get average-value existing-data))
      (new-average (/ (+ (* current-average (get total-reports existing-data)) new-value) total-reports))
    )
      (map-set provider-performance
        { provider-id: provider-id, metric-type: metric-type }
        {
          total-reports: total-reports,
          average-value: new-average,
          last-updated: block-height
        }
      )
    )
    (map-set provider-performance
      { provider-id: provider-id, metric-type: metric-type }
      {
        total-reports: u1,
        average-value: new-value,
        last-updated: block-height
      }
    )
  )
)

;; Read-only Functions
(define-read-only (get-performance-metric (metric-id uint))
  (map-get? performance-metrics { metric-id: metric-id })
)

(define-read-only (get-provider-performance (provider-id uint) (metric-type (string-ascii 30)))
  (map-get? provider-performance { provider-id: provider-id, metric-type: metric-type })
)

(define-read-only (get-next-metric-id)
  (var-get next-metric-id)
)
