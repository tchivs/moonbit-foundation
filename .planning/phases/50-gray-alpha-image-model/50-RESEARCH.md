# Phase 50: Gray+Alpha Image Model - Research

**Researched:** 2026-07-22
**Domain:** Portable MoonBit image descriptor, packed owned storage, and typed capability boundaries
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
## Implementation Decisions

### Public image contract
- **D-01:** Add `ChannelOrder::GrayAlpha` as the explicit two-component order and provide an `ImageFormat` convenience factory consistent with existing `rgb8()`/`rgba8()` naming. — **Reversibility:** one-way — public enum and factory names become downstream API contracts.
- **D-02:** Phase 50 accepts only packed U8 Gray+Alpha with `AlphaMode::Straight`, encoded sRGB, and the established top-left/builtin-sRGB metadata rules; planar, premultiplied, F32, and U16 Gray+Alpha stay unsupported. — **Reversibility:** costly — widening this model later requires validation and test coverage across descriptor, storage, and operations.

### Compatibility boundary
- **D-03:** Existing Gray/RGB/RGBA constructors and observable descriptor/storage/view behavior remain byte- and behavior-compatible. Operations do not gain new Gray+Alpha processing semantics in this phase; they must either preserve their existing supported inputs or reject the new order through typed existing-boundary behavior.
- **D-04:** Do not add PNG factories, scanline handling, release scripts, source-tree copies, or new target-specific paths in this phase. Those belong to Phases 51-52.

### the agent's Discretion
- Select the smallest set of model and storage regression tests that proves channel count, component indexing, straight-alpha metadata, and legacy non-regression.
- Follow existing public naming and typed-error patterns when adding exhaustive `ChannelOrder` handling.

### Deferred Ideas (OUT OF SCOPE)
- Gray+Alpha16 and Gray+Alpha Adam7 — future requirements after the 8-bit non-interlaced contract is verified.
- Gray+Alpha PNG factories and wire behavior — Phase 51.
- Portable hostile-capacity and four-target public evidence — Phase 52.
</user_constraints>

## Project Constraints (from AGENTS.md)

- Core algorithms and shared data models must be implemented in MoonBit; native stubs stay small, isolated, documented, and replaceable. [VERIFIED: AGENTS.md]
- Public packages must keep acyclic, explicit dependencies and preserve SemVer stability once declared stable. [VERIFIED: AGENTS.md]
- Public operations must be deterministic and GUI-independent; benchmarks need declared workloads and reproducible baselines. [VERIFIED: AGENTS.md]
- Model, storage, and operation packages must keep their `+js+wasm+wasm-gc+native` support boundary. [VERIFIED: modules/mb-image/{model,storage,ops}/moon.pkg]
- No direct implementation work is authorized here; this research artifact is produced through the active GSD planning workflow. [VERIFIED: AGENTS.md]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| GRAYA-01 | A user can create and inspect a packed U8 grayscale-plus-alpha image with exactly two components and explicit straight-alpha metadata, while existing Gray/RGB/RGBA descriptors, views, storage, and operations retain behavior. | Add the descriptor-level `GrayAlpha` contract, exercise generic packed storage/view indexing, and retain fail-closed operation support. [VERIFIED: .planning/REQUIREMENTS.md; modules/mb-image/model/descriptor.mbt; modules/mb-image/storage/views.mbt] |
</phase_requirements>

## Summary

Phase 50 should add one public `ChannelOrder::GrayAlpha` case, make its component count two, and expose a U8/packed/little-endian convenience factory. `ImageDescriptor::new` already computes packed row requirements and plane counts from `ImageFormat::channel_count()`, so a valid Gray+Alpha descriptor naturally requires one packed plane with `width * 2` row bytes. [VERIFIED: modules/mb-image/model/descriptor.mbt]

The important semantic change is alpha validation, not storage allocation: existing validation accepts any alpha identity only for `Rgba` and requires no alpha for every other order. Change that decision table so legacy `Rgba` continues to accept its current alpha behavior, `GrayAlpha` accepts only `Some(AlphaMode::Straight)`, and Gray/RGB stay alpha-free. [VERIFIED: modules/mb-image/model/descriptor.mbt; .planning/phases/50-gray-alpha-image-model/50-CONTEXT.md]

`OwnedImage`, immutable views, mutable leased views, crops, checked component access, and offset calculations are format-generic once a descriptor is valid; no new Gray+Alpha storage type or view path is warranted. Capability-owning operations remain deliberately closed: update the two exhaustive channel-order matches (`supports_reference_operations` and `supports_copy_flip`) to reject `GrayAlpha`; processing and bilinear resize already reject it through explicit RGB/RGBA predicates. [VERIFIED: modules/mb-image/storage/owned_image.mbt; modules/mb-image/storage/views.mbt; modules/mb-image/model/descriptor.mbt; modules/mb-image/ops/{copy_flip,processing,resize}.mbt]

**Primary recommendation:** Implement `GrayAlpha` only in the descriptor contract and generic storage regression coverage, add explicit typed rejections to current exhaustive operation-support matches, and leave every codec/PNG file unchanged. [VERIFIED: .planning/phases/50-gray-alpha-image-model/50-CONTEXT.md; modules/mb-image/png/encode.mbt]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Public Gray+Alpha format identity | Portable library model | — | `ChannelOrder`, `ImageFormat`, metadata validation, and descriptor invariants belong to the model package. [VERIFIED: modules/mb-image/model/descriptor.mbt] |
| Packed byte allocation and lifetime-scoped mutation | Portable library storage | Portable library model | Storage accepts the validated descriptor, owns bytes, and only grants packed U8/U16 mutable views inside a callback lease. [VERIFIED: modules/mb-image/storage/owned_image.mbt] |
| Component lookup and checked offsets | Portable library storage | Portable library model | Views derive pixel stride and channel bounds from `bytes_per_component()` and `channel_count()`. [VERIFIED: modules/mb-image/storage/views.mbt] |
| Operation admission | Portable library operations | Portable library model | Copy/flip, processing, and resize own capability decisions rather than treating any packed format as processable. [VERIFIED: modules/mb-image/ops/{copy_flip,processing,resize}.mbt] |
| PNG color-type-4 emission | Deferred codec tier | Portable library model | Encoding profiles are explicitly admitted in the PNG encoder and are owned by Phase 51, not this model phase. [VERIFIED: modules/mb-image/png/encode.mbt; .planning/ROADMAP.md] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| MoonBit `tchivs/mb-image` model/storage/ops packages | workspace `0.1.0`; toolchain `moon 0.1.20260713` | Public image descriptors, owned storage, views, and operations | The required behavior is an additive change inside the established four-target package boundary; no new dependency is needed. [VERIFIED: modules/mb-image/moon.mod.json; `moon --version`] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|-------------|-------------|
| `tchivs/mb-color` | workspace `0.1.0` | `AlphaMode`, sRGB color/transfer identities, and builtin profile identity | Reuse it to express `Some(AlphaMode::Straight)` in the existing metadata object. [VERIFIED: modules/mb-image/model/descriptor.mbt; modules/mb-image/moon.mod.json] |
| `tchivs/mb-core` | workspace `0.1.0` | Checked arithmetic, errors, budgets, and byte storage | Reuse existing descriptor and view checks; do not add a separate stride/offset implementation. [VERIFIED: modules/mb-image/model/descriptor.mbt; modules/mb-image/storage/views.mbt; modules/mb-image/moon.mod.json] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Explicit `ChannelOrder::GrayAlpha` | Model alpha as separate opaque metadata on `Gray` | Rejected: the descriptor would still claim one component and storage/view stride would be wrong. [VERIFIED: modules/mb-image/model/descriptor.mbt; .planning/phases/50-gray-alpha-image-model/50-CONTEXT.md] |
| Existing generic packed storage | A dedicated GrayAlpha image/view type | Rejected: generic storage already uses format component count and preserves the lease and bounds contracts. [VERIFIED: modules/mb-image/storage/{owned_image,views}.mbt] |
| Fail-closed existing operations | Add Gray+Alpha copy, resize, composite, or processing semantics | Rejected by locked scope; operation algorithms have RGB/RGBA-specific color and alpha contracts. [VERIFIED: .planning/phases/50-gray-alpha-image-model/50-CONTEXT.md; modules/mb-image/ops/{copy_flip,processing,resize}.mbt] |

**Installation:** None — Phase 50 installs no external package. [VERIFIED: modules/mb-image/moon.mod.json; .planning/phases/50-gray-alpha-image-model/50-CONTEXT.md]

## Architecture Patterns

### System Architecture Diagram

```text
Application/library caller
        |
        v
ImageFormat::graya8() [ASSUMED: recommended public name]
        + ImageMetadata(sRGB, encoded-sRGB, Straight, builtin-sRGB, TopLeft)
        |
        v
ImageDescriptor::new
  ├─ validates GrayAlpha => exactly Straight alpha
  ├─ derives packed components = 2
  └─ validates one plane and width * 2 row bytes
        |
        v
OwnedImage::new ──> ImageView / callback-scoped MutImageView
        |                    |
        |                    └─ checked channel 0 = gray; channel 1 = alpha
        v
Existing operations
  ├─ reference/copy-flip: explicit typed capability rejection
  ├─ processing/resize: existing RGB/RGBA-only predicates reject
  └─ PNG/QOI/PPM: unchanged in this phase; existing profile boundaries reject
```

### Recommended Project Structure

```text
modules/mb-image/
├── model/
│   ├── descriptor.mbt       # GrayAlpha enum/factory/count/metadata and reference admission
│   └── model_test.mbt       # public descriptor and legacy compatibility assertions
├── storage/
│   └── storage_test.mbt     # owned-image and checked two-component view access
└── ops/
    ├── copy_flip.mbt        # exhaustive typed rejection for GrayAlpha
    └── copy_flip_test.mbt   # operation boundary regression
```

### Pattern 1: Descriptor Is the Single Source of Packed Layout

**What:** Define component count once on `ImageFormat`; let descriptor validation, storage, and views consume that value. [VERIFIED: modules/mb-image/model/descriptor.mbt; modules/mb-image/storage/views.mbt]

**When to use:** Every Phase-50 construction and test should create a standard `ImageDescriptor` first, then allocate `OwnedImage`; no test should bypass descriptor shape validation. [VERIFIED: modules/mb-image/storage/owned_image.mbt]

**Example:**

```moonbit
// Source: modules/mb-image/model/descriptor.mbt and storage/views.mbt
let format = @model.ImageFormat::graya8() // [ASSUMED: recommended factory spelling]
let descriptor = @model.ImageDescriptor::new(
  2UL,
  1UL,
  format,
  [@model.PlaneDescriptor::new(0UL, 4UL, 4UL, 4UL, 1UL, 1UL, 2UL, 1UL).unwrap()],
  4UL,
  straight_srgb_top_left_metadata(),
).unwrap()
// get_byte/set_byte use channel_count(): channel 0 is gray, channel 1 is alpha.
```

### Pattern 2: Capability Gates Stay Format-Specific

**What:** Preserve existing operations by rejecting a new order at the operation’s established capability boundary rather than silently treating it like RGBA. [VERIFIED: modules/mb-image/ops/{copy_flip,processing,resize}.mbt]

**When to use:** Add `GrayAlpha => false` to exhaustive enum matches and assert `CapabilityUnavailable` on one representative public operation. Predicates that already test only `Rgb`/`Rgba` need no semantic widening. [VERIFIED: modules/mb-image/model/descriptor.mbt; modules/mb-image/ops/{copy_flip,processing,resize}.mbt]

### Anti-Patterns to Avoid

- **Treating any alpha-bearing format as RGBA:** Gray+Alpha has two components, so RGBA load/store paths would read invalid component indexes and invent color semantics. [VERIFIED: modules/mb-image/ops/{processing,resize}.mbt]
- **Hard-coding a two-byte stride in storage/views:** Use `channel_count()` so plane validation, crops, and component offsets remain centralized. [VERIFIED: modules/mb-image/model/descriptor.mbt; modules/mb-image/storage/views.mbt]
- **Adding a PNG profile or changing a profile rejection now:** PNG admission is an explicit profile match and Phase 51 owns Gray+Alpha output. [VERIFIED: modules/mb-image/png/encode.mbt; .planning/ROADMAP.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Packed stride and plane-shape validation | A Gray+Alpha-specific width/stride validator | `ImageDescriptor::new` plus `ImageFormat::channel_count()` | It already checks plane count, subsampling, row bytes, ranges, overlap, and checked arithmetic. [VERIFIED: modules/mb-image/model/descriptor.mbt] |
| Owned mutable pixel buffer | A new Gray+Alpha byte owner | `OwnedImage::new` and `with_mut_view` | It already charges the budget and scopes mutable authority to an invalidating callback lease. [VERIFIED: modules/mb-image/storage/owned_image.mbt] |
| Pixel component addressing | Manual `((y * width + x) * 2)` offsets | `get_byte` / `set_byte` | Views perform format capability checks, bounds checks, and checked offsets using descriptor-derived stride. [VERIFIED: modules/mb-image/storage/views.mbt] |
| Alpha compositing or Gray+Alpha resampling | New operation semantics | Existing typed capability rejections | This phase only introduces the model; its correctness requirement is preserving operation boundaries. [VERIFIED: .planning/phases/50-gray-alpha-image-model/50-CONTEXT.md] |

**Key insight:** a Gray+Alpha descriptor is a new valid packed data model, not authorization to treat that model as an already-supported processing format. [VERIFIED: .planning/phases/50-gray-alpha-image-model/50-CONTEXT.md; modules/mb-image/ops/{copy_flip,processing,resize}.mbt]

## Common Pitfalls

### Pitfall 1: Broad Alpha Validation Accidentally Admits Premultiplied Gray+Alpha

**What goes wrong:** Extending the current `Rgba => Some(_)` condition to every alpha-bearing order would admit `GrayAlpha` with premultiplied alpha. [VERIFIED: modules/mb-image/model/descriptor.mbt]

**Why it happens:** The existing branch intentionally supports all current RGBA alpha identities, whereas D-02 narrows the new order to straight alpha. [VERIFIED: modules/mb-image/model/descriptor.mbt; .planning/phases/50-gray-alpha-image-model/50-CONTEXT.md]

**How to avoid:** Match `ChannelOrder::GrayAlpha` separately and accept only `Some(@color.AlphaMode::Straight)`; retain the exact legacy RGBA rule. [VERIFIED: .planning/phases/50-gray-alpha-image-model/50-CONTEXT.md]

**Warning signs:** A descriptor with Gray+Alpha plus `None` or `Premultiplied` constructs successfully, or an existing premultiplied RGBA descriptor begins to fail. [VERIFIED: modules/mb-image/model/descriptor.mbt]

### Pitfall 2: Updating the Enum but Missing Exhaustive Capability Matches

**What goes wrong:** `channel_count`, reference-operation support, and copy/flip support each explicitly match channel order; the new case must be handled intentionally. [VERIFIED: modules/mb-image/model/descriptor.mbt; modules/mb-image/ops/copy_flip.mbt]

**Why it happens:** Generic view code has no enum match, while these public capability gates encode semantic policy. [VERIFIED: modules/mb-image/storage/views.mbt; modules/mb-image/model/descriptor.mbt; modules/mb-image/ops/copy_flip.mbt]

**How to avoid:** Audit all `match ...channels()` sites after adding the enum; add an explicit false/rejection arm only where the match lacks an existing wildcard. [VERIFIED: modules/mb-image/{model/descriptor,ops/copy_flip,png/encode,qoi/encode}.mbt]

**Warning signs:** A compiler non-exhaustiveness error, a Gray+Alpha copy succeeding, or an operation reads channel 2+. [VERIFIED: modules/mb-image/ops/{copy_flip,processing,resize}.mbt]

### Pitfall 3: Letting Generic Storage Imply Generic Processing

**What goes wrong:** A valid two-channel owned image may be read and written through views, but conversion, resize, processing, and copy APIs have narrower supported-format contracts. [VERIFIED: modules/mb-image/storage/{owned_image,views}.mbt; modules/mb-image/ops/{copy_flip,processing,resize}.mbt]

**How to avoid:** Test storage access separately from one public typed operation rejection, and do not alter conversion or codec behavior. [VERIFIED: .planning/phases/50-gray-alpha-image-model/50-CONTEXT.md]

## Code Examples

Verified project patterns:

### Non-symmetric Gray/Alpha Storage Regression

```moonbit
// Source pattern: modules/mb-image/storage/storage_test.mbt
let image = @storage.OwnedImage::new(gray_alpha_descriptor(), storage_budget(4UL)).unwrap()
image.with_mut_view(fn(view) {
  view.set_byte(0UL, 0UL, 0UL, b'\x13').unwrap() // gray
  view.set_byte(0UL, 0UL, 1UL, b'\xE7').unwrap() // alpha
  view.set_byte(1UL, 0UL, 0UL, b'\xC1').unwrap()
  view.set_byte(1UL, 0UL, 1UL, b'\x2A').unwrap()
  Ok(())
}).unwrap()
let view = image.view()
inspect(view.get_byte(0UL, 0UL, 0UL).unwrap(), content="b'\\x13'")
inspect(view.get_byte(0UL, 0UL, 1UL).unwrap(), content="b'\\xE7'")
inspect(view.get_byte(0UL, 0UL, 2UL) is Err(_), content="true")
```

The non-symmetric pairs make an accidental gray/alpha swap or an omitted alpha observable. [VERIFIED: .planning/phases/50-gray-alpha-image-model/50-CONTEXT.md]

### Exhaustive Fail-Closed Operation Admission

```moonbit
// Source pattern: modules/mb-image/ops/copy_flip.mbt
match format.channels() {
  @model.ChannelOrder::Rgb => metadata.alpha() is None
  @model.ChannelOrder::Rgba => /* retain existing RGBA rule */
  @model.ChannelOrder::Gray => false
  @model.ChannelOrder::GrayAlpha => false
}
```

The same deliberate false result is needed for `ImageDescriptor::supports_reference_operations`; the RGB/RGBA-only predicates in processing and resize already reject the new case without modification. [VERIFIED: modules/mb-image/model/descriptor.mbt; modules/mb-image/ops/{copy_flip,processing,resize}.mbt]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Three-order descriptor model (`Gray`, `Rgb`, `Rgba`) | Explicit four-order model including `GrayAlpha` | Phase 50 | The model can represent two-component straight-alpha grayscale without overloading `Gray` metadata. [VERIFIED: modules/mb-image/model/descriptor.mbt; .planning/ROADMAP.md] |
| Separate storage implementation per pixel format | Descriptor-driven generic packed storage and views | Existing architecture | Gray+Alpha can reuse checked allocation, leases, offsets, and crops. [VERIFIED: modules/mb-image/storage/{owned_image,views}.mbt] |

**Deprecated/outdated:** No existing API is deprecated by this phase; adding `GrayAlpha` is additive and legacy formats retain their behavior. [VERIFIED: .planning/phases/50-gray-alpha-image-model/50-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The public convenience factory should be spelled `ImageFormat::graya8()` to parallel `rgb8()` and `rgba8()`. | Architecture Patterns / Code Examples | It becomes a public API name; changing it later is a compatibility cost. [ASSUMED] |

## Open Questions

1. **Exact public factory spelling**
   - What we know: D-01 locks an `ImageFormat` convenience factory consistent with `rgb8()`/`rgba8()`. [VERIFIED: .planning/phases/50-gray-alpha-image-model/50-CONTEXT.md]
   - What's unclear: The exact identifier is not named in the locked decision. [VERIFIED: .planning/phases/50-gray-alpha-image-model/50-CONTEXT.md]
   - Recommendation: Use `graya8()` unless the planner/operator chooses another public spelling before implementation. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| MoonBit toolchain (`moon`, `moonc`, `moonrun`) | Compile and run model/storage/operation tests | ✓ | `moon 0.1.20260713`, `moonc v0.10.4`, `moonrun 0.1.20260713` | None; this is the project runtime. [VERIFIED: `moon --version`] |

**Missing dependencies with no fallback:** None. [VERIFIED: `moon --version`]

**Missing dependencies with fallback:** None. [VERIFIED: `moon --version`]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | No authentication boundary is introduced. [VERIFIED: .planning/REQUIREMENTS.md] |
| V3 Session Management | No | No session state is introduced. [VERIFIED: .planning/REQUIREMENTS.md] |
| V4 Access Control | No | No authorization boundary is introduced. [VERIFIED: .planning/REQUIREMENTS.md] |
| V5 Input Validation | Yes | `ImageDescriptor::new`, `PlaneDescriptor::new`, view capability gates, bounds checks, and checked arithmetic validate dimensions, metadata, planes, and component access. [VERIFIED: modules/mb-image/model/descriptor.mbt; modules/mb-image/storage/views.mbt] |
| V6 Cryptography | No | No cryptographic operation or key material is introduced. [VERIFIED: .planning/REQUIREMENTS.md] |

### Known Threat Patterns for MoonBit Image Descriptors

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malformed Gray+Alpha plane length or row bytes | Tampering | Preserve descriptor plane-count, row-shape, containment, overlap, and checked-arithmetic validation; add a two-component valid-case regression. [VERIFIED: modules/mb-image/model/descriptor.mbt] |
| Invalid alpha identity (missing or premultiplied) | Tampering | Require `Some(Straight)` for `GrayAlpha` and retain existing legacy rules unchanged. [VERIFIED: .planning/phases/50-gray-alpha-image-model/50-CONTEXT.md; modules/mb-image/model/descriptor.mbt] |
| Out-of-range component index | Tampering | Let view access compare `channel` with format-derived `channel_count()` before checked offset calculation. [VERIFIED: modules/mb-image/storage/views.mbt] |
| Unsupported operation applied to new format | Elevation of Privilege | Preserve capability-gate rejection rather than reusing RGB/RGBA color-processing paths. [VERIFIED: modules/mb-image/ops/{copy_flip,processing,resize}.mbt] |

## Sources

### Primary (HIGH confidence)

- `modules/mb-image/model/descriptor.mbt` — public enum/factory surface, component count, alpha/plane validation, and reference-operation admission. [VERIFIED: codebase]
- `modules/mb-image/storage/owned_image.mbt` and `modules/mb-image/storage/views.mbt` — owned allocation, callback-scoped mutation, packed view eligibility, bounds, and offsets. [VERIFIED: codebase]
- `modules/mb-image/ops/copy_flip.mbt`, `processing.mbt`, and `resize.mbt` — operation capability boundaries. [VERIFIED: codebase]
- `modules/mb-image/png/encode.mbt` and `.planning/phases/50-gray-alpha-image-model/50-CONTEXT.md` — explicit codec scope boundary and locked phase decisions. [VERIFIED: codebase]

### Secondary (MEDIUM confidence)

- [MoonBit language fundamentals](https://docs.moonbitlang.com/en/latest/language/fundamentals.html) — enum constructors and pattern matching require deliberate branch handling. [CITED: docs.moonbitlang.com/en/latest/language/fundamentals.html]
- [W3C PNG Specification](https://w3c.github.io/png/) — PNG supports grayscale with alpha, which is deliberately deferred to Phase 51. [CITED: w3c.github.io/png]

### Tertiary (LOW confidence)

- None. [VERIFIED: research session]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — this is an existing MoonBit workspace change with no package addition. [VERIFIED: modules/mb-image/moon.mod.json; `moon --version`]
- Architecture: HIGH — descriptor, storage, view, and operation admission paths were inspected directly. [VERIFIED: modules/mb-image/{model,storage,ops}]
- Pitfalls: HIGH — each pitfall follows a concrete validation branch, offset calculation, or operation predicate. [VERIFIED: modules/mb-image/{model,storage,ops}]

**Research date:** 2026-07-22
**Valid until:** 2026-08-21 — the implementation findings are codebase-specific; refresh if any of the inspected model/storage/operation files change. [ASSUMED]
