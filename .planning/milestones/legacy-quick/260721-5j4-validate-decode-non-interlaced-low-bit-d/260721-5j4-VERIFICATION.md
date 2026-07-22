---
quick_id: 260721-5j4
verified: 2026-07-20T20:23:34Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Quick Task 260721-5j4 Verification Report

**Goal:** Validate decoding of non-interlaced low-bit-depth grayscale PNG.

**Commits audited:** `4716bd8`, `e316342`, `4219f15`, `a2a22e1`, and `14cff62`.

**Status:** `passed`

## Goal Achievement

| # | Observable truth | Status | Evidence |
|---|---|---|---|
| 1 | Type-0 PNG at depths 1, 2, 4, and 8 decodes as RGB8 when opaque and straight RGBA8 with valid grayscale `tRNS`. | VERIFIED | `PngStreamTransport.bit_depth` carries IHDR depth to `PngDecoder`; descriptor channels follow validated transparency. The generated public decoder test asserts every pixel and channel for low-bit opaque and `tRNS` records. |
| 2 | Packed rows use `ceil(width * depth / 8)`, bpp 1 reconstruction, MSB-first expansion, and ignore padding. | VERIFIED | `_png_grayscale_row_bytes`, `PngPackedRows::reconstruct`, and `_png_write_packed_grayscale_row` reconstruct private packed bytes before expanding only `x < width`. 9/5/3-pixel depth-1/2/4 families exercise filters 0--4 and cross byte boundaries. |
| 3 | Low-bit samples scale fully and `tRNS` compares the raw sample, with malformed keys rejected before an image is exposed. | VERIFIED | Depth scaling is 255/85/17; the raster writer compares `raw` with the validated `PngTransparency::Grayscale` key. Transport requires a two-byte key, zero high byte, and a depth mask. Generated accepted RGBA cases plus hostile high-byte/mask cases execute through `PngDecoder`. |
| 4 | Image storage and exactly two packed source rows are budgeted before decode, without changing unrelated opaque paths. | VERIFIED | `_png_grayscale_decode_budget` reserves RGB/RGBA output plus two checked packed rows with three allocations; `png.mbt` creates those rows before `OwnedImage`. Existing RGB/RGBA/indexed routes remain distinct and passed all-target regression tests. |
| 5 | Fixtures independently prove filters, splits, exact pixels, bounds, manifest identity, and portable behavior. | VERIFIED | The PowerShell oracle independently inflates, reconstructs bpp-1 packed rows, unpacks/scales raw samples, validates `tRNS`, and emits 161 low-bit records (322 total executable records). `-Check`, generated MoonBit vectors, four targets, and the PNG lane all pass. |

**Score:** 5/5 truths verified.

## Required Artifacts

| Artifact | L1 exists | L2 substantive | L3 wired | Data flow / status |
|---|---|---|---|---|
| `modules/mb-image/png/structural.mbt` | Yes | Checked depth, row sizing, budget, and `tRNS` validation | Called from stream transport | IHDR facts flow into `PngStreamTransport`; VERIFIED |
| `modules/mb-image/png/deflate_inflate.mbt` | Yes | Handles packed row bytes and row completion | Live `PngDecoder` inflater | Writes reconstructed rows to packed grayscale emission; VERIFIED |
| `modules/mb-image/png/raster_decode.mbt` | Yes | Packed-row state, five filters, MSB unpack, scale, alpha | Used by live and private raster routes | Encoded bytes flow into exact image pixels; VERIFIED |
| `fixtures/png/decode-cases.json` | Yes | Low-bit valid/error matrix and split declarations | Generator input | SHA-256 checked and rendered to generated table; VERIFIED |
| `scripts/fixtures/Generate-PngDecodeVectors.ps1` | Yes | Independent zlib/packed-row oracle | Invoked by `-Check` and quality lane | Produces and validates generated conformance data; VERIFIED |
| `modules/mb-image/png/generated_decode_vectors_test.mbt` | Yes | 322 concrete decoder vectors | Consumed by public PNG test | Pixel/channel/error assertions reach `PngDecoder`; VERIFIED |

## Key Links and Data Flow

| Link | Status | Evidence |
|---|---|---|
| IHDR depth -> stream transport -> packed-row allocation and output descriptor | WIRED | `structural.mbt` stores `bit_depth`; `png.mbt` derives `row_bytes` and builds packed rows before constructing the image. |
| Packed scanlines -> bpp-1 filters -> actual-width RGB/RGBA pixels | WIRED | `deflate_inflate.mbt` feeds each packed byte to `PngPackedRows`; on complete rows it calls `_png_write_packed_grayscale_row`. |
| JSON corpus -> independent oracle -> generated table -> portable decoder test | WIRED | Generator `-Check` passed 322 records; the named generated-vector decoder test passed and four-target test execution passed. |

## Automated Evidence

| Check | Result |
|---|---|
| `pwsh -NoProfile -File ./scripts/fixtures/Generate-PngDecodeVectors.ps1 -Check` | PASS — 322 executable cases. |
| `moon -C modules/mb-image test png --target all --frozen` | PASS — 25/25 on wasm, wasm-gc, js, and native. |
| `moon -C modules/mb-image test png --target native --frozen -f '*generated PNG decode vectors*'` | PASS — named behavioral test, exact pixels/channels/errors. |
| `moon -C modules/mb-image test png --target native --frozen -f '*PNG grayscale IHDR accepts low depths*'` | PASS — named packed-row sizing/depth test. |
| `pwsh -NoProfile -File ./scripts/quality/Invoke-MoonQuality.ps1 -Lane Png` | PASS — includes generator checks, four targets, and lane isolation. |
| `moon -C modules/mb-image check --target all --deny-warn --frozen` | WARNING, non-blocking — 26 existing unused-field diagnostics in `generated_vectors.mbt` (`d84d0418`) and legacy `PngTransport` fields (`eeeb47b8`). They predate this task; the only task-owned field is `bit_depth`. |

## Requirement Coverage

| Requirement | Status | Evidence |
|---|---|---|
| `PNGX-01` — palette, grayscale, transparency, and 16-bit profiles with explicit mapping | SATISFIED (bounded grayscale/transparency slice) | This quick task verifies the declared low-bit grayscale and transparency scope. Palette, 16-bit, and other deferred PNG profiles remain out of scope. |

## Anti-Pattern and Scope Scan

No task-owned `TBD`, `FIXME`, `XXX`, placeholder, or empty implementation markers were found. `git diff --check 4716bd8^ 14cff62` is clean. The audited commits modify only declared PNG decoder, fixture, generator, and generated-test paths: no QOI, release, registry, configuration, encoding, palette, Adam7, colour-management, or public streaming changes were included.

## Disconfirmation Pass

The stale full-package `--deny-warn` gate was the potential false-positive failure path. Blame shows its 26 diagnostics are older than this quick task, while the targeted PNG lane and all required behavior checks pass. No partial requirement, unwired artifact, or task-owned error path was found.

_Verified independently against source, commits, generated artifacts, and executed checks; SUMMARY.md claims were not accepted as evidence._
