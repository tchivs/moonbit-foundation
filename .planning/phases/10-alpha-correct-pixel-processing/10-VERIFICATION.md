---
phase: 10-alpha-correct-pixel-processing
verified: 2026-07-20T08:21:53Z
status: gaps_found
score: 0/4 must-haves verified
behavior_unverified: 3
overrides_applied: 0
gaps:
  - truth: "The same public and adversarial processing behavior passes on js, wasm, wasm-gc, and native."
    status: failed
    reason: "All four target suites report 31/31 passing, but only three Phase 10 processing tests exist. They do not exercise the promised independent linear-premultiplied/ties-even oracle, composite metadata rejection policy, unsupported representation cases, blur overflow, or every budget ceiling. The passing count therefore cannot establish the stated public and adversarial behavior."
    artifacts:
      - path: "modules/mb-image/ops/processing_test.mbt"
        issue: "One smoke test covers opaque source-over, equal grayscale channels, and radius-zero identity only; no translucent exact-output or metadata-policy behavior test."
      - path: "modules/mb-image/ops/processing_wbtest.mbt"
        issue: "Two tests cover unequal dimensions and one halo fixture; no independent conversion/quantization oracle or hostile-input/complete-budget matrix."
    missing:
      - "Independent decode → linear → premultiply → source-over / Rec.709 / blur → unpremultiply → encode → ties-even reference-oracle tests."
      - "Metadata, capability, radius-overflow, and every resource-ceiling rejection tests asserting an unchanged complete Budget.remaining snapshot."
behavior_unverified_items:
  - truth: "A caller can composite equal-size straight encoded-sRGB RGBA8 images with source-over calculated in linear-premultiplied space and receive the documented straight output and metadata boundary."
    test: "Run independent translucent-source and nontrivial-destination vector tests, plus each metadata incompatibility, against composite_source_over."
    expected: "Exact ties-even RGBA bytes match the independent linear-premultiplied oracle; only built-in-sRGB/equal-orientation/empty-opaque pairs succeed and output retains the documented metadata/disposition."
    why_human: "The implementation is wired to typed transfer and quantization helpers, but the existing opaque-only test cannot distinguish it from an encoded-space shortcut or prove the metadata rejection boundary."
  - truth: "A caller can apply deterministic Rec.709 grayscale and clamp-to-edge alpha-aware box blur without transparent-color halos."
    test: "Exercise nontrivial RGB/alpha grayscale and multi-pixel edge blur vectors whose expected values are independently calculated in linear-premultiplied space."
    expected: "Rec.709 bytes and clamp-to-edge output match the oracle; transparent saturated samples contribute no visible straight-color halo."
    why_human: "The code contains the coefficients and clamp logic, but no test independently proves their numeric result or edge sampling pattern."
  - truth: "Unsupported representations, incompatible metadata/extents, overflowing blur work, and insufficient resources return typed CoreError values without changing the caller budget; radius zero is identity."
    test: "Invoke every operation with unsupported layout/component/channel/transfer/alpha, metadata incompatibilities, overflowing radius arithmetic, and each budget ceiling; compare all remaining counters before and after."
    expected: "Each input fails with the documented typed error before allocation/charge, while radius zero returns an exact identity image."
    why_human: "Only incompatible-dimension atomicity is tested; the other error and resource transitions are not behaviorally exercised."
---

# Phase 10: Alpha-Correct Pixel Processing Verification Report

**Phase Goal:** Library users can compose and filter RGBA images with stable alpha and resource semantics.
**Verified:** 2026-07-20T08:21:53Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A caller can composite compatible straight encoded-sRGB RGBA8 images through linear-premultiplied source-over and receive the documented new straight RGBA8 result/metadata. | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | `processing.mbt` decodes with `@transfer.decode_srgb`, premultiplies typed normalized pixels, applies `source + destination * (1-source alpha)`, then unpremultiplies, encodes, and `@quantize.quantize_*`s ([processing.mbt](D:/source/moonbit-foundation/modules/mb-image/ops/processing.mbt:70), [processing.mbt](D:/source/moonbit-foundation/modules/mb-image/ops/processing.mbt:123)). The only composite test is opaque-source smoke coverage, so it cannot prove alpha math or quantization. |
| 2 | A caller can apply deterministic Rec.709 grayscale and clamp-to-edge, alpha-aware box blur without transparent-color halos. | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Implementation uses `0.2126/0.7152/0.0722`, typed linear-premultiplied averages, and clamp logic ([processing.mbt](D:/source/moonbit-foundation/modules/mb-image/ops/processing.mbt:161), [processing.mbt](D:/source/moonbit-foundation/modules/mb-image/ops/processing.mbt:180)). Existing tests only prove equal grayscale channels, radius-zero identity, and one no-halo fixture—not Rec.709 or clamp output values. |
| 3 | Invalid representations, metadata/extents, overflowing blur work, and budget shortages fail deterministically without budget mutation; radius zero is valid. | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Capability, dimension, metadata, checked radius/window/work, and preflight paths exist before `OwnedImage::new_operation` ([processing.mbt](D:/source/moonbit-foundation/modules/mb-image/ops/processing.mbt:108), [processing.mbt](D:/source/moonbit-foundation/modules/mb-image/ops/processing.mbt:180)). Only incompatible-dimension budget atomicity is exercised. |
| 4 | The same public and adversarial processing behavior passes on js, wasm, wasm-gc, and native. | ✗ FAILED | Each target reports `31/31`, but Phase 10 contributes only three processing tests; the planned adversarial oracle/error matrix is absent. Passing unrelated prior operations cannot prove this truth. |

**Score:** 0/4 truths verified (3 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/ops/processing.mbt` | Public source-over, grayscale, box-blur, and typed linear-premultiplied helpers | ✓ VERIFIED | 218 substantive lines; exported in the `ops` package and called by tests/README. No encoded-space `premultiply_encoded` or `unpremultiply_encoded` call occurs in this operation path. |
| `modules/mb-image/ops/processing_test.mbt` | Black-box raster-operation behavior and metadata tests | ⚠️ PARTIAL | Exists and is wired, but its sole test omits translucent source-over bytes and metadata-policy rejection behavior. |
| `modules/mb-image/ops/processing_wbtest.mbt` | Independent alpha/quantization, hostile-input, atomic-budget tests | ✗ STUB | Exists but implements only two narrow tests; it lacks the independent oracle and the hostile-input/full-budget coverage it claims to provide. |
| `modules/mb-image/README.mbt.md` | Stable processing contract and checked usage example | ✓ VERIFIED | Documents exact processing boundary and provides a public grayscale/blur example ([README.mbt.md](D:/source/moonbit-foundation/modules/mb-image/README.mbt.md:181)); all four `mbt check` runs exit 0. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `processing.mbt` | `tchivs/mb-color/transfer`, `tchivs/mb-color/quantize` | Typed decode/encode and byte conversion | ✓ WIRED | Package imports both ([moon.pkg](D:/source/moonbit-foundation/modules/mb-image/ops/moon.pkg:9)); `load_linear_premultiplied`/`store_linear_premultiplied` call the typed helpers. |
| `processing.mbt` | `storage/owned_image.mbt` | Preflight → one `OwnedImage::new_operation` → `with_mut_view` | ✓ WIRED | `allocate_processing` preflights then allocates once ([processing.mbt](D:/source/moonbit-foundation/modules/mb-image/ops/processing.mbt:108)); all operations write only inside `with_mut_view`. |
| `processing.mbt` | image/model metadata and profile contracts | Composite compatibility gate and source metadata output descriptor | ✓ WIRED | Rejects non-built-in profiles, mismatched orientation, and nonempty opaque metadata before allocation ([processing.mbt](D:/source/moonbit-foundation/modules/mb-image/ops/processing.mbt:131)). |
| processing tests | processing public APIs | Direct calls | ⚠️ PARTIAL | All three APIs are called, but behavioral coverage is insufficient for the asserted contract. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `processing.mbt` | Per-pixel premultiplied linear RGBA | Caller `ImageView` bytes → dequantize/decode/premultiply | Caller-supplied data, no static fallback | ✓ FLOWING |
| `processing.mbt` | Output RGBA bytes | Calculated premultiplied result → unpremultiply/encode/ties-even quantize → mutable output view | Fully computed for every output pixel | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| `ops` suite on js | `moon test modules/mb-image/ops --target js` | 31 passed, 0 failed | ✓ PASS |
| Same suite on wasm | `moon test modules/mb-image/ops --target wasm` | 31 passed, 0 failed | ✓ PASS |
| Same suite on wasm-gc | `moon test modules/mb-image/ops --target wasm-gc` | 31 passed, 0 failed | ✓ PASS |
| Same suite on native | `moon test modules/mb-image/ops --target native` | 31 passed, 0 failed | ✓ PASS |
| README examples | `moon -C modules/mb-image check README.mbt.md --target js|wasm|wasm-gc|native --frozen` | All four exit 0 (native emits only upstream unused-value warnings) | ✓ PASS |

### Probe Execution

SKIPPED — no Phase 10 probe is declared and no conventional `probe-*.sh` was found.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| RASTER-01 | 10-01 | Alpha-correct documented RGBA source-over | ✗ BLOCKED | Implementation/wiring is present, but no behavioral evidence distinguishes linear-premultiplied source-over from an encoded-space shortcut; required public/adversarial coverage is absent. |
| RASTER-02 | 10-01 | Deterministic grayscale and checked, bounded box blur | ✗ BLOCKED | Algorithm paths are present, but the promised independent Rec.709/clamp/quantization and resource-boundary tests are absent. |

No orphaned Phase 10 requirements: RASTER-01 and RASTER-02 both appear in `10-01-PLAN.md`.

### Anti-Patterns Found

No `TBD`, `FIXME`, `XXX`, `TODO`, `HACK`, placeholder, or empty-implementation marker was found in Phase 10's modified implementation, tests, or README. The blocker is incomplete behavioral evidence, not a debt-marker issue.

### Human Verification Required

The three behavior-unverified items in frontmatter remain relevant after automated gap closure; they are intentionally retained so a future re-verification cannot silently pass symbol presence as runtime proof.

### Gaps Summary

The implementation is substantive and its source-level data flow matches the intended linear-premultiplied design. However, Phase 10's executable contract was not actually delivered: `processing_test.mbt` and `processing_wbtest.mbt` contain only three narrow tests, while the plan required independent conversion/quantization oracles and comprehensive typed-error/atomic-budget checks. The four target `31/31` results are real but do not establish RASTER-01 or RASTER-02 because the required cases are absent. This is a blocker until those tests are added and pass on all four targets.

---

_Verified: 2026-07-20T08:21:53Z_
_Verifier: the agent (gsd-verifier)_
