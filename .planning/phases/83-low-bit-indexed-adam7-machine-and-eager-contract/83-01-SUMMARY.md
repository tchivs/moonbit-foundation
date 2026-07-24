---
phase: 83-low-bit-indexed-adam7-machine-and-eager-contract
plan: 01
subsystem: png-encoding
tags: [moonbit, png, indexed-color, adam7, streaming]
requires:
  - phase: 82-indexed8-adam7-stream-qualification
    provides: Indexed8 Adam7's acknowledged machine and selector pattern
provides:
  - Explicit Type-3 Indexed1/2/4 Adam7 eager and chunk selectors
  - Profile-aware checked Adam7 preflight and local MSB-first packed replay
  - Independent low-bit eager wire, decode, and admission evidence
affects: [84-low-bit-indexed-adam7-streaming-qualification]
tech-stack:
  added: []
  patterns: [single acknowledged machine, profile-aware Adam7 geometry, literal wire oracle]
key-files:
  created: []
  modified:
    - modules/mb-image/png/encode.mbt
    - modules/mb-image/png/stream_encode.mbt
    - modules/mb-image/png/encode_test.mbt
    - modules/mb-image/png/encode_wbtest.mbt
    - modules/mb-image/png/stream_encode_test.mbt
key-decisions:
  - "Selected low-bit public facades share one private PngIndexedBitDepth-to-wire-profile mapper; legacy facades explicitly forward None."
  - "Adam7 preflight and scalar replay both derive passes from the requested profile depth, with no packed source or staging."
patterns-established:
  - "Low-bit Adam7 payload bytes restart packing at each pass-local column zero and preserve zero tail bits."
requirements-completed: [INDEXLOWADAM7-01, INDEXLOWADAM7-02, INDEXLOWADAM7-03, INDEXLOWADAM7-04]
coverage:
  - id: D1
    description: Selected Indexed1/2/4 eager and chunk Adam7 selectors preserve legacy None forwards.
    requirement: INDEXLOWADAM7-01
    verification:
      - kind: integration
        ref: moon -C modules/mb-image test png --target all --frozen
        status: pass
    human_judgment: false
  - id: D2
    description: The existing machine derives selected-depth Adam7 geometry and locally packs MSB-first zero-tailed payloads.
    requirement: INDEXLOWADAM7-02
    verification:
      - kind: integration
        ref: modules/mb-image/png/encode_test.mbt#PNG selected low-bit Adam7 eager wires literal packed passes and palette decode
        status: pass
    human_judgment: false
  - id: D3
    description: Literal 5x5 Type-3 frames prove framing, CRCs, stored raster bytes, PLTE/tRNS, and RGB8/RGBA8 decode.
    requirement: INDEXLOWADAM7-03
    verification:
      - kind: integration
        ref: modules/mb-image/png/encode_test.mbt#PNG selected low-bit Adam7 eager wires literal packed passes and palette decode
        status: pass
    human_judgment: false
  - id: D4
    description: Exact selected-depth frame and work limits admit once while rejected output, work, cap, and overflow cases remain atomic.
    requirement: INDEXLOWADAM7-04
    verification:
      - kind: unit
        ref: modules/mb-image/png/encode_wbtest.mbt#PNG selected low-bit Adam7 preflight facts and admission are exact
        status: pass
    human_judgment: false
duration: 15m
completed: 2026-07-24
status: complete
---

# Phase 83 Plan 01: Low-Bit Indexed Adam7 Machine and Eager Contract Summary

**Type-3 Indexed1, Indexed2, and Indexed4 Adam7 output now uses the existing acknowledged PNG machine with checked pass-local packing and atomic frame admission.**

## Performance

- **Duration:** 15m
- **Started:** 2026-07-24T09:25:17+08:00
- **Completed:** 2026-07-24T09:39:37+08:00
- **Tasks:** 2/2
- **Files modified:** 5

## Accomplishments

- Added additive eager and chunk selected-depth interlace selectors; existing low-bit and Indexed8 compatibility routes remain explicit non-interlaced forwards.
- Generalized Adam7 preflight and replay to use profile-depth geometry, with per-pass local MSB-first packing and deterministic zero tails inside the sole machine.
- Added independent 5x5 wire/frame/CRC/decode oracles, atomic preflight facts, and a sufficient-lease selector smoke without importing Phase 84 hostile-lifecycle scope.

## Task Commits

1. **Task 1: Add independent failing 5×5 low-bit Adam7 wire, framing, preflight, and freeze tracers** — `db90dbb` (test)
2. **Task 2: Generalize selected-depth Adam7 preflight and local packing in the sole machine** — `555877e` (feat)

## Files Created/Modified

- `modules/mb-image/png/encode.mbt` — selected-depth eager selector, shared profile mapper, and profile-aware Adam7 preflight.
- `modules/mb-image/png/stream_encode.mbt` — thin chunk selector and bounded pass-local low-bit byte provider.
- `modules/mb-image/png/encode_test.mbt` — literal wire/framing/CRC/RGBA8/RGB8 evidence.
- `modules/mb-image/png/encode_wbtest.mbt` — exact frame/work/atomicity preflight evidence.
- `modules/mb-image/png/stream_encode_test.mbt` — ordinary sufficient-lease selected-depth Adam7 IHDR smoke.

## Decisions Made

- Shared one selected-depth profile mapper between public eager and chunk facades.
- Kept low-bit Adam7 as scalar bounded replay in the existing machine; no pass, image, or output staging was added.
- Retained Stored DEFLATE, filter None, palette-cap, and canonical tRNS contracts.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test oracle] Corrected inconsistent fixture literals**

- **Found during:** Task 2
- **Issue:** The supplied depth-1 fixture source had a transcribed final-row code, and the supplied depth-2 `B4` pass byte conflicted with the stated `23012` rows; MSB-first packing of those literal rows is `B1`.
- **Fix:** Restored the stated depth-1 row and used the independently derived `B1` literal for the depth-2 pass rows.
- **Files modified:** `modules/mb-image/png/encode_test.mbt`
- **Verification:** Native and four-target PNG package gates pass.
- **Committed in:** `555877e`

**Total deviations:** 2 auto-fixed (Rule 1 test oracle correction; Rule 3 execution-metadata recovery).

### Execution Metadata

- [Rule 3 - Blocking] The state SDK could not parse this repository's legacy `Plan: —` position field for `state.advance-plan`; the affected Phase 83/84 position and completed roadmap row were updated directly after all other named state handlers completed.

## TDD Gate Compliance

- RED: `db90dbb` records the intended missing-selector test failure.
- GREEN: `555877e` implements the selectors and shared machine behavior.

## Issues Encountered

- The first GREEN compile exposed a required `UInt64 -> Int` conversion at the shared Adam7 geometry API boundary; corrected inline before verification.

## User Setup Required

None.

## Next Phase Readiness

Phase 84 can qualify the existing selected-depth chunk facade under hostile lease schedules and independently parse collected chunk-origin bytes. No machine architecture work remains.

## Verification

- `moon -C modules/mb-image test png --target native --frozen` — pass (294/294).
- `moon -C modules/mb-image test png --target all --frozen` — pass (294/294 each on wasm, wasm-gc, js, and native).

## Self-Check: PASSED

All five modified implementation/test files and both task commits are present.

*Phase: 83-low-bit-indexed-adam7-machine-and-eager-contract*
*Completed: 2026-07-24*
