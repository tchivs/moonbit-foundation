---
phase: 28-portable-png-streaming-evidence
plan: "01"
subsystem: testing
tags: [png, streaming, chunk-decoder, portable-targets, quality-lane]
requires:
  - phase: 27-public-png-chunk-decoder
    provides: Public PngChunkDecoder with exact progress, explicit finish, and sticky terminal outcomes.
provides:
  - Corpus-wide public hostile packet schedule evidence for PngChunkDecoder.
  - A four-target chunk-decode, bilinear-resize, eager-encode PNG example.
  - Exact scoped PNG quality-lane evidence for the portable workflow.
affects: [png, quality, verification]
tech-stack:
  added: []
  patterns:
    - Public decoder schedules create a fresh caller-owned slice for every push and compare against a separate eager oracle.
    - Portable executable evidence is an exact, target-neutral single status line.
key-files:
  created:
    - .planning/phases/28-portable-png-streaming-evidence/28-01-SUMMARY.md
  modified:
    - modules/mb-image/png/stream_decode_test.mbt
    - examples/png-portable/main/main.mbt
    - modules/mb-image/README.mbt.md
    - scripts/quality/Invoke-MoonQuality.ps1
key-decisions:
  - "Use the existing 3,850-record generated corpus and public PngChunkDecoder only; do not add a second parser or private-state assertions."
  - "Keep the fixed portable workflow's eager PngEncoder and frozen 78-byte digest while making public chunk decode visible."
  - "Keep the PNG quality lane fail-closed and scoped; release, registry, credentials, and a streaming encoder remain out of scope."
patterns-established:
  - "A one-byte route captures the first source terminal prefix, and the ragged route must reproduce that exact prefix before sticky replay."
requirements-completed: [PNGS-04]
coverage:
  - id: D1
    description: Every generated accepted and rejected PNG record proves public chunk progress, finish ownership, eager parity, diagnostics, budgets, and sticky terminals under empty-one-byte and ragged schedules.
    requirement: PNGS-04
    verification:
      - kind: unit
        ref: moon -C modules/mb-image test png --target all --frozen
        status: pass
    human_judgment: false
  - id: D2
    description: The portable public example chunk-decodes the fixed PNG before bilinear resize and eager canonical encoding on every supported target.
    requirement: PNGS-04
    verification:
      - kind: integration
        ref: pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png
        status: pass
    human_judgment: false
  - id: D3
    description: README ownership guidance and scoped quality isolation reproduce the public workflow without release or registry routing.
    requirement: PNGS-04
    verification:
      - kind: integration
        ref: moon -C modules/mb-image check README.mbt.md --target all --frozen; pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png
        status: pass
    human_judgment: false
duration: 31min
completed: 2026-07-21
status: complete
---

# Phase 28 Plan 01: Portable PNG Streaming Evidence Summary

**Public PNG chunks now have corpus-wide hostile-schedule evidence and a frozen four-target decode-to-resize-to-eager-encode workflow.**

## Performance

- **Duration:** 31 min
- **Tasks:** 3/3
- **Files modified:** 4

## Accomplishments

- Added one reusable black-box schedule runner that drives every generated PNG record through empty-plus-one-byte and deterministic ragged public packets, with exact admissions, finish-only transfer, eager parity, budget/diagnostic parity, and sticky replay.
- Converted `png-portable` to `PngChunkDecoder` using a fixed sixteen-push schedule while retaining the asserted 3-by-1 bilinear pixels and canonical 78-byte, `626208771` output.
- Documented the `push`/`finish` ownership rule and froze the exact workflow evidence in the isolated PNG quality lane.

## Task Commits

1. **Task 1: Prove every generated PNG record through hostile public chunk schedules** — `076d3bd` (RED contract), `d7b3613` (green corpus proof)
2. **Task 2: Convert the sole PNG public example to chunk decode and document the contract** — `104806a`
3. **Task 3: Freeze the scoped PNG quality evidence and isolation trace** — `91674fb`

## Verification

- `moon -C modules/mb-image test png --target native --frozen` — 84/84 passed.
- `pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png` — passed in 261.1 seconds: fixture freshness reported 3,850 executable decode cases; each target's PNG suite passed 84/84; exact portable workflow, README checks, and isolation trace passed.
- Direct `png-portable` runs on js, wasm, wasm-gc, and native each emitted exactly `example=png-portable input_schedule=workflow-zero-signature-ihdr-idat-deflate-iend pushes=16 bytes_read=75 bytes_written=78 width=3 height=1 resize_bilinear digest=626208771`.

## Decisions Made

- The public evidence uses no private decoder state and retains no caller `ByteView` after a push.
- A one-byte schedule is the oracle for the ragged route's first source-terminal byte; EOF-only failures remain finish-only.
- The quality lane remains limited to PNG policy, fixtures, package contents, public workflow, README, and portable targets.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Corrected the new MoonBit test helper's assertion scope and explicit packet clipping.**

- **Found during:** Task 1
- **Issue:** Helper functions cannot call test-only `fail`, and MoonBit has no unqualified `min` identifier.
- **Fix:** Used `abort` in helper paths and explicit scheduled-versus-available clipping; added an explicit capture mode for the one-byte route's first source terminal.
- **Files modified:** `modules/mb-image/png/stream_decode_test.mbt`
- **Verification:** Native corpus suite passed 84/84; isolated four-target PNG quality lane passed.
- **Committed in:** `d7b3613`

**Total deviations:** 1 auto-fixed (1 blocking test-helper correction).

## Issues Encountered

The first quality-lane invocation reached the executor's 124-second command timeout without an application failure. Re-running the same scoped lane with a 10-minute timeout completed successfully in 261.1 seconds.

## Known Stubs

None.

## Next Phase Readiness

Phase 28's sole plan is complete. The v0.8 milestone now has executable public evidence for the PNG chunk-decoding contract on all required targets; no release, registry, or public streaming-encoder work was introduced.

## Self-Check: PASSED

- Summary exists at the required Phase 28 path.
- Task commits `076d3bd`, `d7b3613`, `104806a`, and `91674fb` exist.

