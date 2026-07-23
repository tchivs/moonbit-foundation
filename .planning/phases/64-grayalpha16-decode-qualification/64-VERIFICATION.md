---
phase: 64-grayalpha16-decode-qualification
verified: 2026-07-23T16:55:00+08:00
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 64: GrayAlpha16 Decode Qualification Verification Report

**Phase Goal:** Qualify explicit high-precision Type-4/16 decoding across PNG filters, Adam7, hostile boundaries, frozen generic compatibility, and all portable targets.

## Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Explicit eager and chunk decoders preserve every non-symmetric Type-4/16 lane as `Glo,Ghi,Alo,Ahi` through five PNG filters and all seven nonempty Adam7 passes. | ✓ VERIFIED | Fixed public filter and 5×5 Adam7 literals plus component-byte oracles cover eager, one-byte, and ragged chunk paths in `png_test.mbt` and `stream_decode_test.mbt`. Focused JS `*graya16*`: 8/8 passed. |
| 2 | Legal Type-4/16 Adam7 enters only the explicit profile; incompatible type/depth, transparency, legacy-colour, and ICC facts remain rejected before a result is visible. | ✓ VERIFIED | `stream_decode.mbt` retains all profile gates except the incompatible interlace rejection; `raster_decode.mbt` threads `PngDecodeProfile` into Adam7 scatter and uses the existing component-byte store only for `GrayAlpha16`. White-box profile admission coverage remains in `stream_decode_wbtest.mbt`. |
| 3 | Exact/one-less resource evidence, split hostile chunk inputs, and terminal replay remain bounded and atomic, while generic eager/chunk decoding stays frozen as `RGBA8(Ghi,Ghi,Ghi,Ahi)`. | ✓ VERIFIED | The Phase 64 public tests reuse the bounded schedule/terminal helpers and assert generic high-byte output against the independent literals; `5c8312a` adds five-filter and limit qualification without a second decoder or storage path. |
| 4 | The ordinary full PNG package passes on every supported target. | ✓ VERIFIED | Direct, unwrapped command `moon -C modules/mb-image test png --target all --frozen` completed successfully: 235 passed, 0 failed for wasm, wasm-gc, js, and native. |

**Score:** 4/4 truths verified.

## Required Artifacts

| Artifact | Status | Details |
| --- | --- | --- |
| `modules/mb-image/png/stream_decode.mbt` | ✓ VERIFIED | Explicit profile admits legal Adam7 without widening generic admission. |
| `modules/mb-image/png/raster_decode.mbt` | ✓ VERIFIED | Adam7 Type-4/16 scatter preserves all lanes through the existing little-endian component-byte representation only under the explicit profile. |
| `modules/mb-image/png/png_test.mbt` | ✓ VERIFIED | Independent fixed filter and Adam7 wire literals assert every explicit lane and frozen generic output. |
| `modules/mb-image/png/stream_decode_test.mbt` | ✓ VERIFIED | Public eager/chunk parity, split schedules, terminal, generic, and limit qualification are substantive. |
| `modules/mb-image/png/stream_decode_wbtest.mbt` | ✓ VERIFIED | Profile admission regression retains non-Adam7 rejections while accepting legal explicit Adam7. |

## Behavioral Evidence

| Command | Result | Status |
| --- | --- | --- |
| `moon -C modules/mb-image test png --target js --frozen --filter '*graya16*'` | 8 passed, 0 failed | ✓ PASS |
| `moon -C modules/mb-image test png --target all --frozen` | 235 passed, 0 failed on wasm, wasm-gc, js, and native | ✓ PASS |

The final all-target command emitted two pre-existing compiler warnings only; neither is a test failure.

## Requirement Coverage

| Requirement | Status | Evidence |
| --- | --- | --- |
| `GRA16DEC-03` | ✓ SATISFIED | Truths 1–4 and the ordinary all-target package result prove the required independent vectors, filter/Adam7 fidelity, hostile bounded behavior, frozen generic compatibility, and portability. |

## Gaps Summary

None. The Phase 64 goal is achieved without an alternate decoder, generic result widening, staging buffer, wrapper, copied build tree, or release automation.

---

_Verified: 2026-07-23T16:55:00+08:00_
_Verifier: root agent after independent verifier dispatch timed out before artifact creation._
