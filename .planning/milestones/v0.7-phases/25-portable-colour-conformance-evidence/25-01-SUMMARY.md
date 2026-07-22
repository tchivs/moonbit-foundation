---
phase: 25-portable-colour-conformance-evidence
plan: "01"
subsystem: png-colour-conformance
tags: [png, colour, conformance, portable, documentation]
requires:
  - phase: 24-bounded-non-srgb-and-icc-preservation
    provides: retained non-sRGB metadata and typed no-output encoder boundary
provides:
  - manifest-backed split-IDAT colour declaration conformance evidence
  - public metadata, capability, and encoder-boundary assertions on all portable targets
  - isolated quality trace and checked public preservation-boundary documentation
affects: [png-colour-fidelity]
tech-stack:
  added: []
  patterns: [declarative fixture oracle, public decoder conformance, isolated quality trace]
key-files:
  created: []
  modified:
    - fixtures/png/decode-cases.json
    - fixtures/manifest.json
    - scripts/fixtures/Generate-PngDecodeVectors.ps1
    - modules/mb-image/png/generated_decode_vectors_test.mbt
    - modules/mb-image/png/png_test.mbt
    - scripts/quality/Invoke-MoonQuality.ps1
    - modules/mb-image/README.mbt.md
key-decisions:
  - "Use comparison groups to derive unsplit baselines and deterministic split-IDAT schedules from declarative colour cases."
  - "Assert retained non-sRGB capability through public descriptor and encoder contracts without adding colour transforms."
metrics:
  duration: 20min
  tasks_completed: 2
  generated_vectors: 3850
completed: 2026-07-21
status: complete
---

# Phase 25 Plan 01: Portable Colour Conformance Evidence Summary

**Portable PNG proof now independently exercises retained colour declarations, hostile partition equivalence, and the public no-transform boundary.**

## Accomplishments

- Added declarative split-IDAT groups for compatible sRGB/legacy precedence, retained gAMA and cHRM metadata, authoritative iCCP metadata, and a hostile sRGB grammar failure.
- Regenerated the manifest-backed corpus with 3,850 public vectors and strengthened public comparisons to include metadata identities, opaque values, reference-operation eligibility, typed failure data, and no-output canonical PNG encoding.
- Added a public checked PNG-colour section that distinguishes declaration retention from unavailable sample conversion or profile transformation.
- Extended the isolated PNG quality lane with an exact, per-target colour-conformance stage for public PNG vectors and the README assertion.

## Task Commits

1. Task 1 RED public harness: `48f288f`.
2. Task 1 generated colour evidence: `e58992b`.
3. Task 2 quality trace and documentation: `0042a43`.

## Verification

- `pwsh -NoProfile -File scripts/fixtures/Generate-PngDecodeVectors.ps1 -Check` — passed, 3,850 executable cases.
- `moon -C modules/mb-image test png --target all --frozen` — passed, 40/40 on wasm, wasm-gc, js, and native.
- `pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png` — passed; colour vectors and README check ran on js, wasm, wasm-gc, and native. The lane reports the pre-existing 29 warnings and zero errors.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Test correctness] Corrected the public opaque-metadata comparison loop to use the metadata API's `Int` index type.
- **Found during:** Task 1 four-target test.
- **Fix:** Used `Int` for metadata-entry lookup while retaining `UInt64` for byte-view comparison.
- **Files modified:** `modules/mb-image/png/png_test.mbt`.
- **Commit:** `e58992b`.

2. [Rule 1 - Test correctness] Relaxed the generated encoder-boundary assertion to validate the established typed capability category/code and zero writer output without prescribing a private error-context string.
- **Found during:** Task 1 four-target test.
- **Fix:** Kept the observable public capability/no-output contract and removed an over-specific context expectation.
- **Files modified:** `modules/mb-image/png/png_test.mbt`.
- **Commit:** `e58992b`.

## Known Stubs

None.

## Self-Check: PASSED

All scoped files exist, all three task commits are present, and the required generator, four-target PNG test, and isolated quality lane passed.
