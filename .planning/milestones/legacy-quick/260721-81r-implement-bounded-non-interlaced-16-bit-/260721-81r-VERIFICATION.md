---
phase: quick-260721-81r
verified: 2026-07-20T22:12:51Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Quick Task 260721-81r Verification Report

**Goal:** Decode bounded, non-interlaced 16-bit PNG type 4/type 6 into straight RGBA8 by using every raw big-endian component's high byte.

**Status:** passed

## Goal Achievement

| # | Observable truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Type-4 depth-16 data decodes as straight RGBA8, expanding grayscale high byte to RGB and preserving native alpha high byte. | VERIFIED | `structural.mbt` accepts depth 16 for type 4 and gives four output channels. `raster_decode.mbt::_png_write_16bit_grayscale_alpha_row` reads offsets 0 and 2 from each reconstructed four-byte sample and writes `(gray, gray, gray, alpha)`. The generator's type-4 accepted vector and all generated boundary variants passed on four targets. |
| 2 | Type-6 depth-16 data decodes as straight RGBA8 by selecting each component's high byte, without conversion or premultiplication. | VERIFIED | `_png_write_16bit_rgba_row` reads offsets `0,2,4,6` from each reconstructed eight-byte source pixel and writes them to channels `0..3`. The type-6 accepted vector and all generated boundary variants passed on four targets. |
| 3 | Filtering and resource accounting use encoded source bpp 4/8 in both eager and live paths while output is RGBA8. | VERIFIED | `_png_source_bytes_per_pixel` derives byte-pair source widths; `_png_16bit_decode_budget` reserves two encoded source rows plus four-channel output. Both `_png_write_raster` and `_png_inflate_zlib_to_raster` call `rows.reconstruct(... transport.source_bytes_per_pixel ...)`. White-box coverage asserts bpp 4 for type 4 and 8 for type 6. |
| 4 | Native-alpha `tRNS`, malformed data, and resource-limit inputs fail without exposing an image. | VERIFIED | Structural parsing rejects type 4/6 `tRNS` through `png-semantic-chunk`; 19 native-alpha corpus cases cover normal/duplicate/post-IDAT/CRC `tRNS`, invalid depth/filter/deflate, and image/output/work limits. The public runner uses `unwrap_err()` for every hostile record before any image access and compares error category/code/context to the unsplit baseline. |
| 5 | The independent corpus/oracle/manifest/generated vectors prove unsplit and every nonempty two-IDAT split across all portable targets. | VERIFIED | `Generate-PngDecodeVectors.ps1 -Check` independently inflates and reconstructs corpus rows, validates the corpus SHA-256 manifest entry, and reported **1,653 executable cases**. It creates one unsplit and every split offset `1..zlibLength-1`; the native-alpha subset is 19 corpus cases / 790 executable variants. The public test compares pixels and boundary baselines. |

**Score:** 5/5 truths verified (0 present-but-behavior-unverified)

## Critical Regression Check: Existing 8-bit Type-6 Contract

The prior 502-byte expectation is not retained.

| Check | Result |
| --- | --- |
| Corpus record `dynamic-rgba-filters-semantic-idat-split` | `20 × 5 × 4 = 400` expected bytes (`pixels_hex` is 800 hex characters) |
| Generated table record | 400 `\\xNN` expected-byte literals |
| Public contract | `png_test_decode_vector` verifies dimensions/channels and iterates every `width × height × channels` byte against `item.pixels[index]` |
| Stale expectation scan | No `502` marker found in corpus, generator, or generated table |

## Required Artifacts

| Artifact | Status | Verification |
| --- | --- | --- |
| `modules/mb-image/png/structural.mbt` | VERIFIED | Substantive legality, source-byte, and checked-resource implementation; wired into stream transport and descriptor/allocation construction. |
| `modules/mb-image/png/raster_decode.mbt` | VERIFIED | Explicit 16-bit native-alpha writers; selected by eager raster decoding. |
| `modules/mb-image/png/deflate_inflate.mbt` | VERIFIED | Live IDAT path uses the same source-row width, reconstruction bpp, and native-alpha writers. |
| `scripts/fixtures/Generate-PngDecodeVectors.ps1` | VERIFIED | Independent Zlib/reconstruction oracle, required-ID guard, split generation, generated-table freshness, and manifest-digest validation passed. |
| `fixtures/png/decode-cases.json` | VERIFIED | Contains both accepted type-4/type-6 depth-16 profiles plus 17 hostile native-alpha cases, all assigned comparison groups. |
| `modules/mb-image/png/generated_decode_vectors_test.mbt` | VERIFIED | Generated portable table is consumed by the public PngDecoder test and contains the corrected 400-byte existing type-6 expectation. |

## Key Link Verification

| From | To | Status | Evidence |
| --- | --- | --- | --- |
| `structural.mbt` | `png.mbt` | WIRED | `PngStreamTransport` carries `bit_depth`, source channels/bytes-per-pixel, four output channels, and budget; `PngDecoder::decode` turns it into `PngTransport`, descriptor, packed rows, and image allocation. |
| `deflate_inflate.mbt` | `raster_decode.mbt` | WIRED | Live and eager functions dispatch to the same two native-alpha writers after encoded-byte reconstruction. |
| corpus/oracle | generated public test | WIRED | Generator check verifies exact generated output; `png_test.mbt` iterates `_generated_png_decode_cases()` and compares successful pixels or hostile errors/baselines. |

## Behavioral Spot-Checks

| Command | Result |
| --- | --- |
| `pwsh -NoProfile -File ./scripts/fixtures/Generate-PngDecodeVectors.ps1 -Check` | PASS — `PNG decode vector generation/check passed (1653 executable cases).` |
| `moon -C modules/mb-image test png --target all --frozen` | PASS — 32/32 tests on wasm, wasm-gc, js, and native. |

## Anti-Patterns

No `TBD`, `FIXME`, `XXX`, `TODO`, placeholder, empty-result, or console-only implementation markers were found in the task's implementation, generator, corpus, or generated-test artifacts.

## Requirements Coverage

| Requirement | Status | Evidence |
| --- | --- | --- |
| PNGX-01 (native-alpha 16-bit slice) | SATISFIED | This task's type-4/type-6 depth-16 mapping, semantic rejection, bounds, and reproducible evidence are implemented and tested. This verdict does not claim unrelated PNGX-01 work outside the quick task. |

_Verified independently; SUMMARY.md claims were not used as evidence._
