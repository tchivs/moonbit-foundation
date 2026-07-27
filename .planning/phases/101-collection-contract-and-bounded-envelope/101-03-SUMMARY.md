---
phase: 101-collection-contract-and-bounded-envelope
plan: 03
subsystem: font
tags: [moonbit, opentype, ttc, dsig, revision, portability]
requires:
  - phase: 101-collection-contract-and-bounded-envelope
    provides: count-first all-face envelope, root-relative protected ranges, exact alias authority, and compact atomic charging
provides:
  - bounded TTCHeader v2 DSIG version-1/format-1 structural inspection
  - closed absent versus present-unverified public DSIG semantics
  - final post-normalization revision guard before one budget charge and publication
  - complete four-target Phase 101 qualification evidence
affects:
  - 102-root-relative-selected-face-admission
  - 103-hostile-licensed-and-four-target-qualification
tech-stack:
  added: []
  patterns:
    - DSIG payload bytes remain opaque while tuple, record, and block envelopes are checked
    - unsupported complete DSIG versions or formats are Capability; malformed envelopes are Data
    - normalization precedes a deterministic revision hook, final guard, one charge, and publication
key-files:
  created: []
  modified:
    - modules/mb-font/font/collection_parser.mbt
    - modules/mb-font/font/collection.mbt
    - modules/mb-font/font/collection_test.mbt
    - modules/mb-font/font/collection_wbtest.mbt
key-decisions:
  - "Accept only TTCHeader v2 DSIG version 1 with non-zero bounded format-1 records, zero reserved fields, exact block lengths, and an envelope ending at collection EOF."
  - "Expose every supported structural signature only as PresentUnverified and never inspect payload content."
  - "Run the final root revision guard after compact normalization and before the single budget charge."
patterns-established:
  - "DSIG admission: tuple authority -> protected/table validation -> bounded envelope traversal -> exact retained/work preflight -> normalization -> revision -> charge -> publication."
  - "DSIG blocks: relative-to-DSIG checked ranges outside the record array, pairwise non-overlap, exact 8+payload length, and no payload read."
requirements-completed: [TTC-01]
coverage:
  - id: D1
    description: "TTC v1 and all-zero TTC v2 tuples report Absent; valid v1/format-1 DSIG reports PresentUnverified; partial tuples and malformed bodies fail atomically."
    requirement: TTC-01
    verification:
      - kind: unit
        ref: "modules/mb-font/font/collection_test.mbt#TTC-01 DSIG tuple and supported envelope remain explicitly unverified"
        status: pass
      - kind: unit
        ref: "modules/mb-font/font/collection_test.mbt#TTC-01 DSIG body rejects malformed and complete unsupported facts"
        status: pass
    human_judgment: false
  - id: D2
    description: "Exact DSIG byte, record, retained, work, and caller-budget authority is enforced before traversal or publication with unchanged budgets on every rejection."
    requirement: TTC-01
    verification:
      - kind: unit
        ref: "modules/mb-font/font/collection_test.mbt#TTC-01 DSIG record and work ceilings are exact and atomic"
        status: pass
      - kind: unit
        ref: "modules/mb-font/font/collection_wbtest.mbt#collection DSIG work includes header records and block pairs exactly"
        status: pass
    human_judgment: false
  - id: D3
    description: "Mutation followed by restoration after normalization fails State before charge/publication, and the complete package preserves equal semantics on all four targets."
    requirement: TTC-01
    verification:
      - kind: unit
        ref: "modules/mb-font/font/collection_wbtest.mbt#collection final revision guard rejects mutate-restoration atomically"
        status: pass
      - kind: integration
        ref: "moon -C modules/mb-font test font --target {js,wasm,wasm-gc,native} --frozen --no-parallelize"
        status: pass
    human_judgment: false
duration: 15min
completed: 2026-07-28
status: complete
---

# Phase 101 Plan 03: DSIG, Atomic Publication, and Phase Gate Summary

Bounded DSIG v1/format-1 structural inspection with opaque payloads, explicit `PresentUnverified` semantics, atomic post-normalization revision protection, and 124/124 passing font tests on every supported target.

## Performance

- **Started:** 2026-07-27T22:04:00Z
- **Completed:** 2026-07-27T22:19:07Z
- **Duration:** 15 min
- **Tasks:** 2
- **Files changed:** 4

## Accomplishments

- Added checked DSIG tuple, header, record-array, signature-block, containment, overlap, reserved-field, and exact-length validation without reading or interpreting payload bytes.
- Enforced exact DSIG record and byte ceilings plus the existing `3 + 6*N + C2(N)` work term in the collection's single compact resource transaction.
- Added a deterministic post-normalization test seam and proved mutation plus byte restoration fails before the budget commit or `FontCollection` publication.
- Qualified the complete font package independently on `js`, `wasm`, `wasm-gc`, and `native`, with 124/124 tests passing on each.
- Regenerated ignored interface evidence and passed the exact interface, portable-source, dependency, publication, and target policy gates without changing the public allowlist.

## Task Commits

Each task was committed through explicit TDD RED and GREEN gates:

1. **Task 1 RED: failing DSIG envelope matrix** - `ff12f84f`
2. **Task 1 GREEN: bounded DSIG structural inspection** - `66b9a9b3`
3. **Task 2 RED: failing final revision-hook test** - `e262dcf2`
4. **Task 2 GREEN: post-normalization revision guard** - `017fae97`

## Files Created/Modified

- `modules/mb-font/font/collection_parser.mbt` - Parses bounded DSIG v1/format-1 envelopes, validates blocks, and includes exact record work in the atomic charge.
- `modules/mb-font/font/collection.mbt` - Routes public open through the private post-normalization hook before final revision guard, charge, and publication.
- `modules/mb-font/font/collection_test.mbt` - Covers valid-unverified, partial tuple, malformed body, unsupported capability, record/byte/work ceiling, and budget-atomicity outcomes.
- `modules/mb-font/font/collection_wbtest.mbt` - Freezes exact DSIG work and deterministic mutate-restoration behavior.

## Decisions Made

- Unsupported DSIG version and signature format are reported as `Capability` only after their bounded enclosing fields are available; truncated, overlapping, inconsistent, or reserved-field violations remain `Data`.
- The only supported flag bit is accepted, every signature payload is non-empty, and the maximum block end must equal the declared DSIG end at collection EOF.
- Public `FontCollection::open` remains unchanged; the deterministic callback is private white-box evidence only.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test bug] Corrected a DSIG flag mutation that also overwrote the following format field**
- **Found during:** Task 1 GREEN
- **Issue:** A four-byte mutation at the two-byte flags field changed both flags and the next signature-format bytes, causing the case to exercise `Capability` instead of the intended malformed-flags `Data` path.
- **Fix:** Used two-byte writes for the DSIG count and flags mutations.
- **Files modified:** `modules/mb-font/font/collection_test.mbt`
- **Verification:** The focused public suite passes 17/17 with the exact expected category and context.
- **Committed in:** `66b9a9b3`

**2. [Rule 1 - Test bug] Kept formula calculation separate from semantic limit comparison**
- **Found during:** Task 1 GREEN
- **Issue:** The first white-box test expected `font_collection_exact_work` itself to reject a one-short semantic limit, while that helper uses the limit only to map checked-arithmetic overflow; `font_collection_retained_charge` owns the final exact-value comparison.
- **Fix:** Asserted the formula returns 48 under both arithmetic authorities and retained the public one-short `max-work` test through collection open.
- **Files modified:** `modules/mb-font/font/collection_wbtest.mbt`
- **Verification:** White-box DSIG work passes and the public `max-work=47` case fails `Resource` atomically.
- **Committed in:** `66b9a9b3`

---

**Total deviations:** 2 auto-fixed test bugs.
**Impact on plan:** Both corrections sharpen the intended evidence without widening the public API, parser scope, or resource model.

## Issues Encountered

Native RED runs surface failing MoonBit tests as process exit `0xc0000409`; after GREEN, the same focused native binaries reported all tests passing normally.

## Verification

- Focused collection white-box suite: 4/4 passed on native.
- Focused collection black-box suite: 17/17 passed on native.
- Complete font package: 124/124 passed independently on `js`, `wasm`, `wasm-gc`, and `native`.
- `moon -C modules/mb-font info --target all --frozen`: passed.
- `git check-ignore modules/mb-font/font/pkg.generated.mbti`: passed; generated interface remains ignored evidence.
- `Assert-FontFoundationPolicy -PolicyPath ./policy/foundation.json`: passed exact interface, dependency, inventory, source, documentation, and target gates.
- `moon -C modules/mb-font check --target all --frozen`: passed.

## TDD Gate Compliance

- Task 1: RED `ff12f84f` precedes GREEN `66b9a9b3`.
- Task 2: RED `e262dcf2` precedes GREEN `017fae97`.
- No refactor gate was needed.

## Known Stubs

None.

## Authentication Gates

None.

## User Setup Required

None.

## Next Phase Readiness

- Phase 101's additive TTC-01 contract is complete: bounded collection identity, all-face structure, root-relative alias/protected authority, closed DSIG status, atomic accounting, stable revision behavior, and equal four-target semantics.
- Phase 102 can consume the retained root-relative face facts without changing `Font::open` or reinterpreting DSIG payloads.
- No blockers remain.

## Self-Check: PASSED

All four modified artifacts, all four TDD commits, all focused and four-target verification commands, the ignored-interface invariant, and the exact policy gates were verified in the isolated worktree. No tracked deletion, uncommitted file, stub marker, new dependency, FFI, ambient I/O, trust claim, payload exposure, or selected-face capability was found.

---
*Phase: 101-collection-contract-and-bounded-envelope*
*Completed: 2026-07-28*
