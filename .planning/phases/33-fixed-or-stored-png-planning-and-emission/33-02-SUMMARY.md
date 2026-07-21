---
phase: 33-fixed-or-stored-png-planning-and-emission
plan: "02"
subsystem: png-encoding-tests
tags: [png, fixed-huffman, moonbit, streaming, resource-limits]
dependency_graph:
  requires: [bounded-fixed-or-stored-emission]
  provides: [configured-fixed-or-stored-behavioral-evidence]
  affects: [png-eager-encoder, png-chunk-encoder, phase-34-corpus]
tech-stack:
  added: []
  patterns: [fail-closed-test-outline, fixed-replay-stimulus, terminal-lease-isolation]
key-files:
  created: []
  modified:
    - modules/mb-image/png/encode_test.mbt
    - modules/mb-image/png/encode_wbtest.mbt
    - modules/mb-image/png/stream_encode_test.mbt
    - modules/mb-image/png/stream_encode_wbtest.mbt
decisions:
  - The focused PNG selector uses the MoonBit glob '*fixed-or-stored*' only after every required test name is found in the per-target outline.
  - The same mutable 5×1 RGB8 fixture drives public chunk-terminal and private replay-work failure coverage.
requirements-completed: [PNGC-02, PNGC-03]
coverage:
  - id: D1
    description: FixedOrStored public factories reject capability, geometry, output, work, and budget failures atomically and retain terminal caller-lease isolation.
    requirement: PNGC-02
    verification:
      - kind: unit
        ref: modules/mb-image/png/stream_encode_test.mbt#PNG fixed-or-stored public admission is atomic
        status: pass
      - kind: unit
        ref: modules/mb-image/png/stream_encode_test.mbt#PNG fixed-or-stored configured sticky terminals preserve leases
        status: pass
    human_judgment: false
  - id: D2
    description: Fixed preflight selected work, acknowledgement-only state commits, and replay mismatch remain deterministic and sticky.
    requirement: PNGC-03
    verification:
      - kind: unit
        ref: modules/mb-image/png/encode_wbtest.mbt#PNG fixed-or-stored white-box selected work boundary charges once
        status: pass
      - kind: unit
        ref: modules/mb-image/png/stream_encode_wbtest.mbt#PNG fixed-or-stored white-box replay mismatch is sticky
        status: pass
    human_judgment: false
metrics:
  duration: 24m
  completed_date: 2026-07-22
  tasks_completed: 2
  files_modified: 4
status: complete
---

# Phase 33 Plan 02: Fixed-or-Stored Evidence Closure Summary

Configured FixedOrStored PNG tests now prove atomic admission, exact selected-work charging, acknowledgement-only fixed replay, and sticky caller-buffered terminals on every portable target.

## Completed Work

- Added public configured-route admission coverage for capability, geometry, selected-output, selected-work, and exhausted-budget rejection, including all eight unchanged remaining-budget fields.
- Added exact selected-work and one-less boundary tests, plus configured zero/one/ragged terminal lease tests.
- Added the exact mutable 5×1 RGB8 replay fixture to reach `png-encode-fixed-replay-work` after 57 accepted bytes and verify sticky error/lease behavior.
- Added private assertions for fixed plan arithmetic, acknowledgement-only state transition, and repeated replay-mismatch state.

## Verification

- Fail-closed outline guard and `-f '*fixed-or-stored*'`: 11/11 passed independently on js, wasm, wasm-gc, and native.
- `moon -C modules/mb-image test png --target all --frozen`: 113/113 passed on each declared target.
- `pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png`: passed, including policy checks, generated vectors, four-target tests, and lane isolation.

## Task Commits

1. **Task 1: Cover configured public admission boundaries and sticky chunk terminals** — `3fd94e1`.
2. **Task 2: Exercise A2 selected-work, failed-output acknowledgement, and replay-mismatch paths** — `82b5fd9`.

## Decisions Made

- Use a fail-closed outline guard so the valid wildcard selector cannot silently execute zero tests.
- Keep public and white-box replay tests on the identical mutable 5×1 RGB8 stimulus and exact 57-byte failure boundary.

## Deviations from Plan

None — plan scope and owned paths were preserved.

## Issues Encountered

- The first native compile exposed test-only MoonBit constraints in a helper and an Option comparison; both were corrected before the full verification run.

## Known Stubs

None.

## Next Phase Readiness

Phase 33's configured-route evidence is complete. Phase 34 corpus, decoder-round-trip corpus evidence, compression claims, and benchmarks remain intentionally excluded.

## Self-Check: PASSED

- Confirmed all four modified test files and both task commits exist.
- Confirmed no placeholder or TODO-style stub marker in the plan-owned test changes.
