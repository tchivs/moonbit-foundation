---
phase: 24-bounded-non-srgb-and-icc-preservation
plan: "02"
subsystem: png-icc-resource-safety
tags: [png, iccp, budget, deflate, fixtures, portable]
requires:
  - phase: 24-bounded-non-srgb-and-icc-preservation
    provides: retained bounded ICC metadata
provides:
  - caller-preflighted temporary iCCP allocation and work envelope
  - all-target hostile ICC header, profile-space, and resource-limit evidence
affects: [phase-24-verification]
tech-stack:
  added: []
  patterns: [temporary-budget-lease, generated-hostile-icc-vectors]
key-files:
  modified:
    - modules/mb-image/png/structural.mbt
    - modules/mb-image/png/structural_wbtest.mbt
    - fixtures/png/decode-cases.json
    - scripts/fixtures/Generate-PngDecodeVectors.ps1
    - modules/mb-image/png/generated_decode_vectors_test.mbt
    - modules/mb-image/png/png_test.mbt
decisions:
  - "iCCP resources are fully preflighted against the caller then charged to an isolated temporary lease because their buffers are released before the later image allocation."
  - "ICC fixtures generate minimal stored-zlib profiles from declarative mutations instead of copied profile blobs."
metrics:
  tasks_completed: 2
  tests: "PNG 40/40 on wasm, wasm-gc, js, and native; model 13/13 on all targets"
status: complete
---

# Phase 24 Plan 02: iCCP Resource Gap Closure Summary

**iCCP collection and inflate now preflight caller-derived temporary resources, with portable hostile evidence for ICC grammar and every declared resource boundary.**

## Accomplishments

- Threaded the caller budget through colour-chunk parsing and reserved compressed collection, 32 KiB history, bounded output, and conservative DEFLATE work before expansion.
- Kept the 64 KiB profile ceiling while making caller output, allocation, byte, and work limits authoritative.
- Added declarative ICC profile mutations for header, declared size, signature, and incompatible space, plus compressed, inflated, allocation, and work-limit vectors.

## Task Commits

1. RED test: `640c709`.
2. iCCP resource implementation: `7cdf23a`.
3. Generated hostile ICC corpus: `b0e8db2`.

## Verification

- `pwsh -NoProfile -File scripts/fixtures/Generate-PngDecodeVectors.ps1 -Check` — passed (3,780 executable cases).
- `moon -C modules/mb-image test png --target all --frozen` — passed (40/40 on wasm, wasm-gc, js, and native).
- `moon -C modules/mb-image test model --target all --frozen` — passed (13/13 on wasm, wasm-gc, js, and native).
- `pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png` — passed (29 pre-existing warnings, 0 errors).

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Resource lifetime] The shared budget cannot release counters after transient iCCP buffers are freed. The implementation therefore first preflights the complete caller envelope, then charges an isolated temporary lease; this preserves caller-limit enforcement without preventing the subsequent image/raster allocation.

## Known Stubs

None.

## Self-Check: PASSED

All committed implementation files, regenerated vectors, and required verification commands are present and passed.
