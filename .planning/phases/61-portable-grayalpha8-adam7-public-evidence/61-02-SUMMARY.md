---
phase: 61-portable-grayalpha8-adam7-public-evidence
plan: "02"
subsystem: testing
tags: [moonbit, png, grayalpha8, adam7, streaming, conformance]
requires:
  - phase: 59-grayalpha8-adam7-factory-and-pass-profile
    provides: Public GrayAlpha8 Adam7 eager and chunk factories
  - phase: 60-bounded-adam7-streaming-semantics
    provides: Shared bounded replay accounting across all strategy selections
provides:
  - Fresh public GrayAlpha8 Adam7 hostile caller-lease proof across all six selector pairs
  - Independent GrayAlpha16 Stored/None chunk compatibility literal
  - Four-target frozen PNG package qualification
affects: [png-public-evidence, grayalpha8-adam7, streaming-regression]
tech-stack:
  added: []
  patterns: [Fresh eager-and-chunk peers, Z-filled caller leases, literal frozen compatibility anchors]
key-files:
  created: [.planning/phases/61-portable-grayalpha8-adam7-public-evidence/61-02-SUMMARY.md]
  modified: [modules/mb-image/png/stream_encode_test.mbt]
key-decisions:
  - "Construct distinct fresh GrayAlpha8 Adam7 sources for eager and caller-buffered peers on every scheduled invocation."
  - "Use the independently derived 77-byte GrayAlpha16 literal as the chunk-route oracle instead of another encoder output."
patterns-established:
  - "Public caller-buffered Adam7 evidence begins with an empty sublease and checks accepted prefixes, untouched tails, and a later terminal lease."
requirements-completed: [GRAYA8A7-03]
coverage:
  - id: D1
    description: Fresh public GrayAlpha8 Adam7 encoders retain eager identity, accepted-only progress, untouched lease tails, and sticky completion for all Stored, FixedOrStored, and DynamicOrFixedOrStored selections with None and Adaptive filters.
    requirement: GRAYA8A7-03
    verification:
      - kind: unit
        ref: "modules/mb-image/png/stream_encode_test.mbt#PNG GrayAlpha8 Adam7 public hostile schedules"
        status: pass
    human_judgment: false
  - id: D2
    description: Default and configured GrayAlpha16 chunk routes match the independent 77-byte Stored/None literal, while the ordinary frozen PNG package passes on every production target.
    requirement: GRAYA8A7-03
    verification:
      - kind: unit
        ref: "moon -C modules/mb-image test png --target all --frozen"
        status: pass
    human_judgment: false
duration: 10min
completed: 2026-07-23
status: complete
---

# Phase 61 Plan 02: Portable GrayAlpha8 Adam7 Public Evidence Summary

**Fresh public GrayAlpha8 Adam7 hostile-drain coverage now proves six selector pairs preserve caller lease ownership and eager identity, with a frozen GrayAlpha16 chunk oracle across all targets.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-07-23T04:12:51Z
- **Completed:** 2026-07-23T04:22:08Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added a fresh-source GrayAlpha8 Adam7 drain helper that asserts empty-lease no-op behavior, accepted-only totals, untouched tails, eager identity, and sticky Finished output.
- Exercised each Stored, FixedOrStored, and DynamicOrFixedOrStored selection with None and Adaptive filters under zero/one/ragged schedules.
- Added the independently derived 77-byte GrayAlpha16 Stored/None literal to the chunk frozen-vector matrix and passed the ordinary PNG suite on wasm, wasm-gc, js, and native (227 tests each).

## Task Commits

1. **Task 1 RED: Add the GrayAlpha8 Adam7 hostile tracer** - `fbd7edb` (`test`)
2. **Task 1 GREEN: Prove GrayAlpha8 Adam7 hostile drains** - `2999099` (`feat`)
3. **Task 2: Expand selector schedules and frozen chunk vectors** - `fba21ca` (`test`)

## Files Created/Modified

- `modules/mb-image/png/stream_encode_test.mbt` - Adds the public Adam7 hostile-drain helper/matrix and the independent GrayAlpha16 chunk literal.
- `.planning/phases/61-portable-grayalpha8-adam7-public-evidence/61-02-SUMMARY.md` - Records evidence, TDD gates, and portable verification.

## Decisions Made

- Built eager and caller-buffered peers from separate fresh GrayAlpha8 Adam7 images so the test never shares mutable source state.
- Kept the GrayAlpha16 expected stream as the plan-supplied literal, not a value derived by an encoder route.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The first all-target command exceeded the execution wrapper's two-minute timeout without reporting a test failure; the identical command was rerun with a longer command budget and completed successfully.

## TDD Gate Compliance

- RED: `fbd7edb` added the focused tracer and failed on its intentionally unbound helper.
- GREEN: `2999099` supplied the test-local helper, after which the focused tracer passed.

## Known Stubs

None.

## Self-Check: PASSED

- Found the modified PNG streaming test and generated summary files.
- Found all three Task 1/Task 2 commits in repository history.

## Next Phase Readiness

- The public GrayAlpha8 Adam7 evidence and retained non-interlaced frozen routes are qualified on all supported production targets.
- No blockers or production changes introduced.

---
*Phase: 61-portable-grayalpha8-adam7-public-evidence*
*Completed: 2026-07-23*
