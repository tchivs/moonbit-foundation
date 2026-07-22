---
phase: 40-portable-adaptive-filter-evidence
plan: 01
subsystem: png-public-evidence
tags: [png, adaptive-filter, portable, public-api]
requires: [phase-39-adaptive-filter]
provides: [PNGF-04-portable-evidence]
affects: [png-public-tests, quality-evidence]
tech-stack:
  added: []
  patterns: [generated-MoonBit-corpus, selector-isolated-portable-tests, owned-temp-root-cleanup]
key-files:
  created: [.planning/phases/40-portable-adaptive-filter-evidence/40-01-SUMMARY.md]
  modified:
    - modules/mb-image/png/encode_test.mbt
    - modules/mb-image/png/stream_encode_test.mbt
    - scripts/quality/Invoke-PngEncodeEvidence.ps1
    - .planning/phases/40-portable-adaptive-filter-evidence/40-RESEARCH.md
decisions:
  - CandidateSelection selected R1 for RGB8 and A1 for straight-RGBA8 by first all-target pass order.
  - Final evidence remains restricted to public encoder/chunk encoder/PngDecoder contracts.
metrics:
  candidate_targets: 4
  candidate_selectors: 6
  final_targets: 4
  final_selectors: 4
  completed_date: 2026-07-22
status: complete
---

# Phase 40 Plan 01: Portable Adaptive-Filter Evidence Summary

Generated RGB8 R1 and straight-RGBA8 A1 corpus sources prove a strict same-strategy Adaptive PNG size win, hostile chunk/eager byte identity, and complete public decode equality on all four portable targets.

## Delivered

- Added six exact public CandidateSelection selectors for R1-R3 and A1-A3.
- Recorded a complete all-pass four-target matrix and the deterministic R1/A1 selections in Research A1.
- Added the two selected eager and two selected hostile-chunk public evidence selectors.
- Reworked the focused PowerShell runner around explicit CandidateSelection and FinalEvidence modes, per-target GUID-owned temporary roots, verified containment/prefix cleanup in `finally`, and independent selector processes.

## Verification

- `& .\scripts\quality\Invoke-PngEncodeEvidence.ps1 -Mode CandidateSelection` — passed: all six candidates passed on js, wasm, wasm-gc, and native; selected R1/A1.
- `& .\scripts\quality\Invoke-PngEncodeEvidence.ps1 -Mode FinalEvidence` — passed: all four final selectors passed independently on js, wasm, wasm-gc, and native.
- Verified that no `mnf-png-adaptive-evidence-*` temporary roots remained after execution.

## Decisions Made

- Retained only R1 (RGB8 32x1 horizontal) and A1 (straight-RGBA8 16x8) as the final corpus because they are the first ordered all-target strict winners.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking issue] Added evidence-specific test capacity**
- **Found during:** Task 1 CandidateSelection
- **Issue:** The existing eager test helper's 512-byte output/input and work limits prevented the specified generated candidates from reaching the public encoder.
- **Fix:** Added a test-only 4096-byte/high-work evidence encode path and matching public-decode oracle capacity; production limits and PNG implementation remain unchanged.
- **Files modified:** `modules/mb-image/png/encode_test.mbt`

## Known Stubs

None.

## Self-Check: PASSED

- All four owned implementation artifacts and this summary exist.
- CandidateSelection and FinalEvidence completed successfully.
- No temporary evidence target root remained after cleanup.
