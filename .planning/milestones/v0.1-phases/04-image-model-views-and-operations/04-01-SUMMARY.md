---
phase: 04-image-model-views-and-operations
plan: "01"
subsystem: image-metadata
tags: [moonbit, metadata, budgets, owned-bytes, deterministic-ordering]

requires:
  - phase: 02-bounded-core-primitives
    provides: Structured errors, hierarchical budgets, and retained owned bytes/views
provides:
  - Bounded duplicate-free opaque metadata with canonical ordering
  - Exact retained metadata payloads backed by one authoritative allocation
  - Machine-readable preserve/transform/discard disposition records
affects: [04-image-model-views-and-operations, image-operations, codec-contracts]

tech-stack:
  added: []
  patterns:
    - Pure validation and canonicalization before a single OwnedBytes allocation
    - Stable insertion ordering over bounded ASCII compound keys

key-files:
  created:
    - modules/mb-image/metadata/moon.pkg
    - modules/mb-image/metadata/metadata.mbt
    - modules/mb-image/metadata/metadata_test.mbt
    - modules/mb-image/metadata/metadata_wbtest.mbt
  modified:
    - policy/foundation.json

key-decisions:
  - "Pack all opaque values into one retained OwnedBytes allocation after pure validation so duplicate, token, count, and aggregate-limit failures cannot partially consume storage budget."
  - "Define metadata identity as the canonical namespace/key/tag tuple, sort it bytewise, and reject duplicate tuples."
  - "Require each disposition field to occur in exactly one of preserved, transformed, or discarded and sort each collection canonically."

patterns-established:
  - "Metadata allocation authority: validate the entire collection, allocate once, then expose retained ByteView slices."
  - "Disposition exclusivity: a bounded field has exactly one deterministic disposition."

requirements-completed: [IMAG-06]

coverage:
  - id: D1
    description: Bounded opaque metadata remains exact, duplicate-free, canonical, and budget-atomic.
    requirement: IMAG-06
    verification:
      - kind: unit
        ref: "modules/mb-image/metadata/metadata_test.mbt and metadata_wbtest.mbt; moon -C modules/mb-image test metadata --target all --frozen (9/9 per target)"
        status: pass
    human_judgment: false
  - id: D2
    description: Metadata disposition is bounded, exclusive, ordered, and machine-readable.
    requirement: IMAG-06
    verification:
      - kind: integration
        ref: "pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required"
        status: pass
    human_judgment: false

duration: 10min
completed: 2026-07-17
status: complete
---

# Phase 4 Plan 1: Bounded Opaque Metadata Summary

**Core-only metadata with canonical compound keys, exact retained payloads, atomic budget behavior, and deterministic disposition records**

## Performance

- **Duration:** 10 min
- **Started:** 2026-07-17T04:36:31+08:00
- **Completed:** 2026-07-17T04:46:17+08:00
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added bounded ASCII namespace/key/tag metadata whose values remain exact opaque retained bytes.
- Canonicalized entry order and rejected duplicate compound keys before any authoritative allocation or budget charge.
- Added deterministic, bounded, mutually exclusive preserve/transform/discard disposition records and registered the core-only metadata leaf in exact policy.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: Add failing metadata contract tests** - `baf8fd4` (test)
2. **Task 1 GREEN: Implement bounded opaque metadata** - `e1d483a` (feat)
3. **Task 2: Register the metadata leaf** - `67edc64` (chore)

## Files Created/Modified

- `modules/mb-image/metadata/moon.pkg` - Core-only imports and explicit four-target package policy.
- `modules/mb-image/metadata/metadata.mbt` - Bounded opaque entries, canonical collection construction, and disposition contracts.
- `modules/mb-image/metadata/metadata_test.mbt` - Public ordering, exact-value, duplicate, and disposition tests.
- `modules/mb-image/metadata/metadata_wbtest.mbt` - Adversarial limit, storage-budget, opacity, token, and disposition tests.
- `policy/foundation.json` - Exact publication inventory, import allowlist, semantic interface, and supported targets.

## Decisions Made

- Used one contiguous `OwnedBytes` owner for all opaque values so collection validation completes before allocation and entries expose retained zero-copy slices.
- Compared canonical namespace/key/tag tokens by ASCII code units rather than relying on backend-specific collection ordering.
- Rejected disposition duplication both within one category and across categories so operation metadata behavior cannot be ambiguous.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The pinned formatter attempted its known `moon.mod.json` migration; only the three intended metadata sources were retained, and generated manifest changes were removed before verification and commit.

## User Setup Required

None - no external service configuration required.

## Verification

- `moon -C modules/mb-image test metadata --target all --frozen`: 9/9 passed independently on js, wasm, wasm-gc, and native.
- `pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required`: passed, including 120/120 workspace tests per target, 41 exact metadata semantic-interface lines, publication allowlist, DAG, negative fixtures, and read-only proof.

## Self-Check: PASSED

- All five planned files exist.
- Commits `baf8fd4`, `e1d483a`, and `67edc64` resolve in repository history.
- No known stubs or new network, host, filesystem, authentication, or schema threat surface was introduced.

## Next Phase Readiness

- The core-only metadata leaf is ready for descriptor, storage, operation, and codec packages to consume without a color/model dependency cycle.
- No blockers remain for Plan 04-02.

---
*Phase: 04-image-model-views-and-operations*
*Completed: 2026-07-17*
