---
phase: 10-alpha-correct-pixel-processing
verified: 2026-07-20T08:24:41Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 0/4
  gaps_closed:
    - "Independent linear-premultiplied/ties-even source-over and Rec.709 oracle evidence."
    - "Composite metadata/capability rejection, blur-overflow, and complete budget-atomicity coverage."
    - "Four-target evidence for the added processing behavior tests."
  gaps_remaining: []
  regressions: []
---

# Phase 10: Alpha-Correct Pixel Processing Verification Report

**Phase Goal:** Library users can compose and filter RGBA images with stable alpha and resource semantics.
**Verified:** 2026-07-20T08:24:41Z
**Status:** passed
**Re-verification:** Yes — after gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A caller can composite one RGBA image over another with documented source-over alpha behavior and predictable output pixels. | ✓ VERIFIED | The production path is byte dequantization → sRGB decode → linear premultiply → source-over → unpremultiply → sRGB encode → ties-even quantization ([processing.mbt](D:/source/moonbit-foundation/modules/mb-image/ops/processing.mbt:70), [processing.mbt](D:/source/moonbit-foundation/modules/mb-image/ops/processing.mbt:123)). The test-local translucent oracle produces fixed `b3 33 5d c4` independently of production private helpers, and the public API returns those bytes with source-over operand order ([processing_wbtest.mbt](D:/source/moonbit-foundation/modules/mb-image/ops/processing_wbtest.mbt:127), [processing_wbtest.mbt](D:/source/moonbit-foundation/modules/mb-image/ops/processing_wbtest.mbt:180), [processing_test.mbt](D:/source/moonbit-foundation/modules/mb-image/ops/processing_test.mbt:109)). |
| 2 | A caller can apply grayscale deterministically without changing documented alpha semantics. | ✓ VERIFIED | `grayscale` applies the documented linear Rec.709 coefficients before shared straight-output storage ([processing.mbt](D:/source/moonbit-foundation/modules/mb-image/ops/processing.mbt:161)). A test-local oracle and public fixed vector prove `97 97 97 60`, including preserved alpha ([processing_wbtest.mbt](D:/source/moonbit-foundation/modules/mb-image/ops/processing_wbtest.mbt:142), [processing_test.mbt](D:/source/moonbit-foundation/modules/mb-image/ops/processing_test.mbt:122)). |
| 3 | A caller can apply a checked, bounded, deterministic box blur. | ✓ VERIFIED | `box_blur` calculates radius/window/work with checked arithmetic before its sole allocation, samples clamp-to-edge in linear-premultiplied space, and writes a fully calculated output ([processing.mbt](D:/source/moonbit-foundation/modules/mb-image/ops/processing.mbt:180)). Exact two-pixel edge bytes, radius-zero identity, transparent-color halo prevention, overflow rejection, and insufficient-work handling are exercised ([processing_test.mbt](D:/source/moonbit-foundation/modules/mb-image/ops/processing_test.mbt:128), [processing_wbtest.mbt](D:/source/moonbit-foundation/modules/mb-image/ops/processing_wbtest.mbt:60), [processing_wbtest.mbt](D:/source/moonbit-foundation/modules/mb-image/ops/processing_wbtest.mbt:241)). |
| 4 | All documented processing behavior is portable across js, wasm, wasm-gc, and native. | ✓ VERIFIED | `ops` declares all four targets ([moon.pkg](D:/source/moonbit-foundation/modules/mb-image/ops/moon.pkg:16)); the current suite is `35/35` on each target and README checks pass on each target. |

**Score:** 4/4 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/ops/processing.mbt` | Source-over, grayscale, box blur, typed linear-premultiplied conversion | ✓ VERIFIED | Substantive, exported, and all data originates in caller image bytes. It imports and uses transfer/quantization helpers; no encoded-space `premultiply_encoded` / `unpremultiply_encoded` shortcut occurs in the processing route. |
| `modules/mb-image/ops/processing_test.mbt` | Public translucent output, metadata boundary, grayscale, and edge-blur assertions | ✓ VERIFIED | Three substantive public tests call all APIs, assert exact fixed vectors and source-over order, plus complete metadata mismatch budget snapshots. |
| `modules/mb-image/ops/processing_wbtest.mbt` | Independent color/quantization oracle and hostile-input/complete-budget matrix | ✓ VERIFIED | Test-local source-over/grayscale conversion pipeline does not call `processing.mbt` private helpers; capability variants, extent mismatch, two radius-overflow paths, and every charged resource ceiling compare bytes, allocations, allocation size, width, height, pixels, depth, and work. |
| `modules/mb-image/README.mbt.md` | Stable public processing contract and checked usage example | ✓ VERIFIED | Documents linear-premultiplied source-over, strict metadata policy, Rec.709, clamp-to-edge alpha-aware blur, radius-zero identity, and resource behavior ([README.mbt.md](D:/source/moonbit-foundation/modules/mb-image/README.mbt.md:181)). |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `processing.mbt` | `tchivs/mb-color/transfer`, `tchivs/mb-color/quantize` | Typed decode/encode and deterministic byte conversion | ✓ WIRED | Declared imports and direct calls in common load/store helpers; those helpers surround every composite/filter calculation. |
| `processing.mbt` | `storage/owned_image.mbt` | Preflight → one `OwnedImage::new_operation` → `with_mut_view` | ✓ WIRED | Validation and resource preflight precede allocation; all three APIs allocate through the authoritative boundary and write in its mutable-view lease. |
| `processing.mbt` | model/profile/metadata | Strict composite metadata gate and retained compatible source metadata | ✓ WIRED | Built-in profile, equal orientation, and empty opaque metadata are required before allocation ([processing.mbt](D:/source/moonbit-foundation/modules/mb-image/ops/processing.mbt:131)); public tests verify each incompatible variant. |
| processing tests | public processing APIs | Direct calls plus independently computed/fixed expectations | ✓ WIRED | Tests invoke `composite_source_over`, `grayscale`, and `box_blur`; all execute in each supported target suite. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `processing.mbt` | Linear-premultiplied RGBA | Caller `ImageView` → typed bytes/dequantization/decode/premultiply | No static/fallback data | ✓ FLOWING |
| `processing.mbt` | Output encoded RGBA | Source-over, luminance, or blur average → unpremultiply/encode/ties-even → output view | Every output pixel is computed and stored | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Processing and adjacent ops on js | `moon test modules/mb-image/ops --target js` | 35 passed, 0 failed | ✓ PASS |
| Same behavior on wasm | `moon test modules/mb-image/ops --target wasm` | 35 passed, 0 failed | ✓ PASS |
| Same behavior on wasm-gc | `moon test modules/mb-image/ops --target wasm-gc` | 35 passed, 0 failed | ✓ PASS |
| Same behavior on native | `moon test modules/mb-image/ops --target native` | 35 passed, 0 failed | ✓ PASS |
| Checked module documentation | `moon -C modules/mb-image check README.mbt.md --target js|wasm|wasm-gc|native --frozen` | All four commands exited 0 | ✓ PASS |

### Probe Execution

SKIPPED — no Phase 10 probe is declared and no conventional processing probe exists.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| RASTER-01 | 10-01, 10-02 | Documented alpha-correct RGBA source-over | ✓ SATISFIED | Typed linear-premultiplied source, fixed translucent-byte oracle, operand-order and strict metadata/capability behavior tests, all four targets. |
| RASTER-02 | 10-01, 10-02 | Deterministic grayscale and checked bounded box blur | ✓ SATISFIED | Rec.709 fixed vector, clamp-to-edge/halo/radius-zero vectors, checked overflow and complete resource-budget rejection matrix, all four targets. |

No orphaned Phase 10 requirements: both RASTER IDs are declared by the Phase 10 plans.

### Anti-Patterns Found

No blocker or warning markers were found in the Phase 10 processing implementation, tests, or README. No source, package, docs, release, or publication artifact was altered by the gap-closure commits: `341d517` changes only `processing_wbtest.mbt`; `f736523` changes only `processing_test.mbt`.

### Commit-Scope Check

`9003d9a` was not accepted as evidence: it deleted unrelated release/publication artifacts. `83d38ce` fully reverses that deletion, and `f897a4c` restores only the legitimate `10-02-SUMMARY.md`. The functional evidence comes from the clean test-only commits `341d517` and `f736523`, inspected directly above.

### Gaps Summary

None. The prior verification gaps are closed with executable four-target evidence. Phase 10 achieves RASTER-01 and RASTER-02 and is ready for its Phase 11 integration/evidence work.

---

_Verified: 2026-07-20T08:24:41Z_
_Verifier: the agent (gsd-verifier)_
