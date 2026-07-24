---
phase: 81-indexed8-adam7-machine-and-eager-wire-contract
plan: 01
subsystem: png-encoding
tags: [moonbit, png, indexed8, adam7, streaming, tdd]
requires:
  - phase: 79-indexed-low-bit-png-encode
    provides: Indexed PNG wire profiles and acknowledged Type-3 machine
provides:
  - Additive eager and caller-buffered Indexed8 Adam7 selectors
  - Shared-pass preflight and scalar pull-based Indexed8 Adam7 traversal
  - Independent Type-3/8 wire, decode, and atomic-admission evidence
affects: [82-indexed8-adam7-streaming-qualification, png]
tech-stack:
  added: []
  patterns: [explicit-interlace-selector, shared-adam7-pass-geometry, scalar-indexed-traversal]
key-files:
  created: []
  modified:
    - modules/mb-image/png/encode.mbt
    - modules/mb-image/png/stream_encode.mbt
    - modules/mb-image/png/encode_test.mbt
    - modules/mb-image/png/encode_wbtest.mbt
    - modules/mb-image/png/stream_encode_test.mbt
key-decisions:
  - "Indexed8 Adam7 is opt-in through additive eager and chunk selectors; established Indexed8 and low-bit routes explicitly retain None."
  - "Preflight and scalar output each consume _png_adam7_passes(width, height, 1UL, 8), without staging or an alternate encoder."
patterns-established:
  - "Type-3/8 Adam7 framing reuses PngEncodeMachine and Stored/filter-None acknowledgement semantics."
requirements-completed: [INDEXADAM7-01, INDEXADAM7-02, INDEXADAM7-03, INDEXADAM7-04]
coverage:
  - id: D1
    description: Additive Indexed8 eager and chunk Adam7 selector wiring
    requirement: INDEXADAM7-01
    verification:
      - kind: integration
        ref: modules/mb-image/png/stream_encode_test.mbt#PNG Indexed8 Adam7 chunk selector wires the shared machine IHDR
        status: pass
    human_judgment: false
  - id: D2
    description: Shared scalar Indexed8 Adam7 pass traversal and bounded preflight
    requirement: INDEXADAM7-02
    verification:
      - kind: unit
        ref: moon -C modules/mb-image test png --target all --frozen
        status: pass
    human_judgment: false
  - id: D3
    description: Type-3/8 Adam7 frame, canonical palette transparency, raw raster, and public palette decode
    requirement: INDEXADAM7-03
    verification:
      - kind: integration
        ref: modules/mb-image/png/encode_test.mbt#PNG Indexed8 Adam7 eager wire raster and palette decode are exact
        status: pass
    human_judgment: false
  - id: D4
    description: Exact and one-less selected work/output admission remains atomic
    requirement: INDEXADAM7-04
    verification:
      - kind: unit
        ref: modules/mb-image/png/encode_wbtest.mbt#PNG Indexed8 Adam7 preflight facts and admission are exact
        status: pass
    human_judgment: false
duration: 41min
completed: 2026-07-23
status: complete
---

# Phase 81 Plan 01: Indexed8 Adam7 Machine and Eager Wire Contract Summary

**Type-3/8 Indexed8 Adam7 encoding now uses additive eager and chunk selectors over the existing bounded PNG machine, with literal seven-pass wire and atomic-admission coverage.**

## Performance

- **Duration:** 41 min
- **Started:** 2026-07-23T22:26:50Z
- **Completed:** 2026-07-23T23:07:50Z
- **Tasks:** 2/2
- **Files modified:** 5

## Accomplishments

- Added explicit Indexed8 interlace selection for eager and caller-buffered encoding, while legacy Indexed8 and selected Indexed1/2/4 paths explicitly select non-interlaced output.
- Routed Type-3/8 Adam7 frame/work/output calculation and scalar index emission through the shared checked Adam7 pass geometry without pass or image staging.
- Proved the 5x5 transparent and opaque wire contract, including chunk order, CRCs, canonical tRNS, 36-byte raw pass raster, palette decode, and exact/one-less atomic admission.

## Task Commits

1. **Task 1: Add the independent failing Indexed8 Adam7 wire, resource, and legacy tracer** - `9df9a79` (`test`)
2. **Task 2: Route Indexed8 Adam7 through the sole bounded machine and satisfy the tracer** - `62425b6` (`feat`)

## Files Created/Modified

- `modules/mb-image/png/encode.mbt` - Adds Indexed8 Adam7 preflight facts and eager selector.
- `modules/mb-image/png/stream_encode.mbt` - Adds the thin chunk selector and pull-based scalar pass-row traversal.
- `modules/mb-image/png/encode_test.mbt` - Defines the literal Type-3/8 seven-pass oracle, public decode, and eager atomicity checks.
- `modules/mb-image/png/encode_wbtest.mbt` - Asserts exact selected preflight facts and one-less rejection atomicity.
- `modules/mb-image/png/stream_encode_test.mbt` - Smoke-tests chunk selector IHDR Adam7 wiring with one sufficient lease.

## Decisions Made

- Retained `encode_indexed8` and `new_indexed8` as explicit `PngInterlaceStrategy::None` wrappers to preserve byte compatibility.
- Limited Adam7 to `PngIndexedWireProfile::Eight`; low-bit packed indexed Adam7 remains deferred.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Avoided normal-row filter indexing before Adam7 pass lookup**
- **Found during:** Task 2
- **Issue:** The Indexed scanline branch could return a normal-row filter byte at a global offset that is a non-filter Adam7 pass byte for dimensions other than the 5x5 tracer.
- **Fix:** Route Indexed8/Adam7 directly through shared pass location before normal row-width arithmetic.
- **Files modified:** `modules/mb-image/png/stream_encode.mbt`
- **Verification:** Native and four-target PNG package suites pass.
- **Committed in:** `62425b6`

**Total deviations:** 1 auto-fixed (Rule 1 bug)

## Issues Encountered

- The first full four-target command exceeded the short tool timeout without emitting a test failure; rerunning it with a sufficient timeout completed successfully on all targets.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 82 can add hostile caller-buffered lease/tail/progress/sticky-terminal qualification to the already shared Indexed8 Adam7 machine.
- No low-bit Adam7, alternate encoder, staging, strategy expansion, or release automation was added.

## Self-Check: PASSED

- Confirmed all five planned source/test files exist and both task commits are reachable in git history.
