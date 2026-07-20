---
quick_id: 260721-4vk
verified: 2026-07-20T19:55:15Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 4/5
  gaps_closed:
    - "The decode-vector oracle now independently validates type-0 and type-2 tRNS source scanlines and RGBA8 output."
  gaps_remaining: []
  regressions: []
---

# Quick Task 260721-4vk Verification Report

**Goal:** Validate PNG `tRNS` transparency for supported 8-bit profiles.

**Commits audited:** `21e5556` (`feat(quick-260721-4vk): decode PNG tRNS transparency`) and `0354596` (`fix(quick-260721-4vk): verify PNG tRNS source transparency oracle`)

**Status:** `passed` (re-verification)

## Goal Achievement

| # | Observable truth | Status | Evidence |
|---|---|---|---|
| 1 | Type-0, type-2, and type-3 valid `tRNS` decode to exact straight RGBA8. | VERIFIED | `PngTransparency` is carried from transport into both raster paths. The native named generated-vector test passed, and the four-target run passed 23/23 tests on wasm, wasm-gc, js, and native. Generated valid families assert exact RGBA bytes. |
| 2 | Filtering uses encoded source bpp (1/3/1), not exposed RGBA bpp. | VERIFIED | Streaming raster calculation uses `transport.source_channels` for row width, pixel coordinate, left, and upper-left; it expands/comparisons only afterward. The private helper follows the same flow. Valid all-filter vector families pass. |
| 3 | Duplicate, misplaced, CRC-invalid, malformed, and type-6 `tRNS` inputs fail before an image is returned. | VERIFIED | Transport validates CRC before semantics, enforces one pre-IDAT chunk, validates length/high bytes and PLTE order, and rejects type 6. Generated error cases cover duplicate, after-IDAT, pre-PLTE, CRC, both length/high-byte forms, indexed length, and type 6; all four targets passed. |
| 4 | Output and indexed row-cache resource limits are checked atomically before allocation. | VERIFIED | Transparent non-indexed preflight reserves RGBA8 while computing filtered work from source channels; indexed preflight reserves RGBA8 plus two width-byte rows with three allocations. The named exact/below reservation test passed. |
| 5 | Generated fixtures independently validate all supported `tRNS` forms, all filters, every two-IDAT split, manifests, and four targets. | VERIFIED | `Assert-Oracle` now independently inflates and reconstructs type 0 (bpp 1), type 2 (bpp 3), and type 3 (bpp 1), validates zero high bytes/low-byte keys, derives straight RGBA8, and compares it with fixture pixels before record generation. Generator check and four-target tests pass. |

**Score:** 5/5 truths verified.

## Required Artifacts

| Artifact | L1 exists | L2 substantive | L3 wired | Status |
|---|---|---|---|---|
| `modules/mb-image/png/structural.mbt` | Yes | Typed state, validation, preflight, and deterministic errors | Used by `PngDecoder` transport | VERIFIED |
| `modules/mb-image/png/deflate_inflate.mbt` | Yes | Source-channel reconstruction and grayscale/RGB alpha emission | Live decoder path | VERIFIED |
| `modules/mb-image/png/raster_decode.mbt` | Yes | Private raster path applies indexed/default alpha and source-bpp filtering | White-box tests use it | VERIFIED |
| `fixtures/png/decode-cases.json` | Yes | Valid/error matrix and split declarations | Regenerated into MoonBit vectors | VERIFIED |
| `scripts/fixtures/Generate-PngDecodeVectors.ps1` | Yes | Generates chunks, split records, digests, and independent type-0/type-2/type-3 oracles | Used by `-Check` and quality lane | VERIFIED |

## Key Links and Data Flow

| Link | Status | Evidence |
|---|---|---|
| `tRNS` chunk → typed transport → descriptor/preflight/raster | WIRED | CRC-captured payload becomes `Grayscale`, `Rgb`, or `Indexed`; descriptor channels and child budget use that state, which is passed to stream raster writing. |
| Source scanlines → filter reconstruction → transparency output | WIRED | Both stream and private helpers calculate neighbours using `source_channels`; type 0 compares reconstructed gray, type 2 compares complete reconstructed RGB, and indexed lookup applies a supplied alpha or `255`. |
| JSON fixtures → generator → generated vectors → four targets | WIRED | The generator calls its oracle for every accepted record; its type-0, type-2, and type-3 branches reconstruct source scanlines and compare derived output before emitting vectors. |

## Automated Evidence

| Check | Result |
|---|---|
| `pwsh -NoProfile -File ./scripts/fixtures/Generate-PngDecodeVectors.ps1 -Check` | PASS (re-run after `0354596`) — 161 executable cases |
| `pwsh -NoProfile -File ./scripts/fixtures/Generate-PngStructuralVectors.ps1 -Check` | PASS — 89 public/white-box cases |
| `moon -C modules/mb-image test png --target all --frozen` | PASS (re-run after `0354596`) — 23/23 on wasm, wasm-gc, js, native |
| `moon -C modules/mb-image test png --target native --frozen -f '*generated PNG decode vectors*'` | PASS — 1/1 named behavioral test |
| `moon -C modules/mb-image test png --target native --frozen -f '*tRNS reserves RGBA8*'` | PASS — 1/1 named resource-limit test |
| `pwsh -NoProfile -File ./scripts/quality/Invoke-MoonQuality.ps1 -Lane Png` | PASS (re-run after `0354596`) — includes generation, four targets, and lane isolation |
| `moon -C modules/mb-image check --target all --deny-warn --frozen` | WARNING — fails on 26 existing generated/legacy unused-field diagnostics; these fields predate this commit and are outside the tRNS behavior change. |

## Requirement Coverage

| Requirement | Status | Evidence |
|---|---|---|
| `PNGX-01` — transparency mapping among PNG profiles | SATISFIED (bounded slice) | The task's supported 8-bit tRNS profiles and independent evidence are verified. The broader requirement's 16-bit work remains explicitly outside this quick task's scope. |

## Anti-Pattern and Scope Scan

No task-owned `TBD`, `FIXME`, `XXX`, placeholder, or empty-implementation markers were found. `git diff --check 21e5556^ 21e5556` is clean. The audited commit modifies only declared PNG/fixture/generator files; it does not touch QOI, release, registry, configuration, encoding, or public streaming work.

## Re-verification Summary

The prior blocker is closed in `0354596`. The independent oracle now reconstructs encoded source rows with bpp 1 for grayscale and bpp 3 for RGB, validates the standard 16-bit tRNS representation's zero high bytes, compares the low-byte key after reconstruction, derives straight RGBA8, and compares the result to the declared fixture bytes. The re-run generator check, four portable targets, and PNG quality lane all pass.

_Verified independently against code and generated artifacts; SUMMARY.md claims were not accepted as evidence._
