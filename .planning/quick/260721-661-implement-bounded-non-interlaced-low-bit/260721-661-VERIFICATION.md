---
phase: quick-260721-661
verified: 2026-07-20T20:41:14Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Quick 260721-661: Low-Bit Indexed PNG Decode Verification Report

**Goal:** Bounded non-interlaced PNG type-3 indexed decode at depths 1/2/4 (retaining 8), with valid PLTE and optional tRNS producing RGB8/RGBA8; packed-byte filtering, MSB-first width-limited expansion, limits, and independently generated four-target evidence.

**Verified:** 2026-07-20T20:41:14Z
**Status:** passed
**Mode:** Initial verification; no previous `VERIFICATION.md` existed.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Valid type-3 PNGs at depths 1/2/4/8 decode through `PngDecoder` as RGB8 or indexed-tRNS RGBA8. | VERIFIED | `structural.mbt` accepts exactly 1/2/4/8 for colour type 3; stream transport carries depth, palette, entry count, and transparency to `PngDecoder`; the generated public test executes depth-1/2/4 RGB fixtures plus a depth-2 tRNS RGBA fixture through the actual decoder. `moon -C modules/mb-image test png --target all --frozen` passed 26/26 on wasm, wasm-gc, js, and native. |
| 2 | Indexed rows use checked packed stride, bpp=1 packed-byte filtering, and MSB-first expansion through exactly `width` samples. | VERIFIED | `_png_grayscale_row_bytes` uses checked `width * bit_depth`; both `_png_inflate_zlib_to_raster` and `_png_write_indexed_raster` reconstruct `row_bytes` into `PngPackedRows`, whose left predictor is one byte. `_png_write_packed_indexed_row` iterates `x < width` and computes MSB-first sample offsets, excluding padding. Fixtures use widths 9/5/3 and all filters. |
| 3 | PLTE, palette index, and tRNS rules reject malformed inputs before an image can be returned; valid omitted tRNS entries are opaque. | VERIFIED | Stream transport requires PLTE before IDAT, enforces 1..`2^depth` entries, checks tRNS order/length, and `_png_write_indexed_pixel` rejects `entry >= palette_entries` and defaults absent alpha entries to `0xff`. Generated cases cover bad depth, oversized PLTE, missing/duplicate/post-IDAT/CRC-invalid PLTE, out-of-range index, and tRNS failures; each is asserted as an `Err` by the public decoder test. |
| 4 | Resource accounting reserves exposed image storage plus exactly two packed rows, with checked filtered/work bounds; failures do not expose a result image. | VERIFIED | `_png_indexed_decode_budget` adds image bytes + `2 * row_bytes`, limits checked filtered output/work, and creates a three-allocation child budget. White-box test covers exact 139-byte allowance and 138-byte failure for width 9/depth 1. Decoder only constructs `DecodeResult` after successful inflate, so all malformed/filter/index paths return `Err` rather than an image. |
| 5 | Independently reconstructed fixtures, generated table, manifest digest, and all targets agree. | VERIFIED | PowerShell `Assert-Oracle` independently decompresses, reconstructs packed bytes at bpp 1, expands actual-width MSB-first indexes, validates PLTE/tRNS, and checks expected pixels. `-Check` verified the generated table and manifest record for 413 executable cases; all targets passed the generated decoder table. |

**Score:** 5/5 truths verified (0 present-but-behavior-unverified).

## Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/structural.mbt` | Indexed IHDR, PLTE, transport, and bounded-budget rules | VERIFIED | Substantive validation and checked arithmetic; used by the live `PngDecoder` stream preflight. |
| `modules/mb-image/png/raster_decode.mbt` | Packed indexed reconstruction and palette emission | VERIFIED | `PngPackedRows`, indexed raster helper, MSB-first writer, and index/tRNS checks are substantive. The live inflater calls the shared writer. |
| `scripts/fixtures/Generate-PngDecodeVectors.ps1` | Independent PNG corpus oracle and generated-table/manifest verification | VERIFIED | Implements separate .NET `ZLibStream` oracle and checks generated file plus SHA-256 manifest record. `-Check` exits 0. |
| `fixtures/png/decode-cases.json` | Low-bit accepted and hostile corpus | VERIFIED | Contains depth-1/2/4 indexed accepted cases at widths 9/5/3, partial indexed tRNS, and depth/PLTE/index failures. |
| `modules/mb-image/png/generated_decode_vectors_test.mbt` | Generated execution table | VERIFIED | Regenerated from corpus; public test iterates every entry and compares every output channel or expected error context. |

## Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- |
| IHDR / PLTE preflight | `PngStreamTransport` / `PngDecoder` | Stored bit depth, palette, entry count, transparency, and child budget | WIRED | `_png_read_stream_transport` invokes indexed budget with `ihdr[8]`, enforces PLTE cardinality, and returns these fields; `png.mbt` passes them to the live inflater. |
| Live DEFLATE and eager helper | Shared packed rows / palette writer | `PngPackedRows::reconstruct` then `_png_write_packed_indexed_row` | WIRED | `_png_inflate_zlib_to_raster` is the production call path. `_png_write_indexed_raster` uses the same private writer and is exercised by raster white-box tests. |
| Corpus | generated MoonBit table and manifest | `Generate-PngDecodeVectors.ps1` | WIRED | Script requires all new case IDs, runs the independent oracle, produces table text, and compares corpus SHA-256 with `png-decode-vectors` in the manifest. |

## Data-Flow Trace

| Artifact | Data | Source | Produces real data | Status |
| --- | --- | --- | --- | --- |
| Live indexed decoder | Reconstructed packed row → palette pixels | CRC-authenticated IDAT bytes through `PngIdatSource` and DEFLATE | Yes — decoded IDAT bytes flow into the row state, then lookup writes image pixels | FLOWING |
| Generated vector table | PNG bytes / expected pixels | JSON corpus, independently checked by PowerShell | Yes — generator check proves table text and digest match corpus | FLOWING |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Independent corpus oracle, generated table, and manifest integrity | `pwsh -NoProfile -File ./scripts/fixtures/Generate-PngDecodeVectors.ps1 -Check` | `PNG decode vector generation/check passed (413 executable cases).` | PASS |
| Full public PNG decoder behavior on all targets | `moon -C modules/mb-image test png --target all --frozen` | 26/26 passed on wasm, wasm-gc, js, native | PASS |
| PNG scoped quality/inventory/generator/test lane | `pwsh -NoProfile -File ./scripts/quality/Invoke-MoonQuality.ps1 -Lane Png` | PNG quality lane and isolation proof passed | PASS |
| Workspace deny-warning check | `moon -C modules/mb-image check --target all --deny-warn --frozen` | Exit 1: 26 unused-field warnings | NON-BLOCKING PRE-EXISTING |

The deny-warning failure is not attributed to this quick task: `git blame` places all 24 `generated_vectors.mbt` warnings in pre-task commits `d84d0418`/`99afece2`, and the two `PngTransport.idat`/`consumed` warnings in `eeeb47b8`. The task commit added indexed transport fields but did not introduce those warnings. It is a repository-quality follow-up, not evidence that this decoder goal failed.

## Requirements Coverage

| Requirement | Source Plan | Status | Evidence |
| --- | --- | --- | --- |
| PNGX-01 — strict eager RGB/RGBA PNG interchange | `260721-661-PLAN.md` | SATISFIED | The live decoder emits RGB8/RGBA8 for bounded non-interlaced indexed inputs, and the independent generated suite verifies valid and hostile cases across four targets. |

## Anti-Patterns Found

No task-introduced `TBD`, `FIXME`, `XXX`, placeholder, empty handler, or hardcoded-empty-data markers were found in the modified implementation, tests, generator, corpus, or generated table. `git diff --check 8dcd265..HEAD` also returned clean.

## Disconfirmation Pass

- **Partial-requirement check:** Low-bit filtering could have incorrectly used palette-pixel bpp rather than packed-byte bpp. Both runtime paths reconstruct `PngPackedRows` by byte and the 9/5/3-width all-filter fixtures passed.
- **Misleading-test check:** Generated expected pixels are not merely copied into the table: the PowerShell oracle independently decompresses and reconstructs source rows before comparing its result to corpus expectations; `-Check` passed.
- **Uncovered-error-path check:** The core invalid-depth, PLTE-cardinality, palette-index, tRNS-order/length/CRC, filter, and compressed-data cases are covered. No unaddressed failure path was found within this quick task’s bounded scope.

## Gaps Summary

No task-scoped gaps found. The phase goal is achieved.

---

_Verified: 2026-07-20T20:41:14Z_
_Verifier: gsd-verifier_
