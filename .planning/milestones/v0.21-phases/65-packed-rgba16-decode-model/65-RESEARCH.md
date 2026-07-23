# Phase 65: Packed RGBA16 Decode Model - Research

**Researched:** 2026-07-23
**Domain:** Checked portable packed U16 RGBA image representation
**Confidence:** High — repository source inspection

## Findings

- `modules/mb-image/model/descriptor.mbt` already models U16 components, four RGBA channels, packed layout, little endianness, checked row shape, and storage ranges. Phase 65 needs only `ImageFormat::rgba16()` plus a narrow RGBA16 identity validator alongside `validate_gray_alpha_identity`.
- Existing `validate_alpha_identity` permits any RGBA alpha mode. The explicit preservation result requires a new constrained validator: U16, packed, little-endian, builtin sRGB/encoded-sRGB, straight alpha, and top-left orientation.
- `modules/mb-image/storage/views.mbt` already supports packed U16 component-byte reads/writes for arbitrary channel counts and deliberately rejects `get_byte` on U16 images. No storage API change is needed.
- `model_test.mbt` and `storage_test.mbt` contain direct `graya16` descriptor and all-component-byte patterns. Mirror them with four channels and an eight-byte row/pixel, preserving existing U8 format regressions.

## Minimal Files

| File | Change |
| --- | --- |
| `modules/mb-image/model/descriptor.mbt` | Add `ImageFormat::rgba16` and `validate_rgba16_identity`, then invoke it from `ImageDescriptor::new`. |
| `modules/mb-image/model/model_test.mbt` | Prove descriptor identity, exact eight-byte plane shape, and rejection of invalid alpha/colour/profile/orientation/layout/endianness facts. |
| `modules/mb-image/storage/storage_test.mbt` | Prove all eight non-symmetric storage bytes and component bounds; preserve U8 accessor rejection. |

## Verification

1. Focused model/storage tests on JS during TDD.
2. `moon -C modules/mb-image test model --target all --frozen` and `moon -C modules/mb-image test storage --target all --frozen` after implementation.

## Scope Fences

No decoder selector, PNG profile, buffer type, conversion operation, or U8 algorithm widening belongs in this phase.
