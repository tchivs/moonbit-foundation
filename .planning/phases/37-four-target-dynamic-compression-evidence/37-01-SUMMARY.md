---
phase: 37-four-target-dynamic-compression-evidence
plan: "01"
subsystem: png-testing
tags: [moonbit, png, deflate, dynamic-huffman, four-target]
requires:
  - phase: 36-bounded-dynamic-planning-and-replay
    provides: strict DynamicOrFixedOrStored selection and acknowledgement-safe replay
provides:
  - Generated periodic five-symbol RGB8 and straight-RGBA8 Dynamic compression evidence
  - Public strategy size, BTYPE, determinism, chunk-drain, and complete-decode checks
affects: [png-dynamic-huffman-compression, four-target-validation]
tech-stack:
  added: []
  patterns: [generated in-memory compression corpus, outline-guarded four-target package test]
key-files:
  created: []
  modified:
    - modules/mb-image/png/stream_encode_test.mbt
key-decisions:
  - Reused the existing complete-input descriptor-and-component decode oracle for all Dynamic outputs.
  - Kept the prior compact RGB Dynamic and FixedOrStored corpus coverage unchanged while adding one named four-target test.
patterns-established:
  - Generated corpus cases construct Stored, FixedOrStored, repeated Dynamic eager, and hostile-drain Dynamic routes before public comparisons.
requirements-completed: [PNGD-04]
coverage:
  - id: D1
    description: Public periodic RGB8/RGBA8 corpus proves strict Dynamic selection, deterministic eager/chunk output, and complete decode fidelity.
    requirement: PNGD-04
    verification:
      - kind: integration
        ref: modules/mb-image/png/stream_encode_test.mbt#PNG dynamic corpus evidence is deterministic, strictly wins periodic RGB8/RGBA8, and decodes completely
        status: pass
      - kind: unit
        ref: moon -C modules/mb-image test png --target all --target-dir _build/phase37-all --frozen
        status: pass
    human_judgment: false
duration: 6min
completed: 2026-07-22
status: complete
---

# Phase 37 Plan 01: Four-Target Dynamic Compression Evidence Summary

**Public periodic RGB8 and straight-RGBA8 PNG corpus proves strict Dynamic compression wins, eager/chunk determinism, and complete four-target decode fidelity.**

## Accomplishments

- Added an in-memory 128x1 five-symbol corpus whose component sequence defeats the retained distance-1-through-4 matcher for both RGB8 and straight-RGBA8.
- Compared explicit Stored, unchanged FixedOrStored, and DynamicOrFixedOrStored public routes; Dynamic must be final BTYPE=10, no larger, and strictly smaller than FixedOrStored.
- Proved repeated eager output and a zero/ragged caller-buffered drain are byte-identical, then decoded all Dynamic products through the existing complete-input component oracle.
- Verified the named test once in each js, wasm, wasm-gc, and native outline; all filtered runs passed, as did the 131-test PNG suite on every target.

## Task Commits

1. **Task 1: Add the public five-symbol Dynamic corpus and four-target evidence** — `25b4c31` (test)

## Files Created/Modified

- `modules/mb-image/png/stream_encode_test.mbt` — generated Dynamic corpus helpers and the named four-target public evidence test.

## Decisions Made

- Reused `png_stream_test_fixed_or_stored_corpus_decode_matches_source` so complete-input decoding retains its existing descriptor and every-component policy.
- Constructed the Stored comparison route without changing the existing FixedOrStored corpus helpers or compact Dynamic tests.

## Verification

- Filtered outline-and-test evidence passed on js, wasm, wasm-gc, and native using `_build/phase37-<target>` directories.
- `moon -C modules/mb-image test png --target all --target-dir _build/phase37-all --frozen` passed: 131/131 tests on each target.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Self-Check: PASSED

- `modules/mb-image/png/stream_encode_test.mbt` exists.
- Task commit `25b4c31` exists.

## Next Phase Readiness

PNGD-04 now has deterministic public four-target evidence with no production, API, configuration, or policy changes.
