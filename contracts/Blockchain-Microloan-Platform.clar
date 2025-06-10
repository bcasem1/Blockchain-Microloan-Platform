;; Blockchain Microloan Platform
;; Borrowers can request loans; lenders can fund them.

(define-constant err-loan-exists (err u100))
(define-constant err-loan-not-found (err u101))
(define-constant err-not-borrower (err u102))
(define-constant err-already-funded (err u103))
(define-constant err-invalid-amount (err u104))

;; Define loan structure
(define-map loans principal
  {
    amount: uint,
    lender: (optional principal),
    repaid: bool
  }
)

;; Borrower creates a loan request
(define-public (request-loan (amount uint))
  (begin
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (is-none (map-get? loans tx-sender)) err-loan-exists)
    (map-set loans tx-sender {
      amount: amount,
      lender: none,
      repaid: false
    })
    (ok true)
  )
)

;; Lender funds the loan to borrower using STX
(define-public (fund-loan (borrower principal))
  (let ((loan (map-get? loans borrower)))
    (match loan
      loan-data
      (begin
        (asserts! (is-none (get lender loan-data)) err-already-funded)
        (try! (stx-transfer? (get amount loan-data) tx-sender borrower))
        (map-set loans borrower {
          amount: (get amount loan-data),
          lender: (some tx-sender),
          repaid: false
        })
        (ok true)
      )
      err-loan-not-found
    )
  )
)
