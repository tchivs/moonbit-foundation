---
phase: 27-public-png-chunk-decoder
plan: "02"
subsystem: png-decoder
tags: [moonbit, png, chunked-decode, eof, portability]
requires:
  - phase: 27-public-png-chunk-decoder
    provides: public PngChunkDecoder facade and private byte-fed PNG machine
provides:
  - executable public arbitrary-schedule, ownership, and eager-parity coverage
  - executable private/public EOF classifier and sticky-terminal matrix
  - corrected terminal accounting and eager raster outcome parity
affects: [27-03-eof-matrix-closure, 28-portable-png-streaming-evidence]
key-files:
  modified:
    - modules/mb-image/png/stream_decode_test.mbt
    - modules/mb-image/png/stream_decode_wbtest.mbt
    - modules/mb-image/png/stream_decode.mbt
key-decisions:
  - "Keep the public adapter byte-local: tests mutate and reuse caller-owned input only after push returns."
  - "Compare every observable result/error, diagnostic, and remaining budget field with an independent eager decode."
  - "Preserve the private machine as the sole parser; the test-driven fixes are limited to terminal accounting and outcome parity."
requirements-completed: [PNGS-01]
requirements-advanced: [PNGS-02]
status: complete
---

# Phase 27 Plan 02: PNG Chunk Contract Gap Closure Summary

**Public chunk scheduling, ownership, sticky-terminal, and eager-parity evidence is now executable; the remaining EOF classifier rows were isolated for Plan 03.**

## Accomplishments

- Added public one-byte and mixed-boundary schedules across accepted generated PNG profiles, exact accepted-byte checks, strict pre-finish progress, caller-buffer mutation/reuse, terminal replay, and eager/chunk observable parity.
- Added paired private/public classifier coverage for framing, CRC, raster, stored-zlib, and terminal precedence, including full error shape and zero-consumption replay.
- Corrected only test-proven terminal EOF accounting and eager raster-terminal outcome parity while retaining the single private `PngDecodeMachine` parser and finish-only result transfer.

## Task Commits

1. **Task 1: Public arbitrary partitions, ownership, and eager parity** — `3213dd3` (test)
2. **Task 2: Freeze the initial executable EOF classifier matrix** — `5a5ecaa` (test)
3. **Task 3: Correct test-proven terminal drift** — `3363646` and `649200f` (fix)

## Verification

- `moon -C modules/mb-image test png --target native --frozen -f '*PNG chunk*'` — focused public/private contract tests passed.
- `moon -C modules/mb-image test png --target all --frozen` — 81/81 passed on wasm, wasm-gc, js, and native.
- `pwsh -NoProfile -File scripts/fixtures/Generate-PngDecodeVectors.ps1 -Check` — 3,850 cases passed.
- `pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png` — passed in an isolated worktree because the main checkout had a stale local Moon build lock; this was a native quality execution of the same revision.

## Deviation and Follow-up

The re-verifier found three real missing paused-inflater rows (fixed token, dynamic tree, dynamic match) and two zero-length non-IEND type rows. They were deliberately not claimed by this summary; Plan 03 closes exactly those classifier rows.

## Next Phase Readiness

Plan 03 is required to complete PNGS-02. It should add literal public/private EOF vectors for the five omitted rows without widening the public interface or changing Reader EOF semantics.

## Self-Check: PASSED

- All listed implementation and test commits exist in repository history.
- Scope is limited to PNG chunk contract tests and their demonstrated private-adapter fixes.
