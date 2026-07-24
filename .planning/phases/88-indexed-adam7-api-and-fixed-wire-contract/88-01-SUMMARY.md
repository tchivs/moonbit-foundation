---
phase: 88-indexed-adam7-api-and-fixed-wire-contract
plan: "01"
subsystem: png
tags: [moonbit, png, indexed-color, adam7, deflate, streaming]
requires:
  - phase: 87-indexed-png-compression-profiles
    provides: Indexed Stored/FixedOrStored machine seam and hostile stream contracts
provides:
  - Additive eager and chunked Adam7 compression selector APIs for Indexed1/2/4/8
  - Pass-local packed indexed Adam7 matcher producer shared by bounded FixedOrStored planning and replay
  - All-target regression coverage for the selector surface
affects: [89-pass-aware-preflight-and-shared-machine-integration, 90-hostile-streaming-and-independent-qualification]
tech-stack:
  added: []
  patterns:
    - "Existing interlace-only APIs are literal Stored forwards"
    - "Indexed Adam7 FixedOrStored reuses one preflight and one acknowledged machine"
key-files:
  created:
    - .planning/phases/88-indexed-adam7-api-and-fixed-wire-contract/88-01-SUMMARY.md
  modified:
    - modules/mb-image/png/encode.mbt
    - modules/mb-image/png/stream_encode.mbt
    - modules/mb-image/png/stream_encode_test.mbt
key-decisions:
  - "Keep the public surface additive and preserve all existing Stored wrappers as byte-compatible forwards."
  - "Use the existing Adam7 geometry and scalar packed-byte producer for matcher planning; do not stage pass rows or add a second encoder."
  - "Exercise Indexed8 with the independent 5x5 fixture so selector tests remain within declared output/work limits."
patterns-established:
  - "Each indexed wire depth selects its profile at the single PngEncodeMachine construction seam."
  - "FixedOrStored is selected only after complete indexed frame facts are available and otherwise falls back to Stored."
requirements-completed: [ADAM7COMP-01]
coverage:
  - id: D1
    description: "Indexed1/2/4/8 expose additive eager and chunked Adam7 compression selectors."
    requirement: ADAM7COMP-01
    verification:
      - kind: unit
        ref: "modules/mb-image/png/stream_encode_test.mbt#PNG indexed Adam7 explicit compression selectors cover all low-bit depths"
        status: pass
      - kind: other
        ref: "moon test modules/mb-image/png --target all"
        status: pass
    human_judgment: false
  - id: D2
    description: "Adam7 pass-local filter-None packing is shared by FixedOrStored planning and replay without staging."
    requirement: ADAM7COMP-01
    verification:
      - kind: unit
        ref: "moon test modules/mb-image/png --target all"
        status: pass
      - kind: other
        ref: "git diff inspection: PngIndexedRawCursor and PngEncodeMachine share _png_indexed_adam7_scanline_byte"
        status: pass
    human_judgment: false
  - id: D3
    description: "Existing interlace-only methods remain Stored forwards and legacy package tests remain green."
    requirement: ADAM7COMP-01
    verification:
      - kind: unit
        ref: "moon test modules/mb-image/png --target all"
        status: pass
    human_judgment: false
metrics:
  duration: "~45 min"
  completed: 2026-07-24
  status: complete
---

# Phase 88: Indexed Adam7 API and Fixed Wire Contract Summary

**Indexed1/2/4/8 now share additive Adam7 Stored-or-FixedOrStored eager/chunked selectors over the existing bounded PNG machine.**

## Performance

- **Tasks:** 3 implementation/verification tasks represented by the plan
- **Files modified:** 3 source/test files
- **Validation:** 316 tests passed on native, wasm, wasm-gc, and js

## Accomplishments

- Added paired eager and caller-buffered selector methods for low-bit indexed profiles and Indexed8.
- Extended the indexed matcher cursor to traverse Adam7 pass geometry and MSB-first packed tails through the existing scalar producer.
- Preserved Stored wrapper compatibility and verified the complete package on all four declared targets.

## Task Commits

1. **Implementation and regression coverage** - `5e9526b` (`feat(88): add indexed Adam7 compression selectors`)

## Files Created/Modified

- `modules/mb-image/png/encode.mbt` - Adds eager selector overloads and pass-aware indexed matcher traversal.
- `modules/mb-image/png/stream_encode.mbt` - Adds chunked selector overloads and routes Fixed replay through the pass-aware cursor.
- `modules/mb-image/png/stream_encode_test.mbt` - Covers all low-bit depths plus Indexed8 eager/chunked selector construction and progress.

## Decisions Made

- Compression selection remains additive; old Adam7 methods forward explicitly to `Stored`.
- Dynamic/adaptive indexed compression and wider source/encoder models remain out of scope.
- The public selector test uses a bounded 5x5 fixture rather than the phase-87 large matrix, keeping its declared limits meaningful.

## Deviations from Plan

The typed GSD research/planner/executor agents did not return in this workspace, so the plan and implementation were completed inline using the already-created phase context and research artifacts. No scope expansion resulted.

## Issues Encountered

- An early selector test used a large Indexed8 fixture and failed under the declared bounded test budget. It was replaced with the independent 5x5 Adam7 fixture; all four targets then passed 316/316 tests.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 89 can now tighten pass-aware preflight and shared-machine accounting against the additive selector seam. Phase 90 remains responsible for the full hostile lease/replay matrix and independent RGB8/RGBA8 qualification.

---
*Phase: 88-indexed-adam7-api-and-fixed-wire-contract*
*Completed: 2026-07-24*
