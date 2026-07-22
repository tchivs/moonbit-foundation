# Phase 53: GrayAlpha16 Model and Checked Storage - Research

**Researched:** 2026-07-23
**Domain:** MoonBit image descriptor admission and checked packed-U16 storage
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Descriptor contract
- **D-01:** Add an explicit `ImageFormat::graya16()` identity using packed `ChannelOrder::GrayAlpha`, `ComponentType::U16`, `Some(AlphaMode::Straight)`, encoded builtin sRGB, and top-left orientation. — **Reversibility:** one-way — public format spelling and metadata form a compatibility contract.
- **D-02:** Admit GrayAlpha16 only with its exact packed U16 two-component descriptor identity. Reject malformed, opaque, premultiplied, linear/unknown-colour, or altered-layout variants through existing validation rather than silently normalizing them.

### Storage and compatibility
- **D-03:** Reuse the existing generic checked packed-image storage access; non-symmetric gray and alpha samples must expose both U16 bytes per component without a new backing representation or conversion buffer.
- **D-04:** Existing Gray8, Gray16, GrayAlpha8, RGB8, and straight-RGBA8 descriptors, views, storage, and reference operations remain unchanged. GrayAlpha formats remain unsupported by reference operations unless a later phase adds a deliberate semantic contract.

### the agent's Discretion
- Mirror the smallest existing Gray16 and GrayAlpha8 model/storage test patterns and preserve exhaustive test helper coverage for formats.
- Keep the change localized to the model and storage packages; no codec, release, FFI, platform branch, or source-copy work.

### Deferred Ideas (OUT OF SCOPE)

- Type-4/16 PNG factories and wire emission — Phase 54.
- Public decode, hostile caller schedules, frozen PNG vectors, and four-target PNG qualification — Phase 55.
- GrayAlpha16 Adam7, colour conversion, premultiplied alpha, palette/low-bit formats, release automation, and copied source trees.
</user_constraints>

## Project Constraints (from AGENTS.md)

- Keep core algorithms and shared models in MoonBit; native is primary, while portable targets are protected through capability boundaries and conformance tests. [VERIFIED: AGENTS.md]
- Keep public packages modular with acyclic documented dependencies; honor SemVer once an API is stable. [VERIFIED: AGENTS.md]
- Do not introduce FFI, GUI-dependent behavior, unsupported performance claims, or architectural boundary changes without the required governance. [VERIFIED: AGENTS.md]
- Preserve the existing GSD workflow and use codebase discovery patterns; the configured code-graph MCP tools are unavailable in this agent runtime, so code search was used only as the documented fallback. [VERIFIED: AGENTS.md; agent runtime]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| GRAYA16-01 | A library user can create and inspect a packed U16 grayscale-plus-alpha image with exactly one gray and one straight-alpha component, while existing Gray, GrayAlpha8, RGB, and RGBA descriptor and storage behavior remains unchanged. | Add one U16 factory and widen only the GrayAlpha descriptor identity predicate; exercise the existing checked component-byte view APIs with two U16 lanes, then retain model and capability controls. [VERIFIED: .planning/REQUIREMENTS.md; modules/mb-image/model/descriptor.mbt; modules/mb-image/storage/views.mbt] |
</phase_requirements>

## Summary

Phase 53 is a model-admission change, not a storage, operation, or codec redesign. Add `ImageFormat::graya16()` next to `graya8()` with `U16`, `GrayAlpha`, `Packed`, and `Little` fields, then let `ImageDescriptor::new` admit that identity only when the existing straight-alpha, encoded builtin-sRGB, and top-left metadata rules also hold. [VERIFIED: modules/mb-image/model/descriptor.mbt; 53-CONTEXT.md]

The generic packed-U16 component-byte APIs already calculate `pixel_stride = bytes_per_component * channel_count` and `component_offset = channel * bytes_per_component + component_byte`; a valid U16 GrayAlpha descriptor therefore has a four-byte pixel and needs no production storage implementation. [VERIFIED: modules/mb-image/storage/views.mbt; modules/mb-image/model/descriptor.mbt]

**Primary recommendation:** change only the GrayAlpha factory/identity validation and add focused model/storage regressions. Do not touch PNG, FFI, release, target-specific, source-copy, or reference-operation production code in this phase. [VERIFIED: 53-CONTEXT.md; .planning/REQUIREMENTS.md; modules/mb-image/ops/copy_flip.mbt]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Public GrayAlpha16 identity and metadata admission | Portable library model | — | `ImageFormat`, `ImageDescriptor`, alpha validation, and packed-plane geometry live in `model/descriptor.mbt`. [VERIFIED: modules/mb-image/model/descriptor.mbt] |
| Owned backing, checked U16 byte addressing, and mutation lease | Portable library storage | Portable library model | `OwnedImage` consumes an already-valid descriptor while views derive lane bounds and offsets from it. [VERIFIED: modules/mb-image/storage/owned_image.mbt; modules/mb-image/storage/views.mbt] |
| Copy/reference-operation rejection | Portable library operations | Portable library model | Current gates reject non-U8 inputs and explicitly reject `GrayAlpha`; the phase must preserve that boundary rather than add semantics. [VERIFIED: modules/mb-image/model/descriptor.mbt; modules/mb-image/ops/copy_flip.mbt] |
| PNG type-4/16 framing and wire bytes | Deferred codec tier | Portable library model | The roadmap assigns all encoder factory and byte-emission work to Phase 54. [VERIFIED: .planning/ROADMAP.md] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---|---:|---|---|
| Existing `tchivs/mb-image` MoonBit module | `0.1.0` | Public image model, checked storage, and tests | The complete required model/storage capability already exists in this workspace; no dependency is needed. [VERIFIED: modules/mb-image/moon.mod.json] |
| MoonBit toolchain | `0.1.20260713` | Compile and run the package suite | Installed workspace toolchain supports the module’s js, wasm, wasm-gc, and native target declaration. [VERIFIED: `moon --version`; modules/mb-image/moon.mod.json] |

**Installation:** None. This phase installs no external package. [VERIFIED: modules/mb-image/moon.mod.json; 53-CONTEXT.md]

## Architecture Patterns

### System Architecture Diagram

```text
caller metadata + ImageFormat::graya16()
                  |
                  v
         ImageDescriptor::new
          | alpha / identity / plane-shape validation
          v
packed one-plane descriptor: width * 4 row bytes
                  |
                  v
OwnedImage -> immutable ImageView / callback-scoped MutImageView
                  |
                  v
get_component_byte(x, y, gray|alpha, 0|1)
                  |
                  +--> current reference/copy capability gate rejects GrayAlpha

PNG factories and wire framing: deferred to Phase 54
```

The format’s `channel_count()` is already two for `GrayAlpha`, `bytes_per_component()` is two for `U16`, and descriptor plane validation derives `width * 4` row bytes from those facts. [VERIFIED: modules/mb-image/model/descriptor.mbt]

### Recommended Project Structure

```text
modules/mb-image/
├── model/descriptor.mbt       # add graya16 factory; widen exact GrayAlpha identity predicate
├── model/model_test.mbt       # descriptor and malformed-identity controls
├── storage/storage_test.mbt   # two U16 lanes through checked byte access
└── ops/                       # unchanged production capability boundary
```

### Pattern 1: One Channel Order, Two Explicit Factories

**What:** Keep `ChannelOrder::GrayAlpha` as the only two-component order and distinguish U8/U16 using `ImageFormat` factories. [VERIFIED: modules/mb-image/model/descriptor.mbt]

**Use:** Add `graya16()` as the direct U16 counterpart of `graya8()`; do not add an enum case, a special image type, or inferred alpha behavior. [VERIFIED: 53-CONTEXT.md; modules/mb-image/model/descriptor.mbt]

```moonbit
// Source pattern: modules/mb-image/model/descriptor.mbt
pub fn ImageFormat::graya16() -> ImageFormat {
  {
    component_value: ComponentType::U16,
    channels_value: ChannelOrder::GrayAlpha,
    layout_value: PlaneLayout::Packed,
    endianness_value: Endianness::Little,
  }
}
```

### Pattern 2: Descriptor Is the Validation and Layout Seam

**What:** `ImageDescriptor::new` first validates alpha identity and GrayAlpha’s exact identity, then enforces one packed plane, checked `width * components * component_bytes` row bytes, storage containment, and non-overlap. [VERIFIED: modules/mb-image/model/descriptor.mbt]

**Use:** Change only `validate_gray_alpha_identity` from `component == U8` to the explicit `U8 || U16` set; all other clauses remain exact. This admits the new factory while continuing to reject F32, planar, big-endian, non-sRGB, non-builtin, non-top-left, missing-alpha, and premultiplied variants through existing errors. [VERIFIED: modules/mb-image/model/descriptor.mbt; 53-CONTEXT.md]

### Pattern 3: Component-Byte Tests Expose Storage, Not Numeric Conversion

**What:** `get_component_byte` and `set_component_byte` are the deliberate U8/U16 view API; `get_byte`/`set_byte` remain U8-only. [VERIFIED: modules/mb-image/storage/views.mbt]

**Use:** Write non-symmetric storage-order bytes to both lane 0 (gray) and lane 1 (alpha), read all four back, and assert both a third channel and component-byte index `2` fail. Do not add U16 conversion or host-endian interpretation in this phase. [VERIFIED: modules/mb-image/storage/storage_test.mbt; 53-CONTEXT.md]

## Exact Implementation and Validation Seams

| Seam | Required Phase-53 change | Preservation check |
|---|---|---|
| `ImageFormat` factory | Add public `graya16()` with packed/little-endian U16 GrayAlpha fields. [VERIFIED: modules/mb-image/model/descriptor.mbt; 53-CONTEXT.md] | `graya8()`, `rgb8()`, and `rgba8()` retain their present values. [VERIFIED: modules/mb-image/model/descriptor.mbt] |
| `validate_alpha_identity` | No change: GrayAlpha already requires `Some(Straight)`. [VERIFIED: modules/mb-image/model/descriptor.mbt] | Keep existing `Rgba => Some(_)` and non-alpha `None` rules unchanged. [VERIFIED: modules/mb-image/model/descriptor.mbt] |
| `validate_gray_alpha_identity` | Broaden only the allowed component predicate to explicit U8 or U16; retain packed/little/sRGB/encoded/builtin/top-left clauses. [VERIFIED: modules/mb-image/model/descriptor.mbt; 53-CONTEXT.md] | Invalid U16 GrayAlpha must still fail for altered layout, endian, color, profile, orientation, or alpha identity. [VERIFIED: modules/mb-image/model/descriptor.mbt] |
| `validate_plane_shape` | No production change. A two-lane U16 packed image derives `width * 2 * 2`, so a 1×1 descriptor has four row bytes and one plane. [VERIFIED: modules/mb-image/model/descriptor.mbt] | Retain existing checked arithmetic and range/overlap validation. [VERIFIED: modules/mb-image/model/descriptor.mbt] |
| `ImageView` / `MutImageView` component bytes | No production change. Existing APIs permit packed U8/U16 only and bounds-check channel and byte indices before offset calculation. [VERIFIED: modules/mb-image/storage/views.mbt] | Retain U8-only `get_byte`/`set_byte` contract. [VERIFIED: modules/mb-image/storage/views.mbt] |
| Reference/copy operations | No production change. `supports_reference_operations` returns false for `GrayAlpha`, while copy/flip rejects non-U8 before work/budget use. [VERIFIED: modules/mb-image/model/descriptor.mbt; modules/mb-image/ops/copy_flip.mbt] | Add or retain a public negative control if the scoped test change needs explicit proof. [VERIFIED: modules/mb-image/ops/copy_flip_test.mbt] |

## U16 Test Pattern

Use one 1×1 descriptor with a four-byte packed row and the canonical straight-alpha metadata. Through `with_mut_view`, set gray lane bytes `(0x34, 0x12)` and alpha lane bytes `(0xC5, 0xA7)` at `(x=0, y=0)`; immutable `get_component_byte` must return the same four storage-order bytes. Then assert errors for `channel=2`, `component_byte=2`, and U16 `get_byte`. This combines the existing Gray16 byte-access test with the GrayAlpha8 two-lane test and makes lane swaps or byte-index errors observable. [VERIFIED: modules/mb-image/storage/storage_test.mbt; 53-CONTEXT.md]

The model regression should construct `ImageFormat::graya16()` and assert `U16`, `GrayAlpha`, `Packed`, `Little`, `channel_count()==2`, `plane_count()==1`, `row_bytes()==4` for 1×1, `Some(Straight)`, builtin sRGB, top-left, and `supports_reference_operations()==false`. Its negative matrix must replace the current “U16 GrayAlpha is invalid” control with accepted canonical U16, then retain invalid F32, planar, big-endian, missing/premultiplied alpha, linear/unknown color, non-builtin profile, rotated orientation, and malformed row bytes. [VERIFIED: modules/mb-image/model/model_test.mbt; modules/mb-image/model/descriptor.mbt; 53-CONTEXT.md]

## Don’t Hand-Roll

| Problem | Don’t Build | Use Instead | Why |
|---|---|---|---|
| U16 GrayAlpha backing | Format-specific owned image, conversion buffer, or host-endian scalar adapter | Existing `OwnedImage`, `ImageView`, `MutImageView`, and component-byte APIs | They already allocate from the validated descriptor, use checked offsets, and preserve callback-scoped mutation. [VERIFIED: modules/mb-image/storage/owned_image.mbt; modules/mb-image/storage/views.mbt] |
| Row-byte arithmetic | Manual `width * 4` allocation path | `ImageDescriptor::new` and `validate_plane_shape` | Existing checked arithmetic, one-plane, range, and overlap validation stays the single source of truth. [VERIFIED: modules/mb-image/model/descriptor.mbt] |
| GrayAlpha processing | Copy/flip, conversion, resize, or alpha-compositing support | Existing fail-closed capability gates | GrayAlpha has no operation-semantic contract in this milestone. [VERIFIED: 53-CONTEXT.md; modules/mb-image/ops/{copy_flip,convert,resize,processing}.mbt] |

## Common Pitfalls

### Pitfall 1: Broadening the U8-only rule too far

Allowing arbitrary non-U8 `GrayAlpha` would also admit F32 and break the locked exact packed-U16 identity. Use an explicit two-value U8/U16 predicate, not “not U8” or a layout-only condition. [VERIFIED: modules/mb-image/model/descriptor.mbt; 53-CONTEXT.md]

### Pitfall 2: Reversing the wrong validation control

The Phase-50 negative test deliberately rejects U16 GrayAlpha. Phase 53 must convert that one case into a valid canonical descriptor while retaining all other invalid-identity controls, including a bad four-byte row layout. [VERIFIED: modules/mb-image/model/model_test.mbt; 53-CONTEXT.md]

### Pitfall 3: Testing symmetric bytes or only one lane

Repeated bytes or equal gray/alpha lanes cannot detect component-byte or channel-offset defects. Use distinct bytes in both U16 lanes and assert all four reads plus both index failures. [VERIFIED: modules/mb-image/storage/storage_test.mbt; 53-CONTEXT.md]

### Pitfall 4: Accidentally widening reference operations

Storage validity does not authorize processing. Keep `GrayAlpha => false` and the U16 rejection behavior unchanged; Phase 54 is codec-only and does not change that boundary either. [VERIFIED: modules/mb-image/model/descriptor.mbt; modules/mb-image/ops/copy_flip.mbt; .planning/ROADMAP.md]

## Scope Boundary

**In scope:** one additive `graya16()` model identity, narrow descriptor admission, model/storage negative and compatibility regressions, and optional assertion-only operation-boundary coverage. [VERIFIED: 53-CONTEXT.md; .planning/ROADMAP.md]

**Out of scope:** any PNG factory, PNG scanline/wire behavior, type-4/16 headers, bounded encode/replay changes, decoder behavior, hostile caller schedules, frozen vectors, four-target PNG qualification, FFI, platform branches, release automation, registry work, and copied source trees. [VERIFIED: 53-CONTEXT.md; .planning/REQUIREMENTS.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| `moon` | Model/storage package tests | ✓ | `0.1.20260713` | — [VERIFIED: `moon --version`] |

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | no | No identity boundary is added. [VERIFIED: phase scope] |
| V3 Session Management | no | No session state is added. [VERIFIED: phase scope] |
| V4 Access Control | no | No authorization boundary is added. [VERIFIED: phase scope] |
| V5 Input Validation | yes | Existing descriptor identity, plane shape, storage range, and view-index checks remain the enforcement point. [VERIFIED: modules/mb-image/model/descriptor.mbt; modules/mb-image/storage/views.mbt] |
| V6 Cryptography | no | No cryptographic operation is added. [VERIFIED: phase scope] |

| Threat Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Malformed U16 GrayAlpha descriptor creates an invalid packed layout | Tampering | Retain exact component/metadata predicate and the checked one-plane/row-byte/storage-range validation. [VERIFIED: modules/mb-image/model/descriptor.mbt] |
| Caller indexes a nonexistent lane or U16 byte | Tampering | Existing view APIs validate channel and `component_byte` before checked offset calculation. [VERIFIED: modules/mb-image/storage/views.mbt] |
| Valid storage is treated as supported image processing | Elevation of Privilege | Preserve the explicit false/rejection operation gates. [VERIFIED: modules/mb-image/model/descriptor.mbt; modules/mb-image/ops/copy_flip.mbt] |

## Sources

### Primary (HIGH confidence)

- `53-CONTEXT.md`, `.planning/ROADMAP.md`, and `.planning/REQUIREMENTS.md` — locked Phase-53 scope, GRAYA16-01, and deferred boundaries. [VERIFIED: planning artifacts]
- `modules/mb-image/model/descriptor.mbt` and `model_test.mbt` — format factory, validation ordering, packed row shape, and current negative matrix. [VERIFIED: codebase]
- `modules/mb-image/storage/owned_image.mbt`, `views.mbt`, and `storage_test.mbt` — generic backing, U16 lane offsets, and current Gray16/GrayAlpha8 test patterns. [VERIFIED: codebase]
- `modules/mb-image/ops/copy_flip.mbt` and `copy_flip_test.mbt` — preserved fail-closed reference/copy boundary. [VERIFIED: codebase]
- Archived Phase 47 and Phase 50 context, plan, summary, research, and verification artifacts — U16 storage and GrayAlpha compatibility precedents. [VERIFIED: planning artifacts]

### Secondary (MEDIUM confidence)

- [MoonBit language fundamentals](https://docs.moonbitlang.com/en/latest/language/fundamentals.html) — enum constructors and match expressions; local implementation details are grounded in repository code. [CITED: docs.moonbitlang.com/en/latest/language/fundamentals.html]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — no package selection or installation is involved. [VERIFIED: modules/mb-image/moon.mod.json]
- Architecture: HIGH — every recommended seam was read in the current working tree. [VERIFIED: codebase]
- Pitfalls: HIGH — each follows a current validation clause, checked-offset guard, or archived U16/GrayAlpha test precedent. [VERIFIED: codebase; planning artifacts]

**Research date:** 2026-07-23
**Valid until:** 2026-08-22, unless the inspected model, storage, or operation seams change. [ASSUMED]
