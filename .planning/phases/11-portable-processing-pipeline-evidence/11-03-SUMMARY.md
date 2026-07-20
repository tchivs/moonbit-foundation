---
phase: 11-portable-processing-pipeline-evidence
plan: "03"
subsystem: benchmarking
tags: [moonbit, native, ppm, resize, composite, reproducibility]
requires:
  - phase: "09"
    provides: "Checked nearest-neighbor resize"
  - phase: "10"
    provides: "Alpha-correct source-over and RGB/RGBA conversions"
provides:
  - "Isolated native public resize-and-composite PPM benchmark"
  - "Phase-11-local warmup and seven-capture reproducibility record"
affects: [phase-11-verification, benchmark-maintenance]
tech-stack:
  added: []
  patterns: ["correctness validation before benchmark closure", "local benchmark records isolated from release qualification"]
key-files:
  created:
    - benchmarks/ppm/phase-11-resize-composite-baseline.md
  modified:
    - benchmarks/ppm/ppm_bench.mbt
key-decisions:
  - "The resize-and-composite workload remains a native local benchmark with no release-harness dependency or performance promise."
  - "Opaque deterministic PPM fixtures permit an independently calculated encoded-output rolling digest before timing."
patterns-established:
  - "Benchmarks construct inputs outside the measured closure, validate public-pipeline output, then time the identical route."
requirements-completed: [INTEG-03]
coverage:
  - id: D1
    description: "A named native benchmark executes the public decode, resize, convert, source-over, convert, and encode pipeline."
    requirement: INTEG-03
    verification:
      - kind: integration
        ref: "moon -C benchmarks bench --release --target native --frozen ppm"
        status: pass
    human_judgment: false
  - id: D2
    description: "A local tracked record preserves workload provenance, one warmup, and seven individually timestamped captures."
    requirement: INTEG-03
    verification:
      - kind: other
        ref: "benchmarks/ppm/phase-11-resize-composite-baseline.md validation"
        status: pass
    human_judgment: false
duration: 15min
completed: 2026-07-20
status: complete
---

# Phase 11 Plan 03: Local Resize-Composite Benchmark Summary

**A native public PPM resize-and-composite workload now has correctness-gated execution and an isolated seven-capture local reproducibility record.**

## Performance

- **Duration:** 15 min
- **Completed:** 2026-07-20
- **Tasks:** 2/2
- **Files modified:** 2

## Accomplishments

- Added `ppm/pipeline/resize-composite/256x256`, which decodes deterministic strict PPM sources, nearest-resizes, bridges RGB/RGBA, composites source-over, converts back to RGB, and encodes PPM through public APIs.
- Validated output extent and independent rolling correctness digest before timing the same pipeline.
- Recorded one warmup and seven direct native captures with toolchain, input/output digest, command, host facts, timestamps, and transparent aggregate.

## Task Commits

1. **Task 1: Add the isolated native resize-composite benchmark workload** — `c8bf148` (feat)
2. **Task 2: Capture and document the local Phase-11 benchmark baseline** — `d2c8922` (docs)

## Verification

- `moon -C benchmarks bench --release --target native --frozen ppm` — 9/9 passed, including `ppm/pipeline/resize-composite/256x256`.
- Phase-11 local record validation — confirmed required provenance strings, exactly seven timestamped capture rows, and no release-harness reference.

## Decisions Made

- Kept all inputs, budgets, and codec limits explicit and fresh; the benchmark has no external dependency or release qualification role.
- Reported host-dependent capture observations without thresholds or performance claims.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Self-Check: PASSED

- Confirmed the benchmark source, local record, and both task commits exist.
