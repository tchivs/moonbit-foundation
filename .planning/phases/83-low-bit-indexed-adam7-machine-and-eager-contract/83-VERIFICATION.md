---
phase: 83-low-bit-indexed-adam7-machine-and-eager-contract
verified: 2026-07-24T02:10:44Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 83: Low-Bit Indexed Adam7 Machine and Eager Contract — Verification Report

**Phase Goal:** Users can explicitly encode the canonical unpacked `PngIndexedImage` as bounded Type-3/1, /2, or /4 Adam7 output through the sole acknowledged machine, with deterministic packed pass rows, exact framing, and atomic resource admission.

**Verified:** 2026-07-24T02:10:44Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- |
| 1 | Additive eager and caller-buffered selectors accept Adam7 for Type-3/1, /2, and /4, while legacy selected-depth routes remain explicit non-interlaced forwards and frozen vectors remain available. | ✓ VERIFIED | `PngEncoder::encode_indexed` and `PngChunkEncoder::new_indexed` both forward `PngInterlaceStrategy::None`; the new explicit companions map `PngIndexedBitDepth` once through `_png_indexed_wire_profile` and call `PngEncodeMachine::new_with_indexed_profile`. The registered chunk smoke drives all three depths and observes IHDR depth/type/interlace. |
| 2 | Every nonempty low-bit Adam7 pass row uses selected-depth shared geometry, emits filter None, packs local source indices MSB-first, and leaves final-byte tails zero without staging or another encoder. | ✓ VERIFIED | `_png_indexed_adam7_scanline_byte` and indexed preflight both call `_png_adam7_passes(width, height, 1UL, depth)`. The replay path returns `00` at each pass-row start, packs only `pass_column < pass.width` into a zero-initialized byte, and reads canonical coordinates with `PngIndexedImage::index_at`. Literal raw tests cover all seven passes and zero tails at depths 1, 2, and 4. |
| 3 | Each selected depth has exact Type-3 Adam7 framing, actual-entry PLTE, shortest canonical tRNS, CRCs, Stored/filter-None raster, and palette-exact public RGB8/RGBA8 decode. | ✓ VERIFIED | `PNG selected low-bit Adam7 eager wires literal packed passes and palette decode` owns three test-local 5×5 sources and literal rasters of 22, 24, and 27 bytes. It verifies IHDR, ordered PLTE/tRNS/IDAT/IEND framing, all CRCs, Stored payload bytes, every transparent RGBA pixel, and every opaque RGB pixel. The depth-2 literal is `B1 80` for `23012`, the correct MSB-first encoding rather than the earlier planning typo `B4 80`. |
| 4 | Selected-depth Adam7 preflight computes checked pass/frame/output/work facts and charges once only after validation; exact limits pass, and rejected limits/capacity/arithmetic paths are atomic. | ✓ VERIFIED | `_png_encode_indexed_preflight_with_profile` performs dimensions, pixel, palette cap, selected-depth pass sums, Stored IDAT/frame facts, and all limits before its sole `budget.charge`. White-box tests assert 1/2/4 facts `22/33/122`, `24/35/132`, and `27/38/183`, exact work exhaustion, unchanged full budget snapshots on one-less output/work and palette overflow, and checked Adam7 pass arithmetic error. Public-entry tests additionally assert typed `output-bytes` rejection has writer position zero and unchanged budget for all three depths. |
| 5 | Scope remains the one-machine eager/preflight contract; hostile lease and collected-stream qualification remains Phase 84 work. | ✓ VERIFIED | Phase commits modify only the five planned PNG source/test files. The only added low-bit Adam7 chunk test drains one sufficient 256-byte lease and checks IHDR. It does not add zero/one/ragged schedules, tail checks, released lease replay, terminal lifecycle, or collected-stream parsing for Adam7 routes; those remain explicitly assigned to Phase 84. |

**Score:** 5/5 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- |
| `modules/mb-image/png/encode.mbt` | Selected low-bit interlace selector and selected-depth Adam7 preflight. | ✓ VERIFIED | Additive selector is a thin profile-mapped construction path; preflight generalizes the former Indexed8-only Adam7 branch while retaining the legacy `None` wrapper. |
| `modules/mb-image/png/stream_encode.mbt` | Thin low-bit interlace chunk selector and pass-local Adam7 byte provider in the existing machine. | ✓ VERIFIED | New selector creates the existing `PngEncodeMachine`; the scalar helper derives geometry per call and materializes no pass/image/output buffer. |
| `modules/mb-image/png/encode_test.mbt` and `encode_wbtest.mbt` | Independent wire/decode/freeze and exact admission evidence. | ✓ VERIFIED | Test-local literal source/raster/frame facts, CRC parsing, RGB/RGBA public decode, full budget snapshots, and public/white-box rejection checks are substantive and executed by the package gate. |
| `modules/mb-image/png/stream_encode_test.mbt` | Sufficient-capacity selected-depth Adam7 selector wiring smoke only. | ✓ VERIFIED | The added test loops One/Two/Four through the explicit selector and drains `[256UL]`, asserting Type-3 Adam7 IHDR. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- |
| Eager selected-depth facade | Sole indexed machine | `_png_indexed_wire_profile` → `PngEncodeMachine::new_with_indexed_profile(source, profile, interlace_strategy, ...)` | ✓ WIRED | Direct call in `encode.mbt`; legacy eager wrapper supplies `None`. |
| Chunk selected-depth facade | Sole indexed machine | Same profile mapper and constructor | ✓ WIRED | Direct call in `stream_encode.mbt`; legacy chunk wrapper supplies `None`. |
| Adam7 preflight and emitted bytes | Shared pass facts | `_png_adam7_passes(width, height, 1UL, depth)` | ✓ WIRED | Both the checked pass sum and `_png_indexed_adam7_scanline_byte` use the same selected profile depth, preventing frame totals from diverging from replay geometry. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Low-bit Adam7 scalar replay | `packed` output byte | Immutable `PngIndexedImage::index_at(pass.x + column * pass.dx, pass.y + row * pass.dy)` | Only visible local columns are shifted MSB-first; untouched tail slots retain the initialized zero value. | ✓ FLOWING |
| Admission facts | `scanlines`, `idat_length`, `frame.total_length`, `selected_work` | Selected-depth `_png_adam7_passes`, Stored IDAT facts, `PngFrameFacts` | Facts feed all output/work limit checks, then the single charge and machine construction. | ✓ FLOWING |
| External wire evidence | Eager encoded bytes | Public eager selector into writer | Literal test-local raster/framing assertions and public decoder consume produced PNG bytes rather than production packing helpers. | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Ordinary PNG package on all declared targets | `moon -C modules/mb-image test png --target all --frozen` | Mainline final evidence: **295/295 passed on each of wasm, wasm-gc, js, and native**. `moon.mod.json` declares exactly these four targets; no PNG source/test changed after commit `7549722`. | ✓ PASS |
| Literal selected-depth eager wire/decode behavior | Same package command; `PNG selected low-bit Adam7 eager wires literal packed passes and palette decode` | Included in the 295-per-target result; source inspection confirms raw bytes are test-local literals, not generated through production geometry or packers. | ✓ PASS |
| Exact preflight and public atomic rejection | Same package command; selected low-bit preflight and public preflight tests | Included in the 295-per-target result; tests assert all eight budget fields remain unchanged on rejection. | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- |
| INDEXLOWADAM7-01 | 83-01 | Additive Type-3/1, /2, /4 Adam7 eager/chunk selectors with explicit legacy non-interlaced forwards and frozen vectors. | ✓ SATISFIED | Thin shared-profile selectors plus legacy `None` forwards; sufficient-lease smoke and package vector coverage. |
| INDEXLOWADAM7-02 | 83-01 | Shared selected-depth geometry, local MSB-first packing/filter tags/tail zeros without staging or second encoder. | ✓ SATISFIED | Same `_png_adam7_passes` authority in preflight and replay; scalar local packer and 22/24/27 literal-raster evidence. |
| INDEXLOWADAM7-03 | 83-01 | Exact selected-depth Type-3 frame, actual PLTE/canonical tRNS, Stored raster/CRCs, and public palette decode. | ✓ SATISFIED | Independent parser checks every chunk and CRC plus all-coordinate RGBA and RGB decoding at every depth. |
| INDEXLOWADAM7-04 | 83-01 | Checked preflight, exact one-charge admission, and atomic limit/cap/arithmetic failures. | ✓ SATISFIED | Code ordering returns before the sole charge on validation errors; white-box and public tests prove exact / rejected accounting and zero writer progress. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- |
| — | — | No phase-introduced TODO/FIXME/XXX/HACK/placeholder, empty implementation, second machine, staging buffer, model widening, or prohibited strategy path. `git diff --check db90dbb^..7549722 -- modules/mb-image/png` is clean. | — | — |

### Scope and Compatibility Check

- Phase commits `db90dbb`, `555877e`, and `7549722` affect only the five planned PNG files; there is no FFI, wrapper, copied tree, release, decoder, public packed-source model, or additional strategy change.
- `PngEncodeMachine::new_with_indexed_profile` remains the sole machine constructor used by the added eager and chunk APIs. No pass, image, or output staging collection is created.
- Existing non-interlaced selected-depth APIs explicitly pass `None`; Type-3/8 Adam7 remains on its fixed profile path. The current head has no post-Phase-83 PNG source/test delta.
- The only dirty worktree item is a pre-existing unrelated Phase 66 research input; it was not modified.

## Gaps Summary

No implementation gap found. The original Phase 83 plan contained two inconsistent test literal details; the committed implementation corrected them to the actual stated source rows and MSB-first packing (`B1`, not `B4`, for depth 2), and the independent all-target test result validates the corrected oracle.

## VERDICT: PASS

All four Phase 83 requirements and the Phase 83/84 boundary are achieved in the current codebase. The admitted selected-depth Adam7 route is bounded, independently wire-qualified on eager output, atomic at preflight, and remains one-machine architecture.

---

_Verified: 2026-07-24T02:10:44Z_
_Verifier: the agent (gsd-verifier)_
