---
phase: 69-explicit-rgba16-png-encoding
verified: 2026-07-23T12:24:00Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 69: Explicit RGBA16 PNG Encoding Verification Report

**Phase Goal:** Library users can explicitly encode a checked packed `rgba16` image as a byte-exact, non-interlaced PNG Type-6/16 stream while legacy encoding remains frozen.
**Verified:** 2026-07-23T12:24:00Z
**Status:** passed

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Four explicit eager RGBA16 factories select an isolated, non-interlaced Type-6/16 profile. | ✓ VERIFIED | `PngEncoder::new_rgba16*` in `png.mbt` all set `PngEncodeProfile::Rgba16` and `PngInterlaceStrategy::None`; no `PngChunkEncoder::new_rgba16` or Adam7 selector was added. |
| 2 | Packed little-endian `rgba16` samples emit `Rhi,Rlo,Ghi,Glo,Bhi,Blo,Ahi,Alo` with no conversion, then `decode_rgba16` restores the source component-byte order. | ✓ VERIFIED | Profile preflight counts eight bytes per pixel; `_png_wire_byte` uses the existing per-component U16 endian mapping; IHDR selects bit depth 16/type 6. The independent two-pixel test asserts all sixteen PNG lanes and all sixteen restored storage bytes. |
| 3 | Only the checked packed, little-endian, straight-alpha encoded-sRGB RGBA16 identity is accepted; incompatible sources and output limits fail before writer output. | ✓ VERIFIED | `_png_encode_source` keeps the common metadata/layout gates, then requires RGBA/U16/little-endian/straight alpha. Tests assert explicit RGB rejection, one-byte-short output rejection, and zero writer bytes; exact output limit succeeds. |
| 4 | Generic RGB8/RGBA8 encoding behavior is not widened. | ✓ VERIFIED | `PngEncoder::new()` remains on `LegacyRgbOrRgba`; the RGBA16 test asserts it rejects the source with `component-u8-required` before writing. Existing ordinary PNG package tests pass on every supported target. |

**Score:** 4/4 truths verified (0 behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/png.mbt` | Explicit eager RGBA16 factories and private profile | ✓ VERIFIED | Additive `Rgba16` profile plus exactly four eager factory shapes. |
| `modules/mb-image/png/encode.mbt` | Admission, eight-byte accounting, U16 wire traversal, non-interlace preflight | ✓ VERIFIED | The shared bounded preflight/machine is retained; no staging or alternate implementation exists. |
| `modules/mb-image/png/stream_encode.mbt` | Type-6 IHDR selection | ✓ VERIFIED | `Rgba16` maps to PNG colour type 6 and shares the U16 bit-depth selection. |
| `modules/mb-image/png/encode_test.mbt` | Exact lane, factory, atomic-rejection, and compatibility tests | ✓ VERIFIED | Two public RGBA16 tests cover stored wire bytes, explicit decode restoration, all factory shapes, exact/one-less limits, and generic rejection. |

### Key Link Verification

| From | To | Via | Status |
| --- | --- | --- | --- |
| `PngEncoder::encode` | `PngEncodeMachine::new_with_profile` | Encoder forwards `self.profile` to the existing machine. | ✓ WIRED |
| `PngEncodeProfile::Rgba16` | `_png_wire_byte` | U16 component mapping reverses little-endian storage per channel before filtering and DEFLATE traversal. | ✓ WIRED |
| `PngEncodeMachine::byte_at` | PNG IHDR | Profile chooses Type 6 and shared U16 selection chooses depth 16. | ✓ WIRED |

### Behavioral Evidence

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Focused public RGBA16 encoder contract | `moon -C modules/mb-image test png --target js --frozen --filter '*RGBA16*'` | 2 passed, 0 failed | ✓ PASS |
| Ordinary PNG package on wasm | `moon -C modules/mb-image test png --target wasm --frozen` | 247 passed, 0 failed | ✓ PASS |
| Ordinary PNG package on wasm-gc | `moon -C modules/mb-image test png --target wasm-gc --frozen` | 247 passed, 0 failed | ✓ PASS |
| Ordinary PNG package on js | `moon -C modules/mb-image test png --target js --frozen` | 247 passed, 0 failed | ✓ PASS |
| Ordinary PNG package on native | `moon -C modules/mb-image test png --target native --frozen` | 247 passed, 0 failed | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status |
| --- | --- | --- | --- |
| `RGBA16ENC-01` | `69-01-PLAN.md` | Explicit eager non-interlaced Type-6/16 encode from `rgba16`, while legacy output stays frozen. | ✓ SATISFIED |

## Gaps Summary

No gaps found. Caller-buffered RGBA16 encoding remains deferred to Phase 70 and Adam7 RGBA16 selection remains deferred to Phase 71.
