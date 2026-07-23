---
phase: 66-explicit-rgba16-png-preservation
verified: 2026-07-23T10:12:08Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 66: Explicit RGBA16 PNG Preservation Verification Report

**Phase Goal:** Library users can explicitly decode legal encoded-sRGB Type-6/16 PNG input into a byte-preserving `rgba16` result while generic decoding stays frozen.
**Verified:** 2026-07-23T10:12:08Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A caller can use `PngDecoder::decode_rgba16` for declaration-free or sRGB Type-6/16 input and receive packed little-endian straight-alpha `rgba16`. | ✓ VERIFIED | The public selector in `png.mbt:28-38` constructs the existing machine with the private `Rgba16` profile. Preflight admits only colour type 6, bit depth 16, no transparency, and Default/sRGB declarations (`stream_decode.mbt:520-541`), then creates `ImageFormat::rgba16()` (`raster_decode.mbt:69-77`). The focused JS suite passed 4/4, including declaration-free normal and sRGB Adam7 literals. |
| 2 | Every reconstructed Type-6/16 source lane is observable as `Rlo,Rhi,Glo,Ghi,Blo,Bhi,Alo,Ahi`, with no scaling, premultiplication, colour conversion, or second raster buffer. | ✓ VERIFIED | Normal rows write every U16 component through `set_component_byte(..., 0, low)` then `(..., 1, high)` from the byte-domain row (`raster_decode.mbt:294-308`). The Adam7 scatter repeats that map at the final pass coordinate (`raster_decode.mbt:580-632`). The public tests use distinct source bytes for every normal lane and every coordinate/lane of an independent 5x5 Adam7 literal (`png_test.mbt:26-102`); the focused JS run passed. |
| 3 | The same Type-6/16 input through generic decoding remains `RGBA8(Rhi,Ghi,Bhi,Ahi)`. | ✓ VERIFIED | `PngDecoder::decode` is unchanged on the generic profile; `decode_rgba16` is an additive selector. The normal-row test decodes the same literal through `ImageDecoder::decode` and asserts the four high bytes only (`png_test.mbt:59-70`); it passed in the focused JS suite. |
| 4 | Unsupported type/depth, transparency, legacy-colour, and ICC facts fail before a preservation result is allocated or exposed. | ✓ VERIFIED | `preflight_first_idat` performs each Rgba16 gate before output budget, descriptor, `OwnedImage`, sink, lifecycle, or outcome (`stream_decode.mbt:520-580`). The white-box test supplies wrong depth/type, tRNS, gAMA, and authenticated ICC facts and asserts the typed error, zero lifecycle allocations, no outcome, and unchanged budget (`stream_decode_wbtest.mbt:404-426`, `141-152`); it passed in the focused JS suite. |

**Score:** 4/4 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/png.mbt` | Public eager `decode_rgba16` selector | ✓ VERIFIED | Substantive public function delegates to `new_with_profile(PngDecodeProfile::Rgba16, ...)`; no public chunk selector was added. |
| `modules/mb-image/png/stream_decode.mbt` | Rgba16 profile, strict first-IDAT admission, and profile-aware layout charging | ✓ VERIFIED | Private enum, pre-allocation capability gates, eight-byte output budget selection, `rgba16` descriptor dispatch, and profile-bearing sink construction are all wired. |
| `modules/mb-image/png/raster_decode.mbt` | Exact normal and Adam7 Type-6/16 packed stores | ✓ VERIFIED | Both final-store branches write low then high component bytes; the descriptor payload and row stride are `pixels * 8` and `width * 8`. |
| `modules/mb-image/png/png_test.mbt` | Public eager lane and generic-compatibility regressions | ✓ VERIFIED | Hand-authored normal and Adam7 Type-6/16 literals assert all retained lanes and generic high-byte compatibility. |
| `modules/mb-image/png/stream_decode_wbtest.mbt` | Atomic admission and eight-byte layout evidence | ✓ VERIFIED | Tests cover legal Default/sRGB admission, profile rejection with no lifecycle/result, exact 48-byte two-pixel boundary, one-less failure, and retained GrayAlpha16 admission. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `png.mbt` | `stream_decode.mbt` | `decode_rgba16` creates the byte-fed machine with `Rgba16` | ✓ WIRED | `PngDecoder::decode_rgba16` calls `PngDecodeMachine::new_with_profile(PngDecodeProfile::Rgba16, ...)` at `png.mbt:28-38`. The generated key-link probe was falsely negative because its single-line regex does not cross the newline. |
| `stream_decode.mbt` | `raster_decode.mbt` | Preflight selects descriptor/layout then passes the profile to the sink and Adam7 traversal | ✓ WIRED | Preflight chooses `_png_rgba16_descriptor_with_metadata` and calls `PngRasterSink::new_with_profile(..., self.profile, ...)`; the sink passes its profile to normal and Adam7 final-store branches. |
| `raster_decode.mbt` | `storage/views.mbt` | Completed pixels use the existing U16 component-byte view | ✓ WIRED | Both Type-6/16 stores call `MutImageView::set_component_byte` for channels 0–3 at byte indices 0 and 1. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `raster_decode.mbt` normal store | `rows.current` | Byte-domain inflate/unfilter reconstruction in `PngPackedRows` | Reconstructed Type-6/16 row bytes are read at all eight source offsets and stored once to the owned image. | ✓ FLOWING |
| `raster_decode.mbt` Adam7 store | `rows.current`, `pass` | Same pass-local reconstructed row plus Adam7 pass coordinates | Each pass value is scattered to `pass.x + column*pass.dx`, `pass.y + row*pass.dy`; no static or empty prop/data path exists. | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Public exact-lane, generic-compatibility, profile-admission, and layout-boundary regressions | `moon -C modules/mb-image test png --target js --frozen --filter '*rgba16*'` | `Total tests: 4, passed: 4, failed: 0.` | ✓ PASS |
| Ordinary PNG package on wasm | `moon -C modules/mb-image test png --target wasm --frozen` | `Total tests: 239, passed: 239, failed: 0.` | ✓ PASS |
| Ordinary PNG package portability | `moon -C modules/mb-image test png --target all --frozen` | The aggregate runner exceeded its 180-second timeout without reporting a test failure. The executor then ran the ordinary command serially: wasm, wasm-gc, js, and native each passed 239/239. This report records that result accurately; only wasm was re-run directly during verification to avoid duplicating the already completed broad runs. | ✓ PASS (serial evidence) |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- |
| `RGBA16DEC-02` | `66-01-PLAN.md` | Explicit legal Type-6/16 preservation with frozen generic RGBA8 behavior | ✓ SATISFIED | All four roadmap success criteria are verified above, including eager selector, exact normal/Adam7 lane order, generic high-byte regression, and pre-allocation admission failure. |

No orphaned Phase 66 requirements were found: `RGBA16DEC-02` is the sole roadmap-mapped requirement and is declared by the plan.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| — | — | No phase-introduced TODO/FIXME/XXX markers, empty implementations, placeholder output, or console-only handlers found in the five modified files. | ℹ️ Info | No blocker. Existing prose uses of “not available”/“placeholder” are outside Phase 66 diffs and do not describe unfinished implementation. |

## Gaps Summary

No gaps found. The eager-only scope is respected: repository search finds no `PngChunkDecoder::new_rgba16`; caller-owned chunk construction remains deferred to Phase 67. Phase 68's broader independent all-filter/hostile-input qualification is intentionally future scope and is not a missing Phase 66 roadmap truth.

---

_Verified: 2026-07-23T10:12:08Z_
_Verifier: the agent (gsd-verifier)_
