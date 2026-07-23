---
phase: 61-portable-grayalpha8-adam7-public-evidence
plan: "01"
subsystem: testing
tags: [moonbit, png, adam7, grayalpha8, conformance]
requires:
  - phase: 59-grayalpha8-adam7-factory-and-pass-profile
    provides: Independent GrayAlpha8 Adam7 pass raster oracle and public factories
  - phase: 60-bounded-adam7-streaming-semantics
    provides: Verified all-strategy bounded Adam7 encoder behavior
provides:
  - Public GrayAlpha8 Adam7 Type-4/8 decode canonicalization evidence
  - Frozen GrayAlpha16 Stored/None non-interlaced compatibility vector
affects: [61-02, png-public-evidence]
tech-stack:
  added: []
  patterns: [Independent wire oracle followed by public ImageDecoder assertions]
key-files:
  created: [.planning/phases/61-portable-grayalpha8-adam7-public-evidence/61-01-SUMMARY.md]
  modified: [modules/mb-image/png/encode_test.mbt]
key-decisions:
  - "Decode the all-strategy Stored/None output only after its independently enumerated seven-pass raster comparison."
  - "Freeze GrayAlpha16 from the research-supplied literal rather than deriving expected bytes through an encoder."
patterns-established:
  - "Public Adam7 conformance checks assert U8 RGBA descriptors and calculate source-coordinate pixels locally."
requirements-completed: [GRAYA8A7-03]
coverage:
  - id: D1
    description: Public 5x5 GrayAlpha8 Adam7 Stored/None PNG proves all seven G,A pass rows and canonical RGBA8 decoding.
    requirement: GRAYA8A7-03
    verification:
      - kind: unit
        ref: "moon -C modules/mb-image test png --target native --frozen -f 'PNG GrayAlpha8 Adam7 eager pass profile'"
        status: pass
    human_judgment: false
  - id: D2
    description: GrayAlpha16 default and configured Stored/None eager output remain byte-identical to the independent non-interlaced literal.
    requirement: GRAYA8A7-03
    verification:
      - kind: unit
        ref: "moon -C modules/mb-image test png --target native --frozen -f 'PNG filter strategy eager frozen compatibility vectors'"
        status: pass
    human_judgment: false
duration: 3min
completed: 2026-07-23
status: complete
---

# Phase 61 Plan 01: Public GrayAlpha8 Adam7 Evidence Summary

**Independent seven-pass Type-4/8 GrayAlpha8 wire evidence now reaches a public U8 RGBA decoder oracle, with frozen GrayAlpha16 Stored/None bytes retained.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-07-23T04:07:04Z
- **Completed:** 2026-07-23T04:10:01Z
- **Tasks:** 1
- **Files modified:** 2

## Accomplishments

- Decoded the public 5x5 GrayAlpha8 Adam7 Stored/None PNG through `PngDecoder` and checked every `(G,G,G,A)` pixel from its independent coordinate formula.
- Preserved the existing 61-byte independently enumerated all-seven-pass G,A inflated-raster comparison before the decoder assertion.
- Added the exact 77-byte GrayAlpha16 Stored/None non-interlaced literal to the eager compatibility matrix for both default and configured factories.

## Task Commits

1. **Task 1: Prove the public Stored/None GrayAlpha8 Adam7 wire-to-decode slice (RED)** - `8135147` (`test`)
2. **Task 1: Prove the public Stored/None GrayAlpha8 Adam7 wire-to-decode slice (GREEN)** - `b69a93e` (`feat`)

## Files Created/Modified

- `modules/mb-image/png/encode_test.mbt` - Adds the public GrayAlpha8 Adam7 decoder oracle and the independent GrayAlpha16 frozen vector.
- `.planning/phases/61-portable-grayalpha8-adam7-public-evidence/61-01-SUMMARY.md` - Records plan evidence and verification.

## Decisions Made

- Decoded only the explicit `new_graya8_with_all_strategies(Stored, None, Adam7)` output, after its wire-raster oracle had passed.
- Kept all expected data test-local and literal/coordinate-derived; no encoder traversal state or production change was used as an oracle.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. The red gate failed on the intentionally unbound decoder-oracle helper, then the completed test passed.

## Known Stubs

None.

## Next Phase Readiness

- Plan 02 can add caller-buffered schedule evidence and run the ordinary four-target package gate.
- No blockers or production changes introduced.

## Self-Check: PASSED

- Found the modified test and generated summary files.
- Found both TDD commits in the repository history.

---
*Phase: 61-portable-grayalpha8-adam7-public-evidence*
*Completed: 2026-07-23*
