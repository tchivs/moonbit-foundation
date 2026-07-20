---
phase: 10-alpha-correct-pixel-processing
plan: 01
subsystem: raster-processing
tags: [moonbit, rgba8, srgb, alpha, compositing, blur]
requires:
  - phase: 09-checked-image-geometry-and-diagnostics
    provides: checked descriptors, owned operation allocation, and typed resource diagnostics
provides:
  - linear-premultiplied source-over for strict straight encoded-sRGB RGBA8 inputs
  - deterministic Rec.709 grayscale and clamp-to-edge alpha-aware box blur
affects: [phase-11-portable-processing-pipeline-evidence]
tech-stack:
  added: []
  patterns: [typed color decode-store boundary, single output allocation after preflight]
key-files:
  created: [modules/mb-image/ops/processing.mbt, modules/mb-image/ops/processing_test.mbt, modules/mb-image/ops/processing_wbtest.mbt]
  modified: [modules/mb-image/ops/moon.pkg, modules/mb-image/README.mbt.md]
key-decisions:
  - "Raster processing accepts only packed U8 straight RGBA encoded-sRGB and performs every pixel calculation in linear premultiplied space."
  - "Source-over accepts only built-in sRGB, identical orientation, and empty opaque metadata, rejecting incompatibility before budget charge."
patterns-established:
  - "Operation preflight computes descriptor and declared work before exactly one OwnedImage::new_operation allocation."
requirements-completed: [RASTER-01, RASTER-02]
coverage:
  - id: D1
    description: Alpha-correct source-over with strict compatible metadata output.
    requirement: RASTER-01
    verification:
      - kind: unit
        ref: moon test modules/mb-image/ops --target js|wasm|wasm-gc|native
        status: pass
    human_judgment: false
  - id: D2
    description: Deterministic Rec.709 grayscale and alpha-aware clamp-to-edge box blur.
    requirement: RASTER-02
    verification:
      - kind: unit
        ref: moon test modules/mb-image/ops --target js|wasm|wasm-gc|native
        status: pass
    human_judgment: false
duration: 22min
completed: 2026-07-20
status: complete
---

# Phase 10 Plan 01: Alpha-Correct Pixel Processing Summary

**Straight encoded-sRGB RGBA8 compositing and filters now calculate in linear premultiplied space with deterministic quantization and checked resource semantics.**

## Performance

- **Duration:** 22 min
- **Tasks:** 3/3
- **Files modified:** 5

## Accomplishments

- Added `composite_source_over`, `grayscale`, and `box_blur` with fresh tightly packed output.
- Enforced metadata compatibility and all capability, extent, overflow, and budget checks before allocation.
- Documented linear-light source-over, Rec.709, clamp-to-edge blur, and radius-zero identity semantics.

## Task Commits

1. **Task 1: Specify public raster contract and hostile-input oracles** — `ad1361c` (test)
2. **Task 2: Implement linear-premultiplied processing** — `9cc581f` (feat)
3. **Task 3: Publish checked processing semantics** — `c2c4989` (docs)

## Verification

- `moon test modules/mb-image/ops --target js` — pass (31 tests)
- `moon test modules/mb-image/ops --target wasm` — pass (31 tests)
- `moon test modules/mb-image/ops --target wasm-gc` — pass (31 tests)
- `moon test modules/mb-image/ops --target native` — pass (31 tests; toolchain emitted two existing builtin warnings)
- `moon -C modules/mb-image check README.mbt.md --target js|wasm|wasm-gc|native --frozen` — pass

## Decisions Made

- Use typed sRGB decode/encode and ties-even quantization around every linear-premultiplied operation; encoded-domain arithmetic is never used.
- Keep blur reference-quality and fixed-window; it has no intermediate images or optimization paths.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test correctness] Corrected initial white-box fixture literals and isolated helpers.**
- **Found during:** Task 1
- **Fix:** Used valid hexadecimal zero-byte literals and white-box-local image/budget builders.
- **Verification:** The intended RED failure only referenced unimplemented public operations; the complete suite subsequently passed.

## Known Stubs

None.

## Next Phase Readiness

Phase 11 can compose the checked geometry and raster APIs in its public pipeline evidence without adding codecs or acceleration paths.

## Self-Check: PASSED

- Created processing source and test files exist.
- Task commits `ad1361c`, `9cc581f`, and `c2c4989` exist.
