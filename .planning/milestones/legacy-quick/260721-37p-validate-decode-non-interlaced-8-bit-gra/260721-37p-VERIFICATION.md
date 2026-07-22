---
quick_id: 260721-37p
verified: 2026-07-21T00:00:00Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
commit_verified: 51dc49e593054ea400cb927f13e6605a74ac817e
---

# Quick Task 260721-37p: Grayscale PNG Decode Verification Report

**Objective:** Extend the strict eager PNG decoder to accept the bounded colour-type-0 subset: opaque, non-interlaced, 8-bit grayscale PNG expands to RGB8 (`g,g,g`) without changing RGB/RGBA output, untagged colour semantics, semantic-chunk rejections, or resource safety.

**Verified:** 2026-07-21 UTC
**Status:** passed
**Mode:** initial verification (no prior `VERIFICATION.md`)

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Opaque non-interlaced 8-bit type-0 PNG decodes through `PngDecoder` as RGB8, expanding every sample to `g,g,g`. | VERIFIED | `structural.mbt` maps type 0 to one source channel and three output channels; `png.mbt` carries both values into the descriptor and streaming inflater. Both raster paths fan each reconstructed grayscale value into channels 0–2. The public generated-vector test decoded 22 grayscale PNGs on wasm, wasm-gc, js, and native and compared every expected byte. |
| 2 | Grayscale filters 0–4 work across every arbitrary contiguous two-IDAT split of the zlib payload. | VERIFIED | The canonical 23-byte grayscale zlib stream expands to 22 records (`split-1` through `split-22`), each with exactly two nonempty IDAT chunks. The generator check passed and the public `PngDecoder` test passed on all four targets; the white-box raster test separately exercises filter tags 0–4 with nonzero neighbour values. |
| 3 | Existing RGB8 and straight-RGBA8 bytes remain intact; untagged inputs retain encoded-sRGB / builtin-sRGB metadata. | VERIFIED | The public vector runner still decodes and byte-compares the existing RGB and RGBA records. Only the type-0 channel mapping changed. `_png_empty_metadata` still constructs `Srgb`, `EncodedSrgb`, `builtin_srgb()`, and no alpha for three-channel images; the descriptor selects `rgb8()` for type 0/RGB and `rgba8()` only for type 6. |
| 4 | `gAMA`, `cHRM`, `iCCP`, `sRGB`, and `tRNS` remain typed semantic-chunk rejections; grayscale charging uses RGB8 output/allocation plus grayscale filtered work. | VERIFIED | All structural reader paths return `png-semantic-chunk` for known semantic chunks; the generated structural corpus preserves cases for the named chunk families, and its 89 P+W checks pass. `structural_wbtest.mbt` verifies the type-0 exact limits (30 output/allocation bytes, 45 work) and immediate-below failures; preflight separately computes `width * source_channels`, RGB8 `image_bytes`, then combined work. |
| 5 | Fixture generation and the PNG suite are mutually consistent on all supported targets. | VERIFIED | Both generator `-Check` commands passed (31 decode records; 89 structural records), as did `moon -C modules/mb-image test png --target all --frozen` (20/20 each on wasm, wasm-gc, js, native). The scoped `Png` quality lane independently passed. |

**Score:** 5/5 truths verified (0 present-but-behavior-unverified).

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/structural.mbt` | Type-0 acceptance, source/output accounting, semantic policy | VERIFIED | Substantive preflight/streaming transport code; connected to `PngDecoder` and both structural test paths. |
| `modules/mb-image/png/deflate_inflate.mbt` | Streaming grayscale filter reconstruction | VERIFIED | Uses source-channel neighbours, validates filter 0–4, and writes grayscale samples to three output channels. |
| `modules/mb-image/png/raster_decode.mbt` | Private raster analogue and public descriptor | VERIFIED | Uses the same source/output distinction; produces RGB8 + opaque encoded-sRGB/builtin-sRGB descriptor for three-channel output. |
| `modules/mb-image/png/png.mbt` | Public decoder wiring | VERIFIED | Propagates `source_channels` and `channels` from streaming transport to descriptor/inflater. |
| `modules/mb-image/png/png_test.mbt` | Public vector execution | VERIFIED | Its generated-vector test invokes `PngDecoder` and compares decoded bytes; it consumes the regenerated 22-case grayscale family plus existing RGB/RGBA records. |
| `fixtures/png/decode-cases.json` and `scripts/fixtures/Generate-PngDecodeVectors.ps1` | Canonical grayscale corpus and exhaustive split expansion | VERIFIED | Source declares the grayscale family; generator expands offsets 1 through zlib-length minus one and validates generated output plus the fixture digest. |
| Generated vectors and `fixtures/manifest.json` | Checked-in, authenticated evidence | VERIFIED | Both owning generators accept the files unchanged in `-Check` mode. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- |
| IHDR type 0 | source scanline / RGB8 descriptor allocation | `source_channels` vs `channels` | WIRED | Preflight, stream transport, descriptor, and both raster implementations agree on 1 source channel / 3 output channels. |
| Streaming IDAT reader | DEFLATE raster emitter | `PngIdatSource` → `_png_inflate_zlib_to_raster` | WIRED | The public decoder passes the forward-only source to the inflater; the emitter reconstructs filtered grayscale values before fanning out RGB bytes. |
| JSON corpus | generator | generated MoonBit table + manifest digest | WIRED | Decode and structural generator checks both passed; all four target test runs consume the generated tables. |

### Data-Flow Trace

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Streaming decoder | `stream.source_channels`, `stream.channels` | Validated IHDR byte 9 | Type 0 → 1/3; RGB → 3/3; RGBA → 4/4 | FLOWING |
| Streaming raster | reconstructed `value` | IDAT DEFLATE bytes and PNG inverse filters | Writes real decoded values to RGB channels | FLOWING |
| Public vector test | `item.bytes`, `item.pixels` | Regenerated fixture corpus | 22 grayscale boundary vectors plus existing cases | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Decode corpus generation and integrity | `pwsh -NoProfile -File ./scripts/fixtures/Generate-PngDecodeVectors.ps1 -Check` | 31 executable cases | PASS |
| Structural corpus generation and integrity | `pwsh -NoProfile -File ./scripts/fixtures/Generate-PngStructuralVectors.ps1 -Check` | 89 P+W cases | PASS |
| Public decoder/filter/boundary behavior on all targets | `moon -C modules/mb-image test png --target all --frozen` | 20/20 on wasm, wasm-gc, js, native | PASS |
| PNG-specific quality contract | `pwsh -NoProfile -File ./scripts/quality/Invoke-MoonQuality.ps1 -Lane Png` | All PNG stages and isolation proof passed | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PNGX-01 | `260721-37p-PLAN.md` | Decode palette, grayscale, transparency, and 16-bit PNG profiles with explicit image-model mapping. | PARTIAL — intentional scoped slice | This quick task proves the opaque 8-bit grayscale/RGB8 slice only. Palette, transparency mapping, and 16-bit profiles remain explicitly out of scope, so the SUMMARY claim that full PNGX-01 is complete is not accepted. This does not block the stated quick-task objective. |

### Quality and Scope Notes

- `moon -C modules/mb-image check --target all --deny-warn --frozen` fails because 26 pre-existing unused-field warnings are promoted to errors. The changed structural-vector record does not alter the warned struct definitions, and `PngTransport.idat` / `consumed` were already present before `51dc49e`.
- `pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required` fails before the lane begins: `quality.ps1` dot-sources `Invoke-MoonQuality.ps1`, whose mandatory top-level `Lane` parameter is invoked without a value. Neither quality script is part of `51dc49e`. The direct scoped PNG lane above is the relevant quality evidence and passes.
- Commit `51dc49e` contains only PNG decoder, fixtures, generators, and generated-vector files. Its path list contains no QOI, publication, or registry files. Existing dirty QOI worktree files were not changed by this verification.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| — | — | No TODO/FIXME/XXX, placeholder, empty implementation, or console-only implementation found in the commit's changed files. | — | None |

## Conclusion

The quick-task objective is achieved. The code, generated corpus, fixture manifests, public decoder test, white-box filter/budget tests, semantic-rejection policy, and scoped PNG quality lane all corroborate the bounded grayscale-to-RGB8 implementation. The broader `PNGX-01` requirement remains only partially complete by deliberate scope and should not be marked complete at milestone level.

---

_Verified: 2026-07-21 UTC_
_Verifier: gsd-verifier_
