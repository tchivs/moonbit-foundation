---
phase: 42-bounded-adam7-pass-encoding
plan: 01
subsystem: png-encoding
tags: [png, adam7, deflate, streaming]
requires: [41-01]
provides: [bounded-adam7-filtered-source, adam7-chunk-replay]
affects: [PNGI-02, PNGI-03]
tech-stack:
  added: []
  patterns: [checked-pass-geometry, scalar-cursor-replay, acknowledgement-gated-output]
key-files:
  created: []
  modified:
    - modules/mb-image/png/encode.mbt
    - modules/mb-image/png/stream_encode.mbt
    - modules/mb-image/png/encode_wbtest.mbt
    - modules/mb-image/png/encode_test.mbt
    - modules/mb-image/png/stream_encode_test.mbt
decisions:
  - Adam7 geometry is regenerated from _png_adam7_passes for scalar cursor lookups and is never retained as a pass cache.
  - Adam7 uses the existing Stored, Fixed, and Dynamic planner/replay ownership model; acknowledgement remains the only state commit point.
requirements-completed: [PNGI-02, PNGI-03]
coverage:
  - deliverable: Bounded Adam7 filtered traversal and atomic preflight
    verification:
      - kind: test
        ref: tests/modules/mb-image/png/encode_wbtest.mbt#PNG-Adam7
        status: pass
    human_judgment: false
  - deliverable: Adam7 eager and caller-buffered replay framing
    verification:
      - kind: test
        ref: tests/modules/mb-image/png/encode_test.mbt#PNG-Adam7
        status: pass
      - kind: test
        ref: tests/modules/mb-image/png/stream_encode_test.mbt#PNG-Adam7
        status: pass
    human_judgment: false
metrics:
  tasks_completed: 3
  files_modified: 5
  native_tests: 167
completed: 2026-07-22
status: complete
---

# Phase 42 Plan 01: Bounded Adam7 Pass Encoding Summary

Adam7 PNG encoding now emits checked seven-pass filtered bytes through the existing bounded DEFLATE planners and acknowledgement-safe output machine.

## Accomplishments

- Added scalar, pass-local Adam7 filtered traversal using `_png_adam7_passes` as the sole pass-geometry source, including pass-local adaptive predictor history.
- Routed Stored, FixedOrStored, and DynamicOrFixedOrStored planning and replay through the same bounded Adam7 producer and single atomic preflight charge.
- Made Adam7 output frame IHDR with interlace method `1`, while retaining all legacy and explicit-None method-`0` paths.
- Replaced compatible Adam7 pending assertions with eager/chunk parity and hostile-capacity coverage for RGB8 and straight-RGBA8.

## Verification

- `moon -C modules/mb-image test png --target native --frozen --no-parallelize` — passed: 167 tests.
- `moon -C modules/mb-image test png --target native --frozen --filter 'PNG Adam7*' --no-parallelize` — passed: 5 tests.
- `git diff --check` — passed.

## Commits

- `50c6ac1` — bounded Adam7 filtered traversal and white-box planner coverage.
- `b1424d8` — acknowledgement-safe Adam7 stream replay and chunk tests.
- `4fb46b7` — eager Adam7 framing tests while retaining None vectors.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Self-Check: PASSED

All five planned implementation/test files exist in their task commits, and the native PNG suite passes.

## Next Phase Readiness

Phase 43 can add the generated fidelity corpus and independent four-target public evidence without changing the bounded Adam7 replay boundary.
