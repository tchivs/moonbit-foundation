---
phase: 62-explicit-grayalpha16-decode-contract
verified: 2026-07-23T05:38:29Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 62: Explicit GrayAlpha16 Decode Contract Verification Report

**Phase Goal:** Users can explicitly decode a legal encoded-sRGB Type-4/16 PNG into the existing packed little-endian, straight-alpha `graya16` result without changing generic decoding.
**Verified:** 2026-07-23T05:38:29Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A user can call `PngDecoder::decode_graya16` for default or `sRGB` Type-4/16 input and receive an existing `DecodeResult` containing packed LE, straight-alpha, top-left, encoded-sRGB `graya16`. | ✓ VERIFIED | [`png.mbt`](../../../modules/mb-image/png/png.mbt) exposes the sole public eager selector and sends `GrayAlpha16` into `decode_reader`; [`stream_decode.mbt`](../../../modules/mb-image/png/stream_decode.mbt) creates the existing `DecodeResult`, and its first-IDAT preflight accepts only Type-4/16/non-interlaced `Default` or `Srgb`. The focused JS public test passed (1/1). |
| 2 | Every reconstructed asymmetric wire tuple `Ghi,Glo,Ahi,Alo` is observable as `Glo,Ghi,Alo,Ahi`, with no scaling, premultiplication, or colour conversion. | ✓ VERIFIED | The independent two-pixel literal has unequal lanes `12,34,a7,c5` and `be,0f,5a,76`; [`raster_decode.mbt`](../../../modules/mb-image/png/raster_decode.mbt) writes byte offsets `+1,+0,+3,+2` via `set_component_byte`, and [`png_test.mbt`](../../../modules/mb-image/png/png_test.mbt) asserts all eight stored component bytes. Focused JS public test passed (1/1). |
| 3 | The ordinary generic decoder remains the frozen `RGBA8(Ghi,Ghi,Ghi,Ahi)` route for the same Type-4/16 source. | ✓ VERIFIED | The `ImageDecoder` implementation continues constructing `PngDecodeMachine::new`, which selects `GenericRgba8`; the same independent literal asserts generic first-pixel RGB `0x12,0x12,0x12` and alpha `0xa7`. Focused JS public test passed (1/1). |
| 4 | An incompatible explicit profile fails with the established typed `png-decode/graya16-profile` diagnostic before private lifecycle/result/output-budget/sink construction. | ✓ VERIFIED | Preflight performs its profile gate before transport/output-budget/descriptor/image/sink construction. White-box tests exercise wrong depth, wrong colour type, interlace, legacy gAMA, and iCCP; they assert capability category/code, operation/context, zero lifecycle allocations, no outcome, and unchanged bytes budget. Focused JS profile tests passed (2/2). |

**Score:** 4/4 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/png.mbt` | Public `decode_graya16` selector returning `DecodeResult`. | ✓ VERIFIED | Exists, substantive, and its profile-selection call is used by the public API. |
| `modules/mb-image/png/stream_decode.mbt` | Private profile selection and pre-allocation first-IDAT admission. | ✓ VERIFIED | `PngDecodeProfile` is private; `new_with_profile` threads it through preflight to the sink. |
| `modules/mb-image/png/raster_decode.mbt` | Profile-aware Type-4/16 final sink. | ✓ VERIFIED | Completed reconstructed rows take the `GrayAlpha16` branch and write all four U16 component bytes. |
| `modules/mb-image/png/png_test.mbt` | Independent public fidelity and generic-compatibility regression. | ✓ VERIFIED | Hand-authored default and sRGB PNG byte literals drive public decode APIs; focused test passes. |
| `modules/mb-image/png/stream_decode_wbtest.mbt` | Private typed, atomic profile-rejection evidence. | ✓ VERIFIED | Direct machine fixtures verify every required rejection and valid default/sRGB admission; focused tests pass. |

`verify.artifacts` independently reported 5/5 passing artifacts. All artifacts are wired; none is an orphan or stub.

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `png.mbt` | `stream_decode.mbt` | `decode_graya16` → `new_with_profile(GrayAlpha16)` → `decode_reader` | ✓ WIRED | The call is split across lines 21–23, so the plan's single-line regex did not match; manual source inspection confirms the exact connection. |
| `stream_decode.mbt` | `raster_decode.mbt` | First-IDAT preflight selects graya16 descriptor and passes profile to sink. | ✓ WIRED | Preflight selects `_png_graya16_descriptor_with_metadata` and calls `PngRasterSink::new_with_profile(..., self.profile, ...)`. |
| `raster_decode.mbt` | existing storage component-byte API | Completed Type-4/16 row writes U16 bytes. | ✓ WIRED | `_png_write_16bit_grayscale_alpha_row_graya16` writes four mapped values through `set_component_byte`. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `raster_decode.mbt` | `rows.current[offset + 0..3]` | CRC-authenticated IDAT → existing inflater → bytewise row reconstruction | The hand-authored PNG payload reaches the completed-row sink; the public test observes all eight resulting component bytes. | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Explicit default/sRGB fidelity plus generic compatibility | `moon -C modules/mb-image test png --target js --frozen --filter '*explicit graya16*'` | 1 passed, 0 failed | ✓ PASS |
| Typed atomic explicit-profile admission/rejection | `moon -C modules/mb-image test png --target js --frozen --filter '*graya16 profile*'` | 2 passed, 0 failed | ✓ PASS |
| Native compilation of the current package | `moon -C modules/mb-image check --target native --frozen` | 0 errors (pre-existing warnings only) | ✓ PASS |

The recorded full native-suite Clang out-of-memory condition was not treated as a Phase 62 functional failure and was not replayed: this phase's required focused functional evidence is the JS 3/3 tests plus a native source check. Full four-target package qualification belongs to Phase 64.

### Probe Execution

Step 7c: SKIPPED — no phase-declared or conventional probe script exists.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `GRA16DEC-01` | `62-01-PLAN.md` | Explicit legal sRGB Type-4/16 decode retains all LE `graya16` bytes while generic remains high-byte RGBA8. | ✓ SATISFIED | Truths 1–4, exact lane test, typed admission test, and native check above. |

No requirements mapped to Phase 62 are absent from the plan; no orphaned requirement was found.

### Anti-Patterns Found

No blocker or warning anti-patterns found in the five Phase 62 files. The only keyword matches were descriptive comments about pre-existing unavailable encoder/chunk behavior and a private no-input-reader placeholder; neither reaches user-visible output or represents untracked debt. No unreferenced `TBD`, `FIXME`, or `XXX` markers occur in phase-modified files.

### Gaps Summary

None. The public selector is real, its private profile reaches the real decoder and reconstructed-row sink, and focused behavior tests prove both byte fidelity and atomic typed rejection. The lack of Phase 64's portability/hostile-input matrix is explicitly deferred by the roadmap and is not a Phase 62 gap.

---

_Verified: 2026-07-23T05:38:29Z_
_Verifier: the agent (gsd-verifier)_
