---
phase: 46-portable-gray8-public-evidence
plan: 01
subsystem: testing
tags: [moonbit, png, gray8, portable, regression]
requires:
  - phase: 45-bounded-gray8-encoder-path
    provides: Public bounded Gray8 eager and caller-buffered encoder factories.
provides:
  - Public eager Gray8 fidelity evidence across every compression/filter strategy pair.
  - Caller-buffered Gray8 eager-byte identity evidence under hostile lease capacities.
affects: [png, gray8, portable-targets, regression-testing]
tech-stack:
  added: []
  patterns:
    - Public PNG encode/decode assertions must account for decoder RGB canonicalization of Gray input.
    - Chunk parity tests use fresh encoders and the existing accepted-byte drain helper.
key-files:
  created:
    - .planning/phases/46-portable-gray8-public-evidence/46-01-SUMMARY.md
  modified:
    - modules/mb-image/png/encode_test.mbt
    - modules/mb-image/png/stream_encode_test.mbt
key-decisions:
  - Gray8 sources and IHDR retain the one-channel contract while public decoding is asserted as canonical RGB with replicated samples.
  - Hostile-capacity evidence reuses png_chunk_test_drain_encoder so accepted-byte accounting remains the only chunk-output oracle.
patterns-established:
  - Generated Gray8 fidelity covers Stored, FixedOrStored, and DynamicOrFixedOrStored with None and Adaptive filters.
requirements-completed: [GRAYPNG-03]
coverage:
  - id: D1
    description: Generated public eager Gray8 output preserves source dimensions, Gray PNG profile, and samples across all six strategy pairs.
    requirement: GRAYPNG-03
    verification:
      - kind: integration
        ref: modules/mb-image/png/encode_test.mbt#PNG Gray8 eager strategy pairs decode generated samples faithfully
        status: pass
    human_judgment: false
  - id: D2
    description: Fresh public Gray8 chunk encoders preserve eager-byte identity and accepted-byte progress for zero-prefixed, one-byte, and ragged capacities.
    requirement: GRAYPNG-03
    verification:
      - kind: integration
        ref: modules/mb-image/png/stream_encode_test.mbt#PNG Gray8 chunk strategy pairs preserve eager bytes under hostile capacities
        status: pass
    human_judgment: false
  - id: D3
    description: The PNG suite retains frozen RGB8 and straight-RGBA8 compatibility vectors while passing on js, wasm, wasm-gc, and native.
    requirement: GRAYPNG-03
    verification:
      - kind: unit
        ref: moon -C modules/mb-image test png --target js --frozen
        status: pass
      - kind: unit
        ref: moon -C modules/mb-image test png --target wasm --frozen
        status: pass
      - kind: unit
        ref: moon -C modules/mb-image test png --target wasm-gc --frozen
        status: pass
      - kind: unit
        ref: moon -C modules/mb-image test png --target native --frozen
        status: pass
    human_judgment: false
duration: 33min
completed: 2026-07-22
status: complete
---

# Phase 46 Plan 01: Portable Gray8 Public Evidence Summary

**Public Gray8 PNG eager fidelity and caller-buffered eager-byte identity are proven across six strategy pairs and four portable targets.**

## Performance

- **Duration:** 33 min
- **Started:** 2026-07-22T11:41:36Z
- **Completed:** 2026-07-22T12:14:45Z
- **Tasks:** 2/2
- **Files modified:** 2 test files

## Accomplishments

- Added a generated 5x3 mixed-sample Gray8 eager regression for Stored, FixedOrStored, and DynamicOrFixedOrStored with None and Adaptive filtering.
- Proved each public Gray8 PNG advertises bit depth 8, colour type 0, and non-interlace while decoded canonical RGB samples replicate every source Gray value.
- Added fresh Gray8 chunk encoder coverage for direct zero-capacity no-progress and zero-prefixed, one-byte, and ragged drains without changing the existing accepted-progress helper.
- Preserved the existing frozen RGB8 and straight-RGBA8 compatibility vectors in the same portable package suite.

## Verification

All required commands ran independently after both test tasks were present:

| Command | Result |
| --- | --- |
| `moon -C modules/mb-image test png --target js --frozen` | PASS — 181 passed, 0 failed |
| `moon -C modules/mb-image test png --target wasm --frozen` | PASS — 181 passed, 0 failed |
| `moon -C modules/mb-image test png --target wasm-gc --frozen` | PASS — 181 passed, 0 failed |
| `moon -C modules/mb-image test png --target native --frozen` | PASS — 181 passed, 0 failed |

The commands emit existing compiler warnings, but none are failures and this plan did not modify the warned production sources or legacy tests.

## Task Commits

1. **Task 1: Prove generated Gray8 eager fidelity through the public encoder and decoder** — `456c60a` (`test`)
2. **Task 2: Add hostile-capacity Gray8 chunk identity and independent portable-suite evidence** — `59c2178` (`test`)

## Files Created/Modified

- `modules/mb-image/png/encode_test.mbt` — generated Gray8 source and public eager fidelity assertion.
- `modules/mb-image/png/stream_encode_test.mbt` — hostile-capacity Gray8 chunk parity and progress assertion.

## Decisions Made

- The Gray8 source and PNG IHDR remain one-channel, while the public decoder's deliberate RGB canonicalization is asserted explicitly through replicated output samples.
- Existing `png_chunk_test_drain_encoder` remains unchanged; its accepted-byte collection and `total_written` guard are the caller-buffered oracle.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test oracle] Accounted for public decoder Gray-to-RGB canonicalization**
- **Found during:** Task 1
- **Issue:** A generic decoder helper expected a one-channel decoded descriptor and aborted even though all six public Gray8 PNG decodes succeeded.
- **Fix:** Used a Gray8-specific public assertion for source Gray format, PNG IHDR type 0, canonical RGB decoded format, and replicated per-sample values.
- **Files modified:** `modules/mb-image/png/encode_test.mbt`
- **Verification:** All four independent portable target runs pass.
- **Committed in:** `456c60a`

**Total deviations:** 1 auto-fixed test-oracle correction.

## Known Stubs

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

GRAYPNG-03 has portable public evidence for generated Gray8 eager fidelity, caller-buffered identity, and retained RGB8/RGBA8 fixture coverage.

## Self-Check: PASSED

- Confirmed both committed test files and this summary exist.
- Confirmed task commits `456c60a` and `59c2178` exist in repository history.
- No stub patterns were found in the files modified by this plan.

*Phase: 46-portable-gray8-public-evidence*
*Completed: 2026-07-22*
