---
phase: 34-portable-png-compression-corpus-evidence
plan: "01"
subsystem: testing
tags: [moonbit, png, compression, fixed-or-stored, portable-testing]
requires:
  - phase: 33-fixed-or-stored-png-planning-and-emission
    provides: Public FixedOrStored PNG eager and chunk encoder strategies.
provides:
  - Stable public PNG compression corpus evidence for flat RGB8 and straight-RGBA8 inputs.
  - Four-target selector and complete-input decode evidence for the optimized route.
affects: [png, compression, portable-targets, verification]
tech-stack:
  added: []
  patterns:
    - Public encoder/decoder corpus oracle using generated bounded images.
key-files:
  created: [".planning/phases/34-portable-png-compression-corpus-evidence/34-01-SUMMARY.md"]
  modified: ["modules/mb-image/png/stream_encode_test.mbt"]
key-decisions:
  - "Keep PNGC-04 evidence entirely in the existing package test through public Stored, FixedOrStored, chunk encoder, and decoder APIs."
  - "Use deterministic flat 32x1 RGB8 and straight-RGBA8 0xaa images with the hostile [0, 1, 3, 2, 5] output schedule."
patterns-established:
  - "Compression corpus tests compare a public baseline, repeat eager output, drain configured chunk output, and decode every optimized result to source components."
requirements-completed: [PNGC-04]
coverage:
  - id: D1
    description: "Portable deterministic FixedOrStored PNG corpus evidence for flat RGB8 and straight-RGBA8 images."
    requirement: PNGC-04
    verification:
      - kind: unit
        ref: "modules/mb-image/png/stream_encode_test.mbt#PNG fixed-or-stored corpus evidence is deterministic, valid, never-larger, and wins flat RGB8/RGBA8"
        status: pass
      - kind: integration
        ref: "moon -C modules/mb-image test png --target all --frozen"
        status: pass
      - kind: integration
        ref: "isolated outline-and-filter execution on js, wasm, wasm-gc, and native"
        status: pass
    human_judgment: false
duration: 15min
completed: 2026-07-22
status: complete
---

# Phase 34 Plan 01: Portable PNG Compression Corpus Evidence Summary

**Public PNG corpus evidence proves deterministic, strictly smaller FixedOrStored output for flat 32x1 RGB8 and straight-RGBA8 sources on all portable targets.**

## Performance

- **Duration:** 15 min
- **Started:** 2026-07-21T19:30:00Z
- **Completed:** 2026-07-21T19:44:53Z
- **Tasks:** 2/2
- **Files modified:** 1

## Accomplishments

- Added public-boundary helpers that compare an explicit Stored baseline with repeated FixedOrStored eager output and caller-buffered output drained under `[0, 1, 3, 2, 5]`.
- Added the exact named corpus test for the required flat 32x1 RGB8 and straight-RGBA8 `0xaa` sources.
- Proved optimized eager and chunk outputs complete-input decode back to matching dimensions, channel count, and every source component.

## Task Commits

1. **Task 1: Add reusable public corpus and decode-oracle helpers** — `9533dcb` (test)
2. **Task 2: Declare the exact two-record corpus and prove it on every portable target** — `358d878` (test)

## Files Created/Modified

- `modules/mb-image/png/stream_encode_test.mbt` — Public compression corpus helpers and the one stable PNGC-04 test.

## Decisions Made

- Kept the evidence at the public encoder/decoder boundary; no DEFLATE-plan inspection, byte-count constants, fixtures, scripts, or production code were added.
- Reused the existing bounded in-memory flat-image constructor and chunk-drain helper for deterministic four-target coverage.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Use fail-fast helper assertions compatible with MoonBit.**
- **Found during:** Task 1
- **Issue:** Reusable `Unit` helpers cannot call `inspect`, which is restricted to test blocks.
- **Fix:** Replaced helper-level `inspect` calls with descriptive `abort` checks while preserving the planned assertions.
- **Files modified:** `modules/mb-image/png/stream_encode_test.mbt`
- **Verification:** `moon -C modules/mb-image test png --target native --frozen` passed 114/114 tests.
- **Committed in:** `9533dcb`

---

**Total deviations:** 1 auto-fixed (1 Rule 1 bug)
**Impact on plan:** No scope expansion; the exact public corpus behavior remains as planned.

## Verification

- Passed: native PNG suite — 114/114 tests.
- Passed: required outline guard and isolated corpus filter on js, wasm, wasm-gc, and native — each outline named the exact test once and each filtered execution passed 1/1.
- Passed: `moon -C modules/mb-image test png --target all --frozen` — 114/114 on each target.
- Timed out without a reported test failure: `pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png` exceeded the executor's 120-second command limit and was terminated. No retry was run.

## Known Stubs

None. The existing empty arrays in the test file are intentional byte-output accumulators, not UI or mock-data stubs.

## Next Phase Readiness

- PNGC-04 has deterministic public corpus coverage and green focused/full portable target evidence.
- Re-run the scoped PNG quality lane in an environment permitting more than 120 seconds if its broader regression confirmation is required.

## Self-Check: PASSED

- Confirmed the modified test source and this summary exist.
- Confirmed task commits `9533dcb` and `358d878` exist in repository history.

---
*Phase: 34-portable-png-compression-corpus-evidence*
*Completed: 2026-07-22*
