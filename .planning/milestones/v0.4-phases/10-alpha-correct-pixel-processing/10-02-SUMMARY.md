---
phase: 10-alpha-correct-pixel-processing
plan: 02
subsystem: testing
tags: [moonbit, rgba8, srgb, alpha, budget, raster]
requires:
  - phase: 10-01
    provides: Portable source-over, grayscale, and alpha-aware box blur APIs.
provides:
  - Independent linear-premultiplied exact-byte oracle and rejection matrix.
  - Public fixed-byte vectors for translucent raster processing and metadata boundaries.
affects: [phase-10-verification, raster-processing]
tech-stack:
  added: []
  patterns: [test-local typed color oracle, full Budget.remaining atomicity comparison]
key-files:
  created: []
  modified:
    - modules/mb-image/ops/processing_wbtest.mbt
    - modules/mb-image/ops/processing_test.mbt
key-decisions:
  - "Keep linear-premultiplied encode/quantize oracle entirely test-local."
  - "Assert all Budget remaining fields for every rejection path."
patterns-established:
  - "Processing public vectors use fixed RGBA8 bytes established by the white-box oracle."
requirements-completed: [RASTER-01, RASTER-02]
coverage:
  - id: D1
    description: Alpha-correct source-over and deterministic grayscale/blur exact-byte vectors.
    requirement: RASTER-01
    verification:
      - kind: unit
        ref: modules/mb-image/ops/processing_wbtest.mbt#processing oracle fixes translucent linear-premultiplied byte vectors
        status: pass
      - kind: unit
        ref: modules/mb-image/ops/processing_test.mbt#public processing fixed translucent vectors preserve straight owned output
        status: pass
    human_judgment: false
  - id: D2
    description: Capability, metadata, overflow, and complete Budget atomicity rejection evidence.
    requirement: RASTER-02
    verification:
      - kind: unit
        ref: modules/mb-image/ops/processing_wbtest.mbt#processing rejects capability metadata overflow and every resource limit atomically
        status: pass
      - kind: unit
        ref: modules/mb-image/ops/processing_test.mbt#public composite rejects all metadata incompatibilities before charging
        status: pass
    human_judgment: false
duration: 28min
completed: 2026-07-20
status: complete
---

# Phase 10 Plan 02: Processing Evidence Gap Closure Summary

**Independent linear-premultiplied RGBA8 oracle and public exact-byte vectors now prove alpha-correct processing and atomic rejection behavior across all supported targets.**

## Performance

- **Duration:** 28 min
- **Completed:** 2026-07-20T08:50:00Z
- **Tasks:** 2/2
- **Files modified:** 2

## Accomplishments

- Added an independent typed sRGB decode/premultiply/encode/ties-even oracle with fixed translucent composite, Rec.709 grayscale, and clamp-to-edge blur bytes.
- Added hostile capability, extent, blur-overflow, and every Budget resource-ceiling atomicity coverage.
- Added self-contained public vectors for operand order, output metadata, radius-zero semantics, and composite metadata rejection.

## Task Commits

1. **Task 1: Add independent oracle and complete rejection/atomic-budget matrix** — `341d517` (test)
2. **Task 2: Add public alpha, metadata, grayscale, and edge-blur behavior vectors** — `f736523` (test)

## Verification

- `moon test modules/mb-image/ops --target js` — passed (35 tests)
- `moon test modules/mb-image/ops --target wasm` — passed (35 tests)
- `moon test modules/mb-image/ops --target wasm-gc` — passed (35 tests)
- `moon test modules/mb-image/ops --target native` — passed (35 tests; toolchain emitted one unused-value warning)

## Decisions Made

- Kept the production algorithm untouched; conversion and quantization evidence is isolated to white-box tests.
- Used fixed expected byte vectors in public tests, with no production helper or oracle dependency.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Issues Encountered

- Initial test helper assertions needed to return a Boolean because MoonBit's `inspect` is test-context-only; the helper was made pure and callers assert its result.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

RASTER-01 and RASTER-02 now have executable, four-target evidence without processing, package, documentation, or release changes.

## Self-Check: PASSED

- Confirmed both modified processing test files exist.
- Confirmed task commits `341d517` and `f736523` exist in git history.
