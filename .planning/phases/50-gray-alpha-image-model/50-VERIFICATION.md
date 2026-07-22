---
phase: 50-gray-alpha-image-model
verified: 2026-07-22T17:33:17Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 50: Gray+Alpha Image Model Verification Report

**Phase Goal:** Library users can create and inspect a packed U8 grayscale-plus-alpha image with explicit straight-alpha semantics without changing existing Gray, RGB, or RGBA behavior.
**Verified:** 2026-07-22T17:33:17Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A library user can create a packed U8 grayscale-plus-alpha image with exactly one gray and one alpha component. | ✓ VERIFIED | `ImageFormat::graya8()` constructs `U8`/`GrayAlpha`/`Packed`/little-endian; `channel_count()` returns `2` in `modules/mb-image/model/descriptor.mbt:79-85,119-125`. The public black-box descriptor test constructs it with one 4-byte packed plane for two pixels and asserts all layout facts in `model_test.mbt:235-258`; it passed on all four targets. |
| 2 | A library user can inspect explicit straight-alpha metadata for the two-component format. | ✓ VERIFIED | `validate_alpha_identity` accepts GrayAlpha only with `Some(Straight)`, and `validate_gray_alpha_identity` additionally requires packed U8, little-endian, sRGB/encoded-sRGB, builtin sRGB, and top-left metadata (`descriptor.mbt:458-507`). The public test asserts straight alpha and builtin sRGB and rejects missing alpha, premultiplied alpha, U16, planar, linear transfer, non-builtin profile, and rotated variants (`model_test.mbt:259-347`). |
| 3 | Generic owned storage and checked views retain distinct gray and alpha bytes, with a third channel rejected. | ✓ VERIFIED | `OwnedImage::new` consumes the validated descriptor; `ImageView` and `MutImageView` derive bounds and offsets from `format.channel_count()` and `bytes_per_component()` (`storage/views.mbt:182-224,409-473`). The public storage test writes four non-symmetric bytes (`13/E7/C1/2A`), reads the same component locations, and observes channel 2 as an error (`storage_test.mbt:179-194`). |
| 4 | Existing Gray, RGB, and RGBA behavior remains compatible while GrayAlpha is outside current reference and copy/flip capabilities. | ✓ VERIFIED | The only production behavior changes are additive enum/factory/validation paths and explicit `GrayAlpha => false` branches. Existing RGB and RGBA admission expressions are unchanged; public legacy controls retain RGB reference support and premultiplied-RGBA support (`model_test.mbt:187-231`). GrayAlpha returns false from `supports_reference_operations` (`descriptor.mbt:730-744`) and copy/flip rejects it before allocation or budget use (`copy_flip.mbt:50-69,171-184`; public test `copy_flip_test.mbt:201-229`). Other public operation families are closed by the same `supports_copy_flip` predicate or their existing RGBA-only predicate. |

**Score:** 4/4 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/model/descriptor.mbt` | Public order/factory, descriptor admission, component count, and reference-operation rejection. | ✓ VERIFIED | Exists and substantive (the artifact verifier reports no issues). It exposes the public `GrayAlpha` enum case and `graya8`, centralizes two components in `channel_count`, validates the locked identity, and returns false at the reference boundary. |
| `modules/mb-image/storage/storage_test.mbt` | Public generic packed-storage and checked two-component view regression. | ✓ VERIFIED | Exists and substantive (artifact verifier: no issues). The black-box test allocates an actual `OwnedImage`, mutates through `MutImageView`, observes through `ImageView`, and checks the out-of-range component. |
| `modules/mb-image/ops/copy_flip_test.mbt` | Typed existing-operation rejection regression for GrayAlpha. | ✓ VERIFIED | Exists and substantive (artifact verifier: no issues). It asserts `CapabilityUnavailable`, the established `image-copy-format` context, and unchanged bytes/allocations/work/pixels. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `model/descriptor.mbt` | `storage/storage_test.mbt` | `channel_count` drives packed plane shape and checked view addressing. | ✓ WIRED | `ImageDescriptor::new` derives packed plane shape from `channel_count`; views use the same value for channel bounds and pixel stride; the storage test exercises the resulting allocation and reads. The declared key-link verifier also returned `verified: true`. |
| `model/descriptor.mbt` | `ops/copy_flip.mbt` | Channel-order-specific capability decision is fail-closed for GrayAlpha. | ✓ WIRED | `supports_reference_operations` and `supports_copy_flip` contain explicit `GrayAlpha => false` branches; `copy_image` calls the latter before descriptor/output allocation. The declared key-link verifier returned `verified: true`. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `storage/storage_test.mbt` | packed component bytes | `graya8_descriptor()` → `OwnedImage::new` → mutable/immutable checked views | The test writes and reads concrete non-symmetric bytes through the real owned backing; no fixture, empty prop, or static response substitutes for storage. | ✓ FLOWING |
| `ops/copy_flip_test.mbt` | operation budget and result | valid `OwnedImage` view → `copy_image` capability gate | The source is a real validated GrayAlpha image; the gate returns typed rejection before any output allocation or budget consumption. | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Public model, generic view, legacy, and operation-boundary regressions on every supported target | `moon test --target all modules/mb-image/model modules/mb-image/storage modules/mb-image/ops` | 79 passed / 0 failed on wasm, wasm-gc, js, and native | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- |
| GRAYA-01 | `50-01-PLAN.md` | A user can create and inspect a packed U8 grayscale-plus-alpha image with exactly two components and explicit straight-alpha metadata, while existing Gray/RGB/RGBA descriptors, views, storage, and operations retain behavior. | ✓ SATISFIED | Truths 1–4 above cover the public descriptor/factory, locked straight-alpha admission, real generic storage/view read/write behavior, preserved legacy branches/regressions, and explicit operation rejection. The four-target package test passed independently. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| — | — | No `TBD`, `FIXME`, `XXX`, `TODO`, placeholder, empty implementation, or hardcoded-empty-output pattern found in phase-modified code. | ℹ️ Info | No completion-blocking debt marker or stub evidence found. |

### Scope and Disconfirmation Checks

- No prior `50-VERIFICATION.md` existed, so this is initial verification; no overrides apply.
- The phase diff is clean (`git diff --check`) and does not alter PNG/codec/release/target-specific implementation paths. Two additional white-box test helpers were necessarily made exhaustive for the new enum; they do not broaden production behavior.
- Disconfirmation pass: the invalid-admission test does not explicitly instantiate F32 or big-endian GrayAlpha, but the production predicate is a direct equality requirement (`component == U8` and `endianness == Little`), which proves both are rejected. The observed all-target test run also covers the representative invalid variants and the valid stateful storage/copy paths.
- All three affected packages declare `+js+wasm+wasm-gc+native`, and the independent test command executed each target successfully.

### Gaps Summary

No gaps found. The descriptor is publicly constructible only for the locked two-component straight-alpha identity; generic checked storage is data-bearing and bounds-checked; and existing operation capabilities stay explicitly closed to GrayAlpha while legacy supported branches remain unchanged.

---

_Verified: 2026-07-22T17:33:17Z_
_Verifier: the agent (gsd-verifier)_
