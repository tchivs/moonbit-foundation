---
phase: quick-260721-6k0
quick_id: 260721-6k0
verified: 2026-07-20T21:11:06Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Quick Task 260721-6k0 Verification Report

**Goal:** Bounded, non-interlaced, 8-bit PNG grayscale-alpha (colour type 4) decoding to straight RGBA8, with bpp=2 filtering, native-alpha semantics, checked limits, independent generated evidence, and four-target coverage.

**Status:** passed

**Mode:** Initial verification. No earlier `VERIFICATION.md` existed. The SUMMARY was treated as a claim only; evidence below is from the committed code, generated artifacts, corpus cardinality checks, and commands run during verification.

## Goal Achievement

| # | Observable truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Legal non-interlaced type-4/depth-8 input decodes through `PngDecoder` to straight RGBA8 with `g,g,g,a`. | VERIFIED | `structural.mbt` accepts type 4 only at depth 8 and assigns two source channels/four output channels. `deflate_inflate.mbt` reconstructs source bytes with `transport.source_channels`; the two-channel branch calls `_png_write_grayscale_alpha_row`, which copies gray into RGB and preserves alpha. `_png_descriptor` sets `AlphaMode::Straight` for four channels. The generated public test checks descriptor dimensions/channel count and every output byte; all four targets passed. |
| 2 | Type 4 uses bpp=2 and rejects unsupported depths and `tRNS`. | VERIFIED | Both the live inflater and `_png_write_raster` call `rows.reconstruct(..., 2UL, ...)`; the latter is independently exercised by the white-box Paeth/vector test. `_png_preflight_ihdr` rejects depths 1/2/4/16, and the `tRNS` parser routes type 4 to `png-semantic-chunk` before IDAT; post-IDAT `tRNS` is rejected by `PngIdatSource::finish`. Generated public vectors cover depth, semantic/order/CRC `tRNS`, and filter failures. |
| 3 | Type-4 resource and hostile paths are bounded, typed, and cannot expose a `DecodeResult`; every nonempty two-IDAT split agrees with its unsplit baseline. | VERIFIED | Preflight calculates checked `width*2`, filtered bytes, RGBA image bytes, and work; `_png_grayscale_alpha_decode_budget` additionally reserves image plus two source rows before the image allocation. `PngDecoder::decode` constructs `DecodeResult` only after the inflater and IDAT/IEND finish successfully. Generated hostile cases use `unwrap_err()` before any image access and compare category/code/context to the unsplit error. Independent cardinality check found exactly one baseline plus all offsets: valid `gray-alpha-filters` 36 records (offsets 1..35), malformed `gray-alpha-malformed` 2 (offset 1), and limit-sensitive `gray-alpha-limit` 36 (offsets 1..35). All 11 type-4 groups had complete expected record sets and one baseline. |
| 4 | Fixture corpus/table/manifest are independently generated and validated on wasm, wasm-gc, js, and native. | VERIFIED | `Generate-PngDecodeVectors.ps1` has a PowerShell-only type-4 oracle that reconstructs source scanlines with stride `width*2`, bpp=2 predictor state, and explicit RGBA expansion. `-Check` independently verified corpus SHA-256 manifest record and byte-identical generated table, reporting 527 vectors. The public PNG test passed 28 tests on each of wasm, wasm-gc, js, and native. |

**Score:** 4/4 truths verified (0 present-but-behavior-unverified).

## Required Artifacts and Links

| Artifact / link | Status | Verification evidence |
| --- | --- | --- |
| `modules/mb-image/png/structural.mbt` | VERIFIED | Substantive IHDR/type-4 validation, source/output channel selection, checked budgets, and transport wiring. |
| `modules/mb-image/png/raster_decode.mbt` | VERIFIED | Substantive pair reconstruction and grayscale-alpha writer; `_png_write_raster` routes type 4 through bpp 2. |
| `modules/mb-image/png/deflate_inflate.mbt` | VERIFIED | Live IDAT path shares `PngPackedRows::reconstruct` with bpp `transport.source_channels`, then the same grayscale-alpha writer. |
| `scripts/fixtures/Generate-PngDecodeVectors.ps1` → `fixtures/png/decode-cases.json` → generated MoonBit table | VERIFIED | Generator validates oracle output, content digest, and generated file freshness; generated test consumes the table through `_generated_png_decode_cases()`. |
| Generated comparison groups → `PngDecoder` | VERIFIED | `png_test_decode_vector` invokes the public decoder per vector; accepted splits compare descriptor/pixels to baseline, hostile splits compare exact category/code/context to baseline. |

## Data-Flow Trace

| Flow | Status | Evidence |
| --- | --- | --- |
| IHDR type/depth → `PngStreamTransport` → descriptor/budget | FLOWING | Type 4 becomes `source_channels: 2UL`, `channels: 4UL`; transport enters the dedicated type-4 budget path before image allocation. |
| IDAT bytes → bpp-2 source rows → RGBA image | FLOWING | The live inflater reconstructs each encoded pair and writes `gray, gray, gray, alpha`; it does not route native alpha through `PngTransparency`. |
| Corpus JSON → independent PowerShell oracle → generated table → four-target public test | FLOWING | `-Check` passed and the public test enumerates all generated cases. |

## Behavioral and Integrity Checks

| Check | Result |
| --- | --- |
| `pwsh -NoProfile -File ./scripts/fixtures/Generate-PngDecodeVectors.ps1 -Check` | PASS — 527 executable vectors; manifest digest and generated table current. |
| `moon -C modules/mb-image test png --target all --frozen` | PASS — 28/28 on wasm, wasm-gc, js, and native. |
| `pwsh -NoProfile -File ./scripts/quality/Invoke-MoonQuality.ps1 -Lane Png` | PASS — policy, negatives, structural/decode generators, all-target tests, and lane isolation passed. |
| Independent type-4 corpus/generated-table cardinality script | PASS — all 11 groups complete; all valid/malformed/limit boundary offsets present with exactly one baseline. |
| `git diff --check 6154f21^ 289a4e6` and debt-marker scan of task files | PASS — no whitespace errors or `TBD`/`FIXME`/`XXX` markers. |

`moon -C modules/mb-image check --target all --deny-warn --frozen` still fails on 26 existing unused-field diagnostics. `git blame` traces the generated-vector diagnostics to `d84d0418` and the two `PngTransport` fields to `eeeb47b8`, both preceding this task; the task commits did not modify those lines. This is an existing repository quality baseline issue, not a failure of the scoped PNG type-4 goal. The scoped PNG quality lane passes.

## Requirements Coverage

| Requirement | Status | Evidence |
| --- | --- | --- |
| `PNGX-01` — decode palette, grayscale, transparency, and 16-bit PNG profiles with explicit image-model mapping | SATISFIED for this bounded grayscale-alpha slice | Type-4/depth-8 now maps explicitly to straight RGBA8, rejects illegal native/transparency combinations, and has portable corpus evidence. The wider PNGX-01 program remains intentionally broader than this quick task. |

## Anti-Patterns Found

None in the task-modified implementation, test, fixture, generator, or generated-table files.

## Conclusion

The scoped quick-task goal is achieved. The core decoder, its eager helper, resource checks, independent corpus generation, manifest guard, exhaustive type-4 split comparisons, typed no-result failure assertions, and four portable targets are all connected and exercised.

---

_Verified: 2026-07-20T21:11:06Z_
_Verifier: gsd-verifier_
