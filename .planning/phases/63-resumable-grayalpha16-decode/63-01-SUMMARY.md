---
phase: 63-resumable-grayalpha16-decode
plan: "01"
subsystem: png decoder
tags: [moonbit, png, graya16, streaming, decode]
requires:
  - phase: 62-explicit-grayalpha16-decode-contract
    provides: Private GrayAlpha16 profile, eager decoder selector, and atomic first-IDAT admission.
provides:
  - Public PngChunkDecoder::new_graya16 selector using the existing GrayAlpha16 machine profile.
  - Public schedule and terminal regressions for explicit Type-4/16 chunk decoding.
affects: [png decoding, resumable callers, phase-64 qualification]
tech-stack:
  added: []
  patterns:
    - Profile-selected chunk factories reuse the shared machine for ownership, progress, EOF, and sticky terminal behavior.
key-files:
  created: []
  modified:
    - modules/mb-image/png/png.mbt
    - modules/mb-image/png/stream_decode_test.mbt
key-decisions:
  - "Add only new_graya16 and select the existing private GrayAlpha16 profile through the current chunk machine."
  - "Use a U16 component-byte peer comparator so explicit fidelity evidence cannot accidentally validate generic RGBA8 widening."
patterns-established:
  - "Compare opt-in profile chunk schedules with a fresh eager peer and directly observe representation-specific byte lanes."
requirements-completed: [GRA16DEC-02]
coverage:
  - id: D1
    description: "Explicit chunk decoding preserves declaration-free and sRGB Type-4/16 results across zero, one-byte, and ragged caller schedules."
    requirement: GRA16DEC-02
    verification:
      - kind: unit
        ref: "moon -C modules/mb-image test png --target js --frozen --filter '*graya16 chunk*'"
        status: pass
    human_judgment: false
  - id: D2
    description: "Explicit chunk decoding retains early-EOF, malformed, metadata-rejection, and input-limit atomic sticky terminals while generic decoding stays RGBA8-compatible."
    requirement: GRA16DEC-02
    verification:
      - kind: unit
        ref: "moon -C modules/mb-image test png --target js --frozen --filter '*graya16 chunk*'"
        status: pass
    human_judgment: false
duration: 4min
completed: 2026-07-23
status: complete
---

# Phase 63 Plan 01: Resumable GrayAlpha16 Decode Summary

**PngChunkDecoder::new_graya16 now exposes the existing Type-4/16 preservation profile through the shared, caller-owned bounded chunk lifecycle.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-07-23T05:54:31Z
- **Completed:** 2026-07-23T05:58:55Z
- **Tasks:** 2/2
- **Files modified:** 2

## Accomplishments

- Added the sole public `PngChunkDecoder::new_graya16` selector, retaining strict options and all shared machine state.
- Proved declaration-free and sRGB Type-4/16 eager parity under zero-length, one-byte, and prescribed ragged caller schedules, including packed `34,12,c5,a7` and `0f,be,76,5a` component lanes.
- Proved early EOF, malformed input, profile metadata rejection, and input-limit terminals remain atomic and sticky; confirmed the generic chunk selector retains RGBA8 high-byte output.

## Task Commits

1. **Task 1: Red-green explicit GrayAlpha16 chunk selector and eager-parity schedules** - `34055bd` (RED test), `8087d22` (implementation and U16-aware test comparator)
2. **Task 2: Red-green hostile terminal, atomic rejection, and generic-compatibility evidence** - `1386090` (test evidence; the reused lifecycle already satisfied the asserted behavior)

## Files Created/Modified

- `modules/mb-image/png/png.mbt` - adds the sole explicit profile-selected chunk constructor.
- `modules/mb-image/png/stream_decode_test.mbt` - adds explicit schedule, eager-peer, terminal, and generic-compatibility coverage.

## Decisions Made

- Kept `PngChunkDecoder::new` unchanged and routed the additive explicit selector directly to `PngDecodeMachine::new_with_profile(GrayAlpha16, ...)`.
- Reused shared push/finish behavior rather than duplicating parser, source retention, result transfer, or terminal state.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Replaced the generic U8 result comparator in explicit-profile coverage**
- **Found during:** Task 1
- **Issue:** The generic schedule comparator reads U8 channel lanes and aborts on the U16 explicit image contract.
- **Fix:** Added a narrow public-shape comparator that validates metadata, disposition, budgets, diagnostics, and every U16 component byte.
- **Files modified:** `modules/mb-image/png/stream_decode_test.mbt`
- **Verification:** `moon -C modules/mb-image test png --target js --frozen --filter '*graya16 chunk*'`
- **Committed in:** `8087d22`

---

**Total deviations:** 1 auto-fixed (1 Rule 1 bug)
**Impact on plan:** Required for accurate explicit U16 parity evidence; no scope expansion.

## TDD Gate Compliance

- RED and GREEN commits exist in order: `34055bd` then `8087d22`.
- Task 2's new terminal evidence passed immediately because Task 1 deliberately reused the existing lifecycle that already owns those terminal semantics; no production change was needed.

## Verification

- Passed: `moon -C modules/mb-image test png --target js --frozen --filter '*graya16 chunk*'` (2/2).

## Known Stubs

None.

## Self-Check: PASSED

- Confirmed both modified source/test files and this summary exist.
- Confirmed TDD and terminal-evidence commits `34055bd`, `8087d22`, and `1386090` exist in git history.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 64 can qualify this explicit resumable route across its deferred filter, Adam7, resource, and portable-target matrix without changing the generic chunk contract.

---
*Phase: 63-resumable-grayalpha16-decode*
*Completed: 2026-07-23*
