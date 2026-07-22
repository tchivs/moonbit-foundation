---
phase: 21-bounded-png-decode-and-deflate
plan: "03"
subsystem: png-decoder-testing
tags: [moonbit, png, deflate, structural-validation, all-target-tests]
requires:
  - phase: 21-02
    provides: "bounded eager PNG decode, generated structural and decode corpora"
provides:
  - "Explicit current-terminal map for all 89 retained Phase-20 structural records"
  - "Exact public PngDecoder evidence for IHDR, PLTE, and colour ordering terminals"
affects: [phase-23, phase-24, phase-25, png-quality]
tech-stack:
  added: []
  patterns: ["Precompute fixture expectations before decoder execution", "Use stage-specific budget modes for structural regression tests"]
key-files:
  created: []
  modified: [modules/mb-image/png/png_test.mbt, modules/mb-image/png/structural.mbt]
key-decisions:
  - "Legacy structural records that now reach active empty IDAT assert the precise zlib terminal with a decode-capable budget."
  - "Only below-limit preflight resource records retain immutable caller-budget assertions."
patterns-established:
  - "PNG regression fixtures select exact expected category, code, context, and budget policy before invoking PngDecoder."
requirements-completed: [PNG-04, PNG-05]
coverage:
  - id: D1
    description: "All retained structural fixtures have a deterministic public decoder terminal."
    requirement: PNG-05
    verification:
      - kind: integration
        ref: "moon -C modules/mb-image test png --target all --frozen"
        status: pass
    human_judgment: false
  - id: D2
    description: "Generated decode, colour, split-boundary, and resource evidence remains portable."
    requirement: PNG-04
    verification:
      - kind: integration
        ref: "pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png"
        status: pass
    human_judgment: false
duration: 30min
completed: 2026-07-21
status: complete
---

# Phase 21 Plan 03: Current PNG Structural Outcome Map Summary

**A strict public current-stage map preserves all 89 legacy PNG structural records while retaining exact DEFLATE, semantic, resource, and ordering terminals.**

## Performance

- **Duration:** 30 min
- **Completed:** 2026-07-21T04:52:11Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Replaced result-dependent structural assertions with precomputed stage, category, code, context, and budget expectations at the `PngDecoder` boundary.
- Preserved precise current semantic/fixed-length terminals, empty-IDAT `zlib-truncated`, opaque metadata capability behavior, and below-limit resource semantics.
- Retained IHDR framing/order and post-IDAT PLTE/colour ordering guards without changing Phase 23–25 colour behavior.

## Task Commits

1. **Task 1: Define the current-outcome map before asserting the legacy structural corpus** - `9c731d3` (test)
2. **Task 2: Retain only proven structural ordering distinctions and verify generated evidence** - `516c38a` (fix)

## Files Created/Modified

- `modules/mb-image/png/png_test.mbt` - named public structural stages and precomputed exact expectations.
- `modules/mb-image/png/structural.mbt` - IHDR, PLTE, and active-IDAT ordering terminals.

## Decisions Made

- Existing fixture metadata remains the exact source for inherited pre-transport terminals; current-pipeline deviations are explicitly named before decode.
- At-ceiling cases use the decode-capable stage and no longer claim the historical immutable-budget contract.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Issues Encountered

- The first strict native run showed that an `idat-after-semantic` structural terminal can charge current parser scratch. The map now preserves immutable-budget assertions only for the plan-required below-limit preflight resource cases.

## Verification

- `pwsh -NoProfile -File scripts/fixtures/Generate-PngStructuralVectors.ps1 -Check` — passed (89 P+W cases).
- `pwsh -NoProfile -File scripts/fixtures/Generate-PngDecodeVectors.ps1 -Check` — passed (3850 executable cases).
- `moon -C modules/mb-image test png --target all --frozen` — passed 41/41 on wasm, wasm-gc, js, and native.
- `pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png` — passed, including policy, generator, colour, all-target, and isolation checks.

## Next Phase Readiness

PNG structural regression evidence now tracks the current decode and colour pipeline without broad capability fallbacks.

## Self-Check: PASSED

- `modules/mb-image/png/png_test.mbt` and `modules/mb-image/png/structural.mbt` exist.
- Task commits `9c731d3` and `516c38a` exist.
