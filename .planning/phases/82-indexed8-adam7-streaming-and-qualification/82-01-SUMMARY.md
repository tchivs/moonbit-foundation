---
phase: 82-indexed8-adam7-streaming-and-qualification
plan: 01
subsystem: testing
tags: [moonbit, png, indexed8, adam7, streaming, portability]
requires:
  - phase: 81-indexed8-adam7-machine-and-eager-wire-contract
    provides: Indexed8 Adam7 eager/chunk selector and literal wire oracle
provides:
  - Indexed8 Adam7 hostile caller-lease qualification
  - Chunk-origin framing, raster, and public-decode evidence
affects: [png streaming, indexed8 adam7, four-target qualification]
tech-stack:
  added: []
  patterns: [test-owned zero-length lease backed by a sentinel byte, independent chunk-origin PNG qualification]
key-files:
  created: []
  modified: [modules/mb-image/png/stream_encode_test.mbt]
key-decisions:
  - "Keep Phase 82 test-only: exercise the existing Adam7 chunk facade and shared machine without changing production code."
  - "Use a one-byte sentinel owner for a zero-length lease so zero-capacity pulls prove destination ownership without an out-of-bounds test read."
patterns-established:
  - "Caller-lease schedules with recurring zero capacities preserve the previously accepted total; only the first zero-capacity lease has total zero."
requirements-completed: [INDEXADAM7-05, INDEXADAM7-06]
coverage:
  - id: D1
    description: Indexed8 Adam7 chunk lifecycle preserves eager identity, accepted-only accounting, caller tails, and sticky terminals.
    requirement: INDEXADAM7-05
    verification:
      - kind: unit
        ref: modules/mb-image/png/stream_encode_test.mbt#PNG Indexed8 Adam7 chunk hostile leases qualify stream-origin bytes
        status: pass
      - kind: unit
        ref: modules/mb-image/png/stream_encode_test.mbt#PNG Indexed8 Adam7 chunk replays released lease failure
        status: pass
    human_judgment: false
  - id: D2
    description: Drained Type-3/8 Adam7 bytes prove framing, CRCs, literal raster, RGBA decode, and portability.
    requirement: INDEXADAM7-06
    verification:
      - kind: integration
        ref: moon -C modules/mb-image test png --target all --frozen
        status: pass
    human_judgment: false
duration: 39min
completed: 2026-07-24
status: complete
---

# Phase 82 Plan 01: Indexed8 Adam7 Streaming and Qualification Summary

**Indexed8 Adam7 chunk streaming is qualified under hostile caller leases with independent chunk-origin PNG framing, raw-raster, and public-decode evidence across every supported target.**

## Performance

- **Duration:** 39 min
- **Started:** 2026-07-23T23:35:24Z
- **Completed:** 2026-07-24T00:14:25Z
- **Tasks:** 2/2
- **Files modified:** 1

## Accomplishments

- Added RED/GREEN TDD coverage for zero-capacity, one-byte, and ragged Indexed8 Adam7 caller leases, including accepted-only totals, untouched tails, and sticky Finished/Failed replay.
- Independently qualified drained chunk bytes for Type-3/8 Adam7 IHDR, PLTE/tRNS, CRCs, Stored seven-pass raster, and all 25 public RGBA palette pixels.
- Kept all production files unchanged and passed the frozen PNG suite on wasm, wasm-gc, js, and native.

## Task Commits

1. **Task 1: Add the failing Indexed8 Adam7 hostile lifecycle and chunk-origin tracer** — `5520dd1` (test)
2. **Task 2: Implement only the test helper and close Indexed8 Adam7 streaming qualification** — `8e27a00` (test)

## Files Created/Modified

- `modules/mb-image/png/stream_encode_test.mbt` — Adam7 stream-local fixture, hostile lease driver, sticky release test, and independent chunk-origin qualification.

## Decisions Made

- Exercised the Phase 81 selector exclusively; no production encoder, transport, model, or FFI code changed.
- Used an owned one-byte `Z` buffer with a zero-length lease to prove zero-capacity behavior while retaining a real untouched-tail sentinel.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected recurring zero-capacity progress accounting in the test helper**
- **Found during:** Task 2
- **Issue:** The ragged schedule repeats zero capacity after accepted output, so requiring `total_written == 0` on every zero-capacity pull was incorrect.
- **Fix:** Require zero writes and unchanged total for every zero-capacity pull, with total zero specifically for the first such pull.
- **Files modified:** `modules/mb-image/png/stream_encode_test.mbt`
- **Verification:** Targeted JS/native tests and the frozen four-target suite pass.
- **Committed in:** `8e27a00`

**2. [Rule 3 - Blocking] Repaired legacy planning-state text after SDK parse failure**
- **Found during:** Plan state updates
- **Issue:** `state.advance-plan` could not parse the legacy `Plan: Not started` line even though the phase's summary count and frontmatter progress were complete.
- **Fix:** Updated the stale human-readable state fields to reflect the SDK-recorded 100% progress and completed plan.
- **Files modified:** `.planning/STATE.md`
- **Verification:** `gsd-tools progress` reports Phase 82 as Executed with 2/2 summaries.

---

**Total deviations:** 2 auto-fixed (Rule 1, Rule 3)
**Impact on plan:** The code correction strengthens accepted-only progress proof; the planning-state fallback only reconciles stale execution metadata. No production scope expansion.

## Issues Encountered

- Native aborts from a zero-length owner obscured the test assertion; a one-byte sentinel owner with a zero-length lease gives the required ownership evidence and works on all targets.

## Known Stubs

None.

## Next Phase Readiness

- Indexed8 Adam7 stream qualification and four-target portability proof are complete.
- No production changes or remaining blockers.

## Self-Check: PASSED

- Found `modules/mb-image/png/stream_encode_test.mbt`.
- Found commits `5520dd1` and `8e27a00`.

---
*Phase: 82-indexed8-adam7-streaming-and-qualification*
*Completed: 2026-07-24*
