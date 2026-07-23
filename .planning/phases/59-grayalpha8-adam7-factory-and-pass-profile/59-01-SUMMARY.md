---
phase: 59-grayalpha8-adam7-factory-and-pass-profile
plan: "01"
subsystem: png-encoding
tags: [moonbit, png, adam7, grayalpha8, streaming]
requires:
  - phase: v0.18
    provides: "Shared profile-aware Adam7 encoder machine and GrayAlpha16 selector pattern."
provides:
  - "Explicit eager GrayAlpha8 Adam7 selector pair."
  - "Explicit caller-buffered GrayAlpha8 Adam7 selector pair using the shared machine."
  - "Independent five-by-five Type-4/8 G,A Adam7 Stored wire proof."
affects: [phase-60-bounded-adam7-streaming, phase-61-public-adam7-evidence]
tech-stack:
  added: []
  patterns: ["Additive opt-in interlace selectors retain legacy None factories and bytes.", "GrayAlpha8 reuses the existing profile-aware Adam7 cursor without staging."]
key-files:
  created: []
  modified:
    - modules/mb-image/png/png.mbt
    - modules/mb-image/png/encode.mbt
    - modules/mb-image/png/stream_encode.mbt
    - modules/mb-image/png/encode_test.mbt
    - modules/mb-image/png/stream_encode_test.mbt
key-decisions:
  - "Expose GrayAlpha8 Adam7 only through additive eager and caller-buffered selector pairs."
  - "Open only the GrayAlpha8 Adam7 preflight gate; retain all shared descriptor, ledger, traversal, and legacy None behavior."
patterns-established:
  - "Type-4/8 Adam7 tests use an independent G,A pass enumeration over a non-symmetric 5x5 source."
requirements-completed: [GRAYA8A7-01]
coverage:
  - id: D1
    description: "Legal packed straight-alpha GrayAlpha8 sources can explicitly select eager Adam7 Type-4/8 output."
    requirement: GRAYA8A7-01
    verification:
      - kind: unit
        ref: "modules/mb-image/png/encode_test.mbt#PNG GrayAlpha8 Adam7 eager pass profile"
        status: pass
    human_judgment: false
  - id: D2
    description: "Caller-buffered GrayAlpha8 Adam7 selectors produce the matching eager Type-4/8 stream through the shared machine."
    requirement: GRAYA8A7-01
    verification:
      - kind: integration
        ref: "modules/mb-image/png/stream_encode_test.mbt#PNG GrayAlpha8 Adam7 chunk parity"
        status: pass
    human_judgment: false
duration: 14min
completed: 2026-07-23
status: complete
---

# Phase 59 Plan 01: GrayAlpha8 Adam7 Factory and Pass Profile Summary

**Explicit eager and caller-buffered GrayAlpha8 Adam7 selectors now emit the shared Type-4/8 seven-pass G,A stream while established GrayAlpha8 factories stay byte-identical and non-interlaced.**

## Performance

- **Duration:** 14 min
- **Tasks:** 1/1
- **Files modified:** 5
- **Verification:** two focused native PNG tests passed twice, including the tracer re-run.

## Accomplishments

- Added opt-in `new_graya8_with_interlace_strategy` and `new_graya8_with_all_strategies` factories for both eager and caller-buffered encoding.
- Routed the new factories to the existing profile-aware `PngEncodeMachine`; no alternate cursor, pass buffer, or encoder path was added.
- Removed only the GrayAlpha8 Adam7 admission rejection and retained Gray8/Gray16 restrictions, descriptor validation, atomic preflight, and legacy `None` wiring.
- Added independent 5x5 Stored/None Type-4/8 raster assertions for all seven Adam7 passes in G,A order, plus frozen legacy method-0 parity and ordinary chunk-to-eager parity.

## Task Commits

1. **Task 1: Prove and deliver one legal GrayAlpha8 Adam7 eager-to-chunk path**
   - `993272b` — `test(59-01): add GrayAlpha8 Adam7 factory coverage` (RED)
   - `6327742` — `feat(59-01): add GrayAlpha8 Adam7 selectors` (GREEN)

## Files Created/Modified

- `modules/mb-image/png/png.mbt` — additive eager GrayAlpha8 interlace factories.
- `modules/mb-image/png/encode.mbt` — narrow GrayAlpha8 Adam7 admission opening.
- `modules/mb-image/png/stream_encode.mbt` — additive caller-buffered GrayAlpha8 interlace factories.
- `modules/mb-image/png/encode_test.mbt` — independent seven-pass Type-4/8 G,A wire oracle and legacy freeze.
- `modules/mb-image/png/stream_encode_test.mbt` — fresh-source chunk selector parity regression.

## Decisions Made

- GrayAlpha8 Adam7 is opt-in through additive public factories; all existing GrayAlpha8 constructors continue to explicitly select `PngInterlaceStrategy::None`.
- The sole production admission change deletes the GrayAlpha8-specific Adam7 prohibition, preserving the existing bounded profile/machine, pass geometry, wire reader, filtering, compression, and replay authority.

## TDD Gate Compliance

- RED: `993272b` added the new test names and failed because the four selector methods did not exist.
- GREEN: `6327742` added exactly those selectors and the narrow preflight adjustment; both named tests passed.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. The native compiler emitted existing unused/deprecation warnings only; the focused tests passed without new warnings treated as failures.

## Known Stubs

None introduced by this plan.

## Next Phase Readiness

Phase 60 can now exercise all six GrayAlpha8 Adam7 compression/filter pairs, atomic admission, and replay-mutation behavior through the published selector seam.

## Self-Check: PASSED

- Both TDD commits exist and the five planned production/test files are present.
- `moon -C modules/mb-image test png --target native --frozen -f 'PNG GrayAlpha8 Adam7 eager pass profile'` passed.
- `moon -C modules/mb-image test png --target native --frozen -f 'PNG GrayAlpha8 Adam7 chunk parity'` passed.
