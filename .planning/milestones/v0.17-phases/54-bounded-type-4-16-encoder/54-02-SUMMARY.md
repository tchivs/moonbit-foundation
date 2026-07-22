---
phase: 54-bounded-type-4-16-encoder
plan: "02"
subsystem: png-encoding
tags: [moonbit, png, grayalpha16, u16, bounded-encoding, streaming, regression-tests]
requires:
  - phase: 54-bounded-type-4-16-encoder
    provides: explicit bounded Type-4/16 GrayAlpha16 eager and caller-buffered encoder routes
provides:
  - Six-pair GrayAlpha16 atomic-admission regression coverage
  - Fixed and Dynamic Adaptive U16 replay-drift sticky-terminal coverage
affects: [55-grayalpha16-portable-public-evidence, png-encoding]
tech-stack:
  added: []
  patterns: [public eager-chunk error parity, caller-lease sentinel verification, checked U16 replay drift]
key-files:
  created: []
  modified:
    - modules/mb-image/png/stream_encode_test.mbt
key-decisions:
  - "All GrayAlpha16 admission matrices use legal little-endian sources; Big-endian GrayAlpha16 remains rejected at the locked descriptor boundary."
  - "Replay drift coverage uses the existing public chunk factories and one-byte accepted framing prefix, with no production-path changes."
patterns-established:
  - "Profile-specific bounded tests assert writer state, resource ledger state, typed eager/chunk errors, and every sentinel lease byte."
requirements-completed: [GRAYA16-03]
coverage:
  - id: D1
    description: GrayAlpha16 rejects incompatible, geometry-, output-, work-, and budget-limited construction atomically across every legal compression/filter pair.
    requirement: GRAYA16-03
    verification:
      - kind: unit
        ref: modules/mb-image/png/stream_encode_test.mbt#PNG GrayAlpha16 strategy admission is atomic
        status: pass
    human_judgment: false
  - id: D2
    description: Fixed and Dynamic GrayAlpha16 Adaptive replay detects a checked U16 source mutation before caller-lease writes and keeps the terminal error sticky.
    requirement: GRAYA16-03
    verification:
      - kind: unit
        ref: modules/mb-image/png/stream_encode_test.mbt#PNG GrayAlpha16 Fixed and Dynamic replay mutations are sticky
        status: pass
    human_judgment: false
duration: 5min
completed: 2026-07-23
status: complete
---

# Phase 54 Plan 02: Bounded Type-4/16 Encoder Summary

**GrayAlpha16 now has focused public regressions proving six-pair atomic admission and zero-write sticky replay drift across the bounded Type-4/16 streaming route.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-07-23T05:15:00+08:00
- **Completed:** 2026-07-23T05:20:36+08:00
- **Tasks:** 2/2
- **Files modified:** 1

## Accomplishments

- Added the all-six-pair GrayAlpha16 admission matrix for incompatible source, geometry, output, work, and budget failures.
- Proved eager/chunk structured-error parity, zero eager output, unchanged budget ledgers, and untouched preallocated caller-lease sentinels.
- Added Fixed and Dynamic Adaptive replay regressions which mutate a checked alpha U16 component after framing acceptance and require pre-write sticky terminal failures.

## Verification

| Command | Result |
| --- | --- |
| `moon -C modules/mb-image test png --target native --frozen --filter '*GrayAlpha16*'` | PASS — 7 passed, 0 failed |
| `moon -C modules/mb-image test png --target native --frozen` | PASS — 203 passed, 0 failed |
| `git diff --check` | PASS |

## Task Commits

1. **Task 1: Assert pre-exposure atomic GrayAlpha16 admission for all strategy pairs**
   - `21ab3b9` — atomic public-constructor, error-parity, budget, and sentinel-lease regressions.
2. **Task 2: Prove GrayAlpha16 Fixed and Dynamic replay errors are pre-write and sticky**
   - `92ca163` — four-byte-profile Fixed/Dynamic Adaptive replay-drift regressions.

## Files Created/Modified

- `modules/mb-image/png/stream_encode_test.mbt` — GrayAlpha16 atomic-admission and sticky U16 replay test helpers and cases.

## Decisions Made

- Retained Phase 53 and Plan 01's locked little-endian-only GrayAlpha16 source contract. Big-endian descriptor rejection is a model-boundary test, not a PNG factory parity case.
- Reused the existing public factory, budget, error-comparison, one-byte pull, and sentinel-owner helpers; no alternate pipeline or production behavior was introduced.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. The focused regression suite passed immediately because Plan 01 already supplied the required bounded implementation.

## Known Stubs

None. The modified test file has no placeholder behavior, TODO/FIXME marker, or unwired data path.

## Next Phase Readiness

- Phase 55 can build independent portable/public evidence on a now-regression-protected GrayAlpha16 bounded route.
- Big-endian GrayAlpha16 remains expressly outside encoder scope and rejected at descriptor construction.

## Self-Check: PASSED

- Modified test file and this summary exist.
- Task commits `21ab3b9` and `92ca163` exist in repository history.

---
*Phase: 54-bounded-type-4-16-encoder*
*Plan: 02*
*Completed: 2026-07-23*
