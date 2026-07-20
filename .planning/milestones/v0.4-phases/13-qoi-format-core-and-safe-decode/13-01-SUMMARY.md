---
phase: 13-qoi-format-core-and-safe-decode
plan: "01"
subsystem: image-codec
tags: [moonbit, qoi, codec, portable, fixtures, hostile-input]
requires:
  - phase: 12-strict-ppm-end-to-end-filter-coverage
    provides: Portable image codec contracts, exact forward I/O, and strict decoder test patterns.
provides:
  - Pure-MoonBit QOI 1.0 `ImageDecoder` implementation for portable targets.
  - Deterministic spec-derived QOI vector generation with provenance validation.
  - Four-target conformance and hostile-reader evidence.
affects: [qoi, image-codecs, portable-interchange]
tech-stack:
  added: []
  patterns: [header-only resource preflight, generated fixture stale check, byte-range opcode dispatch]
key-files:
  created:
    - modules/mb-image/qoi/moon.pkg
    - modules/mb-image/qoi/qoi.mbt
    - modules/mb-image/qoi/decode.mbt
    - modules/mb-image/qoi/generated_vectors.mbt
    - fixtures/qoi/cases.json
    - scripts/fixtures/Generate-QoiVectors.ps1
  modified:
    - fixtures/manifest.json
key-decisions:
  - "QOI decode work is the header-derived checked sum of pixel count and output bytes, precharged atomically by OwnedImage."
  - "Opcode dispatch uses Byte literals and exhaustive Byte ranges so RGB/RGBA retain priority over RUN on all portable targets."
  - "Repository-owned JSON vectors are the fixture authority; the generator verifies generated output and manifest SHA-256 without network access."
patterns-established:
  - "Use caller-owned prefix inspection for codec probe implementations; never read a Reader during probing."
  - "Validate format header, limits, descriptor, and budget before the single output allocation."
requirements-completed: [QOI-01, QOI-02, QOI-04]
coverage:
  - id: D1
    description: Portable QOI prefix probe and eager RGB/RGBA decode with direct metadata mapping.
    requirement: QOI-01
    verification:
      - kind: unit
        ref: moon -C modules/mb-image test --target all --frozen
        status: pass
    human_judgment: false
  - id: D2
    description: Exact QOI chunk-state conformance from deterministic repository-owned vectors.
    requirement: QOI-02
    verification:
      - kind: unit
        ref: modules/mb-image/qoi/decode_wbtest.mbt#generated QOI vectors cover every chunk family with exact bytes
        status: pass
      - kind: other
        ref: pwsh -NoProfile -File scripts/fixtures/Generate-QoiVectors.ps1 -Check
        status: pass
    human_judgment: false
  - id: D3
    description: Bounded preflight, strict completion, malformed input, and forward-reader failure handling.
    requirement: QOI-04
    verification:
      - kind: unit
        ref: modules/mb-image/qoi/decode_test.mbt#QOI header work preflight is exact and leaves rejected budgets unchanged
        status: pass
      - kind: unit
        ref: moon -C modules/mb-image test --target all --frozen
        status: pass
    human_judgment: false
duration: 10min
completed: 2026-07-20
status: complete
---

# Phase 13 Plan 01: QOI Format Core and Safe Decode Summary

**Portable, eager QOI 1.0 RGB/RGBA decoding with atomic resource preflight, strict stream validation, and checked spec-derived vectors.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-07-20T10:34:22Z
- **Completed:** 2026-07-20T10:44:54Z
- **Tasks:** 3/3
- **Files modified:** 9

## Accomplishments

- Added an independent QOI package that implements the unchanged `ImageDecoder` seam across js, wasm, wasm-gc, and native.
- Implemented all six QOI chunk families, direct RGB/RGBA and transfer metadata mapping, checked header limits, atomic budget charging, and strict end-marker/trailing handling.
- Added auditable QOI fixtures, SHA-256 provenance validation, generated MoonBit tables, and conformance/hostile-input coverage.

## Task Commits

1. **Task 1: Create the independent strict QOI decoder package** - `e42e099` (RED tests), `596a153` (implementation)
2. **Task 2: Add checked repository-owned QOI fixture generation** - `5cb5dee`
3. **Task 3: Prove QOI conformance and hostile-input behavior on every portable target** - `a30e9dd`

## Files Created/Modified

- `modules/mb-image/qoi/qoi.mbt` - Public `QoiDecoder` and prefix-only probe.
- `modules/mb-image/qoi/decode.mbt` - Bounded QOI header preflight, allocation, chunk machine, and strict completion.
- `modules/mb-image/qoi/decode_test.mbt` / `decode_wbtest.mbt` - Public hostile-input and generated-vector tests.
- `fixtures/qoi/cases.json` - Human-reviewable QOI 1.0 valid and adversarial records.
- `scripts/fixtures/Generate-QoiVectors.ps1` - Deterministic MoonBit table and manifest validation generator.
- `modules/mb-image/qoi/generated_vectors.mbt` / `fixtures/manifest.json` - Checked generated vectors and fixture provenance.

## Decisions Made

- Used `pixel_count + output_bytes` as the complete header-derived QOI work charge, before the sole `OwnedImage::new_operation` call.
- Used MoonBit Byte literal/range matching for the opcode dispatcher so `0xFE` and `0xFF` precede the `11xxxxxx` RUN range on every target.
- Kept QOI independent from PPM, operations, codec registry, FFI, streaming APIs, and release automation.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected generated INDEX initial-state vector and its end marker.**
- **Found during:** Task 3
- **Issue:** The initial index table stores transparent zero RGBA, not the decoder's opaque previous pixel; the original fixture marker was one byte short.
- **Fix:** Corrected expected pixels and supplied the exact eight-byte marker.
- **Files modified:** `fixtures/qoi/cases.json`, `modules/mb-image/qoi/generated_vectors.mbt`, `fixtures/manifest.json`
- **Verification:** Generated-vector white-box test and all-target suite pass.
- **Committed in:** `a30e9dd`

**2. [Rule 1 - Bug] Corrected DIFF wraparound vector encoding.**
- **Found during:** Task 3
- **Issue:** The fixture's `0x6A` DIFF tag encodes zero deltas, not a red `+1` wraparound.
- **Fix:** Replaced it with `0x7A` and recorded the expected wrapped red byte.
- **Files modified:** `fixtures/qoi/cases.json`, `modules/mb-image/qoi/generated_vectors.mbt`, `fixtures/manifest.json`
- **Verification:** Generated-vector white-box test and all-target suite pass.
- **Committed in:** `a30e9dd`

**Total deviations:** 2 auto-fixed Rule 1 fixture-correctness fixes.

## Issues Encountered

- Initial use of boolean-style opcode matching was avoided after the validated byte-range dispatcher guidance; the final dispatcher compiles on all four targets.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The portable QOI decoder and deterministic corpus are ready for consumers without altering shared codec contracts.
