;; Service Provider Verification Contract
;; Manages telecommunications service provider registration and verification

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_PROVIDER_EXISTS (err u101))
(define-constant ERR_PROVIDER_NOT_FOUND (err u102))
(define-constant ERR_INVALID_STATUS (err u103))

;; Data Variables
(define-data-var next-provider-id uint u1)

;; Data Maps
(define-map providers
  { provider-id: uint }
  {
    owner: principal,
    name: (string-ascii 50),
    license-number: (string-ascii 30),
    status: (string-ascii 20),
    verification-date: uint,
    services: (list 10 (string-ascii 30))
  }
)

(define-map provider-by-owner
  { owner: principal }
  { provider-id: uint }
)

;; Public Functions
(define-public (register-provider (name (string-ascii 50)) (license-number (string-ascii 30)) (services (list 10 (string-ascii 30))))
  (let ((provider-id (var-get next-provider-id)))
    (asserts! (is-none (map-get? provider-by-owner { owner: tx-sender })) ERR_PROVIDER_EXISTS)
    (map-set providers
      { provider-id: provider-id }
      {
        owner: tx-sender,
        name: name,
        license-number: license-number,
        status: "pending",
        verification-date: block-height,
        services: services
      }
    )
    (map-set provider-by-owner { owner: tx-sender } { provider-id: provider-id })
    (var-set next-provider-id (+ provider-id u1))
    (ok provider-id)
  )
)

(define-public (verify-provider (provider-id uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (match (map-get? providers { provider-id: provider-id })
      provider-data
      (begin
        (map-set providers
          { provider-id: provider-id }
          (merge provider-data { status: "verified", verification-date: block-height })
        )
        (ok true)
      )
      ERR_PROVIDER_NOT_FOUND
    )
  )
)

(define-public (update-provider-status (provider-id uint) (new-status (string-ascii 20)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (match (map-get? providers { provider-id: provider-id })
      provider-data
      (begin
        (map-set providers
          { provider-id: provider-id }
          (merge provider-data { status: new-status })
        )
        (ok true)
      )
      ERR_PROVIDER_NOT_FOUND
    )
  )
)

;; Read-only Functions
(define-read-only (get-provider (provider-id uint))
  (map-get? providers { provider-id: provider-id })
)

(define-read-only (get-provider-by-owner (owner principal))
  (match (map-get? provider-by-owner { owner: owner })
    provider-ref (map-get? providers { provider-id: (get provider-id provider-ref) })
    none
  )
)

(define-read-only (get-next-provider-id)
  (var-get next-provider-id)
)
