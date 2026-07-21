---
phase: 21-bounded-png-decode-and-deflate
verified: 2026-07-21T04:58:49Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: passed
  previous_score: 4/4
  gaps_closed:
    - "The retained 89-record Phase-20 structural matrix is now a named public PngDecoder test on every portable target."
  gaps_remaining: []
  regressions: []
---

# Phase 21: Bounded PNG Decode and DEFLATE Verification Report

**Phase Goal:** Library users can decode the supported non-interlaced PNG RGB/RGBA subset through bounded, deterministic pure-MoonBit decompression and scanline reconstruction.

**Verified:** 2026-07-21T04:58:49Z
**Status:** passed
**Re-verification:** Yes — after the reachable-structural-corpus evidence closure.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Users can decode supported RGB8/RGBA8 PNGs with all five filters through the public eager decoder. | VERIFIED | The generated decode test invokes `PngDecoder` through `ImageDecoder::decode`, checks descriptor/metadata and every pixel, and passed on all four targets. The independent decode generator verified 3,850 executable records. |
| 2 | Stored, fixed-Huffman, and dynamic-Huffman streams decode over arbitrary IDAT boundaries. | VERIFIED | The decode corpus generator passed; the all-target public suite passed 41/41 for wasm, wasm-gc, js, and native. The quality lane includes split-boundary decode evidence. |
| 3 | Structural, zlib, resource, checksum, and ordering failures are deterministic before image visibility. | VERIFIED | The named structural test iterates all 89 generated public records, invokes `PngDecoder`, requires `unwrap_err()`, and compares exact category/code/context. The post-DEFLATE corpus independently checks hostile output/work cases. |
| 4 | The legacy structural evidence is reachable with explicit current expectations rather than an outcome-selected oracle. | VERIFIED | `generated_vectors_test.mbt` provides 89 public records; `png_test_legacy_expectation(item)` runs before decode and returns a complete stage/category/code/context/budget expectation. The observed error is only compared afterward. |

**Score:** 4/4 truths verified (0 present but behavior-unverified).

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `modules/mb-image/png/png_test.mbt` | Reachable public structural corpus and explicit outcome map | VERIFIED | Named MoonBit test loops over `_generated_png_public_cases()` and calls `ImageDecoder::decode(PngDecoder::new(), ...)`; the 89-record generator freshness check and four-target test succeeded. |
| `modules/mb-image/png/generated_vectors_test.mbt` | Private generated public structural records | VERIFIED | Contains `_generated_png_public_cases()` with 89 `PngGeneratedCase` constructors, regenerated and checked successfully. |
| `modules/mb-image/png/structural.mbt` | Ordered stream transport and terminal failures | VERIFIED | Initial IHDR type/length are validated before acceptance; duplicate IHDR, PLTE during active IDAT, and recognised colour after IDAT retain distinct terminals. |
| `modules/mb-image/png/deflate_*.mbt`, `raster_decode.mbt`, `png.mbt` | Private bounded DEFLATE-to-raster pipeline | VERIFIED | Policy inventory accepts the private sources; `PngIdatSource` feeds the inflater, raster mutation stays inside `with_mut_view`, and `DecodeResult` is constructed only after terminal completion. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| Generated structural corpus | `PngDecoder` | Named public test → `ImageDecoder::decode` | WIRED | Each generated public record is decoded at `png_test.mbt:482-524`; failures have no result because the test calls `unwrap_err()`. |
| Outcome classifier | assertion | Pre-decode `expected` record | WIRED | Expectation is built at `png_test.mbt:493`, before the decode at line 500; lines 515-518 compare the observed terminal only after execution. |
| Stream transport | DEFLATE/raster | `PngIdatSource` → inflater sink → `with_mut_view` | WIRED | The decoder creates the stream transport, feeds `stream.source` to inflation, completes the source, then constructs `DecodeResult`. |
| Active IDAT ordering | public structural assertions | `PngIdatSource::next_byte` and `finish` | WIRED | IHDR is `png-ihdr-order`; PLTE between IDAT chunks is `png-semantic-chunk`; recognised colour after IDAT is `png-colour-order`, all exercised through the public test path. |

### Data-Flow Trace

| Artifact | Data | Source | Status |
|---|---|---|---|
| Public structural test | 89 generated PNG byte records | `Generate-PngStructuralVectors.ps1` → `_generated_png_public_cases()` → `PngDecoder` | FLOWING |
| Decode corpus | PNG bytes, expected pixels/errors, split schedules | `Generate-PngDecodeVectors.ps1` → generated public decode test → `PngDecoder` | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Structural vectors are current | `pwsh -NoProfile -File scripts/fixtures/Generate-PngStructuralVectors.ps1 -Check` | 89 P+W cases | PASS |
| Decode vectors are current | `pwsh -NoProfile -File scripts/fixtures/Generate-PngDecodeVectors.ps1 -Check` | 3,850 executable cases | PASS |
| Public decoder works across portable targets | `moon -C modules/mb-image test png --target all --frozen` | 41/41 on wasm, wasm-gc, js, native | PASS |
| Policy, scope, generators, colour evidence, and isolated PNG lane agree | `pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png` | Full lane and isolation proof passed | PASS |

### Requirements Coverage

| Requirement | Source Plan | Status | Evidence |
|---|---|---|---|
| PNG-04 | 21-01, 21-03 | SATISFIED | Generated public RGB/RGBA vectors validate pixels, all filters, split boundaries, and portable targets. |
| PNG-05 | 21-01, 21-02, 21-03 | SATISFIED | 89 structural public records, explicit zlib terminals, hostile decode vectors, and all-target runs provide deterministic failure evidence. |

### Scope and Regression Checks

- The public PNG interface remains `PngDecoder`/`PngEncoder` and their codec implementations. All DEFLATE and IDAT helpers are private; no public PNG streaming or generic compression API exists.
- The isolated PNG quality lane passed policy, allowed-import/interface checks, negative fixtures, production-source inventory, and isolation proof.
- Current colour behavior remains exercised: sRGB intent is retained; legal non-sRGB metadata is not relabelled; post-IDAT colour chunks return `png-colour-order`; retained non-sRGB images keep their typed encoder/reference-operation capability boundary.
- The two Plan 21-03 implementation commits are `9c731d3` (explicit expectation map) and `516c38a` (IHDR/PLTE/colour ordering terminals). Their diffs are limited to `png_test.mbt` and `structural.mbt`; `git diff --check` passed for both.

### Anti-Patterns Found

No phase-owned `TBD`, `FIXME`, `XXX`, placeholder, empty-handler, or hardcoded-output stub patterns were found in the two changed source files.

## Gaps Summary

No blockers or human-verification items remain. The prior evidence weakness was resolved: the 89 retained structural records are now reachable through the public decoder on all four portable targets with expectations chosen before execution.

---

_Verified: 2026-07-21T04:58:49Z_
_Verifier: the agent (gsd-verifier)_
