;; Stacks Supreme Knowledge Vault: that Securely stores and manages intellectual property with robust access control mechanisms

;; --------------------------------------------------------------------------
;; Data Structures
;; --------------------------------------------------------------------------
(define-map intellectual-resources
  { resource-id: uint }
  {
    resource-title: (string-ascii 80),
    resource-owner: principal,
    resource-size: uint,
    registration-height: uint,
    resource-abstract: (string-ascii 256),
    resource-categories: (list 8 (string-ascii 40))
  }
)

(define-map resource-access-rights
  { resource-id: uint, accessor: principal }
  { can-view: bool }
)

;; --------------------------------------------------------------------------
;; State Variables
;; --------------------------------------------------------------------------
(define-data-var resource-sequence uint u0)

;; --------------------------------------------------------------------------
;; Constants and Error Codes
;; --------------------------------------------------------------------------
(define-constant VAULT_ADMINISTRATOR tx-sender)
(define-constant ERR_UNAUTHORIZED_ACCESS (err u300))
(define-constant ERR_RESOURCE_NONEXISTENT (err u301))
(define-constant ERR_RESOURCE_DUPLICATE (err u302))
(define-constant ERR_INVALID_RESOURCE_TITLE (err u303))
(define-constant ERR_INVALID_RESOURCE_SIZE (err u304))
(define-constant ERR_ACCESS_FORBIDDEN (err u305))


;; --------------------------------------------------------------------------
;; Resource Modification Functions
;; --------------------------------------------------------------------------
(define-public (update-resource-metadata 
                (resource-id uint) 
                (new-title (string-ascii 80)) 
                (new-size uint) 
                (new-abstract (string-ascii 256)) 
                (new-categories (list 8 (string-ascii 40))))
  (let
    (
      (resource-info (unwrap! (map-get? intellectual-resources { resource-id: resource-id }) ERR_RESOURCE_NONEXISTENT))
    )
    ;; Verify resource exists and sender is owner
    (asserts! (resource-exists? resource-id) ERR_RESOURCE_NONEXISTENT)
    (asserts! (is-eq (get resource-owner resource-info) tx-sender) ERR_ACCESS_FORBIDDEN)

    ;; Validate new metadata
    (asserts! (> (len new-title) u0) ERR_INVALID_RESOURCE_TITLE)
    (asserts! (< (len new-title) u81) ERR_INVALID_RESOURCE_TITLE)
    (asserts! (> new-size u0) ERR_INVALID_RESOURCE_SIZE)
    (asserts! (< new-size u2000000000) ERR_INVALID_RESOURCE_SIZE)
    (asserts! (> (len new-abstract) u0) ERR_INVALID_RESOURCE_TITLE)
    (asserts! (< (len new-abstract) u257) ERR_INVALID_RESOURCE_TITLE)
    (asserts! (are-categories-valid new-categories) ERR_INVALID_RESOURCE_TITLE)

    ;; Update resource metadata
    (map-set intellectual-resources
      { resource-id: resource-id }
      (merge resource-info { 
        resource-title: new-title, 
        resource-size: new-size, 
        resource-abstract: new-abstract, 
        resource-categories: new-categories 
      })
    )
    (ok true)
  )
)

(define-public (remove-resource-permanently (resource-id uint))
  (let
    (
      (resource-info (unwrap! (map-get? intellectual-resources { resource-id: resource-id }) ERR_RESOURCE_NONEXISTENT))
    )
    ;; Verify resource exists and sender is owner
    (asserts! (resource-exists? resource-id) ERR_RESOURCE_NONEXISTENT)
    (asserts! (is-eq (get resource-owner resource-info) tx-sender) ERR_ACCESS_FORBIDDEN)

    ;; Remove resource from vault
    (map-delete intellectual-resources { resource-id: resource-id })
    (ok true)
  )
)

;; --------------------------------------------------------------------------
;; Optimized Resource Retrieval Functions
;; --------------------------------------------------------------------------
(define-public (retrieve-resource-essentials (resource-id uint))
  (let
    (
      (resource-info (unwrap! (map-get? intellectual-resources { resource-id: resource-id }) ERR_RESOURCE_NONEXISTENT))
    )
    ;; Return core metadata for efficient retrieval
    (ok {
      resource-title: (get resource-title resource-info),
      resource-owner: (get resource-owner resource-info),
      resource-size: (get resource-size resource-info)
    })
  )
)
;; This function provides essential resource details with minimal execution cost

(define-public (retrieve-resource-compact (resource-id uint))
  (let
    (
      (resource-info (unwrap! (map-get? intellectual-resources { resource-id: resource-id }) ERR_RESOURCE_NONEXISTENT))
    )
    ;; Return minimal data set for highest efficiency
    (ok {
      resource-title: (get resource-title resource-info),
      resource-owner: (get resource-owner resource-info)
    })
  )
)
;; Ultra-compact function that retrieves only identification information

(define-public (retrieve-full-resource-view (resource-id uint))
  (let
    (
      (resource-info (unwrap! (map-get? intellectual-resources { resource-id: resource-id }) ERR_RESOURCE_NONEXISTENT))
    )
    ;; Create comprehensive presentation structure
    (ok {
      title: (get resource-title resource-info),
      owner: (get resource-owner resource-info),
      size: (get resource-size resource-info),
      abstract: (get resource-abstract resource-info),
      categories: (get resource-categories resource-info)
    })
  )
)

;; Retrieve only resource abstract
(define-public (get-resource-abstract (resource-id uint))
  (let
    (
      (resource-info (unwrap! (map-get? intellectual-resources { resource-id: resource-id }) ERR_RESOURCE_NONEXISTENT))
    )
    (ok (get resource-abstract resource-info))
  )
)

;; --------------------------------------------------------------------------
;; Resource Validation Functions
;; --------------------------------------------------------------------------
(define-public (validate-resource-submission (title (string-ascii 80)) (size uint) (abstract (string-ascii 256)) (categories (list 8 (string-ascii 40))))
  (begin
    ;; Title validation
    (asserts! (> (len title) u0) ERR_INVALID_RESOURCE_TITLE)
    (asserts! (< (len title) u81) ERR_INVALID_RESOURCE_TITLE)
    ;; Size validation
    (asserts! (> size u0) ERR_INVALID_RESOURCE_SIZE)
    (asserts! (< size u2000000000) ERR_INVALID_RESOURCE_SIZE)
    ;; Abstract validation
    (asserts! (> (len abstract) u0) ERR_INVALID_RESOURCE_TITLE)
    (asserts! (< (len abstract) u257) ERR_INVALID_RESOURCE_TITLE)
    ;; Categories validation
    (asserts! (are-categories-valid categories) ERR_INVALID_RESOURCE_TITLE)
    (ok true)
  )
)
;; --------------------------------------------------------------------------
;; Helper Functions
;; --------------------------------------------------------------------------
(define-private (resource-exists? (resource-id uint))
  (is-some (map-get? intellectual-resources { resource-id: resource-id }))
)

(define-private (is-resource-owner (resource-id uint) (owner principal))
  (match (map-get? intellectual-resources { resource-id: resource-id })
    resource-data (is-eq (get resource-owner resource-data) owner)
    false
  )
)

(define-private (get-resource-size (resource-id uint))
  (default-to u0 
    (get resource-size 
      (map-get? intellectual-resources { resource-id: resource-id })
    )
  )
)

(define-private (are-categories-valid (categories (list 8 (string-ascii 40))))
  (and
    (> (len categories) u0)
    (<= (len categories) u8)
    (is-eq (len (filter is-valid-category categories)) (len categories))
  )
)

(define-private (is-valid-category (category (string-ascii 40)))
  (and 
    (> (len category) u0)
    (< (len category) u41)
  )
)

;; --------------------------------------------------------------------------
;; View Generation Functions
;; --------------------------------------------------------------------------
(define-public (generate-resource-dashboard (resource-id uint))
  (let
    (
      (resource-info (unwrap! (map-get? intellectual-resources { resource-id: resource-id }) ERR_RESOURCE_NONEXISTENT))
    )
    ;; Return user interface compatible object
    (ok {
      interface-title: "Resource Information Dashboard",
      resource-title: (get resource-title resource-info),
      resource-owner: (get resource-owner resource-info),
      resource-abstract: (get resource-abstract resource-info),
      resource-categories: (get resource-categories resource-info)
    })
  )
)

;; --------------------------------------------------------------------------
;; Core Resource Management Functions
;; --------------------------------------------------------------------------
(define-public (register-intellectual-resource 
                (title (string-ascii 80)) 
                (size uint) 
                (abstract (string-ascii 256)) 
                (categories (list 8 (string-ascii 40))))
  (let
    (
      (resource-id (+ (var-get resource-sequence) u1))
    )
    ;; Validate input parameters
    (asserts! (> (len title) u0) ERR_INVALID_RESOURCE_TITLE)
    (asserts! (< (len title) u81) ERR_INVALID_RESOURCE_TITLE)
    (asserts! (> size u0) ERR_INVALID_RESOURCE_SIZE)
    (asserts! (< size u2000000000) ERR_INVALID_RESOURCE_SIZE)
    (asserts! (> (len abstract) u0) ERR_INVALID_RESOURCE_TITLE)
    (asserts! (< (len abstract) u257) ERR_INVALID_RESOURCE_TITLE)
    (asserts! (are-categories-valid categories) ERR_INVALID_RESOURCE_TITLE)

    ;; Register resource in the vault
    (map-insert intellectual-resources
      { resource-id: resource-id }
      {
        resource-title: title,
        resource-owner: tx-sender,
        resource-size: size,
        registration-height: block-height,
        resource-abstract: abstract,
        resource-categories: categories
      }
    )

    ;; Grant initial access permission to creator
    (map-insert resource-access-rights
      { resource-id: resource-id, accessor: tx-sender }
      { can-view: true }
    )

    ;; Update resource counter and return ID
    (var-set resource-sequence resource-id)
    (ok resource-id)
  )
)

;; Alternative resource registration with cleaner implementation
(define-public (register-resource-enhanced 
                (title (string-ascii 80)) 
                (size uint) 
                (abstract (string-ascii 256)) 
                (categories (list 8 (string-ascii 40))))
  (let
    (
      (resource-id (+ (var-get resource-sequence) u1))
    )
    ;; Input validation section
    (asserts! (> (len title) u0) ERR_INVALID_RESOURCE_TITLE)
    (asserts! (< (len title) u81) ERR_INVALID_RESOURCE_TITLE)
    (asserts! (> size u0) ERR_INVALID_RESOURCE_SIZE)
    (asserts! (< size u2000000000) ERR_INVALID_RESOURCE_SIZE)
    (asserts! (> (len abstract) u0) ERR_INVALID_RESOURCE_TITLE)
    (asserts! (< (len abstract) u257) ERR_INVALID_RESOURCE_TITLE)
    (asserts! (are-categories-valid categories) ERR_INVALID_RESOURCE_TITLE)

    ;; Resource metadata storage
    (map-insert intellectual-resources
      { resource-id: resource-id }
      {
        resource-title: title,
        resource-owner: tx-sender,
        resource-size: size,
        registration-height: block-height,
        resource-abstract: abstract,
        resource-categories: categories
      }
    )

    ;; Owner access rights assignment
    (map-insert resource-access-rights
      { resource-id: resource-id, accessor: tx-sender }
      { can-view: true }
    )

    ;; Counter increment and result
    (var-set resource-sequence resource-id)
    (ok resource-id)
  )
)


