---
phase: 49-portable-gray16-public-evidence
plan: "01"
status: passed
score: 100
requirements:
  - id: GRAY16-03
    status: passed
gaps: []
human: []
verified: 2026-07-22
---

# Phase 49 Goal-Backward Verification

## Verdict

**Passed — 100/100.** Phase 49 delivers the public-evidence-only `GRAY16-03` boundary. All three Roadmap success criteria are demonstrated without expanding the encoder or public API scope.

## Goal Evidence

| Goal-backward truth | Evidence | Verdict |
| --- | --- | --- |
| Generated U16 Gray input preserves both bytes of every sample in the PNG wire payload. | `png_encode_gray16_public_fidelity_image` creates the required 3×2 non-symmetric U16 corpus for both storage byte orders. `png_encode_gray16_public_stored_scanlines` walks IDAT chunks and validates the known Stored/None zlib header, stored marker, LEN/NLEN, and 14-byte scanlines. `PNG Gray16 public eager fidelity` requires identical little/big PNG bytes and `00 12 34 ab cd 00 ff 00 7f 01 80 02 fe 10`. | PASS |
| Public decode behavior is documented rather than overclaimed. | `png_encode_gray16_public_decode_is_canonical` decodes only through the public `PngDecoder`, requires a 3×2 RGB/U8 result, and checks each RGB channel against the six PNG wire high bytes. The low bytes are asserted only by the wire oracle. | PASS |
| All explicit Gray16 strategy/filter pairs retain public eager behavior. | The eager public-fidelity test iterates Stored, FixedOrStored, and DynamicOrFixedOrStored with None and Adaptive, checks Gray16 IHDR fields, and runs the public decoder canonicalization oracle for every pair. | PASS |
| Zero, one-byte, and ragged caller leases remain eager-byte-identical with accepted-only progress and sticky terminals. | `PNG Gray16 chunk public evidence` iterates the same six pairs using fresh `PngChunkEncoder::new_gray16_with_strategies` instances. It directly verifies the empty lease, then `[0,1]`, `[1]`, and `[0,8,4,1,13,2,5,3,21]` drains. `png_stream_gray16_public_drain` validates `total_written == prior accepted + written`, untouched lease tails, eager equality, and a zero-byte sticky Finished terminal with an untouched later sentinel. | PASS |
| Gray8/RGB8/RGBA8 compatibility remains explicit and frozen. | Both eager and caller-buffered frozen compatibility tests include literal one-pixel Gray8, RGB8, and straight-RGBA8 Stored PNG vectors; assertions compare encoder output to literals rather than regenerated expectations. | PASS |
| Public evidence is independently portable. | The complete PNG test package was run independently for js, wasm, wasm-gc, and native in this verification session; each passed 190 tests. | PASS |

## Independent Commands

| Command | Result |
| --- | --- |
| `moon -C modules/mb-image test png --target js --frozen` | PASS — 190 passed, 0 failed |
| `moon -C modules/mb-image test png --target wasm --frozen` | PASS — 190 passed, 0 failed |
| `moon -C modules/mb-image test png --target wasm-gc --frozen` | PASS — 190 passed, 0 failed |
| `moon -C modules/mb-image test png --target native --frozen` | PASS — 190 passed, 0 failed |

## Scope Verification

- The implementation range after the Phase 49 plan commit is limited to `modules/mb-image/png/encode_test.mbt` and `modules/mb-image/png/stream_encode_test.mbt`, plus expected planning/summary artifacts.
- No production PNG/storage code, public API, script, fixture directory, target branch, or staging buffer was added.
- The stored-block parser is test-local and does not use a private inflater API.
