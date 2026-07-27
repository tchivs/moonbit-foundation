---
phase: 101-collection-contract-and-bounded-envelope
plan: 02
subsystem: font
tags: [moonbit, opentype, ttc, ranges, aliases, budget]
requires:
  - phase: 101-collection-contract-and-bounded-envelope
    provides: opaque FontCollection tracer, eight collection ceilings, revision-first queries, and frozen public interface
provides:
  - count-first TTC v1/v2 all-face declaration and structural validation
  - collection-root table ranges with global protected-range and exact-alias enforcement
  - exact 96/40/24 retained accounting and deterministic pair-work charging
affects:
  - 101-03 DSIG envelope and phase qualification
  - 102-root-relative-selected-face-admission
tech-stack:
  added: []
  patterns:
    - declaration authority precedes structural scans, pair work, and compact normalization
    - protected and table pairs are replayed from root bytes without attacker-sized scratch arrays
    - exact cross-face sharing requires equal range, tag, length, and stored checksum
key-files:
  created:
    - modules/mb-font/font/collection_wbtest.mbt
  modified:
    - modules/mb-font/font/collection_parser.mbt
    - modules/mb-font/font/collection_test.mbt
    - policy/foundation.json
    - scripts/quality/Assert-Policy.ps1
key-decisions:
  - "Keep every directory field absolute while resolving table-record offsets only against collection byte zero."
  - "Replay protected and table records deterministically instead of allocating attacker-sized structural scratch arrays."
  - "Permit cross-face sharing only for an exact root range with matching tag, length, and stored checksum metadata."
patterns-established:
  - "Collection authority: source/header/count ceilings -> all-face structure -> protected/alias replay -> exact charge preflight -> compact normalization."
  - "Collection identity: equal payload bytes at distinct offsets never imply sharing; only exact root coordinates plus metadata do."
requirements-completed: [TTC-01]
coverage:
  - id: D1
    description: "TTC v1/v2 collections validate every directory in offset-array order and expose all five closed profiles without selected-face or checksum admission."
    requirement: TTC-01
    verification:
      - kind: unit
        ref: "modules/mb-font/font/collection_test.mbt#TTC-01 all-face structure preserves v2 offset order and closed profiles"
        status: pass
      - kind: unit
        ref: "modules/mb-font/font/collection_wbtest.mbt#collection structural pass keeps root ranges and face order"
        status: pass
    human_judgment: false
  - id: D2
    description: "One global root-coordinate model rejects protected, same-face, partial, and metadata-conflicting overlaps while accepting touching and exact shared ranges."
    requirement: TTC-01
    verification:
      - kind: unit
        ref: "modules/mb-font/font/collection_test.mbt#TTC-01 exact sharing and touching pass while every overlap conflict fails"
        status: pass
    human_judgment: false
  - id: D3
    description: "Compact retained bytes and deterministic work accept exact semantic/caller authority and leave every budget dimension unchanged on one-short failure."
    requirement: TTC-01
    verification:
      - kind: unit
        ref: "modules/mb-font/font/collection_test.mbt#TTC-01 compact charge exact fit succeeds and every one-short is atomic"
        status: pass
      - kind: unit
        ref: "modules/mb-font/font/collection_wbtest.mbt#collection accounting formula includes every protected and alias pair"
        status: pass
      - kind: integration
        ref: "moon -C modules/mb-font test font --target native --frozen --target-dir target/phase101-plan02-final-regression --no-parallelize"
        status: pass
    human_judgment: false
duration: 27min
completed: 2026-07-28
status: complete
---

# Phase 101 Plan 02: Bounded All-Face Envelope Summary

Count-first TTC v1/v2 inspection with root-relative table ranges, five ordered face profiles, exact cross-face alias authority, and atomic compact resource charging.

## Performance

- **Started:** 2026-07-27T21:37:00Z
- **Completed:** 2026-07-27T22:04:14Z
- **Duration:** 27 min
- **Tasks:** 2
- **Files changed:** 5

## Accomplishments

- Expanded the one-face tracer into a count-first TTC v1/v2 parser that validates every non-zero directory and ordered record before compact normalization.
- Enforced one global half-open root-coordinate model across the header, every directory, optional DSIG coordinates, and all table records.
- Added exact protected-pair, table×protected, and unordered table-pair replay while accepting only exact cross-face range-plus-metadata sharing.
- Proved exact 96/40/24 retained bookkeeping, deterministic work, caller budget atomicity, and unchanged standalone `Font::open` behavior.

## Task Commits

Each TDD task was committed through explicit RED and GREEN gates:

1. **Task 1 RED: all-face structure matrix** - `2e7e6c41`
2. **Task 1 GREEN: all-face TTC v1/v2 validation** - `6cc35606`
3. **Task 2 RED: alias and accounting matrix** - `98e457ce`
4. **Task 2 GREEN: protected/alias authority and exact charging** - `c5a695f7`

## Files Created/Modified

- `modules/mb-font/font/collection_parser.mbt` - Adds declaration, structural, root-range, protected, alias, and exact accounting passes.
- `modules/mb-font/font/collection_test.mbt` - Covers v2/multi-profile order, root offsets, truncation, ceilings, adjacency, exact-fit budgets, atomic one-short failures, and standalone regression.
- `modules/mb-font/font/collection_wbtest.mbt` - Freezes private root-coordinate facts and checked pair-work formulas.
- `policy/foundation.json` - Registers the collection white-box suite in exact test and publication inventories.
- `scripts/quality/Assert-Policy.ps1` - Keeps both independent font inventory selectors synchronized.

## Decisions Made

- Structural pair validation replays already bounded root records rather than allocating a table-record scratch array.
- Empty ranges and touching half-open endpoints do not overlap.
- Same-face overlap always fails; cross-face exact equality succeeds only when tag, length, and stored checksum also match.
- Source length remains semantic authority only; successful admission charges compact retained facts, two allocations, maximum compact-array size, and exact work.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test bug] Corrected a white-box fixture that overlapped a sibling directory**
- **Found during:** Task 2 GREEN
- **Issue:** The initial two-face fixture placed one table at `[120,124)`, inside the second directory `[80,124)`, so the new global protected-range validator correctly rejected the supposedly valid case.
- **Fix:** Moved all three table ranges beyond the final directory while preserving their root-relative ordering.
- **Files modified:** `modules/mb-font/font/collection_wbtest.mbt`
- **Verification:** White-box suite passes 2/2 and the protected-overlap public matrix still rejects the intentional collision.
- **Committed in:** `c5a695f7`

**2. [Rule 3 - Blocking] Synchronized both independent policy inventory selectors**
- **Found during:** Task 1 GREEN policy verification
- **Issue:** The repository has separate qualification and foundation exact arrays; the first update reached only one test list and one publication list.
- **Fix:** Added `collection_wbtest.mbt` to both test-source and both publication selectors.
- **Files modified:** `scripts/quality/Assert-Policy.ps1`
- **Verification:** `Assert-FontFoundationPolicy` passes, including generated-interface and portable-source checks.
- **Committed in:** `6cc35606`

**3. [Rule 2 - Missing critical evidence] Added boundary and precedence cases required by the plan**
- **Found during:** Task 2 acceptance review
- **Issue:** The first matrix did not explicitly cover empty table ranges, duplicate directory protection, or one-over face/per-face/cumulative declaration ceilings.
- **Fix:** Added exact public cases for all three boundary categories with full budget-remaining equality checks.
- **Files modified:** `modules/mb-font/font/collection_test.mbt`
- **Verification:** Public collection tests pass 14/14 and the complete native font suite passes 119/119.
- **Committed in:** `c5a695f7`

---

**Total deviations:** 3 auto-fixed (1 bug, 1 blocking inventory issue, 1 missing critical evidence).
**Impact on plan:** All fixes strengthen required correctness and evidence without widening the public API or phase scope.

## Issues Encountered

None beyond the auto-fixed deviations above.

## Verification

- Collection white-box suite: 2/2 passed on native.
- Collection black-box suite: 14/14 passed on native.
- Complete font package: 119/119 passed on native.
- Foundation font policy, publication inventory, generated semantic interface, dependency, and portable-source gates passed.

## Known Stubs

None.

## User Setup Required

None.

## Next Phase Readiness

- Plan 101-03 can validate the full DSIG v1/format-1 body against the already protected optional root range.
- Phase 102 can consume stable ordered face facts and the proven collection-root coordinate seam.
- No blockers remain.

## Self-Check: PASSED

All five production/test/policy artifacts and all four task commits were verified in the isolated worktree. No tracked deletion, uncommitted file, stub, new dependency, network/auth path, FFI, ambient I/O, or public parser-fact exposure was found.

---
*Phase: 101-collection-contract-and-bounded-envelope*
*Completed: 2026-07-28*
