---
phase: 41-adam7-opt-in-compatibility
plan: 01
subsystem: png-encoding
tags: [moonbit, png, adam7, compatibility, portable-testing]
requires:
  - phase: 40-portable-adaptive-filter-evidence
    provides: Explicit filter strategy seams and target-isolated PNG evidence pattern.
provides:
  - Separate public PNG interlace strategy with explicit None and Adam7 choices.
  - Additive eager and caller-buffered interlace factories with atomic Adam7 rejection.
  - Four-target isolated compatibility selectors for the public boundary.
affects: [42-adam7-encode-planning, 43-adam7-public-evidence]
tech-stack:
  added: []
  patterns: ["Strategy choices are rejected at shared machine admission before source traversal or output state."]
key-files:
  created: [scripts/quality/Invoke-PngAdam7Compatibility.ps1]
  modified:
    - modules/mb-image/png/png.mbt
    - modules/mb-image/png/stream_encode.mbt
    - modules/mb-image/png/encode.mbt
    - modules/mb-image/png/encode_test.mbt
    - modules/mb-image/png/stream_encode_test.mbt
key-decisions:
  - "Adam7 reaches a single interlace-aware preflight that returns png-adam7-pending before source traversal, budget charging, output, or a chunk encoder lease."
  - "All existing eager, chunk, and private machine construction paths explicitly forward PngInterlaceStrategy::None."
patterns-established:
  - "Target-isolated PowerShell runners create a GUID-prefixed direct child of the resolved OS temp root and validate containment immediately before cleanup."
requirements-completed: [PNGI-01]
coverage:
  - id: D1
    description: "Public eager and caller-buffered interlace selections preserve explicit-None compatibility and reject Adam7 atomically."
    requirement: PNGI-01
    verification:
      - kind: integration
        ref: "scripts/quality/Invoke-PngAdam7Compatibility.ps1"
        status: pass
      - kind: unit
        ref: "moon -C modules/mb-image test png --target native --frozen"
        status: pass
    human_judgment: false
metrics:
  duration: 24min
  completed: 2026-07-22
status: complete
---

# Phase 41 Plan 01: Adam7 Opt-In Compatibility Summary

**Explicit Adam7 selection now shares eager and caller-buffered PNG admission while retaining non-interlaced output and returning a typed pending capability error.**

## Performance

- **Duration:** 24 min
- **Completed:** 2026-07-22T06:54:53Z
- **Tasks:** 2/2
- **Files modified:** 6

## Accomplishments

- Added public `PngInterlaceStrategy::{None, Adam7}` plus additive narrow and all-strategy eager/chunk factories.
- Forwarded explicit `None` through legacy construction paths; Adam7 is rejected at atomic preflight with `png-adam7-pending` before output, source traversal, or budget changes.
- Added immutable eager/chunk compatibility selectors and a GUID-contained four-target PowerShell runner.

## Task Commits

1. **Task 1: Write failing public compatibility and pending-boundary tests** — `afe05ce` (`test`); this shared-index commit also contains concurrent non-Phase-41 paths, so the orchestrator must path-filter it before final integration.
2. **Task 2: Implement the additive interlace seam and make the compatibility suite pass** — uncommitted by parent instruction after the shared-index contamination was detected.

## Files Created/Modified

- `modules/mb-image/png/png.mbt` — public interlace strategy and eager factory seams.
- `modules/mb-image/png/stream_encode.mbt` — caller-buffered and private machine interlace forwarding.
- `modules/mb-image/png/encode.mbt` — atomic Adam7-pending preflight boundary.
- `modules/mb-image/png/encode_test.mbt` — eager immutable vectors and rejection assertions.
- `modules/mb-image/png/stream_encode_test.mbt` — chunk immutable vectors and construction rejection assertions.
- `scripts/quality/Invoke-PngAdam7Compatibility.ps1` — isolated js/wasm/wasm-gc/native selector runner.

## Decisions Made

- Reused `_png_encode_capability` with the stable `png-adam7-pending` context instead of adding provisional interlaced output.
- Kept real seven-pass geometry and emission work out of scope for Phase 42.

## Deviations from Plan

None - implementation scope follows the plan. The shared Git index was already populated by concurrent work; the Task 1 commit consequently requires orchestrator path filtering and Task 2 remains uncommitted by explicit parent instruction.

## Issues Encountered

- The shared staging index contained concurrent files when Task 1 was committed. No history rewrite or destructive recovery was attempted.

## Next Phase Readiness

Phase 42 can implement seven-pass traversal at the retained interlace-aware machine seam. The Phase 41 selector runner already proves public boundary behavior independently on all four portable targets.

## Self-Check: PASSED

- All six Phase 41 implementation, test, and runner files exist.
- `afe05ce` exists; its concurrent-path contamination is documented above for integration handling.
- The focused four-target runner and native PNG package suite passed.

---
*Phase: 41-adam7-opt-in-compatibility*
*Completed: 2026-07-22*
