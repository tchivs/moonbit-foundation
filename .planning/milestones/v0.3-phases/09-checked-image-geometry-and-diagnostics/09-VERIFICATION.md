---
phase: 09-checked-image-geometry-and-diagnostics
verified: 2026-07-21T03:38:40Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 9: Checked Image Geometry and Diagnostics Verification Report

**Phase Goal:** Library users can safely crop, reorient, and resize images through composable portable APIs that report invalid work deterministically.
**Verified:** 2026-07-21T03:38:40Z
**Status:** passed
**Re-verification:** No — initial verification in the active Phase 9 directory

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A caller can crop a valid image to a fresh tightly packed owned result and gets typed, deterministic invalid-region/resource-limit errors rather than unsafe allocation or access. | ✓ VERIFIED | `geometry.mbt` validates capability, non-empty region, and source bounds before checked descriptor arithmetic and one `OwnedImage::new_operation` charge. Public and white-box tests assert non-aliasing, exact errors, overflowed `Rect` rejection, and unchanged complete `ResourceLimits` snapshots for every resource limit. |
| 2 | A caller can flip horizontally/vertically and request explicit clockwise 90°, 180°, or 270° rotations with correct pixels, dimensions, and metadata. | ✓ VERIFIED | `copy_flip.mbt` exports both flips; its exact-permutation tests run in the ops suite. `geometry.mbt` has distinct clockwise mappings for all three rotations, swaps 90°/270° dimensions, normalizes orientation to `TopLeft`, and reports the orientation disposition. RGB and RGBA coordinate-oracle tests exercise every channel. |
| 3 | A caller can resize through the documented deterministic integer-floor nearest-neighbor mapping and gets the same output on every supported target. | ✓ VERIFIED | `resize.mbt` computes `floor(destination * source_extent / destination_extent)` with checked multiplication and clamp. RGB and RGBA two-dimensional oracle tests cover every output channel; the README states the formula. The complete ops suite passed on js, wasm, wasm-gc, and native. |
| 4 | Unsupported pixel formats and incompatible/invalid geometry produce typed deterministic failures without partial budget consumption. | ✓ VERIFIED | Shared `supports_copy_flip` capability gate and `operation_error` generate `CapabilityUnavailable`, `InvalidDimensions`, `InvalidRange`, and budget errors. Tests assert operation/context tokens and full-budget atomicity for crop, all rotations, resize zero axes, unsupported formats, and each resource ceiling. |

**Score:** 4/4 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/ops/geometry.mbt` | Public checked crop and 90°/180°/270° rotations | ✓ VERIFIED | 277 substantive lines; public exports, checked descriptor construction, capability gate, allocation seam, and pixel-copy loops are exercised by the four-target suite. |
| `modules/mb-image/ops/geometry_test.mbt` | Black-box output, mapping, metadata, and diagnostic tests | ✓ VERIFIED | Covers fresh/tight crop, no aliasing, exact typed errors, RGB/RGBA rotations, metadata, budget and capability rejection. |
| `modules/mb-image/ops/geometry_wbtest.mbt` | Adversarial rectangles, capability, and atomic resource-limit tests | ✓ VERIFIED | Covers overflowing rectangle construction and every `ResourceLimits` field for crop/rotation rejection. |
| `modules/mb-image/ops/resize_convert_wbtest.mbt` | Two-dimensional nearest-neighbor floor-mapping regression | ✓ VERIFIED | RGB and straight-RGBA every-channel mapping oracles plus zero-axis, capability, and atomic budget witnesses. |
| `modules/mb-image/README.mbt.md` | Executable public geometry/resize contract | ✓ VERIFIED | Documents owned versus borrowed crop, explicit rotations versus `apply_orientation`, capability/budget diagnostics, and the exact nearest formula; compiled on all four targets. |
| `examples/ppm-portable/main/main.mbt` | Four-target public crop/rotation consumer | ✓ VERIFIED | Public PPM workflow calls `@ops.crop` then `@ops.rotate_90` with explicit budgets before downstream operations; exact deterministic output passed on all four targets. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `geometry.mbt` | `storage/owned_image.mbt` | validated descriptor → one authoritative charge → mutable output write | ✓ WIRED | `crop` and `new_rotation_output` call `OwnedImage::new_operation`; that constructor delegates the storage length, dimensions, pixels, and work to one charged owned-byte allocation. |
| `geometry.mbt` | `copy_flip.mbt` | shared capability/error/result/disposition helpers | ✓ WIRED | Direct uses of `supports_copy_flip`, `operation_error`, `ImageOperationResult`, and `preserve_all_disposition`; rotations reuse orientation normalization/disposition helpers. |
| `README.mbt.md` | geometry public API | executable documentation invokes checked crop/rotation | ✓ WIRED | The checked block calls `@ops.crop` at line 222 and `@ops.rotate_90` at line 229, both with caller-owned budgets; all-target `mbt check` passed. |
| `examples/ppm-portable/main/main.mbt` | geometry public API | public composition crop → rotate before later raster/codec stages | ✓ WIRED | Lines 88–89 call `@ops.crop` then `@ops.rotate_90`; the four target runs validated selected rotated pixels and a complete encoded PPM oracle. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `geometry.mbt` | destination pixels | `ImageView.get_byte` from caller-supplied source region | Yes — selected source bytes are copied into a fresh owned output | ✓ FLOWING |
| `resize.mbt` | destination pixels | source coordinates computed from checked floor mapping then `ImageView.get_byte` | Yes — RGB/RGBA output is compared against independent coordinate oracles | ✓ FLOWING |
| `ppm-portable/main.mbt` | PPM output | decoded foreground/background → crop → rotate → processing → encoder | Yes — complete 29-byte output, semantic pixels, digest, and SHA identity are asserted | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Crop, flips, rotations, resize, and diagnostics on js | `moon test modules/mb-image/ops --target js` | 41 passed, 0 failed | ✓ PASS |
| Same ops behavior on wasm | `moon test modules/mb-image/ops --target wasm` | 41 passed, 0 failed | ✓ PASS |
| Same ops behavior on wasm-gc | `moon test modules/mb-image/ops --target wasm-gc` | 41 passed, 0 failed | ✓ PASS |
| Same ops behavior on native | `moon test modules/mb-image/ops --target native` | 41 passed, 0 failed | ✓ PASS |
| Public docs and PPM crop/rotation consumer on js/wasm/wasm-gc/native | `moon -C modules/mb-image check README.mbt.md --target <target> --frozen`; `moon -C examples/ppm-portable run main --target <target> --frozen` | Each README compilation succeeded; each run emitted the exact expected 29-byte PPM identity (`digest=714923673`, SHA-256 `005700…be78bf`) | ✓ PASS |

### Probe Execution

Step 7c: SKIPPED — Phase 9 declares no probe script, PASS marker, or migration/tooling probe.

### Requirements Coverage

The current top-level requirements file is for v0.7 PNG colour work; Phase 9’s authoritative historical requirements are in `.planning/milestones/v0.3-REQUIREMENTS.md`.

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| GEOM-01 | 09-01 | Checked rectangular crop without out-of-bounds access or overflow-driven allocation | ✓ SATISFIED | Truth 1; preflight bounds/checked arithmetic, one charged allocation seam, exact public and adversarial tests. |
| GEOM-02 | 09-01 | Flips and right-angle rotation preserve pixel semantics | ✓ SATISFIED | Truth 2; existing exact flip permutations plus direct 90°/180°/270° RGB/RGBA coordinate oracles. |
| GEOM-03 | 09-01 | Documented deterministic nearest-neighbor resize across all supported targets | ✓ SATISFIED | Truth 3; checked floor-mapping implementation, RGB/RGBA two-dimensional evidence, README formula, four-target suite. |
| RASTER-03 | 09-01 | Typed deterministic unsupported-format, invalid-geometry, and resource-limit errors | ✓ SATISFIED | Truth 4; exact diagnostic token tests and full `ResourceLimits` atomicity checks. |

No Phase 9 requirement is orphaned: all four historical Phase 9 IDs are declared in the active plan and mapped to Phase 9 in the v0.3 traceability table.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| — | — | No `TBD`, `FIXME`, `XXX`, placeholder, empty implementation, or hardcoded-output stub pattern found in Phase 9 artifacts. | — | None |

### Gaps Summary

None. The initial disconfirmation pass found no partially implemented success criterion, misleading test, or untested error path within the phase contract: the source is substantive, the allocation/capability/public-consumer links are live, and behavior-dependent contracts have four-target test evidence. The generic key-link query did not recognize two escaped-regex patterns, but direct source inspection and executable README/consumer checks prove both public links.

---

_Verified: 2026-07-21T03:38:40Z_
_Verifier: the agent (gsd-verifier)_
