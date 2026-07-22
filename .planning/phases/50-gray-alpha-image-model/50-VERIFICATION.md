---
phase: 50-gray-alpha-image-model
verified: 2026-07-22T19:52:23Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: passed
  previous_score: 4/4
  gaps_closed: []
  gaps_remaining: []
  regressions: []
---

# Phase 50: Gray+Alpha Image Model Verification Report

**Phase Goal:** Library users can create and inspect a packed U8 grayscale-plus-alpha image with explicit straight-alpha semantics without changing existing Gray, RGB, or RGBA behavior.
**Verified:** 2026-07-22T19:52:23Z
**Status:** passed
**Re-verification:** Yes — v0.16 closeout refresh; the prior report was passed and current code is regression-free.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A library user can create a packed U8 grayscale-plus-alpha image whose pixels contain exactly one gray and one alpha component. | ✓ VERIFIED | `ChannelOrder::GrayAlpha`, `ImageFormat::graya8()`, and `channel_count() == 2` are implemented in `modules/mb-image/model/descriptor.mbt:26-31,79-86,119-125`. The public `GrayAlpha is a packed two-component straight-alpha descriptor` test constructs a real two-pixel descriptor and asserts U8, packed/little-endian, two channels, one plane, and four packed bytes. |
| 2 | A library user can inspect explicit straight-alpha metadata for the two-component format. | ✓ VERIFIED | `validate_alpha_identity` accepts GrayAlpha only with `Some(Straight)` and `validate_gray_alpha_identity` locks U8, packed, little-endian, encoded builtin sRGB, and top-left metadata before storage is admitted (`descriptor.mbt:458-507,618-621`). The public invalid-identity test exercises missing/premultiplied alpha, U16, planar, linear transfer, non-builtin profile, and rotated inputs. |
| 3 | Existing generic storage and checked views retain distinct gray and alpha bytes, with no fabricated third component. | ✓ VERIFIED | `ImageView::get_byte` and `MutImageView::validated_offset` derive both channel bounds and packed pixel stride from `format.channel_count()` (`modules/mb-image/storage/views.mbt:182-224,409-473`). `checked packed views retain distinct GrayAlpha components` writes `13/E7/C1/2A`, reads the same locations, and verifies channel 2 returns an error. This state transition is exercised by the all-target run. |
| 4 | Existing Gray, RGB, and RGBA behavior remains compatible while GrayAlpha stays outside pre-existing reference and copy/flip operations. | ✓ VERIFIED | The Phase 50 implementation is unchanged since `9d4fc1b`; its diff adds only the `GrayAlpha` cases, leaving the legacy descriptor predicates unchanged. Legacy model controls preserve RGB reference support and premultiplied-RGBA support (`model_test.mbt:187-231`). `supports_reference_operations` and `supports_copy_flip` explicitly return `false` for GrayAlpha (`descriptor.mbt:730-744`, `copy_flip.mbt:50-69`), and `copy rejects GrayAlpha before consuming operation budget` proves typed rejection with unchanged resources. |

**Score:** 4/4 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/model/descriptor.mbt` | Public order/factory, descriptor admission, component count, and reference-operation rejection. | ✓ VERIFIED | Exists, substantive, and public-path wired. `verify.artifacts` reports no issues; descriptors call the GrayAlpha validator during `ImageDescriptor::new`. |
| `modules/mb-image/storage/storage_test.mbt` | Public generic packed-storage and checked two-component view regression. | ✓ VERIFIED | Exists, substantive, and runs through a real `OwnedImage` backing plus mutable and immutable checked views; no hard-coded or empty data path is involved. |
| `modules/mb-image/ops/copy_flip_test.mbt` | Typed existing-operation rejection regression for GrayAlpha. | ✓ VERIFIED | Exists, substantive, and exercises the public `copy_image` gate, error context, and unchanged budget counters. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- |
| `model/descriptor.mbt` | `storage/storage_test.mbt` | `channel_count` drives descriptor plane shape and checked view addressing. | ✓ WIRED | `channel_count()` provides the two-component layout used in view bounds and offsets; the storage test writes and reads real packed backing bytes. The declared key-link verifier returned `verified: true`. |
| `model/descriptor.mbt` | `ops/copy_flip.mbt` | Channel-order-specific capability decision is fail-closed for GrayAlpha. | ✓ WIRED | Both model reference support and copy/flip contain explicit `GrayAlpha => false` branches; `copy_with_transform` checks capability before descriptor/output allocation. The declared key-link verifier returned `verified: true`. |
| `model/descriptor.mbt` | Phase 51 PNG encoder | Validated GrayAlpha reaches the explicit bounded type-4 path without widening copy/flip semantics. | ✓ WIRED | Phase 51's `PngEncoder::new_graya8_with_strategies` selects `PngEncodeProfile::GrayAlpha8`; `encode.mbt` accepts only `ChannelOrder::GrayAlpha` with straight alpha, while the chunk path reaches `PngEncodeMachine::new_with_profile`. PNG tests cover source pair order and all factory forms. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `storage/storage_test.mbt` | packed component bytes | `graya8_descriptor()` → `OwnedImage::new` → mutable/immutable checked views | The test persists non-symmetric component values in allocated backing and reads them through the public immutable view. | ✓ FLOWING |
| `ops/copy_flip_test.mbt` | operation budget and result | valid GrayAlpha `OwnedImage` → `copy_image` capability gate | The actual validated source reaches the public operation and receives a typed failure before allocation or work consumption. | ✓ FLOWING |
| Phase 51 PNG tests | Gray/alpha wire pair | valid `graya8` descriptor → eager/chunk factory → shared encode machine | Tests assert type-4 IHDR and non-symmetric source order (`13/A7`, `D2/4C`) through real eager and caller-buffered paths. | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Model construction/admission, storage/view mutation/readback, copy/flip boundary, and downstream GrayAlpha PNG integration on all supported targets | `moon test --target all modules/mb-image/model modules/mb-image/storage modules/mb-image/ops modules/mb-image/png` | 275 passed / 0 failed on wasm, wasm-gc, js, and native | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- |
| GRAYA-01 | `50-01-PLAN.md` | A user can create and inspect a packed U8 grayscale-plus-alpha image with exactly two components and explicit straight-alpha metadata, while existing Gray/RGB/RGBA descriptors, views, storage, and operations retain behavior. | ✓ SATISFIED | Truths 1–4 cover the descriptor identity, generic data-bearing storage/views, bounded legacy controls, and explicit operation rejection. The downstream Phase 51 encoder independently consumes the same validated model without changing the Phase 50 operation boundaries. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- |
| — | — | No `TBD`, `FIXME`, `XXX`, `TODO`, placeholder, empty implementation, or hardcoded-empty-output pattern in the seven Phase 50 implementation/test files. | ℹ️ Info | No completion-blocking debt marker or stub evidence found. |

### Scope and Disconfirmation Checks

- Inversion checks found no widened model identity: GrayAlpha is rejected for missing/premultiplied alpha, U16, planar, linear, non-builtin-profile, and rotated variants before allocation.
- The possible misleading-positive path — a new enum case that exists but is not usable — is falsified by the real `OwnedImage` mutation/readback test and the downstream Phase 51 eager/chunk encoder tests.
- The potential backwards-compatibility regression — an exhaustive match accidentally changing legacy support — is falsified by the Phase 50 diff (only additive GrayAlpha cases), legacy RGB/RGBA controls, and the current all-target regression suite.
- `git diff --name-only 9d4fc1b..HEAD -- <Phase 50 files>` is empty and `git diff --check` is clean. No later phase modified Phase 50 model, storage, or ops behavior.

### Gaps Summary

No gaps found. GRAYA-01 remains met in current code: the public model is tightly admitted as exactly two packed U8 straight-alpha components, generic checked storage carries both bytes, legacy contracts remain covered, and the later PNG integration consumes the descriptor through its own explicit capability path without widening existing operations.

---

_Verified: 2026-07-22T19:52:23Z_
_Verifier: the agent (gsd-verifier)_
