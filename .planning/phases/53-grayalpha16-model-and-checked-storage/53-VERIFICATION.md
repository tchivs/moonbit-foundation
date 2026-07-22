---
phase: 53-grayalpha16-model-and-checked-storage
verified: 2026-07-22T20:37:57Z
status: passed
score: 3/3 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 53: GrayAlpha16 Model and Checked Storage Verification Report

**Phase Goal:** Library users can create and inspect packed U16 grayscale-plus-alpha images with explicit straight-alpha semantics while existing image descriptor and storage behavior remains unchanged.
**Verified:** 2026-07-22T20:37:57Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A library user can create a packed U16 image with exactly one gray and one straight-alpha component and inspect its canonical descriptor metadata. | ✓ VERIFIED | `ImageFormat::graya16()` is public and fixes `U16`/`GrayAlpha`/`Packed`/`Little` at `modules/mb-image/model/descriptor.mbt:90`. `ImageDescriptor::new` wires strict alpha and GrayAlpha identity validation before plane allocation (`:625-637`); the identity permits only U8 or U16 plus packed/little/encoded builtin-sRGB/top-left facts (`:465-515`). The focused public descriptor test passes on wasm, wasm-gc, JS, and native. |
| 2 | A library user can read and write both bytes of distinct gray and alpha U16 components through checked generic packed-image storage views. | ✓ VERIFIED | Plane validation derives four bytes from `bytes_per_component() * channel_count()` (`descriptor.mbt:549-575`). The generic immutable and mutable component paths bound-check both channel and intra-component byte, then address with `channel * bytes_per_component + component_byte` (`storage/views.mbt:240-295,477-547`). The focused storage test writes `34/12` and `C5/A7` to real `OwnedImage` backing, reads all four bytes, and rejects channel 2, byte 2, and U16 `get_byte` (`storage_test.mbt:219-236`); it passes on all four targets. |
| 3 | Existing Gray, GrayAlpha8, RGB, and RGBA descriptors, storage access, and observable operations retain their prior behavior, while malformed or incompatible GrayAlpha16 descriptors are rejected. | ✓ VERIFIED | The Phase-53 diff changes only the factory/identity predicate and accompanying tests; no later commit changes model, storage, view, or copy/flip seams. The invalid matrix rejects missing/premultiplied alpha, F32, planar, big-endian, non-encoded transfer, non-builtin profile, rotated orientation, and malformed row bytes (`model_test.mbt:297-432`). Existing Gray16, GrayAlpha8, RGB8, and RGBA8 controls remain in the same all-target suites. `supports_reference_operations` remains explicitly false for `GrayAlpha` (`descriptor.mbt:741-755`) and copy/flip remains fail-closed before budget use (`ops/copy_flip.mbt:50-69,170-188`; tested at `copy_flip_test.mbt:201-230`). |

**Score:** 3/3 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/model/descriptor.mbt` | Public `graya16` factory and exact U8-or-U16 GrayAlpha admission. | ✓ VERIFIED | Exists, substantive, and is on the public `ImageDescriptor::new` path. `verify.artifacts` reports no issues. |
| `modules/mb-image/model/model_test.mbt` | Public canonical descriptor, malformed-identity, and legacy-behavior regressions. | ✓ VERIFIED | Exists, substantive, and its focused GrayAlpha16 descriptor test passes on wasm, wasm-gc, JS, and native. |
| `modules/mb-image/storage/storage_test.mbt` | Checked GrayAlpha16 U16 component-byte storage regression. | ✓ VERIFIED | Exists, substantive, and operates on allocated backing through mutable then immutable public views; it has no empty or hard-coded-output data path. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `model/descriptor.mbt` | `storage/storage_test.mbt` | Descriptor-derived component size and channel count form the packed stride used by generic checked views. | ✓ WIRED | `validate_plane_shape` checked-multiplies the component byte width and channel count, and view offsets use the equivalent `bytes_per_component * channel_count` calculation. The real four-byte read/write test proves the link end-to-end. The automated key-link query reported a literal-pattern miss because the source uses checked multiplication rather than the plan's literal expression; manual source and behavioral evidence resolve it. |
| `model/descriptor.mbt` | `ops/copy_flip.mbt` | `GrayAlpha => false` retains the reference/copy boundary. | ✓ WIRED | Both descriptor reference support and copy/flip retain explicit `GrayAlpha => false` branches. Copy rejects before allocation/budget work, exercised by its named all-target test. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- |
| `storage/storage_test.mbt` | Gray and alpha U16 component bytes | `graya16_descriptor()` → `OwnedImage::new` → `with_mut_view` → immutable `ImageView` | Four non-symmetric bytes persist in allocated backing and are read back via calculated checked offsets. | ✓ FLOWING |
| `model/model_test.mbt` | Valid/invalid descriptor results | Public `ImageDescriptor::new` validation path | The test constructs canonical and malformed metadata/plane objects and asserts the returned result/error category. | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Full Phase-53 model, storage, and operation contract on every supported target | `moon test --target all modules/mb-image/model modules/mb-image/storage modules/mb-image/ops` | 81 passed, 0 failed on each of wasm, wasm-gc, JS, and native. | ✓ PASS |
| U16 GrayAlpha mutable-to-immutable byte transition and bounds failures | `moon test --target all modules/mb-image/storage --filter '*GrayAlpha16 component byte pairs*'` | 1 passed on each target. | ✓ PASS |
| Canonical U16 GrayAlpha public descriptor construction | `moon test --target all modules/mb-image/model --filter '*GrayAlpha16 is a packed two-component straight-alpha descriptor*'` | 1 passed on each target. | ✓ PASS |
| Existing fail-closed GrayAlpha copy boundary | `moon test --target all modules/mb-image/ops --filter '*copy rejects GrayAlpha before consuming operation budget*'` | 1 passed on each target. | ✓ PASS |
| Workspace compilation across all targets | `moon check --target all` | Exit 0; warnings are in existing PNG sources outside the three Phase-53 modified files. | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| GRAYA16-01 | `53-01-PLAN.md` | A user can create and inspect packed U16 grayscale-plus-alpha with one gray and one straight-alpha component, without changing Gray, GrayAlpha8, RGB, or RGBA descriptor/storage behavior. | ✓ SATISFIED | Truths 1–3 prove public construction, strict malformed-input rejection, real checked backing access, retained legacy controls, and the fail-closed operations boundary. `REQUIREMENTS.md` maps this sole Phase-53 requirement to Phase 53; no orphaned Phase-53 requirement exists. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| — | — | No `TBD`, `FIXME`, `XXX`, `TODO`, placeholder, empty implementation, or hard-coded empty-output pattern in the three Phase-53 modified files. | ℹ️ Info | No completion-blocking stub or debt marker found. |

### Disconfirmation Checks

- **Over-broad admission:** falsified. The new predicate is the explicit two-value U8/U16 set, not a generic non-U8 allowance; the malformed F32/layout/endian/metadata matrix executes on every target.
- **Misleading storage test:** falsified. It mutates allocated backing with four distinct values across both channels and byte positions, then obtains the values through a separate immutable view. Symmetric-value and single-channel false positives are excluded.
- **Lost operation boundary:** falsified. The GrayAlpha false branches are still present in both reference and copy capability gates, and the copy rejection test proves budget non-consumption.
- **Regression after submission:** falsified. `git diff --name-status 079a18e..HEAD` is empty for the model, storage, view, and copy/flip seams; the current all-target suite passes.

### Gaps Summary

No gaps found. The only automated key-link warning was a literal text-pattern mismatch; source-level data-flow inspection and a four-target behavioral storage test prove the intended checked-stride connection. The security report's T-53-05 is an explicitly non-blocking evidence-record observation, not a missing model, storage, validation, or operation mitigation.

---

_Verified: 2026-07-22T20:37:57Z_
_Verifier: the agent (gsd-verifier)_
