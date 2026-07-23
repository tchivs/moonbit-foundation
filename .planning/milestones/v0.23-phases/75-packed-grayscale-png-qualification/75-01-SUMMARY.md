---
phase: 75-packed-grayscale-png-qualification
plan: 01
subsystem: testing
tags: [png, grayscale, packed-pixels, qualification, moonbit]
requires:
  - phase: 74-resumable-packed-grayscale-png
    provides: Packed grayscale eager/chunk lifecycle and compatibility coverage
provides:
  - Independent complete Type-0 1/2/4-bit PNG wire vectors
  - Public decode and eager whole-file wire qualification
affects: [png, grayscale, qualification]
tech-stack:
  added: []
  patterns: [Hand-authored complete PNG literals as encoder-independent wire oracles]
key-files:
  created: [.planning/phases/75-packed-grayscale-png-qualification/75-01-SUMMARY.md]
  modified: [modules/mb-image/png/png_test.mbt]
key-decisions:
  - "Type-0 grayscale generic decode retains the established opaque RGB8 public contract, rather than introducing an RGBA8 API change."
patterns-established:
  - "Use complete CRC-valid external PNG fixtures for both public decode and eager whole-file equality."
requirements-completed: [GRAYPACK-04]
coverage:
  - id: D1
    description: Independent Type-0 1/2/4-bit PNG vectors decode to canonical opaque RGB8 gray samples and consume all source bytes.
    requirement: GRAYPACK-04
    verification:
      - kind: unit
        ref: modules/mb-image/png/png_test.mbt#PNG packed grayscale public qualification literals decode and freeze eager wire
        status: pass
    human_judgment: false
  - id: D2
    description: Public Gray1, Gray2, and Gray4 eager encoders reproduce the matching full external PNG wire streams.
    requirement: GRAYPACK-04
    verification:
      - kind: integration
        ref: moon -C modules/mb-image test png --target native --frozen
        status: pass
    human_judgment: false
  - id: D3
    description: The ordinary PNG suite retains packed lifecycle and legacy compatibility evidence across all supported targets.
    requirement: GRAYPACK-04
    verification:
      - kind: integration
        ref: moon -C modules/mb-image test png --target all --frozen (verified per target in isolated target directories)
        status: pass
    human_judgment: false
duration: 24min
completed: 2026-07-24
status: complete
---

# Phase 75 Plan 01: Packed Grayscale PNG Qualification Summary

**Independent CRC-valid Type-0 Gray1/2/4 PNG literals now prove public RGB8 decode semantics and complete eager wire-byte stability.**

## Performance

- **Tasks:** 2 completed
- **Files modified:** 2
- **Verification:** native, wasm, wasm-gc, and js PNG suites passed.

## Accomplishments

- Added three complete hand-authored Type-0 PNG fixtures with Stored-DEFLATE, framing, and CRC evidence for 1-, 2-, and 4-bit grayscale rows.
- Asserted full public source consumption, dimensions, opaque RGB8 descriptor/metadata, and independently spelled R=G=B sample values.
- Compared Gray1, Gray2, and Gray4 public eager output byte-for-byte to the external complete PNG fixtures while retaining existing lifecycle and legacy coverage unchanged.

## Decisions Made

- Preserved the existing generic Type-0 public RGB8 contract: opaque grayscale has three RGB channels and no alpha metadata. This reconciles the plan wording with established compatibility behavior without changing production APIs.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test limits] Raised the qualification decode width bound for the nine-pixel Gray1 fixture.**
- **Found during:** Task 1
- **Issue:** An older eight-pixel qualification limit rejected the required width-nine vector.
- **Fix:** Added a local bounded limit with `max_width=16`.
- **Files modified:** `modules/mb-image/png/png_test.mbt`

**2. [Compatibility clarification] Used the established public opaque RGB8 result instead of a fourth RGBA8 channel.**
- **Found during:** Task 1
- **Issue:** Generic Type-0 grayscale decoding intentionally exposes RGB8 with no alpha metadata; requesting channel 3 fails.
- **Fix:** Asserted U8/RGB descriptor, absent alpha metadata, and exact equal RGB channels; no production behavior changed.
- **Files modified:** `modules/mb-image/png/png_test.mbt`

## Verification

- `moon -C modules/mb-image test png --target native --frozen --filter "*packed grayscale public qualification*" --no-parallelize --quiet --target-dir <isolated>` — passed.
- `moon -C modules/mb-image test png --target native --frozen --no-parallelize --quiet --target-dir <isolated>` — passed.
- `moon -C modules/mb-image test png --target wasm --frozen --no-parallelize --quiet --target-dir <isolated>` — passed.
- `moon -C modules/mb-image test png --target wasm-gc --frozen --no-parallelize --quiet --target-dir <isolated>` — passed.
- `moon -C modules/mb-image test png --target js --frozen --no-parallelize --quiet --target-dir <isolated>` — passed.

## Known Stubs

None.

## Next Phase Readiness

Packed grayscale PNG encode/decode qualification is complete with independent wire vectors and retained lifecycle/legacy evidence.
