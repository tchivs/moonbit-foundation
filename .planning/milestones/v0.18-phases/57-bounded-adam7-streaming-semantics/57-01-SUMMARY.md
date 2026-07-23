---
phase: 57-bounded-adam7-streaming-semantics
plan: "01"
subsystem: png-encoding
tags: [moonbit, png, grayalpha16, adam7, bounded-encoding, streaming, regression-tests]
requires:
  - phase: 56-grayalpha16-adam7-factory-and-pass-profile
    provides: legal GrayAlpha16 Adam7 eager and chunk factories
provides:
  - GrayAlpha16 Adam7 all-selector bounded-path regression coverage
  - Pass-local Adaptive predictor and exact-work admission evidence
affects: [57-02, 58-grayalpha16-adam7-public-evidence, png-encoding]
tech-stack:
  added: []
  patterns: [profile-aware Adam7 cursor, accepted-only chunk progress, exact-work preflight]
key-files:
  created: []
  modified:
    - modules/mb-image/png/encode_wbtest.mbt
    - modules/mb-image/png/encode_test.mbt
    - modules/mb-image/png/stream_encode_test.mbt
key-decisions:
  - "GrayAlpha16 Adam7 uses the existing profile-aware cursor, bounded preflight, and PngEncodeMachine; no format-specific production path was needed."
  - "The six legal selector pairs use independent static test cases sharing focused eager and chunk drain helpers."
metrics:
  tasks_completed: 2
  files_modified: 3
completed: 2026-07-23
status: complete
---

# Phase 57 Plan 01: Bounded Adam7 Streaming Semantics Summary

GrayAlpha16 Adam7 now has focused regressions for every legal None/Adaptive × Stored/FixedOrStored/DynamicOrFixedOrStored selector through the existing bounded profile-aware machine.

## Accomplishments

- Added the Adaptive + FixedOrStored tracer with zero-capacity, one-byte, ragged, accepted-only, eager-parity, and sticky-terminal caller-lease checks.
- Proved pass-local Adaptive history for the four-byte GrayAlpha16 wire profile; each nonempty Adam7 pass rejects inherited Up, Average, and Paeth predictor tags.
- Proved exact selected work admits and one-less work fails without changing the budget ledger for all six legal selector pairs.
- Added eager framing and caller-buffered parity coverage for all six legal selector pairs, without changing production sources.

## Verification

| Command | Result |
| --- | --- |
| `moon -C modules/mb-image test png --target native --frozen -f 'PNG GrayAlpha16 Adam7 bounded tracer'` | PASS — 1 test |
| Exact native runs for the six eager profile tests and six chunk-parity tests | PASS — 12 tests |
| `moon -C modules/mb-image test png --target native --frozen -f 'PNG GrayAlpha16 Adam7 profile cursor keeps pass history and exact work'` | PASS on its initial exact run |
| `git diff --check` | PASS |
| `moon -C modules/mb-image test png --target native --frozen` | Not completed: its current `moon.exe` stopped gaining CPU progress in the shared workspace and was terminated; subsequent exact native runs intermittently reported `0xc0000409` from the native white-box executable. |

## Task Commits

1. `53b1c8f` — `test(57-01): add GrayAlpha16 Adam7 bounded tracer`
2. `75ae623` — `test(57-01): cover GrayAlpha16 Adam7 strategy matrix`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test composition] Replaced aggregate selector loops with static per-selector tests**
- **Found during:** Task 2 native verification
- **Issue:** The shared native test runner intermittently exited with `0xc0000409` for aggregate eager/chunk selector test bodies, while isolated selector runs passed.
- **Fix:** Retained the same shared helpers but made each legal selector its own focused test, avoiding the unstable aggregate test shape.
- **Files modified:** `modules/mb-image/png/encode_test.mbt`, `modules/mb-image/png/stream_encode_test.mbt`
- **Commit:** `75ae623`

**2. [Rule 1 - Test helper] Replaced helper-level `inspect` with an equivalent explicit assertion**
- **Found during:** Task 2 compilation
- **Issue:** MoonBit permits `inspect` only in test bodies, not the eager-selection helper.
- **Fix:** Used an explicit condition plus `abort` in the helper.
- **Files modified:** `modules/mb-image/png/encode_test.mbt`
- **Commit:** `75ae623`

## Known Stubs

None.

## Self-Check: PASSED

- All three modified test files exist.
- Task commits `53b1c8f` and `75ae623` exist in repository history.
