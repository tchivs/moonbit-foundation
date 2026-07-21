---
phase: 31-portable-png-encode-evidence
plan: "01"
subsystem: png-encode-evidence
tags: [moonbit, png, chunked-encode, portable-targets, quality-lane]
requires:
  - phase: 30-public-png-chunk-encoder
    provides: Public PngChunkEncoder with exact progress and sticky terminal outcomes
provides:
  - Four-target hostile caller-capacity and constructor-parity evidence for PngChunkEncoder
  - One public PNG chunk-decode, resize, and chunk-encode executable with frozen output evidence
  - Scoped PNG quality-lane matching for the public chunk workflow
affects: [png, portable-targets, quality]
tech-stack:
  added: []
  patterns: [caller-owned output leases, eager-oracle parity, target-isolated evidence, exact workflow lines]
key-files:
  created: []
  modified:
    - modules/mb-image/png/stream_encode_test.mbt
    - examples/png-portable/main/main.mbt
    - scripts/quality/Invoke-MoonQuality.ps1
key-decisions:
  - "Reuse the eager PngEncoder only as a test oracle while public consumers drain PngChunkEncoder through callback-scoped leases."
  - "Keep the PNG quality lane isolated and exact-match its single portable public workflow line on all four required targets."
patterns-established:
  - "Hostile output schedules copy only the reported callback-scoped prefix and assert cumulative progress before the next pull."
  - "Portable workflow evidence names both the deterministic output schedule and exact output pull count."
requirements-completed: [PNGE-04, PNGE-05]
coverage:
  - id: D1
    description: "Public PngChunkEncoder hostile-capacity, eager-parity, preflight-parity, and sticky-terminal evidence runs in isolated builds on all required targets."
    requirement: PNGE-04
    verification:
      - kind: unit
        ref: "pwsh -NoProfile -File scripts/quality/Invoke-PngEncodeEvidence.ps1 -Target {js,wasm,wasm-gc,native}"
        status: pass
    human_judgment: false
  - id: D2
    description: "The sole png-portable workflow chunk-decodes, resizes, and chunk-encodes the frozen 78-byte PNG with a 14-pull public output schedule."
    requirement: PNGE-05
    verification:
      - kind: integration
        ref: "moon -C examples/png-portable run main --target {js,wasm,wasm-gc,native} --frozen"
        status: pass
      - kind: integration
        ref: "pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png"
        status: pass
    human_judgment: false
duration: 25min
completed: 2026-07-21
status: complete
---

# Phase 31 Plan 01: Portable PNG Encode Evidence Summary

**Public PNG output now proves hostile caller-buffer behavior and drives the sole portable decode-resize-encode workflow to the frozen 78-byte, digest-626208771 result on all four targets.**

## Performance

- **Duration:** 25 min
- **Completed:** 2026-07-21
- **Tasks:** 3/3
- **Files modified:** 3

## Accomplishments

- Added selected black-box PngChunkEncoder evidence for RGB8 and straight RGBA8 under empty-then-one-byte, one-byte, and zero-tiny-ragged output schedules, including eager parity, terminal lease non-mutation, and constructor rejection parity.
- Replaced the portable example's final eager writer path with public PngChunkEncoder output drained through a reusable 21-byte caller-owned owner in exactly 14 pulls.
- Updated the PNG-only quality lane to exact-match the new public chunk-decode-resize-chunk-encode evidence line without changing its fail-closed routing.

## Task Commits

1. **Task 1: Add selected four-target public hostile-output and preflight evidence** — `8bc6a73` (RED), `9a867d1` (GREEN)
2. **Task 2: Convert the single PNG portable consumer to public chunk output** — `860513a` (RED), `513705a` (GREEN)
3. **Task 3: Freeze chunk-encode evidence in the scoped PNG quality lane** — `7906fe7`

## Verification

- `Invoke-PngEncodeEvidence.ps1` passed separately for js, wasm, wasm-gc, and native; each target ran 4 selected tests with no failures.
- Direct `png-portable` runs on all four targets emitted the exact frozen workflow line with `output_schedule=zero-tiny-ragged` and `output_pulls=14`.
- `Generate-PngDecodeVectors.ps1 -Check` passed with 3,850 executable cases.
- `Invoke-MoonQuality.ps1 -Lane Png` passed after 332 seconds: all four PNG suites passed 98/98 and the PNG lane isolation proof passed.

## Files Created/Modified

- `modules/mb-image/png/stream_encode_test.mbt` — public hostile output, preflight parity, and sticky terminal evidence.
- `examples/png-portable/main/main.mbt` — caller-buffered public output drain for the existing decode and bilinear-resize workflow.
- `scripts/quality/Invoke-MoonQuality.ps1` — exact four-target workflow expectation and isolation trace label.

## Decisions Made

- Retained the eager encoder only as an independent test oracle; the public portable consumer now uses PngChunkEncoder end to end.
- Kept the established PNG quality lane and changed only its public workflow evidence stage and exact expected status line.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The scoped PNG lane completed successfully after 332 seconds. It reported the existing generated/legacy diagnostics plus an unused `tchivs/mb-core/io` package warning in the portable example after the planned removal of `MemoryWriter`; the plan limited changes to `main.mbt`, so package inventory was preserved.

## Known Stubs

None. The empty byte arrays in the test and example are populated exclusively from accepted public output prefixes and do not reach output as placeholders.

## Next Phase Readiness

PNGE-04 and PNGE-05 now have independent four-target runtime evidence. The PNG lane remains scoped away from Required, QOI, release, registry, and credential paths.

## Self-Check: PASSED

- All three plan-owned implementation files exist and all five task commits are present in git history.
- The four target-isolated encoder runs, four direct portable workflow runs, vector freshness check, and scoped PNG lane all passed.

---
*Phase: 31-portable-png-encode-evidence*
*Completed: 2026-07-21*
