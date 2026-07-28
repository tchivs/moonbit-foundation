---
phase: 102-root-relative-selected-face-admission
plan: 02
subsystem: font-admission
tags: [moonbit, opentype, ttc, root-relative, budgets, checksums, tdd]

requires:
  - phase: 102-root-relative-selected-face-admission
    provides: Offset-aware directory parsing, explicit collection checksum mode, and deferred ancestor-aware admission ledger from Plan 102-01
  - phase: 101-collection-contract-and-bounded-envelope
    provides: Retained collection root, opening revision, cached per-face directory authority, closed profiles, and exact sharing admission
provides:
  - The single public repeatable FontCollection::open_face transaction returning the existing opaque Font
  - Root-relative selected admission over the original collection ByteView and opening revision
  - Exact selected D plus T byte accounting with three allocations and exact semantic work
  - Shared-table, mixed-profile, checksum, budget, and mutation-atomicity evidence
affects: [102-03-equivalence-policy-portability, 103-collection-qualification]

tech-stack:
  added: []
  patterns:
    - Revision/index/profile facade gates before selected byte admission
    - Existing Font publication from retained collection-root DirectoryFacts
    - Deferred cumulative authority with one exact post-revision charge

key-files:
  created: []
  modified:
    - modules/mb-font/font/collection.mbt
    - modules/mb-font/font/font.mbt
    - modules/mb-font/font/tables.mbt
    - modules/mb-font/font/collection_test.mbt
    - modules/mb-font/font/collection_wbtest.mbt

key-decisions:
  - "FontCollection::open_face is the only new public operation and returns the existing opaque Font without cache, provenance, or a selected-face wrapper."
  - "Selected Fonts retain the full collection root and original collection opening revision; directory fields rebase but table-record offsets never do."
  - "Collection selection charges directory extent plus selected table lengths and exact semantic work only after all semantics and the final root revision guard."

patterns-established:
  - "Selected publication: revision -> index -> cached profile -> selected parse/checksums/semantics -> exact preflight -> final revision -> one charge -> existing Font."
  - "Sibling isolation: exact shared ranges are independently admitted while unsupported siblings stop at the cached profile gate and are never semantically scanned."

requirements-completed:
  - TTC-02
  - TTC-03

coverage:
  - id: D1
    description: "Any admitted in-range StaticGlyf face opens repeatedly through exactly FontCollection::open_face and exposes the existing Font query surface over root-relative tables."
    requirement: TTC-02
    verification:
      - kind: integration
        ref: "modules/mb-font/font/collection_test.mbt#TTC-02 opens a cached static face against the retained collection root"
        status: pass
      - kind: integration
        ref: "moon -C modules/mb-font test font --target native --frozen (144/144)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Revision, index, and cached profile precedence reject invalid selections before selected byte work and leave caller budgets unchanged."
    requirement: TTC-02
    verification:
      - kind: unit
        ref: "modules/mb-font/font/collection_test.mbt#TTC-02 selection gates revision then index then cached profile"
        status: pass
    human_judgment: false
  - id: D3
    description: "Exact cross-face sharing and CFF, CFF2, or variable siblings do not change the selected static face's semantics or admission transaction."
    requirement: TTC-03
    verification:
      - kind: integration
        ref: "modules/mb-font/font/collection_test.mbt#TTC-03 exact sharing and unsupported siblings stay selection local"
        status: pass
    human_judgment: false
  - id: D4
    description: "Selected source limits, D plus T bytes, allocations, allocation size, exact work, ancestor authority, checksums, and mutation guards are exact and failure-atomic."
    requirement: TTC-03
    verification:
      - kind: unit
        ref: "modules/mb-font/font/collection_test.mbt#TTC-02 selected D plus T charge is exact and every failure is atomic"
        status: pass
      - kind: unit
        ref: "modules/mb-font/font/collection_wbtest.mbt#selected final revision hook is atomic and successful Font retains root identity"
        status: pass
    human_judgment: false

duration: 19min
completed: 2026-07-28
status: complete
---

# Phase 102 Plan 02: Selected-Face Transaction Summary

**One root-relative, checksum-correct, selected-only transaction now turns any cached static TrueType collection face into the existing opaque Font without copying, caching, or charging sibling data.**

## Performance

- **Duration:** 19 min
- **Started:** 2026-07-28T01:21:00Z
- **Completed:** 2026-07-28T01:40:42Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added exactly `FontCollection::open_face(UInt64, FontLimits, Budget) -> Result[Font, CoreError]` with stable revision, index, and cached-profile precedence.
- Reused collection-mode directory parsing, per-table checksums, semantic admission, metric indexing, and the exact existing `Font` representation over the original collection root and revision.
- Closed selected-only `D + T`, allocation, exact-work, live-ancestor, final-revision, and one-charge atomicity while leaving standalone `Font::open` unchanged.
- Proved before/after-directory tables, exact shared sibling ranges, mixed unsupported siblings, bad checksums, repeated independent selections, and inherited post-publication mutation failure.

## Task Commits

TDD gates and task outcomes were committed atomically:

1. **Task 1 RED: selected-face public tracer** — `5768821b`
2. **Task 1 GREEN: retained-root open_face and shared Font publication** — `3e7bf934`
3. **Task 2 RED: sharing/accounting/mutation contracts** — `11aada96`
4. **Task 2 GREEN: exact selected extent and atomic transaction** — `e44b3ac7`
5. **Task 2 boundary lock: exact/one-short selected max-work** — `3ad4cc13`

## Files Created/Modified

- `modules/mb-font/font/collection.mbt` — single public facade, revision/index/profile errors, cached authority selection, and private final-guard hook.
- `modules/mb-font/font/font.mbt` — common admitted-Font constructor plus collection-mode semantic admission, final revision, one charge, and publication.
- `modules/mb-font/font/tables.mbt` — checked selected directory-plus-table extent and mode-specific final byte charge.
- `modules/mb-font/font/collection_test.mbt` — real TTC selected-face builders and public success, precedence, sharing, sibling, checksum, budget, ancestor, and mutation evidence.
- `modules/mb-font/font/collection_wbtest.mbt` — exact selected extent, deterministic mutate/restore hook, and retained root/revision identity evidence.

## Decisions Made

- Kept the public surface to one method returning `Font`; all cached face, directory, table, source, and revision facts remain private.
- Used a shared private `font_from_admitted_facts` constructor so standalone and collection publication cannot diverge in exposed metrics or retained table state.
- Derived selected directory bytes from the cached table count (`12 + 16R`) and selected table bytes from the reparsed root-backed windows; sibling extents never enter the charge.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. The MoonBit toolchain continues to emit its pre-existing generated `Result` unused-expression warning; all scoped repository gates pass.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None. The scoped stub, TODO, FIXME, skipped-test, and placeholder scan returned no matches.

## Next Phase Readiness

- Plan 102-03 can advance the exact public interface allowlist by the single `open_face` signature and run the full equivalence/precedence/four-target gate.
- Phase 103 can qualify licensed and hostile collection fixtures through the settled root-relative transaction.
- No blockers remain.

## Self-Check: PASSED

All five modified implementation/test files exist, all five TDD/task commits resolve, focused public tests pass 29/29, focused white-box tests pass 12/12, the complete native font package passes 144/144, `git diff --check` passes, and the worktree contains no generated or unrelated changes.

---
*Phase: 102-root-relative-selected-face-admission*
*Completed: 2026-07-28*
