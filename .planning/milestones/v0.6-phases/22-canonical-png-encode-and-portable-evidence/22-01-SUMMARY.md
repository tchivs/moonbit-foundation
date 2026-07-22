---
phase: 22-canonical-png-encode-and-portable-evidence
plan: "01"
subsystem: image-codec
tags: [moonbit, png, stored-deflate, crc32, adler32, portable]
requires:
  - phase: 21-bounded-png-decode-and-deflate
    provides: strict eager PNG decoder, checked PNG framing, and portable DEFLATE helpers
provides:
  - canonical RGB8 and straight-RGBA8 PngEncoder through the ImageEncoder contract
  - byte-level stored-DEFLATE PNG conformance checks
  - public four-target decode-flip-encode evidence executable
affects: [png, image-codec, portable-examples]
tech-stack:
  added: []
  patterns: [zero-write image encoder preflight, deterministic stored-DEFLATE fixture evidence]
key-files:
  created: [modules/mb-image/png/encode.mbt, modules/mb-image/png/encode_test.mbt, modules/mb-image/png/encode_wbtest.mbt, examples/png-portable/main/main.mbt]
  modified: [modules/mb-image/png/png.mbt, moon.work]
key-decisions:
  - "Encode only packed U8 RGB8 and straight-RGBA8 TopLeft built-in encoded-sRGB views, rejecting all metadata and layout variance before Writer access."
  - "Freeze filter-None scanlines in a single zlib stored-DEFLATE IDAT representation for deterministic all-target bytes."
patterns-established:
  - "PNG eager encoders construct and validate the complete byte representation before charging the caller budget and writing."
  - "Portable public examples compare fixed bytes and a target-neutral digest, then print one stable evidence line."
requirements-completed: [PNG-06, PNG-07]
coverage:
  - id: D1
    description: Canonical PNG encoding with zero-write preflight and exact Writer progress.
    requirement: PNG-06
    verification:
      - kind: unit
        ref: moon -C modules/mb-image test png --target all --frozen
        status: pass
    human_judgment: false
  - id: D2
    description: Public decode→flip-horizontal→encode evidence produces fixed PNG bytes on every supported target.
    requirement: PNG-07
    verification:
      - kind: integration
        ref: moon -C examples/png-portable run main --target {js,wasm,wasm-gc,native} --frozen
        status: pass
    human_judgment: false
duration: 9min
completed: 2026-07-20
status: complete
---

# Phase 22 Plan 01: Canonical PNG Encode and Portable Evidence Summary

**Pure-MoonBit canonical PNG encoding for RGB8/straight-RGBA8, backed by stored-DEFLATE exact-byte proof and a public four-target decode→flip→encode workflow.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-07-20T17:55:05Z
- **Completed:** 2026-07-20T18:04:35Z
- **Tasks:** 2/2
- **Files modified:** 8

## Accomplishments

- Added `PngEncoder` with strict semantic/layout preflight, exact limit and budget charging, deterministic stored-DEFLATE framing, PNG CRC-32, and zlib Adler-32.
- Added public and white-box coverage for RGB/RGBA round trips, zero-write failures, Writer progress, block boundaries, checksums, and canonical-byte stability.
- Added a portable workspace executable that decodes a fixed PNG, flips it horizontally, re-encodes fixed expected bytes, and reports the same digest on js, wasm, wasm-gc, and native.

## Task Commits

1. **Task 1: Implement canonical stored-DEFLATE PngEncoder with zero-write preflight** - `d9ae639` (feat)
2. **Task 2: Prove canonical bytes and publish the four-target PNG workflow** - `c6806c1` (test)

## Files Created/Modified

- `modules/mb-image/png/png.mbt` - Publishes `PngEncoder` beside the existing decoder.
- `modules/mb-image/png/encode.mbt` - Performs complete preflight and emits canonical PNG output.
- `modules/mb-image/png/encode_test.mbt` - Exercises public encoder contracts and Writer errors.
- `modules/mb-image/png/encode_wbtest.mbt` - Independently verifies framing, stored-block fields, CRCs, and Adler values.
- `examples/png-portable/main/main.mbt` - Public fixed-input PNG interoperability workflow.
- `moon.work` - Registers the portable PNG example workspace member.

## Decisions Made

- Canonical output has one IHDR, one IDAT with zlib stored-DEFLATE filter-None scanlines, and one IEND; no semantic chunks, FFI, compression dependency, or public streaming surface was added.
- The public proof uses one compact 2×1 RGB vector so flip-horizontal changes pixels and the expected output remains easy to audit exactly.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed evidence comparison for a capacity-backed Writer view**
- **Found during:** Task 2
- **Issue:** The public example compared a 128-byte Writer capacity view as though it were exactly the 75-byte completed output.
- **Fix:** Compare the first completed 75 bytes, while retaining the exact expected-byte and digest assertions.
- **Files modified:** `examples/png-portable/main/main.mbt`
- **Verification:** Identical successful evidence output on js, wasm, wasm-gc, and native.
- **Committed in:** `c6806c1`

**2. [Rule 3 - Blocking] Expanded public-run verification per target**
- **Found during:** Task 2
- **Issue:** The installed MoonBit CLI accepts one backend for `run`; `--target all` is rejected.
- **Fix:** Ran the exact same executable separately for js, wasm, wasm-gc, and native.
- **Verification:** Each target printed the same evidence line.
- **Committed in:** N/A (verification procedure only)

**Total deviations:** 2 auto-fixed (1 bug, 1 blocking verification adjustment).

## Issues Encountered

`moon test --target all` supports all backends, while `moon run` requires one backend at a time. No code or dependency workaround was needed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

PNG-06 and PNG-07 have deterministic public evidence and remain limited to the intended strict eager RGB/RGBA interchange profile.

## Self-Check: PASSED

Verified all eight task files and both task commits (`d9ae639`, `c6806c1`) exist; the task-file stub scan found no placeholder or TODO markers.

*Phase: 22-canonical-png-encode-and-portable-evidence*
*Completed: 2026-07-20*
