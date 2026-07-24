---
phase: 84-low-bit-indexed-adam7-streaming-qualification
plan: 01
subsystem: testing
tags: [moonbit, png, adam7, indexed-color, streaming, portability]
requires:
  - phase: 83-low-bit-indexed-adam7-machine-and-eager-contract
    provides: selected-depth Type-3 Adam7 encoder and literal pass vectors
provides:
  - Caller-owned hostile-lease qualification for Indexed1/2/4 Adam7 streams
  - Independent Type-3 PNG framing, CRC, Stored raster, packing, and decode oracle
affects: [png-streaming, indexed-color, adam7-conformance]
tech-stack:
  added: []
  patterns: [test-local chunk parser, local Adam7 packing oracle, sentinel-backed zero-capacity lease]
key-files:
  created: []
  modified: [modules/mb-image/png/stream_encode_test.mbt]
key-decisions:
  - "The selected-depth Adam7 chunk selector remains the sole exercised stream route."
  - "Collected bytes are qualified against literal data and local pass arithmetic; eager bytes provide lifecycle parity only."
patterns-established:
  - "Use a one-byte Z owner with a zero-length borrowed lease to observe zero-capacity preservation."
  - "Validate Type-3 Adam7 pass packing with local geometry and MSB-first expected bytes, including zero tail bits."
requirements-completed: [INDEXLOWADAM7-05, INDEXLOWADAM7-06]
coverage:
  - id: D1
    description: Hostile caller-owned Indexed1/2/4 Adam7 streams preserve accepted-only progress, sentinel tails, and sticky terminal outcomes.
    requirement: INDEXLOWADAM7-05
    verification:
      - kind: integration
        ref: moon -C modules/mb-image test png --target all --frozen
        status: pass
    human_judgment: false
  - id: D2
    description: Collected low-bit Adam7 bytes prove Type-3 framing, CRCs, literal Stored pass raster, local packing, and public RGB8/RGBA8 decode.
    requirement: INDEXLOWADAM7-06
    verification:
      - kind: integration
        ref: modules/mb-image/png/stream_encode_test.mbt#PNG selected low-bit Adam7 chunk qualifies every hostile lease schedule
        status: pass
      - kind: integration
        ref: moon -C modules/mb-image test png --target all --frozen
        status: pass
    human_judgment: false
duration: 17min
completed: 2026-07-24
status: complete
---

# Phase 84 Plan 01: Low-Bit Indexed Adam7 Streaming Qualification Summary

**Caller-owned Indexed1/2/4 Adam7 streams now have independent Type-3 PNG, packed-pass, lifecycle, and RGB/RGBA decode evidence across all supported targets.**

## Performance

- **Duration:** 17 min
- **Started:** 2026-07-24T02:29:59Z
- **Completed:** 2026-07-24T02:47:23Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Added the Indexed1 TDD tracer with zero/one caller leases, accepted-only totals, sentinel tails, Finished replay, independent chunk framing, and transparent RGBA8 decode.
- Expanded the focused harness to One, Two, and Four under zero/one/ragged schedules plus released-lease sticky failures.
- Added literal Type-3 frame/raster assertions, local Adam7/MSB packing and zero-tail checks, and opaque RGB8 public decode from caller-buffered streams.
- Preserved the existing non-interlaced low-bit and Indexed8 Adam7 vectors; the frozen PNG suite passed on wasm, wasm-gc, js, and native.

## Task Commits

1. **Task 1: TDD tracer for one caller-owned Indexed1 Adam7 stream** - `a403933` (RED), `0f0d143` (GREEN)
2. **Task 2: Expand qualification to every low-bit depth, sticky failure, and frozen targets** - `2a6a225` (RED), `43c573d` (GREEN)

## Files Created/Modified

- `modules/mb-image/png/stream_encode_test.mbt` - Selected-depth Adam7 hostile lease matrix and independent collected-byte qualification.

## Decisions Made

- Exercised only `new_indexed_with_interlace_strategy(..., Adam7, ...)` for the route under test.
- Kept eager output as a supplementary lifecycle parity check; frame, CRC, Stored raster, packing, and decode checks consume collected stream bytes and fixed test-local literals.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected the local packing oracle shift-count type**
- **Found during:** Task 2
- **Issue:** MoonBit requires an `Int` shift count while the local pass arithmetic produces `UInt64`.
- **Fix:** Converted only the test-local shift count to `Int`.
- **Files modified:** `modules/mb-image/png/stream_encode_test.mbt`
- **Verification:** Native and all-target frozen PNG package gates passed.
- **Committed in:** `43c573d`

**Total deviations:** 1 auto-fixed (Rule 1)

## Issues Encountered

- The full native compile exceeded an initial short command timeout; it passed when rerun with an isolated longer-lived temporary target directory, which was removed after completion.

## Known Stubs

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The selected low-bit Adam7 stream route has portable, externally observed lifecycle and wire evidence. No production architecture or deferred scope changed.

## Self-Check: PASSED

- Confirmed `modules/mb-image/png/stream_encode_test.mbt` exists and task commits `a403933`, `0f0d143`, `2a6a225`, and `43c573d` are present.

---
*Phase: 84-low-bit-indexed-adam7-streaming-qualification*
*Completed: 2026-07-24*
