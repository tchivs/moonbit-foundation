---
phase: 20-png-structural-safety-gate
plan: "04"
subsystem: testing
tags: [png, generated-fixtures, crc, codec-limits, budget, moonbit]
requires:
  - phase: 20-png-structural-safety-gate
    provides: PngDecoder structural validator and EOF boundary repair
provides:
  - Exact 89-case provenance-checked PNG structural and resource matrix
  - Generated public and white-box record tables with typed expectations and complete profiles
  - PngDecoder probe matrix and all-target decoder execution evidence
affects: [png, phase-21-deflate, phase-22-png-workflows]
tech-stack:
  added: []
  patterns: [declarative hostile transport matrix, generated CodecLimits and ResourceLimits profiles]
key-files:
  created: [.planning/phases/20-png-structural-safety-gate/20-04-SUMMARY.md]
  modified: [fixtures/png/cases.json, scripts/fixtures/Generate-PngStructuralVectors.ps1, modules/mb-image/png/generated_vectors.mbt, modules/mb-image/png/generated_vectors_test.mbt, modules/mb-image/png/png_test.mbt, modules/mb-image/png/structural_wbtest.mbt]
key-decisions:
  - "Keep byte construction declarative in fixture data and generate compact chunk/CRC bytes deterministically."
  - "Execute all decode records through PngDecoder while reserving CRC-precedence checks for the white-box layer."
requirements-completed: [PNG-01, PNG-02, PNG-03]
coverage:
  - id: D1
    description: Complete generated PNG structural, semantic, CRC, IEND/EOF, and resource-boundary corpus.
    requirement: PNG-02
    verification:
      - kind: unit
        ref: pwsh -NoProfile -File scripts/fixtures/Generate-PngStructuralVectors.ps1 -Check
        status: pass
    human_judgment: false
  - id: D2
    description: PngDecoder public/white-box matrix and bounded probe outcomes on four portable targets.
    requirement: PNG-01
    verification:
      - kind: unit
        ref: moon -C modules/mb-image test png --target all --frozen
        status: pass
    human_judgment: false
status: complete
---

# Phase 20 Plan 04: Complete PNG Structural Matrix Summary

**A provenance-checked 89-case PNG structural corpus now drives PngDecoder through public and white-box proof boundaries on js, wasm, wasm-gc, and native.**

## Performance

- **Tasks:** 2/2
- **Files modified:** 7
- **Verification:** generator Check and four-target PNG tests passed.

## Case Matrix Coverage

| Matrix area | Cases | Evidence |
| --- | ---: | --- |
| Signature | 4 | Empty, short, seven-byte, and mismatched signatures |
| Header and IHDR order/shape | 19 | Truncation, length/type form, first/duplicate IHDR, and every rejected supported-profile field |
| IDAT/IEND/EOF transitions | 14 | Required/contiguous IDAT, early/invalid/truncated IEND, duplicate/post-IEND chunks, and trailing input |
| CRC and metadata policy | 21 | Five distinct CRC-before-policy paths, unknown critical, discard/preserve ancillary, and 13 semantic families |
| Accepted transports | 2 | RGB8 and RGBA8 structural terminals |
| CodecLimits and Budget boundaries | 29 | Exact/below input, geometry, image/output bytes, work, allocation, and every inherited Budget envelope |

Every one of the 89 records has explicit mutation/construction, typed expectation, DecodeOptions, CodecLimits profile, ResourceLimits profile, immutable-state flag, and P+W routing. `png_test.mbt` uses only `ImageDecoder::decode(PngDecoder)` for the generated decode matrix; `structural_wbtest.mbt` also checks the CRC-precedence fixture set. The public caller-owned probe rows prove `NeedMore(8)`, `NoMatch`, `Match`, and the `probe-bytes` resource ceiling.

## Task Commits

1. **RED: Require generated PNG matrix metadata** — `4b9eba3`
2. **Task 1: Generate complete PNG structural matrix** — `d84d041`
3. **Task 2: Execute PNG matrix at public and private boundaries** — `e67956f`

## Verification

- `pwsh -NoProfile -File scripts/fixtures/Generate-PngStructuralVectors.ps1` — passed (89 P+W cases)
- `pwsh -NoProfile -File scripts/fixtures/Generate-PngStructuralVectors.ps1 -Check` — passed
- `moon -C modules/mb-image test png --target all --frozen` — 11/11 passed on wasm, wasm-gc, js, and native

## Deviations from Plan

None - no parser, API, DEFLATE, raster, encoder, or quality-lane code was changed.

## Known Stubs

None.

## Next Phase Readiness

Phase 21 can rely on the structural gate’s finite acceptance and rejection boundary. The corpus intentionally leaves DEFLATE, scanline reconstruction, pixels, and encoding to their planned owners.

## Self-Check: PASSED

- Fixture source, manifest digest, generator, both generated tables, and both PNG test layers exist.
- Commits `4b9eba3`, `d84d041`, and `e67956f` exist.
