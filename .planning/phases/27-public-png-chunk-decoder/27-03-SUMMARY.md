---
phase: 27-public-png-chunk-decoder
plan: "03"
subsystem: png-decoder
tags: [moonbit, png, chunked-decode, deflate, eof]
requires:
  - phase: 27-public-png-chunk-decoder
    provides: broad public chunk contract evidence with five EOF classifier rows outstanding
provides:
  - real fixed-Huffman and dynamic-Huffman paused-inflater EOF vectors
  - zero-length non-IEND pending-type EOF classification
  - complete executable Phase 27 EOF classifier matrix
affects: [28-portable-png-streaming-evidence]
key-files:
  modified:
    - modules/mb-image/png/stream_decode_wbtest.mbt
    - modules/mb-image/png/stream_decode.mbt
key-decisions:
  - "Classifier vectors must prove the actual retained inflater phase; stored-block substitutes do not qualify fixed or dynamic rows."
  - "A completed zero-length non-IEND type after complete raster remains a private pending type state until finish classifies it."
requirements-completed: [PNGS-02]
status: complete
---

# Phase 27 Plan 03: EOF Classifier Matrix Closure Summary

**The final five executable EOF rows now prove zlib-first precedence and pending-IEND-type sticky behavior through both the private classifier and public `PngChunkDecoder::finish`.**

## Accomplishments

- Added literal vectors that pause in a real fixed-Huffman token, dynamic-tree construction, and dynamic match work; each correctly returns `zlib-truncated` before open IDAT/IEND framing.
- Added zero-length wrong-fourth-type and complete non-IEND type vectors. Both remain active through byte 68, become `png-iend-type` only at `finish()`, and replay the same error with zero subsequent input consumption.
- Added the smallest private pending-type state needed to preserve that finish-time classification, without changing the public API, eager `Reader` semantics, result-transfer gate, or policy.

## Task Commits

1. **Task 1: Add real paused-inflater and zero-length-type RED vectors** — `1a4d947` (test)
2. **Task 2: Preserve pending EOF type state and qualify the matrix** — `5e52003` (fix)

## Verification

- `moon -C modules/mb-image test png --target native --frozen -f '*PNG chunk EOF classifier*'` — 5/5 newly closed rows passed.
- `moon -C modules/mb-image test png --target all --frozen` — 83/83 passed on wasm, wasm-gc, js, and native.
- `pwsh -NoProfile -File scripts/fixtures/Generate-PngDecodeVectors.ps1 -Check` — 3,850 cases passed.
- Direct PNG policy and negative-fixture checks passed after the source change.
- Final independent verifier `43786fc` — 4/4 observable truths verified, with no Phase 27 gap remaining.

## Next Phase Readiness

Phase 27 is complete. Phase 28 can now add the broader hostile-schedule evidence and the public portable chunk-decode → image-operation → eager-encode workflow on the stable API.

## Self-Check: PASSED

- The two task commits exist in repository history.
- The final verifier confirms all frozen EOF contexts, parity, ownership, and portable API requirements are satisfied.
