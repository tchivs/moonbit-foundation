---
phase: quick-260721-7d5
verified: 2026-07-20T21:45:47Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Quick Task 260721-7d5 Verification Report

**Goal:** Bounded non-interlaced 16-bit grayscale (type 0) and truecolour (type 2) PNG decode to existing RGB8/RGBA8 images, using big-endian high-byte mapping and full-raw `tRNS` comparison.

**Verified:** 2026-07-20T21:45:47Z
**Status:** passed
**Re-verification:** No — initial verification; no previous verification report existed.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Type-0, depth-16 PNGs decode to RGB8/RGBA8 from each raw sample's big-endian high byte; a grayscale `tRNS` key is matched on both raw bytes. | ✓ VERIFIED | `structural.mbt` accepts type 0/depth 16 and retains `Grayscale16(high, low)`; `raster_decode.mbt` reads pairs at `x * 2`, replicates `high`, and sets alpha only for `high == key_high && low == key_low`. The public generated corpus includes accepted all-filter RGB8 and RGBA8 vectors, including equal-high/different-low samples. |
| 2 | Type-2, depth-16 PNGs decode to RGB8/RGBA8 from the high byte of each raw component; RGB `tRNS` matches all six raw bytes. | ✓ VERIFIED | Type 2/depth 16 is legal in `structural.mbt`; `_png_write_16bit_rgb_row` reads the six-byte raw triplet at `x * 6`, writes only component high bytes, and compares all six bytes before choosing alpha. Generated accepted and transparency vectors execute through public `PngDecoder`. |
| 3 | Type-0 and type-2 encoded source width, filtering, and reservations use bpp 2 and bpp 6 respectively in both eager and live paths. | ✓ VERIFIED | `_png_source_bytes_per_pixel` returns `source_channels * 2` at depth 16; `_png_16bit_decode_budget` reserves the expanded image plus two encoded source rows. `_png_write_raster` and `_png_inflate_zlib_to_raster` both call `rows.reconstruct(..., transport.source_bytes_per_pixel, ...)`, then select the corresponding 16-bit writer. |
| 4 | Exact-width `tRNS`, malformed/order/CRC/post-IDAT failures, limit failures, and no-image-on-error behavior are retained. | ✓ VERIFIED | Stream transport validates lengths before storing full raw keys; `PngIdatSource::finish` rejects post-IDAT `tRNS`. Generated vectors cover 16-bit bad length, duplicate, post-IDAT, CRC, malformed filter/zlib, invalid depths, and image/output/work limits. Their public test obtains `unwrap_err()` and compares category/code/context with each unsplit baseline, so no `DecodeResult`/image is available on error. |
| 5 | An independent oracle, manifest-bound generated table, and unsplit/two-IDAT boundary tests reproduce the contract on all four targets. | ✓ VERIFIED | `Generate-PngDecodeVectors.ps1` independently inflates with .NET `ZLibStream`, reconstructs 16-bit bytes with stride/bpp 2 or 6, checks raw-key transparency, validates the generated file and `png-decode-vectors` SHA-256. It generated 863 executable records. The public test compares every split record to its unsplit comparison-group baseline. |

**Score:** 5/5 truths verified (0 present-but-behavior-unverified).

## Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/structural.mbt` | 16-bit legality, raw `tRNS`, checked accounting | ✓ VERIFIED | Substantive type/depth gate, raw transparency variants, source-byte helper, and 16-bit budget are reached from live transport construction. |
| `modules/mb-image/png/raster_decode.mbt` | Eager 16-bit filtering and high-byte writers | ✓ VERIFIED | Eager 16-bit branch reconstructs bpp from transport and calls concrete grayscale/RGB writers. |
| `modules/mb-image/png/deflate_inflate.mbt` | Live IDAT 16-bit path | ✓ VERIFIED | Live scanline callback uses the same source-row calculation, `source_bytes_per_pixel`, packed rows, and concrete writers. |
| `scripts/fixtures/Generate-PngDecodeVectors.ps1` | Independent oracle and split-vector generation | ✓ VERIFIED | Does not import or invoke decoder helpers; uses independently reconstructed zlib scanlines and raw key comparisons. `-Check` passed. |
| `fixtures/png/decode-cases.json` | Legal and hostile corpus | ✓ VERIFIED | Schema `2.4.0` includes four accepted 16-bit type-0/type-2 families plus hostile/order/depth/filter/resource cases and comparison groups. |
| `modules/mb-image/png/generated_decode_vectors_test.mbt` | Portable public vectors | ✓ VERIFIED | Generated file is current according to generator `-Check` and is consumed by `png_test.mbt`'s public decoder test. |

## Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `structural.mbt` | `png.mbt` | `PngStreamTransport` carries source layout, depth, and transparency into image construction | ✓ WIRED | `png.mbt` copies `bit_depth`, `source_bytes_per_pixel`, and `transparency` into `PngTransport`, allocates packed rows for depth 16, then invokes the live inflater. |
| `deflate_inflate.mbt` | `raster_decode.mbt` | Shared encoded stride/bpp and high-byte mapping | ✓ WIRED | Live code and eager `_png_write_raster` both reconstruct rows using the same transport bpp and dispatch to `_png_write_16bit_grayscale_row`/`_png_write_16bit_rgb_row`. |
| corpus JSON | generated table/public test | Independent generator, manifest, and public vector execution | ✓ WIRED | Generator checks corpus SHA-256 manifest entry and generated source equality; `png_test.mbt` iterates `_generated_png_decode_cases()` through `PngDecoder`. |

## Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces real data | Status |
| --- | --- | --- | --- | --- |
| Live decoder | `PngStreamTransport.source` / packed rows | Authenticated IDAT chunks → DEFLATE bytes → filter reconstruction | Yes — reader-backed IDAT source is consumed bytewise and CRC-checked | ✓ FLOWING |
| Eager helper | `filtered` scanlines | Caller-supplied decompressed source | Yes — exact filtered-size gate then bytewise reconstruction | ✓ FLOWING |
| Generated public test | `PngDecodeVector` records | `decode-cases.json` → independent PowerShell oracle → generated table | Yes — generator `-Check` confirms table and manifest are current | ✓ FLOWING |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Independent corpus/oracle and manifest/table integrity | `pwsh -NoProfile -File ./scripts/fixtures/Generate-PngDecodeVectors.ps1 -Check` | `PNG decode vector generation/check passed (863 executable cases).` | ✓ PASS |
| Public decode, accepted/hostile split equivalence, all targets | `moon -C modules/mb-image test png --target all --frozen` | 30/30 passed on wasm, wasm-gc, js, and native | ✓ PASS |
| PNG quality lane | `pwsh -NoProfile -File ./scripts/quality/Invoke-MoonQuality.ps1 -Lane Png` | Completed with 26 existing warnings and 0 errors | ✓ PASS |
| Warning-denying static check | `moon -C modules/mb-image check --target all --deny-warn --frozen` | Fails solely on 26 pre-existing unused-field warnings in `generated_vectors.mbt` and `PngTransport.idat`/`consumed` | ℹ️ PRE-EXISTING |

The final static-check observation is not a phase gap: `git log -S` places `generated_vectors.mbt`'s warning-producing structs in `d84d041` (Phase 20), and `git blame` places `PngTransport.idat`/`consumed` in `eeeb47b8`, before this quick task. This task added `source_bytes_per_pixel`, not those fields.

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PNGX-01 | `260721-7d5-PLAN.md` | Explicit image-model mapping for PNG palette, grayscale, transparency, and 16-bit profiles | PARTIAL — intentional quick scope | This task verifies the bounded non-interlaced 16-bit type-0/type-2 slice. Type 4/6 16-bit, Adam7, and colour management are explicitly excluded and remain rejected; they are not unfulfilled deliverables of this quick task. |

## Probe Execution

Step 7c: SKIPPED. No phase-declared probe and no `scripts/**/tests/probe-*.sh` file was present.

## Anti-Patterns Found

No task-introduced `TBD`, `FIXME`, `XXX`, placeholder output, empty handler, or hardcoded-empty production-data pattern was found in the changed implementation, tests, corpus, generator, or manifest. The generated file has its expected generation marker, not a stub marker.

## Disconfirmation Pass

- **Potential partial coverage checked:** hostile `tRNS` categories are distributed across type 0 and type 2 rather than duplicated for every colour type. The parser's per-type length branches and shared CRC/order/post-IDAT enforcement were inspected; the full categories are exercised by the 16-bit generated cases, so this is not an observable gap.
- **Potential misleading test checked:** vectors are not only hardcoded expected pixels. The PowerShell generator independently decompresses, filters at encoded bpp 2/6, verifies the JSON pixels, then checks the emitted MoonBit table and manifest digest.
- **Potential untested error path checked:** the public generated test uses `unwrap_err()` for every hostile vector and compares category, code, context, and unsplit baseline equivalence; therefore it cannot observe a successful image on those error paths.

## Gaps Summary

None. All scoped must-haves are implemented, wired to real IDAT/corpus data, and behaviorally exercised on all four supported targets.

---

_Verified: 2026-07-20T21:45:47Z_
_Verifier: gsd-verifier_
