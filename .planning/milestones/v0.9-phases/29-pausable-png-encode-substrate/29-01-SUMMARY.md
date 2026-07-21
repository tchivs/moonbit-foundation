---
phase: 29-pausable-png-encode-substrate
plan: "01"
subsystem: png-encode
tags: [moonbit, png, stored-deflate, streaming, checksums]

requires:
  - phase: 22-canonical-png-encode-and-portable-evidence
    provides: Frozen RGB8 and straight-RGBA8 stored-DEFLATE PNG representation
provides:
  - Private `PngEncodeMachine` with explicit present/acknowledge byte ownership
  - Atomic shared PNG encode preflight with exact stored-DEFLATE output sizing
  - Eager PNG facade routed through the private emitter
affects: [30-public-png-chunk-encoder, 31-portable-png-streaming-evidence]

tech-stack:
  added: []
  patterns: [private byte-resumable state machine, admission-before-budget-charge]

key-files:
  created: [modules/mb-image/png/stream_encode.mbt]
  modified:
    - modules/mb-image/png/encode.mbt
    - modules/mb-image/png/stream_encode_test.mbt
    - modules/mb-image/png/stream_encode_wbtest.mbt

key-decisions:
  - "Preserve the existing eager PNG bytes by deriving signature, chunks, stored-DEFLATE, Adler-32, and CRC-32 from scalar machine state."
  - "Build disposition and all checked preflight facts before the single work-budget charge."

patterns-established:
  - "Private PNG emitters retain an unacknowledged byte until the consumer explicitly acknowledges it."
  - "Stored-DEFLATE trailer bytes are emitted separately from scanline payload and excluded from Adler accumulation."

requirements-completed: [PNGE-01]

coverage:
  - id: D1
    description: "Private canonical PNG emitter preserves eager RGB/RGBA bytes, exact stored-block framing, CRC/Adler ranges, and acknowledged-byte progress."
    requirement: PNGE-01
    verification:
      - kind: unit
        ref: "moon -C modules/mb-image test png --target all --frozen"
        status: pass
    human_judgment: false

duration: 21min
completed: 2026-07-21
status: complete
---

# Phase 29 Plan 01: Private PNG Encode Substrate Summary

**A private MoonBit PNG byte emitter now preserves canonical stored-DEFLATE output while atomically admitting compatible RGB8 and straight-RGBA8 sources.**

## Performance

- **Duration:** 21 min
- **Started:** 2026-07-21T12:52:36Z
- **Completed:** 2026-07-21T13:13:44Z
- **Tasks:** 2/2
- **Files modified:** 4

## Accomplishments

- Added private `PngEncodeMachine` with separate byte presentation and acknowledgement, checksum cursor state, and no caller output lease or output-sized staging buffer.
- Centralized checked capability, dimension, length, limits, disposition, and budget admission into one atomic preflight path shared by the eager facade.
- Added canonical byte, paused-byte, checksum, exact-length, and multi-stored-block regression coverage.

## Task Commits

1. **Task 1: Freeze private PNG encode admission and incremental-byte behavior** — `446fc42` (test)
2. **Task 2: Implement the shared preflight and private canonical emitter** — `8aa9173` (feat)

## Files Created/Modified

- `modules/mb-image/png/encode.mbt` — shared atomic preflight and eager-machine adapter.
- `modules/mb-image/png/stream_encode.mbt` — private resumable canonical PNG emitter.
- `modules/mb-image/png/stream_encode_test.mbt` — eager canonical-oracle coverage.
- `modules/mb-image/png/stream_encode_wbtest.mbt` — private cursor, checksum, ownership, and stored-block coverage.

## Decisions Made

- Keep the machine private and leave `png.mbt` and public encoder declarations unchanged for Phase 30.
- Advance output/checksum cursors only after an accepted byte is acknowledged.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Excluded the emitted Adler trailer from Adler accumulation**
- **Found during:** Task 2 verification
- **Issue:** Treating the trailer as scanline data invalidated the native emitter path.
- **Fix:** Emit the Adler trailer as a distinct zlib phase and update Adler only for filter/sample bytes.
- **Files modified:** `modules/mb-image/png/stream_encode.mbt`
- **Verification:** Focused JavaScript/native tests and the four-target PNG suite pass.
- **Committed in:** `8aa9173`

**2. [Rule 1 - Bug] Corrected the multi-block regression fixture budget**
- **Found during:** Task 2 verification
- **Issue:** The 65,535-byte stored-block boundary fixture used a work limit below its known canonical output length.
- **Fix:** Supplied the exact sufficient work budget to the white-box constructor assertion.
- **Files modified:** `modules/mb-image/png/stream_encode_wbtest.mbt`
- **Verification:** Focused JavaScript/native tests pass.
- **Committed in:** `8aa9173`

**Total deviations:** 2 auto-fixed (2 Rule 1 bugs)

## Issues Encountered

An early oversized black-box fixture produced a native test-process failure; moving the boundary assertion to the private machine test and correcting its work budget restored deterministic native coverage.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 30 can wrap the private machine in a public caller-buffered API without duplicating preflight or changing frozen eager bytes.

## Self-Check: PASSED

---
*Phase: 29-pausable-png-encode-substrate*
*Completed: 2026-07-21*
