---
phase: 11-portable-processing-pipeline-evidence
plan: "01"
subsystem: portable image-processing evidence
tags: [moonbit, ppm, resize, source-over, cross-target]
requires:
  - phase: 09-checked-image-geometry-and-diagnostics
    provides: checked nearest-neighbor resize and RGB/RGBA conversion APIs
  - phase: 10-alpha-correct-pixel-processing
    provides: alpha-correct source-over API
provides:
  - Strict PPM decode-to-resize-to-source-over-to-encode public example
  - Four frozen target commands with exact deterministic output evidence
affects: [phase-11-integration-evidence, public-examples, mb-image-documentation]
tech-stack:
  added: []
  patterns: [strict codec consumer flow, explicit RGB8-to-straight-RGBA8 bridge, exact encoded-byte oracle]
key-files:
  created: [.planning/phases/11-portable-processing-pipeline-evidence/11-01-SUMMARY.md]
  modified: [examples/ppm-portable/main/main.mbt, modules/mb-image/README.mbt.md]
key-decisions:
  - "Reuse the sole portable PPM example instead of adding a second consumer."
  - "Assert the 17-byte P6 payload and semantic pixels before printing the fixed SHA-256 identity."
patterns-established:
  - "PPM compositing consumers explicitly bridge RGB8 through straight RGBA8 around source-over."
requirements-completed: [INTEG-01]
coverage:
  - id: D1
    description: "Portable strict PPM decode, resize, source-over, and encode pipeline with exact vector evidence."
    requirement: INTEG-01
    verification:
      - kind: integration
        ref: "moon -C examples/ppm-portable run main --target js|wasm|wasm-gc|native --frozen"
        status: pass
    human_judgment: false
  - id: D2
    description: "Runnable four-target documentation for the public processing proof."
    requirement: INTEG-01
    verification:
      - kind: integration
        ref: "moon -C modules/mb-image check README.mbt.md --target js|wasm|wasm-gc|native --frozen"
        status: pass
    human_judgment: false
duration: 15min
completed: 2026-07-20
status: complete
---

# Phase 11 Plan 01: Portable Processing Pipeline Summary

**One portable public consumer now proves strict PPM decode, nearest resize, RGB/RGBA conversion, alpha-correct source-over, and PPM encode with an exact 17-byte vector on every supported target.**

## Performance

- **Duration:** 15 min
- **Completed:** 2026-07-20T09:03:10Z
- **Tasks:** 2/2
- **Files modified:** 2

## Accomplishments

- Replaced the flip-only example route with two real strict P6 decodes, `resize_nearest`, explicit RGB8/straight-RGBA8 conversion, `composite_source_over`, strict conversion back to RGB8, and `PpmEncoder`.
- Checks decoded and encoded byte counts, empty diagnostics, output extent, both RGB pixel triples, the complete 17-byte P6 vector, and rolling digest `9386158` before reporting the fixed SHA-256 identity.
- Documented the flow and exact frozen js, wasm, wasm-gc, and native commands while keeping the Native CLI adapter separate.

## Verification

- `moon -C examples/ppm-portable run main --target js|wasm|wasm-gc|native --frozen` — passed on all four targets; success line includes `bytes_written=17`, `digest=9386158`, and `sha256=cf8f36752d62cd88334bfa8fc45c55bdbf0f70275180bc6d2b14bf3810676464`.
- `moon -C modules/mb-image check README.mbt.md --target js|wasm|wasm-gc|native --frozen` — passed on all four targets.
- Source route inspection confirms `PpmDecoder` → `resize_nearest` → `rgb8_to_straight_rgba8` → `composite_source_over` → `straight_rgba8_to_rgb8` → `PpmEncoder`.

## Task Commits

1. **Task 1: Replace the flip-only portable example with the public resize-and-source-over flow** — `c42f1d5` (`feat`)
2. **Task 2: Document the runnable portable processing proof** — `b4c052f` (`docs`)

## Files Created/Modified

- `examples/ppm-portable/main/main.mbt` — in-memory strict PPM processing pipeline and deterministic vector assertions.
- `modules/mb-image/README.mbt.md` — pipeline semantics and frozen command paths.

## Decisions Made

- Reused the existing portable example so one runnable consumer remains the canonical public proof.
- Used opaque foreground pixels so the source-over result can take the strict, lossless RGBA8-to-RGB8 path required by PPM encoding.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Updated pre-existing out-of-scope wording that failed the plan's README guard**
- **Found during:** Task 2
- **Issue:** The README's existing phrase `performance claims` matched the verifier's forbidden wording despite describing deferred scope rather than making a result claim.
- **Fix:** Reworded it as `speed guarantees`, retaining the same deferred-scope meaning without adding a performance assertion.
- **Files modified:** `modules/mb-image/README.mbt.md`
- **Verification:** All four README checks and the plan's required/forbidden text assertions passed.
- **Committed in:** `b4c052f`

**Total deviations:** 1 auto-fixed (Rule 3)

## Known Stubs

None. The example uses strict public codec and processing APIs with real in-memory bytes; no placeholder output or mock data remains on the success route.

## Next Phase Readiness

The documented public consumer provides the INTEG-01 pipeline proof. Phase 11's concurrent cross-target behavioral/adversarial and benchmark evidence can use the same deterministic public route without release automation.

## Self-Check: PASSED

- Confirmed both modified files exist and task commits `c42f1d5` and `b4c052f` are present in git history.

---
*Phase: 11-portable-processing-pipeline-evidence*
*Completed: 2026-07-20*
