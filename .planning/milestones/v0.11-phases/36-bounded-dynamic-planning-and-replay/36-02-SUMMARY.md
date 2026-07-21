---
phase: 36-bounded-dynamic-planning-and-replay
plan: "02"
subsystem: png-deflate
tags: [moonbit, png, deflate, dynamic-huffman, replay, testing]
requires:
  - phase: 36-bounded-dynamic-planning-and-replay
    provides: Bounded Dynamic planning and acknowledgement-safe replay
provides:
  - Exact and one-less Dynamic selected-work admission evidence
  - Public Dynamic replay-drift sticky-error and caller-lease isolation evidence
affects: [phase-37-dynamic-compression-evidence]
tech-stack:
  added: []
  patterns: [white-box preflight boundary test, public atomic-admission test, sentinel lease isolation]
key-files:
  created: []
  modified:
    - modules/mb-image/png/encode_wbtest.mbt
    - modules/mb-image/png/stream_encode_test.mbt
key-decisions:
  - The strict-winning 128-pixel periodic RGB8 fixture has a documented Dynamic selected-work cost of 9388UL.
  - Focused test evidence remains limited to Phase 36 admission and replay behavior; broader compression corpus evidence remains Phase 37 scope.
requirements-completed: [PNGD-02, PNGD-03]
coverage:
  - id: D3
    description: Dynamic selected-work exact/one-less admission and public adapter atomicity
    requirement: PNGD-02
    verification:
      - kind: unit
        ref: modules/mb-image/png/encode_wbtest.mbt#PNG dynamic selected work boundary charges once
        status: pass
      - kind: integration
        ref: modules/mb-image/png/stream_encode_test.mbt#PNG dynamic public exact and one-less admission is atomic
        status: pass
    human_judgment: false
  - id: D4
    description: Dynamic replay-drift sticky terminal and fresh caller-lease isolation
    requirement: PNGD-03
    verification:
      - kind: integration
        ref: modules/mb-image/png/stream_encode_test.mbt#PNG dynamic replay drift is sticky through chunk encoder
        status: pass
    human_judgment: false
completed: 2026-07-22
status: complete
---

# Phase 36 Plan 02: Dynamic Admission and Replay Evidence Summary

**Focused four-target tests close the Dynamic selected-work admission and public replay-drift lease-isolation evidence gaps.**

## Accomplishments

- Added white-box coverage proving the strict Dynamic fixture's 9388UL selected-work ledger is charged once; exact admission succeeds and 9387UL rejects without changing budget state.
- Added public eager and chunk factory coverage showing exact admission exhausts only work, while one-less admission produces no observable output and preserves resource limits.
- Added public chunk replay-drift coverage proving the first error stays sticky and a later sentinel-filled caller lease remains unchanged.

## Task Commits

1. `87db126` — Dynamic selected-work exact/one-less preflight evidence.
2. `a9f5925` — Public Dynamic admission atomicity and replay-drift lease-isolation evidence.

## Verification

- Focused Dynamic tests: 21/21 passed on js, wasm, wasm-gc, and native, using isolated build directories.
- The previous full PNG suite passed 127/127 tests with `--target all` before these test-only additions.
- The default build lock was pre-existing.

## Deviations from Plan

None. The changes are limited to the two planned PNG test files.

## Known Stubs

None.

## Self-Check: PASSED

- Commits `87db126` and `a9f5925` exist and modify only the planned PNG test files.
- This summary is the only documentation file created for Plan 02.

## Next Phase Readiness

Phase 37 can add the broader Dynamic compression corpus and benchmark evidence without expanding this focused behavioral coverage.
