---
phase: 36-bounded-dynamic-planning-and-replay
plan: "01"
subsystem: png-deflate
tags: [moonbit, png, deflate, dynamic-huffman, replay]
requires:
  - phase: 35-png-dynamic-strategy-compatibility
    provides: opt-in DynamicOrFixedOrStored strategy seam
provides:
  - Bounded canonical Dynamic DEFLATE planning and strict complete-PNG selection
  - Acknowledgement-gated Dynamic replay with source-drift detection
affects: [phase-37-dynamic-compression-evidence]
tech-stack:
  added: []
  patterns: [fixed-RFC-capacity dynamic plans, acknowledgement-gated bit replay]
key-files:
  created: []
  modified:
    - modules/mb-image/png/deflate_huffman.mbt
    - modules/mb-image/png/encode.mbt
    - modules/mb-image/png/stream_encode.mbt
key-decisions:
  - Dynamic replaces FixedOrStored only for a strict complete-PNG byte win.
  - Ordinary Huffman depths above 15 make Dynamic unavailable rather than invoking length limiting.
requirements-completed: [PNGD-02, PNGD-03]
coverage:
  - id: D1
    description: Bounded Dynamic Huffman planning and strict winner selection
    requirement: PNGD-02
    verification:
      - kind: unit
        ref: moon -C modules/mb-image test png --target all --frozen
        status: pass
    human_judgment: false
  - id: D2
    description: Acknowledgement-safe Dynamic replay and public complete-input decode
    requirement: PNGD-03
    verification:
      - kind: integration
        ref: modules/mb-image/png/stream_encode_test.mbt#PNG dynamic strict winner decodes completely through public API
        status: pass
    human_judgment: false
duration: 45min
completed: 2026-07-22
status: complete
---

# Phase 36 Plan 01: Bounded Dynamic Planning and Replay Summary

**Bounded RFC Dynamic-Huffman PNG planning with strict fixed-or-stored fallback and acknowledgement-safe scalar replay.**

## Accomplishments

- Added deterministic ordinary canonical Huffman construction with stable tie ordering and a 15-bit fallback.
- Planned Dynamic headers, RLE, code trees, exact lengths, work, and source fingerprint using only fixed RFC-capacity data.
- Replayed Dynamic blocks through the shared PNG framing machine; preview state commits only after acknowledgement and drift remains sticky.
- Added a public BTYPE=10 strict winner that decodes completely to every source component, plus hostile-capacity parity coverage.

## Task Commits

1. Task 1 RED: `afa9123` — failing dynamic planner coverage.
2. Task 1 GREEN: `435e01d` — bounded Dynamic candidate and strict selection.
3. Task 2 GREEN: `1691a05` — acknowledgement-gated Dynamic replay and public tests.

## Verification

- Outline guard plus `*dynamic*` filter: 18/18 tests passed on js, wasm, wasm-gc, and native.
- Full PNG package: 127/127 tests passed on each of js, wasm, wasm-gc, and native.

## Decisions Made

- Dynamic plans retain alphabet/header facts and scalar counters only; scanlines, tokens, compressed output, leases, and history are not retained.
- Dynamic ties and losses preserve the already-selected FixedOrStored bytes.

## Deviations from Plan

None - plan executed within the listed PNG source/test scope. A stale native test executable was terminated before rerunning verification; no source change was required.

## Known Stubs

None.

## Self-Check: PASSED

- Task commits `afa9123`, `435e01d`, and `1691a05` exist.
- All plan-modified PNG implementation and test files exist.

## Next Phase Readiness

Phase 37 can add broader dynamic compression corpus and benchmark evidence on top of the strict bounded implementation.
