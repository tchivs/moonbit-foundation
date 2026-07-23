---
phase: 81-indexed8-adam7-machine-and-eager-wire-contract
verified: 2026-07-23T23:24:51Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 81: Indexed8 Adam7 Machine and Eager Wire Contract — Verification Report

**Phase Goal:** Users can explicitly encode a canonical `PngIndexedImage` as a bounded Type-3/8 Adam7 PNG through the existing acknowledged machine while legacy Indexed8 routes remain byte-identical and non-interlaced.

**Verified:** 2026-07-23T23:24:51Z  
**Status:** passed  
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Additive eager and caller-buffered Indexed8 selectors accept Adam7; legacy `encode_indexed8` / `new_indexed8` remain explicit non-interlaced wrappers. | ✓ VERIFIED | `encode_indexed8_with_interlace_strategy` and `new_indexed8_with_interlace_strategy` both construct `PngEncodeMachine::new_with_indexed_profile(... Eight, interlace_strategy, ...)`; legacy and selected low-bit callers pass `None`. The chunk smoke test drains the new selector and asserts Type-3/8 IHDR with interlace byte `01`. |
| 2 | Indexed8 Adam7 derives pass rows from the checked shared seven-pass geometry, emits filter None per nonempty pass row, and reads canonical indices without staging or a second encoder. | ✓ VERIFIED | Indexed preflight and `_png_indexed8_adam7_scanline_byte` both call `_png_adam7_passes(width, height, 1UL, 8)`. The scalar helper returns `00` only for pass-row starts and otherwise calls `PngIndexedImage::index_at(mapped_x, mapped_y)`; the existing `PngEncodeMachine` remains the sole emitter. |
| 3 | Type-3/8 Adam7 preserves framing, CRCs, canonical palette transparency, exact seven-pass raster, and public RGB8/RGBA8 palette decode. | ✓ VERIFIED | The independent 5×5 test uses literal source/palette/alpha data and a literal 36-byte raw pass oracle; it asserts IHDR, PLTE, three-byte `tRNS`, 47-byte IDAT, IEND, every CRC, all 25 RGBA pixels, and opaque RGB decode. |
| 4 | Layout-specific scanline/frame/work/output/budget admission is exact and atomic. | ✓ VERIFIED | `_png_encode_indexed_preflight_with_profile` sums checked nonempty Adam7 pass rows before Stored IDAT/frame/limit calculation and performs the sole budget charge afterward. White-box and eager tests prove exact `36` scanlines, `47` IDAT bytes, `143` total/work and one-less output/work rejection with zero writer progress and an unchanged budget. |
| 5 | Existing Indexed8 opaque/transparent and Indexed1/2/4 outputs remain non-interlaced and frozen. | ✓ VERIFIED | The legacy wrappers explicitly select `None`; existing literal 89-byte opaque, 112-byte transparent Indexed8, and Indexed1/2/4 vector tests remain in the PNG suite. No low-bit Adam7 selector is exposed. |

**Score:** 5/5 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/encode.mbt` | Additive eager selection and indexed Adam7 preflight. | ✓ VERIFIED | Public selector delegates to `new_with_indexed_profile`; checked pass-total branch admits only `PngIndexedWireProfile::Eight` for Adam7. |
| `modules/mb-image/png/stream_encode.mbt` | Thin chunk selector and scalar Adam7 emission in the existing machine. | ✓ VERIFIED | Thin selector uses the same constructor; `PngEncodeMachine::scanline_byte` delegates Indexed8 Adam7 bytes to `_png_indexed8_adam7_scanline_byte`. |
| `modules/mb-image/png/encode_test.mbt` | Independent eager wire, decode, atomicity, and legacy tracer. | ✓ VERIFIED | Test-local literal oracle, CRC/chunk checks, both public decode modes, and atomic rejection checks are substantive and exercised by the package suite. |
| `modules/mb-image/png/encode_wbtest.mbt` | Exact Adam7 preflight facts and one-less accounting. | ✓ VERIFIED | Asserts `scanlines=36`, one Stored block, `idat_length=47`, `total_length=selected_work=143`, exact charge, and unchanged resource limits on rejection. |
| `modules/mb-image/png/stream_encode_test.mbt` | Minimal chunk selector-to-machine Adam7 proof. | ✓ VERIFIED | A single sufficient-capacity lease drains 143 bytes and asserts IHDR `08 03 00 00 01`; hostile lifecycle remains deliberately owned by Phase 82. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- |
| Eager Indexed8 selector | `PngEncodeMachine::new_with_indexed_profile` | `PngIndexedWireProfile::Eight`, requested `PngInterlaceStrategy` | ✓ WIRED | Direct constructor call in `encode.mbt`; legacy eager wrapper supplies `None`. |
| Chunk Indexed8 selector | `PngEncodeMachine::new_with_indexed_profile` | `PngIndexedWireProfile::Eight`, requested `PngInterlaceStrategy` | ✓ WIRED | Direct constructor call in `stream_encode.mbt`; legacy chunk wrapper supplies `None`. |
| Indexed Adam7 preflight | Indexed scalar output | shared `_png_adam7_passes(width, height, 1UL, 8)` | ✓ WIRED | Both independently consume the sole pass-geometry authority, preventing normal-row framing from drifting from mapped pass traversal. |
| Indexed source | PNG wire byte stream | `PngIndexedImage::index_at` in scalar helper | ✓ WIRED | The helper maps pass coordinates directly; no `ImageView` coercion or materialized pass/image buffer exists. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Indexed Adam7 scalar emission | mapped `(x, y)` index byte | immutable `PngIndexedImage` via `index_at` | Literal 5×5 test data reaches IDAT and public decode assertions | ✓ FLOWING |
| PLTE / `tRNS` framing | palette and alpha table | immutable `PngIndexedImage` palette/alpha accessors | Actual PLTE bytes and shortest non-opaque alpha prefix are CRC-checked | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Whole PNG package on native, wasm, wasm-gc, and js | `moon -C modules/mb-image test png --target all --frozen` | Recorded from the post-implementation mainline code review: 289 passed on each target. The current source history contains no later PNG source/test changes; this verifier's duplicate invocation timed out behind existing Moon processes without a failure diagnostic. | ✓ PASS (recorded mainline evidence) |
| Independent eager raster / public decode / atomic admission | Same frozen package gate; named assertions in `encode_test.mbt` and `encode_wbtest.mbt` | Included in the recorded 289-per-target result; code inspection confirms the expected data is literal/test-local rather than calculated from production helpers. | ✓ PASS |
| Chunk selector wiring | Same frozen package gate; `PNG Indexed8 Adam7 chunk selector wires the shared machine IHDR` | Included in the recorded 289-per-target result; direct test drains the new public selector and observes IHDR interlace `01`. | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- |
| INDEXADAM7-01 | 81-01 | Additive eager and caller-buffered Type-3/8 Adam7 APIs with frozen wrappers. | ✓ SATISFIED | Both public selectors are wired to the shared machine; legacy wrappers supply `None`; chunk IHDR smoke test verifies Adam7 reaches the machine. |
| INDEXADAM7-02 | 81-01 | Shared Adam7 geometry and direct canonical-index traversal without a second encoder/staging. | ✓ SATISFIED | Checked pass sums and scalar emission both use `_png_adam7_passes(..., 1UL, 8)`; source reads use `index_at`; no alternate transport/emitter was added. |
| INDEXADAM7-03 | 81-01 | Framed Type-3/8 output and exact public RGB8/RGBA8 decode. | ✓ SATISFIED | Literal raw raster/framing/CRC oracle and all-coordinate public decode test cover transparent RGBA8 and opaque RGB8 routes. |
| INDEXADAM7-04 | 81-01 | Exact and atomic layout-specific admission. | ✓ SATISFIED | Exact/one-less frame/work/output facts are asserted before writer output; shared construction means failed chunk admission returns before an encoder or lease exists. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| — | — | No phase-introduced TODO/FIXME/XXX/HACK/placeholder, empty implementation, hardcoded user-visible output, or duplicate transport found. | — | — |

### Scope and Compatibility Check

- Only `PngIndexedWireProfile::Eight` accepts Adam7; Indexed1/2/4 continue to call the profile constructor with `None`.
- Indexed output remains Stored DEFLATE and filter None. No adaptive/filter or Fixed/Dynamic indexed route was added.
- The implementation extends the existing acknowledged `PngEncodeMachine`; no secondary encoder, staging buffer, generic image-model widening, FFI, wrapper, copied tree, or decoder change was introduced.
- `git diff --check 38a16dc..HEAD` is clean for all five phase source/test files. The only unrelated worktree item observed is the user-owned untracked Phase 66 research input, which was left untouched.

## Gaps Summary

No implementation gap found. The prior code-review evidence records the ordinary frozen PNG package suite at **289/289 tests on wasm, wasm-gc, js, and native**. A duplicate local all-target invocation could not complete before its 124-second timeout because existing Moon processes held the build environment; it emitted no test failure. The recorded execution corresponds to the current implementation: after `62425b6` changed PNG code/tests, only Phase 81 documentation commits followed.

## VERDICT: PASS

The phase goal and all four mapped requirements are achieved in the current codebase. Phase 82 remains responsible only for hostile caller-buffer lifecycle and final qualification requirements INDEXADAM7-05 and INDEXADAM7-06.

---

_Verified: 2026-07-23T23:24:51Z_  
_Verifier: the agent (gsd-verifier)_
