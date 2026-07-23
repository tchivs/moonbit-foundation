---
phase: 58-portable-adam7-public-evidence
plan: "02"
subsystem: png-public-streaming-tests
tags: [png, adam7, graya16, chunk-encoder, caller-lease]
requires:
  - phase: 57-bounded-adam7-streaming-semantics
    provides: bounded all-strategy GrayAlpha16 Adam7 public factories
provides:
  - public zero/one/ragged caller-buffer evidence for every legal GrayAlpha16 Adam7 selector
  - explicit non-interlaced method-zero checks for frozen chunk PNG vectors
affects: [modules/mb-image/png/stream_encode_test.mbt]
tech-stack:
  added: []
  patterns: [fresh-public-encoder-per-schedule, accepted-prefix-only, sentinel-tail, sticky-terminal]
key-files:
  created: []
  modified:
    - modules/mb-image/png/stream_encode_test.mbt
decisions:
  - Keep Phase 58 evidence at the public PngChunkEncoder and PngEncoder boundary with no production changes.
  - Replace six narrow pair tests with one all-selector schedule matrix to make required capacity coverage explicit without duplicate drains.
metrics:
  duration: 9min
  completed: 2026-07-23
  tasks_completed: 2
  files_modified: 1
status: complete
---

# Phase 58 Plan 02: Public GrayAlpha16 Adam7 hostile caller-buffer evidence Summary

Every legal GrayAlpha16 Adam7 public chunk selector now proves fresh zero, one-byte, and ragged lease behavior against a fresh eager result while preserving caller-owned tails and sticky completion.

## Completed Tasks

1. **Public hostile tracer** — `f3079d7`
   - Replaced the empty allocation with a one-byte `Z` owner lent as a zero-length lease.
   - Proved zero current/total progress, `NeedOutput`, and preservation of the unleased owner byte before fresh one-byte and ragged drains.

2. **All-selector public schedule matrix and frozen vectors** — `d96760a`
   - Covers Stored, FixedOrStored, and DynamicOrFixedOrStored crossed with None and Adaptive under `[0, 1]`, `[1]`, and the required ragged schedule.
   - Each drain retains accepted-prefix accounting, untouched sentinel tails, byte identity with a fresh eager encoding, and a later untouched sticky `Finished` lease.
   - Retained literal Gray8, Gray16, GrayAlpha8, RGB8, and straight-RGBA8 chunk vectors and now asserts their IHDR interlace byte remains method `0`.

## Verification

- `moon -C modules/mb-image test png --target native --frozen -f 'PNG GrayAlpha16 Adam7 public hostile tracer'` — 1 passed.
- `moon -C modules/mb-image test png --target native --frozen -f 'PNG GrayAlpha16 Adam7 public hostile schedules'` — 1 passed.
- `moon -C modules/mb-image test png --target native --frozen -f 'PNG filter strategy chunk frozen compatibility vectors'` — 1 passed.
- `git diff --check HEAD -- modules/mb-image/png/stream_encode_test.mbt` — passed.

## TDD Gate Compliance

The public encoder behavior was already implemented and verified by Phase 57, so the newly named public evidence passed on its first run. This plan adds no production implementation: it makes the public proof boundary stricter and broader as required by Phase 58.

## Deviations from Plan

None - plan executed exactly as written. The old six narrow parity tests were consolidated into the planned named all-selector matrix; the resulting coverage is broader and avoids executing duplicate schedules.

## Known Stubs

None.

## Self-Check: PASSED

- `modules/mb-image/png/stream_encode_test.mbt` exists and contains the tracer and all-selector hostile-schedule tests.
- Commits `f3079d7` and `d96760a` exist.
