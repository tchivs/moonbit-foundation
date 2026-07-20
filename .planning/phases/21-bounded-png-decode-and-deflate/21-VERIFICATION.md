---
phase: 21-bounded-png-decode-and-deflate
verified: 2026-07-20T17:41:56Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
behavior_unverified_items: []
human_verification: []
---

# Phase 21: Bounded PNG Decode and DEFLATE Verification Report

**Phase Goal:** Library users can decode the supported non-interlaced PNG RGB/RGBA subset through bounded, deterministic pure-MoonBit decompression and scanline reconstruction.

**Verified:** 2026-07-20T17:41:56Z

**Status:** passed

**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A library user can decode non-interlaced RGB8/RGBA8 PNG images with all five filters into the portable image contracts. | ✓ VERIFIED | `png_test.mbt:292-327` invokes the public `PngDecoder`, compares every output byte, and passes for the fixed RGB 2×5 vector and dynamic RGBA 20×5 vector. Corpus rows contain filter tags 0–4 and nonzero predictor data; `raster_decode.mbt:119-141` applies all five inverse filters directly to `MutImageView`. Four-target command passed. |
| 2 | Legal stored, fixed-Huffman, and dynamic-Huffman zlib streams decode across arbitrary IDAT boundaries. | ✓ VERIFIED | Stored public decode passes in `png_test.mbt:108-141`. The fixed RGB corpus splits each of its 38 zlib bytes into its own IDAT; the dynamic RGBA corpus crosses a 2/277-byte boundary. `PngIdatSource::next_byte` (`structural.mbt:671-700`) authenticates and continues IDAT chunks byte by byte. The active inflater consumes that source (`deflate_inflate.mbt:95-187`). |
| 3 | Malformed zlib/DEFLATE, output-limit, PNG-tail, and reader failures are typed and no partial result is visible before every terminal check succeeds. | ✓ VERIFIED | The public generated corpus now executes an incomplete dynamic tree (`deflate-incomplete-tree`), a fixed match before history (`deflate-distance`), filtered-output expansion (`Resource/BudgetExceeded/output-bytes`), and bad Adler after a complete scanline; each is asserted through `Result::unwrap_err`, so no `DecodeResult` is exposed. |
| 4 | Independent valid and hostile fixtures execute on js, wasm, wasm-gc, and native. | ✓ VERIFIED | `Generate-PngDecodeVectors.ps1` independently decompresses accepted zlib rows with .NET `ZLibStream`, verifies fixed/dynamic block bits, frames PNG/CRC, and freshness-checks the generated test table. The public test executes its nine generated valid/hostile rows; `moon -C modules/mb-image test png --target all --frozen` passed 12/12 on all four targets. |

**Score:** 4/4 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/structural.mbt` | Forward-only logical IDAT transport with structural checks. | ✓ VERIFIED | Active `PngIdatSource` retains only reader, 1-byte scratch, counters and CRC state; it verifies each completed IDAT before advancing. |
| `modules/mb-image/png/deflate_bits.mbt`, `deflate_huffman.mbt`, `deflate_inflate.mbt` | Private, bounded pure-MoonBit zlib/DEFLATE. | ✓ VERIFIED | LSB bit source, canonical tree validation including completeness (`deflate_huffman.mbt:19-54`), fixed/dynamic trees, 32 KiB overlap-safe history and sink-driven emission are all private and wired. |
| `modules/mb-image/png/raster_decode.mbt`, `png.mbt` | Raster construction and atomic public eager result. | ✓ VERIFIED | The decoder allocates local `OwnedImage`, inflates inside `with_mut_view`, completes transport terminal checks, then creates `DecodeResult`; only `PngDecoder`/its codec impl are public. |
| `fixtures/png/decode-cases.json`, `scripts/fixtures/Generate-PngDecodeVectors.ps1`, `generated_decode_vectors_test.mbt` | Provenance-tagged independent executable corpus. | ✓ VERIFIED | Literal zlib, split schedule, expected pixels/errors, deterministic framing/CRC, independent oracle and generated public test rows agree; generator `-Check` passed. |
| `policy/foundation.json`, `scripts/quality/Assert-Policy.ps1`, `scripts/quality/Invoke-MoonQuality.ps1` | PNG policy inventories and isolated quality lane. | ✓ VERIFIED | The PNG lane passed policy/interface/negative-inventory checks, both vector freshness checks, and four-target package tests. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `PngDecoder::decode` | `PngIdatSource` | `_png_read_stream_transport` | WIRED | `png.mbt:53-56` starts the stream transport; it constructs the private source at `structural.mbt:619-667`. |
| `PngIdatSource` | private inflater | `PngDeflateBits` | WIRED | `deflate_bits.mbt:5-25` reads directly from the source; inflater receives the source at `deflate_inflate.mbt:95-105`. |
| private inflater | image raster | sink closure over `MutImageView` | WIRED | Every emitted byte is filter-reconstructed and stored at `deflate_inflate.mbt:116-141`; no filtered-output array exists in the active path. |
| raster/terminal checks | `DecodeResult` | `with_mut_view` result then constructor | WIRED | `source.finish()` performs PNG tail/IEND/EOF checks before `png.mbt:69-77` constructs the result. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| active decoder pipeline | emitted DEFLATE byte | `PngIdatSource::next_byte` → bit reader → literal/match decode | Yes — public vectors supply independently checked fixed/dynamic zlib bytes and tests assert each decoded pixel. | ✓ FLOWING |
| raster sink | `row`, `column`, filter and pixel bytes | emitted byte plus already-written neighboring pixels | Yes — output is read from `DecodeResult.image().view()` and compared byte-for-byte. | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Independent corpus is fresh and accepted streams have a non-production oracle. | `pwsh -NoProfile -File scripts/fixtures/Generate-PngDecodeVectors.ps1 -Check` | `PNG decode vector generation/check passed (6 executable cases).` | ✓ PASS |
| Public decode works across all portable targets. | `moon -C modules/mb-image test png --target all --frozen` | 12/12 passed on wasm, wasm-gc, js, native. | ✓ PASS |
| PNG policy and lane wiring work. | `pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png` | Passed policy/negative checks, vector checks and all four targets. | ✓ PASS |

### Probe Execution

Step 7c: SKIPPED — this phase declares no `probe-*.sh` probe.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PNG-04 | 21-01 | Decode supported RGB/RGBA with all five PNG filters. | ✓ SATISFIED | Fixed RGB and dynamic RGBA public vectors exercise filter rows 0–4 and exact output pixels on all four targets. |
| PNG-05 | 21-01 | Decode stored/fixed/dynamic streams across IDAT boundaries; reject malformed input deterministically. | ✓ SATISFIED | Nine generated public rows cover stored/fixed/dynamic streams, IDAT schedules, malformed dynamic trees, invalid distance, expansion, filter, truncation, header, and post-raster Adler failure on all four targets. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `modules/mb-image/png/structural.mbt` | 498 | Legacy `_png_read_transport` retains whole IDAT data but has no production caller. | ⚠️ Warning | The active decoder is not affected, but this stale private staging path is confusing and its fields produce compiler unused-field warnings. Remove it or clearly isolate it once no white-box helper needs `PngTransport`. |
| `modules/mb-image/png/raster_decode.mbt` | 69 | Legacy `_png_write_raster` accepts a full filtered array and is used only by white-box raster tests. | ⚠️ Warning | The public path uses the direct sink instead. Keep tests focused on active sink behavior or retire the old helper to avoid future accidental reuse. |
| `modules/mb-image/png/png_test.mbt` | 238 | Former Phase-20 generated structural matrix is now an uncalled function, not a `test`. | ⚠️ Warning | Vector freshness still runs, but those 89 legacy cases are not included in the current 12-test four-target execution. This weakens regression evidence for structural guarantees retained by Phase 21. |

No `TBD`, `FIXME`, or `XXX` markers were found in phase-owned production or test files.

## Gaps Summary

No implementation blocker remains. The earlier review findings are closed by the active streaming implementation and executable hostile vectors; generator freshness, four-target tests, and the PNG quality lane all pass.

---

_Verified: 2026-07-20T17:41:56Z_

_Verifier: the agent (gsd-verifier)_
