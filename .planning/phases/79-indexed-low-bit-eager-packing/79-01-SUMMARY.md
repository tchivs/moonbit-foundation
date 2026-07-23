---
phase: 79-indexed-low-bit-eager-packing
plan: 01
subsystem: png-encoding
tags: [moonbit, png, indexed-color, low-bit, eager-encoding]
requires:
  - phase: 78-resumable-indexed-png-qualification
    provides: Indexed8 source, eager encoder, and acknowledged Type-3 machine
provides:
  - Explicit eager Type-3 encoding at 1-, 2-, and 4-bit indexed depths
  - Atomic selected-depth palette and work admission
  - MSB-first, zero-tailed packed indexed scanlines
affects: [80-indexed-low-bit-caller-buffered]
tech-stack:
  added: []
  patterns: [private indexed wire profile with fixed-eight compatibility wrappers]
key-files:
  created: []
  modified:
    - modules/mb-image/png/png.mbt
    - modules/mb-image/png/encode.mbt
    - modules/mb-image/png/stream_encode.mbt
    - modules/mb-image/png/encode_test.mbt
    - modules/mb-image/png/encode_wbtest.mbt
key-decisions:
  - "Public PngIndexedBitDepth selects only One, Two, or Four; Indexed8 stays on its existing API."
  - "Low-bit packing is scalar machine emission, retaining canonical unpacked PngIndexedImage ownership."
  - "Fixed-Eight preflight and machine wrappers preserve existing eager, chunk, and white-box signatures."
patterns-established:
  - "Selected indexed depth maps once to a private wire fact used by admission, IHDR, and scanline packing."
requirements-completed: [INDEXLOW-01, INDEXLOW-02, INDEXLOW-03]
coverage:
  - id: D1
    description: Explicit eager Type-3 1/2/4-bit indexed PNG output
    requirement: INDEXLOW-01
    verification:
      - kind: unit
        ref: modules/mb-image/png/encode_test.mbt#Indexed1 Indexed2 Indexed4 eager tests
        status: pass
    human_judgment: false
  - id: D2
    description: Depth-specific packed facts, palette capacity, and atomic work admission
    requirement: INDEXLOW-02
    verification:
      - kind: unit
        ref: modules/mb-image/png/encode_wbtest.mbt#PNG low-bit indexed profiles derive packed facts and reject before work charge
        status: pass
    human_judgment: false
  - id: D3
    description: MSB-first zero-tail vectors with PLTE/tRNS and public RGB8/RGBA8 decode
    requirement: INDEXLOW-03
    verification:
      - kind: unit
        ref: modules/mb-image/png/encode_test.mbt#low-bit indexed eager vectors
        status: pass
    human_judgment: false
metrics:
  duration: 31min
  completed: 2026-07-23
status: complete
---

# Phase 79 Plan 01: Indexed Low-Bit Eager Packing Summary

**Explicit 1-, 2-, and 4-bit eager Type-3 PNG encoding packs canonical indexed pixels directly into MSB-first Stored scanlines while retaining frozen Indexed8 and chunk behavior.**

## Performance

- **Duration:** 31min
- **Tasks:** 2/2
- **Files modified:** 5
- **Verification:** `moon -C modules/mb-image test png --target all --frozen` — 282/282 on wasm, wasm-gc, JS, and native.

## Accomplishments

- Added public `PngIndexedBitDepth::{One, Two, Four}` and eager `PngEncoder::encode_indexed`.
- Added checked selected-depth row/frame admission, palette caps, and direct zero-tailed MSB-first scanline packing.
- Preserved `encode_indexed8` and `PngChunkEncoder::new_indexed8` through fixed-Eight compatibility wrappers.
- Added independent 1/2/4-bit wire vectors, public decode proof, and private selected-work/cap admission coverage.

## Task Commits

1. **Task 1 RED: failing Indexed2 tracer** — `b51146c` (test)
2. **Task 1 GREEN: eager low-bit encoder** — `283a089` (feat)
3. **Task 2: low-bit qualification** — `2aa8553` (test)

## Decisions Made

- Retained a fixed-Eight wrapper around preflight and machine construction so existing Indexed8 eager, chunk, and white-box callers remain byte-compatible.
- Kept the source model unpacked and generated packed bytes only in `PngEncodeMachine::scanline_byte`.

## Deviations from Plan

None - plan executed as written. No caller-buffered low-bit API or Phase 80 lifecycle work was added.

## Known Stubs

None.

## Self-Check: PASSED

- Verified all five planned PNG source/test files exist and all task commits are present in git history.

## Next Phase Readiness

Phase 80 can add the thin caller-buffered low-bit adapter over the authoritative eager machine without altering the fixed Indexed8 route.
