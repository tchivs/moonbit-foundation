---
phase: 49-portable-gray16-public-evidence
plan: "01"
subsystem: png
tags: [moonbit, png, gray16, u16, portability, regression-testing]
requires:
  - phase: 48-bounded-gray16-encoder-path
    provides: Public bounded Gray16 strategy factories and shared eager/chunk encoding path.
provides:
  - Public Gray16 U16 wire-byte and RGB8 canonicalization evidence for both source-storage byte orders.
  - Public hostile-capacity caller-buffered evidence for every Gray16 compression/filter pair.
  - Independent PNG package evidence across js, wasm, wasm-gc, and native.
affects: [png, gray16, encoding, portability, regression-testing]
key-files:
  created:
    - .planning/phases/49-portable-gray16-public-evidence/49-01-SUMMARY.md
  modified:
    - modules/mb-image/png/encode_test.mbt
    - modules/mb-image/png/stream_encode_test.mbt
key-decisions:
  - Verify exact Stored/None Gray16 scanlines with a fixture-bounded test-local stored-block parser rather than the private inflater.
  - Treat public Gray16 decoder output as RGB8 high-byte canonicalization; low bytes are asserted only at the PNG wire boundary.
  - Use fresh chunk encoders for zero-prefixed, one-byte, and ragged schedules so each accepted-only and sticky-terminal check is independent.
requirements-completed: [GRAY16-03]
completed: 2026-07-22
status: complete
---

# Phase 49 Plan 01: Portable Gray16 Public Evidence Summary

Phase 49 closes `GRAY16-03` with public, portable PNG evidence only. No PNG
production code, public API, scripts, fixtures, or target-specific branches
changed.

## Accomplishments

- Added a generated 3×2 non-symmetric Gray16 corpus for little- and big-endian
  U16 storage. Stored/None output is equal across both source orders and its
  14 filtered scanline bytes exactly retain every high/low wire pair.
- Added a test-local IDAT chunk walker restricted to the known Stored/None
  zlib stored-block layout. It validates the zlib header, final stored marker,
  `LEN`/`NLEN`, payload size, and scanlines without referencing
  `PngInflateState` or another private encoder/decoder seam.
- Documented the public decoder contract: the generated Gray16 PNG decodes to
  RGB8 with each source wire high byte replicated across RGB; low bytes are not
  claimed to round-trip at that API boundary.
- Exercised all six public Gray16 compression/filter pairs in both eager and
  caller-buffered forms. Fresh chunk encoders prove zero/one/ragged eager-byte
  identity, accepted-only totals, unchanged lease tails, and sticky successful
  terminals.
- Added explicit Gray8 frozen literals alongside existing RGB8/RGBA8 frozen
  compatibility vectors in both eager and chunk target-level tests.

## Verification

| Command | Result |
| --- | --- |
| `moon -C modules/mb-image test png --target js --frozen` | PASS — 190 passed, 0 failed |
| `moon -C modules/mb-image test png --target wasm --frozen` | PASS — 190 passed, 0 failed |
| `moon -C modules/mb-image test png --target wasm-gc --frozen` | PASS — 190 passed, 0 failed |
| `moon -C modules/mb-image test png --target native --frozen` | PASS — 190 passed, 0 failed |

The existing compiler warnings remain non-fatal; no warning was introduced as
a Phase 49 failure.

## Task Commits

1. `3d219e1` — public Gray16 eager wire, decoder, and frozen-vector evidence.
2. `151c0f9` — hostile-capacity public Gray16 chunk evidence and frozen-vector coverage.

## Next Phase Readiness

`GRAY16-03` now has a public, four-target evidence baseline. Future Gray16
work can extend separately scoped features without weakening the established
wire, canonicalization, or caller-lease contracts.
