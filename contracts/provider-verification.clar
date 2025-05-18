;; Provider Verification Contract
;; This contract validates healthcare practitioners

(define-data-var admin principal tx-sender)

;; Provider status: 0 = unverified, 1 = verified, 2 = suspended
(define-map providers
  { provider-id: principal }
  {
    status: uint,
    specialty: (string-utf8 64),
    license-number: (string-utf8 32),
    verification-date: uint
  }
)

(define-read-only (get-provider (provider-id principal))
  (default-to
    {
      status: u0,
      specialty: u"",
      license-number: u"",
      verification-date: u0
    }
    (map-get? providers { provider-id: provider-id })
  )
)

(define-public (register-provider (specialty (string-utf8 64)) (license-number (string-utf8 32)))
  (begin
    (asserts! (not (is-some (map-get? providers { provider-id: tx-sender }))) (err u1))
    (ok (map-set providers
      { provider-id: tx-sender }
      {
        status: u0,
        specialty: specialty,
        license-number: license-number,
        verification-date: u0
      }
    ))
  )
)

(define-public (verify-provider (provider-id principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-some (map-get? providers { provider-id: provider-id })) (err u404))
    (ok (map-set providers
      { provider-id: provider-id }
      (merge (unwrap-panic (map-get? providers { provider-id: provider-id }))
        {
          status: u1,
          verification-date: block-height
        }
      )
    ))
  )
)

(define-public (suspend-provider (provider-id principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-some (map-get? providers { provider-id: provider-id })) (err u404))
    (ok (map-set providers
      { provider-id: provider-id }
      (merge (unwrap-panic (map-get? providers { provider-id: provider-id }))
        {
          status: u2
        }
      )
    ))
  )
)

(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (var-set admin new-admin))
  )
)
