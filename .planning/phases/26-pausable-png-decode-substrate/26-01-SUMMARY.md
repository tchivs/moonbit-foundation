---
phase: 26-pausable-png-decode-substrate
plan: "01"
subsystem: png-decode
tags: [png, decode, resumable, deflate, raster, portable]
requires:
  - phase: 25-portable-colour-conformance-evidence
    provides: full-profile PNG grammar, metadata, and four-target conformance corpus
provides:
  - private byte-fed PNG framing, IDAT, DEFLATE, raster, and terminal-state substrate
  - eager PngDecoder facade driven by the same private state machine
  - full-profile four-target parity and private-surface policy evidence
affects: [png-decode, png-streaming]
tech-stack:
  added: []
  patterns: [owned byte continuations, authenticated IDAT handoff, private outcome gate, facade parity]
key-files:
  created:
    - modules/mb-image/png/stream_decode.mbt
    - modules/mb-image/png/stream_decode_wbtest.mbt
    - modules/mb-image/png/stream_decode_test.mbt
  modified:
    - modules/mb-image/png/png.mbt
    - modules/mb-image/png/deflate_inflate.mbt
    - modules/mb-image/png/raster_decode.mbt
    - policy/foundation.json
    - scripts/quality/Assert-Policy.ps1
    - scripts/quality/Invoke-MoonQuality.ps1
key-decisions:
  - "Keep the byte-fed state machine private in Phase 26; PngDecoder remains the only public decoder facade."
  - "Create no observable result until IDAT CRC, zlib Adler-32, IEND CRC, and EOF validation all succeed."
  - "Reuse the established full-profile generated corpus rather than introduce a second PNG parser or alter fixture policy."
metrics:
  tasks_completed: 3
  four_target_png_tests: 68
  generated_vectors: 3850
completed: 2026-07-21
status: complete
---

# Phase 26 Plan 01: Pausable PNG Decode Substrate Summary

**The eager PNG decoder now runs through one private, byte-resumable MoonBit state machine without adding a public chunk-decoding API.**

## Accomplishments

- Introduced private owned continuation state for PNG signature/framing, ancillary chunks, per-IDAT CRC, zlib/DEFLATE, scanline reconstruction, Adam7, IEND, and EOF validation.
- Refactored the pure-MoonBit inflater to retain stored, fixed-Huffman, dynamic-Huffman, match-copy, Adler-32, and one-byte output-handoff state across arbitrary input boundaries.
- Retained the preflight image and raster sink privately; a `PngMachineOutcome` is produced only after final IDAT CRC, Adler-32, IEND CRC, and end-of-input checks pass.
- Routed the unchanged public `PngDecoder` Reader facade through the private machine, with full-profile generated corpus parity for grayscale, indexed/PLTE, tRNS, 16-bit, Adam7, sRGB, legacy declarations, iCCP, malformed input, limits, and budgets.
- Added exact private-source policy coverage and an isolated PNG quality-lane check while preserving the public `PngDecoder`/`PngEncoder` interface.

## Task Commits

1. Task 1 private framing and preflight lifecycle: `d985484`, `a35dfe6`, `6642152`, `ce91d07`, `e88704d`, `fa911a3`, `1591c24`.
2. Task 2 resumable DEFLATE, raster, and authenticated output handoff: `26414fe`, `c425b4a`, `8249341`, `944605a`, `3969bcc`, `4f9f400`, `b671110`.
3. Task 3 eager-facade parity and private-source policy evidence: `4ebfaef`, `bd5b2fb`.

## Verification

- `pwsh -NoProfile -File scripts/fixtures/Generate-PngDecodeVectors.ps1 -Check` — passed; 3,850 executable PNG vectors checked.
- `moon -C modules/mb-image test png --target all --frozen` — passed, 68/68 on wasm, wasm-gc, js, and native.
- `pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png` — passed with the private-source/public-interface inventory and four-target corpus checks.
- Independent GSD verification: [`26-01-VERIFICATION.md`](./26-01-VERIFICATION.md) — passed, 4/4 phase must-haves.

## Decisions and Remaining Scope

- `PngDecodeMachine`, its byte adapters, and its terminal outcome remain private implementation details. Phase 26 intentionally exposes neither `PngChunkDecoder` nor public `push`/`finish` methods.
- Phase 27 owns the public caller-buffered `PngChunkDecoder` surface, exact accepted-byte progress, explicit `finish()`, and sticky terminal results. Phase 28 owns public hostile-schedule and workflow evidence.

## Known Stubs

None.

## Self-Check: PASSED

The private substrate, unchanged public facade, full-profile four-target evidence, generated-vector check, isolated quality lane, and independent 4/4 verifier report all exist and pass.
