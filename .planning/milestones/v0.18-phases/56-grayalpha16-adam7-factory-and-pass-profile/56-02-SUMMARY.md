---
phase: 56-grayalpha16-adam7-factory-and-pass-profile
plan: "02"
subsystem: png-encoding-tests
tags: [moonbit, png, grayalpha16, adam7, streaming, regression]
requires:
  - phase: 56-01
    provides: Explicit eager and caller-buffered GrayAlpha16 Adam7 selector families on the shared profile-aware machine.
provides:
  - Complete-byte parity evidence for the two public eager GrayAlpha16 Adam7 selector shapes.
  - Corresponding-eager parity and Type-4/16/Adam7 framing evidence for both public chunk selector shapes.
affects: [57-bounded-adam7-streaming-semantics, 58-portable-adam7-public-evidence, png-encoding]
tech-stack:
  added: []
  patterns: [selector-specific eager-oracle parity, explicit Adam7 framing assertions, frozen non-interlaced regression coverage]
key-files:
  created: []
  modified:
    - modules/mb-image/png/encode_test.mbt
    - modules/mb-image/png/stream_encode_test.mbt
key-decisions:
  - "The two Stored/None eager selector forms must be byte-identical while retaining independent seven-pass Ghi/Glo/Ahi/Alo assertions."
  - "Each caller-buffered selector is compared to its matching eager factory before asserting the shared Type-4/16 Adam7 result."
patterns-established:
  - "Use fresh source images and selector-specific eager peers for public chunk-factory parity tests."
requirements-completed: [GRAYA16A7-01]
coverage:
  - id: D1
    description: Eager GrayAlpha16 Adam7 selectors emit identical Stored/None Type-4/16 Adam7 bytes while retaining seven-pass wire-lane evidence.
    requirement: GRAYA16A7-01
    verification:
      - kind: integration
        ref: "moon -C modules/mb-image test png --target native --frozen -f 'PNG GrayAlpha16 Adam7 eager pass profile'"
        status: pass
    human_judgment: false
  - id: D2
    description: Caller-buffered GrayAlpha16 Adam7 selectors drain to their corresponding eager outputs and retain Type-4/16 Adam7 framing.
    requirement: GRAYA16A7-01
    verification:
      - kind: integration
        ref: "moon -C modules/mb-image test png --target native --frozen -f 'PNG GrayAlpha16 Adam7 chunk parity'"
        status: pass
      - kind: integration
        ref: "moon -C modules/mb-image test png --target native --frozen"
        status: pass
    human_judgment: false
duration: 3min
completed: 2026-07-23
status: complete
---

# Phase 56 Plan 02: GrayAlpha16 Adam7 Factory and Pass Profile Summary

**Public GrayAlpha16 Adam7 selector regressions now prove eager byte identity and caller-buffered parity without expanding the encoder surface.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-07-23T07:09:05+08:00
- **Completed:** 2026-07-23T07:11:30+08:00
- **Tasks:** 2/2
- **Files modified:** 2

## Accomplishments

- Preserved the legal 5x5 little-endian source, Type-4/depth-16/Adam7 framing, and all seven Ghi/Glo/Ahi/Alo pass-lane checks while proving the two eager selector forms yield identical complete output.
- Compared each public caller-buffered Adam7 selector to its exact eager peer using fresh sources and the established ordinary drain schedule.
- Retained the existing Big-endian descriptor-construction rejection and non-interlaced GrayAlpha16 regressions unchanged.

## Task Commits

1. **Task 1: Make the eager GrayAlpha16 Adam7 profile regression self-contained** — `f222ecd` (`test`)
2. **Task 2: Make caller-buffered GrayAlpha16 Adam7 parity explicit** — `5ab6d5f` (`test`)

## Files Created/Modified

- `modules/mb-image/png/encode_test.mbt` — Records both eager public selector outputs and requires complete-byte identity in addition to literal pass data.
- `modules/mb-image/png/stream_encode_test.mbt` — Adds a narrow eager oracle and compares both caller-buffered factories with their corresponding selected eager routes.

## Decisions Made

- Kept this plan test-only: Wave 1’s shared production route already fulfilled the factories and passed the focused regression before these selector-specific assertions were added.
- Did not introduce resource, replay, hostile-schedule, decoder, or portability work reserved for Phases 57–58.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None. The stub scan found only intentional empty test-helper arrays used to collect constructed bytes or expected data.

## Issues Encountered

None. Native test compilation emitted pre-existing generated-code and deprecation warnings, but both focused tests and the full suite passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 57 can extend the proven public selector surface with its bounded-resource and replay semantics.
- The little-endian-only descriptor boundary and frozen non-interlaced GrayAlpha16 routes remain protected by their unchanged tests.

## Self-Check: PASSED

- Scoped test files and this summary exist.
- Task commits `f222ecd` and `5ab6d5f` exist in repository history.

---
*Phase: 56-grayalpha16-adam7-factory-and-pass-profile*
*Plan: 02*
*Completed: 2026-07-23*
