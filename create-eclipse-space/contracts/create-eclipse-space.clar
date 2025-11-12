;; CreateEclipse - Decentralized Media Licensing Platform
;; Revolutionary creator monetization and IP protection through dynamic smart contracts

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-price (err u103))
(define-constant err-insufficient-funds (err u104))
(define-constant err-license-expired (err u105))
(define-constant err-invalid-split (err u106))

;; Data Variables
(define-data-var content-counter uint u0)
(define-data-var license-counter uint u0)
(define-data-var platform-fee-percentage uint u5) ;; 5% platform fee

;; License types
(define-constant license-personal u1)
(define-constant license-commercial u2)
(define-constant license-exclusive u3)
(define-constant license-creative-commons-plus u4)

;; Data Maps

(define-map content-registry
    { content-id: uint }
    {
        creator: principal,
        title: (string-ascii 128),
        ipfs-hash: (string-ascii 64),
        fingerprint-hash: (buff 32),
        base-price: uint,
        total-licenses: uint,
        total-revenue: uint,
        active: bool,
        created-at: uint
    }
)

(define-map licenses
    { license-id: uint }
    {
        content-id: uint,
        licensee: principal,
        license-type: uint,
        price-paid: uint,
        duration-blocks: uint,
        start-block: uint,
        usage-rights: (string-ascii 256),
        active: bool
    }
)

(define-map royalty-splits
    { content-id: uint, collaborator: principal }
    {
        percentage: uint,
        total-earned: uint
    }
)

(define-map creator-stakes
    { content-id: uint, staker: principal }
    {
        amount: uint,
        staked-at: uint,
        rewards-earned: uint
    }
)

(define-map content-analytics
    { content-id: uint }
    {
        views: uint,
        licenses-sold: uint,
        viral-score: uint,
        last-updated: uint
    }
)

(define-map infringement-reports
    { report-id: uint }
    {
        content-id: uint,
        reporter: principal,
        infringing-url: (string-ascii 256),
        similarity-score: uint,
        resolved: bool,
        timestamp: uint
    }
)

(define-map creator-reputation
    { creator: principal }
    {
        total-content: uint,
        total-revenue: uint,
        reputation-score: uint
    }
)

(define-data-var report-counter uint u0)

;; Read-only functions

(define-read-only (get-content (content-id uint))
    (map-get? content-registry { content-id: content-id })
)

(define-read-only (get-license (license-id uint))
    (map-get? licenses { license-id: license-id })
)

(define-read-only (get-royalty-split (content-id uint) (collaborator principal))
    (map-get? royalty-splits { content-id: content-id, collaborator: collaborator })
)

(define-read-only (get-creator-stake (content-id uint) (staker principal))
    (map-get? creator-stakes { content-id: content-id, staker: staker })
)

(define-read-only (get-content-analytics (content-id uint))
    (map-get? content-analytics { content-id: content-id })
)

(define-read-only (get-creator-reputation (creator principal))
    (map-get? creator-reputation { creator: creator })
)

(define-read-only (get-platform-fee)
    (var-get platform-fee-percentage)
)

(define-read-only (calculate-dynamic-price (content-id uint) (base-price uint))
    (let
        (
            (analytics (default-to 
                { views: u0, licenses-sold: u0, viral-score: u0, last-updated: u0 }
                (map-get? content-analytics { content-id: content-id })))
            (viral-multiplier (/ (get viral-score analytics) u100))
        )
        (+ base-price (* base-price viral-multiplier))
    )
)

(define-read-only (is-license-valid (license-id uint))
    (match (map-get? licenses { license-id: license-id })
        license-data
        (and 
            (get active license-data)
            (< block-height (+ (get start-block license-data) (get duration-blocks license-data)))
        )
        false
    )
)

;; Private functions

(define-private (calculate-platform-fee (amount uint))
    (/ (* amount (var-get platform-fee-percentage)) u100)
)

(define-private (update-creator-reputation (creator principal) (revenue uint))
    (let
        (
            (current-rep (default-to 
                { total-content: u0, total-revenue: u0, reputation-score: u0 }
                (map-get? creator-reputation { creator: creator })))
        )
        (map-set creator-reputation
            { creator: creator }
            {
                total-content: (+ (get total-content current-rep) u1),
                total-revenue: (+ (get total-revenue current-rep) revenue),
                reputation-score: (+ (get reputation-score current-rep) u10)
            }
        )
        true
    )
)

(define-private (distribute-royalty-payment (content-id uint) (amount uint) (collaborator principal))
    (let
        (
            (split-data (map-get? royalty-splits { content-id: content-id, collaborator: collaborator }))
        )
        (match split-data
            split-info
            (let
                (
                    (collaborator-share (/ (* amount (get percentage split-info)) u100))
                )
                (if (> collaborator-share u0)
                    (begin
                        (try! (stx-transfer? collaborator-share tx-sender collaborator))
                        (map-set royalty-splits
                            { content-id: content-id, collaborator: collaborator }
                            (merge split-info { total-earned: (+ (get total-earned split-info) collaborator-share) })
                        )
                        (ok collaborator-share)
                    )
                    (ok u0)
                )
            )
            (ok u0)
        )
    )
)

;; Public functions

(define-public (register-content
    (title (string-ascii 128))
    (ipfs-hash (string-ascii 64))
    (fingerprint-hash (buff 32))
    (base-price uint))
    (let
        (
            (new-content-id (+ (var-get content-counter) u1))
        )
        (asserts! (> base-price u0) err-invalid-price)
        (map-set content-registry
            { content-id: new-content-id }
            {
                creator: tx-sender,
                title: title,
                ipfs-hash: ipfs-hash,
                fingerprint-hash: fingerprint-hash,
                base-price: base-price,
                total-licenses: u0,
                total-revenue: u0,
                active: true,
                created-at: block-height
            }
        )
        (map-set content-analytics
            { content-id: new-content-id }
            {
                views: u0,
                licenses-sold: u0,
                viral-score: u100,
                last-updated: block-height
            }
        )
        (var-set content-counter new-content-id)
        (update-creator-reputation tx-sender u0)
        (ok new-content-id)
    )
)

(define-public (purchase-license
    (content-id uint)
    (license-type uint)
    (duration-blocks uint)
    (usage-rights (string-ascii 256)))
    (let
        (
            (content (unwrap! (map-get? content-registry { content-id: content-id }) err-not-found))
            (dynamic-price (calculate-dynamic-price content-id (get base-price content)))
            (platform-fee (calculate-platform-fee dynamic-price))
            (creator-payment (- dynamic-price platform-fee))
            (new-license-id (+ (var-get license-counter) u1))
        )
        (asserts! (get active content) err-not-found)
        (asserts! (> duration-blocks u0) err-invalid-price)
        
        ;; Transfer payment
        (try! (stx-transfer? dynamic-price tx-sender (as-contract tx-sender)))
        (try! (as-contract (stx-transfer? creator-payment tx-sender (get creator content))))
        
        ;; Create license
        (map-set licenses
            { license-id: new-license-id }
            {
                content-id: content-id,
                licensee: tx-sender,
                license-type: license-type,
                price-paid: dynamic-price,
                duration-blocks: duration-blocks,
                start-block: block-height,
                usage-rights: usage-rights,
                active: true
            }
        )
        
        ;; Update content stats
        (map-set content-registry
            { content-id: content-id }
            (merge content {
                total-licenses: (+ (get total-licenses content) u1),
                total-revenue: (+ (get total-revenue content) dynamic-price)
            })
        )
        
        ;; Update analytics
        (let
            (
                (analytics (unwrap! (map-get? content-analytics { content-id: content-id }) err-not-found))
            )
            (map-set content-analytics
                { content-id: content-id }
                (merge analytics {
                    licenses-sold: (+ (get licenses-sold analytics) u1),
                    last-updated: block-height
                })
            )
        )
        
        (var-set license-counter new-license-id)
        (update-creator-reputation (get creator content) creator-payment)
        (ok new-license-id)
    )
)

(define-public (add-royalty-split
    (content-id uint)
    (collaborator principal)
    (percentage uint))
    (let
        (
            (content (unwrap! (map-get? content-registry { content-id: content-id }) err-not-found))
        )
        (asserts! (is-eq tx-sender (get creator content)) err-unauthorized)
        (asserts! (<= percentage u100) err-invalid-split)
        (map-set royalty-splits
            { content-id: content-id, collaborator: collaborator }
            {
                percentage: percentage,
                total-earned: u0
            }
        )
        (ok true)
    )
)

(define-public (stake-on-creator
    (content-id uint)
    (amount uint))
    (let
        (
            (content (unwrap! (map-get? content-registry { content-id: content-id }) err-not-found))
        )
        (asserts! (> amount u0) err-insufficient-funds)
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        (map-set creator-stakes
            { content-id: content-id, staker: tx-sender }
            {
                amount: amount,
                staked-at: block-height,
                rewards-earned: u0
            }
        )
        (ok true)
    )
)

(define-public (update-viral-score
    (content-id uint)
    (new-views uint)
    (new-viral-score uint))
    (let
        (
            (content (unwrap! (map-get? content-registry { content-id: content-id }) err-not-found))
            (analytics (unwrap! (map-get? content-analytics { content-id: content-id }) err-not-found))
        )
        (asserts! (is-eq tx-sender (get creator content)) err-unauthorized)
        (map-set content-analytics
            { content-id: content-id }
            (merge analytics {
                views: new-views,
                viral-score: new-viral-score,
                last-updated: block-height
            })
        )
        (ok true)
    )
)

(define-public (report-infringement
    (content-id uint)
    (infringing-url (string-ascii 256))
    (similarity-score uint))
    (let
        (
            (new-report-id (+ (var-get report-counter) u1))
        )
        (map-set infringement-reports
            { report-id: new-report-id }
            {
                content-id: content-id,
                reporter: tx-sender,
                infringing-url: infringing-url,
                similarity-score: similarity-score,
                resolved: false,
                timestamp: block-height
            }
        )
        (var-set report-counter new-report-id)
        (ok new-report-id)
    )
)

(define-public (resolve-infringement (report-id uint))
    (let
        (
            (report (unwrap! (map-get? infringement-reports { report-id: report-id }) err-not-found))
            (content (unwrap! (map-get? content-registry { content-id: (get content-id report) }) err-not-found))
        )
        (asserts! (is-eq tx-sender (get creator content)) err-unauthorized)
        (map-set infringement-reports
            { report-id: report-id }
            (merge report { resolved: true })
        )
        (ok true)
    )
)

(define-public (revoke-license (license-id uint))
    (let
        (
            (license (unwrap! (map-get? licenses { license-id: license-id }) err-not-found))
            (content (unwrap! (map-get? content-registry { content-id: (get content-id license) }) err-not-found))
        )
        (asserts! (is-eq tx-sender (get creator content)) err-unauthorized)
        (map-set licenses
            { license-id: license-id }
            (merge license { active: false })
        )
        (ok true)
    )
)

(define-public (update-platform-fee (new-fee uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (<= new-fee u20) err-invalid-price)
        (var-set platform-fee-percentage new-fee)
        (ok true)
    )
)

(define-public (deactivate-content (content-id uint))
    (let
        (
            (content (unwrap! (map-get? content-registry { content-id: content-id }) err-not-found))
        )
        (asserts! (is-eq tx-sender (get creator content)) err-unauthorized)
        (map-set content-registry
            { content-id: content-id }
            (merge content { active: false })
        )
        (ok true)
    )
)