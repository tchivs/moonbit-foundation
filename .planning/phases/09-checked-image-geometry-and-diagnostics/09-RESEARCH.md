# Phase 9: Checked Image Geometry and Diagnostics - Research

**Researched:** 2026-07-20  
**Domain:** Portable MoonBit raster geometry and deterministic diagnostics  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Geometry API shape
- **D-01:** Crop produces a new tightly packed `OwnedImage`, not a borrowed view, so callers may freely compose it with existing copy/resize operations and budgets cover all output storage.
- **D-02:** Expose explicit 90°, 180°, and 270° rotations as image operations; metadata-driven `apply_orientation` remains supported but is not the public substitute for an explicit requested rotation.
- **D-03:** Cropping and rotation preserve the existing image format and color/alpha metadata; operations that materially realize orientation normalize resulting orientation metadata to `TopLeft` consistently with `apply_orientation`.

### Capability and diagnostics
- **D-04:** Match the existing reference-operation capability boundary: packed sRGB U8 RGB/RGBA only; unsupported formats fail deterministically with `CapabilityUnavailable` and do not silently convert.
- **D-05:** Validate crop regions with checked end coordinates before allocation; empty, out-of-bounds, overflowed, or budget-rejected requests return typed `CoreError` values rather than panicking or partially allocating.
- **D-06:** Nearest-neighbor resize remains the sole resampling algorithm in this phase. It is a deterministic reference baseline, not a quality-oriented interpolation API.

### the agent's Discretion
- File layout, helper naming, and whether rotations reuse a generalized coordinate mapper or focused routines should follow the established `ops` package style.
- Tests should focus on externally observable pixels, dimensions, metadata disposition, error category/code/context, overflow, and budget behavior.

### Deferred Ideas (OUT OF SCOPE)
- High-quality interpolation kernels belong to a later milestone requirement (`RESIZE-01`).
- Alpha compositing and filters belong to Phase 10.
- Registry publication automation remains deferred outside v0.3.
</user_constraints>

## Project Constraints (from AGENTS.md)

- Keep core algorithms and shared data models in MoonBit; keep all four declared portable targets working. [CITED: AGENTS.md]
- Maintain acyclic public-package dependencies; do not add GUI-state or release-automation work to this phase. [CITED: AGENTS.md]
- Public APIs require SemVer-minded stability; operations must be deterministic and usable by CLI/agent/MCP consumers. [CITED: AGENTS.md]
- Public-package black-box tests and internal/adversarial white-box tests are established project practice. [CITED: AGENTS.md; .planning/PROJECT.md]
- Do not modify module implementation during research; Phase 9 scope explicitly excludes publication automation. [CITED: .planning/phases/09-checked-image-geometry-and-diagnostics/09-CONTEXT.md]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| GEOM-01 | Crop into a checked rectangular result without out-of-bounds access or overflow allocation. | Use `@model.Rect` checked endpoints, validate bounds before `OwnedImage::new_operation`, and copy only the requested stored-coordinate rectangle. |
| GEOM-02 | Flip horizontally/vertically and rotate by right angles while preserving pixel semantics. | Retain existing flips; add explicit rotations with source-to-destination maps and normalized orientation metadata. |
| GEOM-03 | Deterministic nearest-neighbor resize across targets. | Preserve `resize_nearest` and its floor mapping; extend only its shared diagnostics coverage if needed. |
| RASTER-03 | Typed deterministic errors for unsupported formats, invalid regions, incompatible dimensions, and limits. | Reuse `CoreError`, capability predicate, checked arithmetic, and authoritative `Budget` allocation/work charging. |
</phase_requirements>

## Summary

Phase 9 should be an additive extension of `modules/mb-image/ops`, not a geometry rewrite. The existing package already has the exact portable operation skeleton: `ImageOperationResult`, one packed-sRGB U8 RGB/RGBA capability predicate, checked descriptor construction, one `OwnedImage::new_operation` charge, and callback-bounded pixel writes. [CITED: modules/mb-image/ops/copy_flip.mbt; modules/mb-image/storage/owned_image.mbt]

Implement checked crop as a fresh, tightly packed output and add explicit `rotate_90`, `rotate_180`, and `rotate_270` operations. Validate capability and all crop shape/bounds conditions before allocation. Reuse the existing orientation realization semantics for metadata normalization and swapped dimensions, but do not expose `apply_orientation` as a rotation substitute because it is driven by source metadata. [CITED: modules/mb-image/ops/orientation.mbt; .planning/phases/09-checked-image-geometry-and-diagnostics/09-CONTEXT.md]

**Primary recommendation:** Add a focused `geometry.mbt` plus matching public and white-box tests; reuse shared package-private helpers from `copy_flip.mbt` rather than changing flip, orientation, or resize behavior.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Checked crop and right-angle rotation | Library / portable core | Storage | Coordinate mapping and validation are pure MoonBit; storage supplies the controlled fresh output lease. [CITED: modules/mb-image/ops/*.mbt; modules/mb-image/storage/owned_image.mbt] |
| Resource-limit diagnostics | Library / portable core | `mb-core` budget/error | `OwnedImage::new_operation` makes the one authoritative allocation/work charge using validated descriptor dimensions. [CITED: modules/mb-image/storage/owned_image.mbt] |
| Existing nearest-neighbor resize | Library / portable core | — | It already uses integer floor mapping with checked multiplication and has no host dependency. [CITED: modules/mb-image/ops/resize.mbt] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| MoonBit `mb-image/ops` | workspace source | Public geometry operations | Existing portable operation family and public contract. [CITED: modules/mb-image/ops/moon.pkg] |
| MoonBit `mb-image/model` | workspace source | `Rect`, descriptor, format, metadata, orientation | Owns validated geometry/data contracts. [CITED: modules/mb-image/model/descriptor.mbt] |
| MoonBit `mb-image/storage` | workspace source | Fresh owned output and mutable write boundary | Encapsulates charged allocation and safe mutation. [CITED: modules/mb-image/storage/owned_image.mbt] |
| MoonBit `mb-core/checked`, `budget`, `error` | workspace source | Overflow-safe arithmetic, resource charging, stable errors | Already imported by `ops` and used by all existing operations. [CITED: modules/mb-image/ops/moon.pkg; modules/mb-core/error/core_error.mbt] |

### Supporting

| Library | Purpose | When to Use |
|---------|---------|-------------|
| `mb-image/metadata` | `MetadataDisposition` | Preserve all fields for crop; mark orientation transformed for explicit rotations. [CITED: modules/mb-image/ops/copy_flip.mbt; modules/mb-image/ops/orientation.mbt] |
| `mb-color/model` and `profile` | Validate/pass color and alpha identity | Via the existing capability predicate and descriptor metadata, without conversion. [CITED: modules/mb-image/ops/copy_flip.mbt] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Fresh crop image | Borrowed `ImageView` subregion | Rejected by locked D-01: a view cannot independently account output storage or offer the required composable owned result. [CITED: 09-CONTEXT.md] |
| Explicit rotations | `apply_orientation` alone | Rejected by locked D-02: it realizes metadata-selected orientation, not an API caller's requested angle. [CITED: 09-CONTEXT.md; modules/mb-image/ops/orientation.mbt] |
| Nearest neighbor | New interpolation kernel | Deferred by locked D-06 and `RESIZE-01`. [CITED: 09-CONTEXT.md; .planning/REQUIREMENTS.md] |

**Installation:** None; use existing workspace packages. [CITED: modules/mb-image/ops/moon.pkg]

## Package Legitimacy Audit

No external package installation is required. The phase uses only existing workspace MoonBit packages. [CITED: modules/mb-image/ops/moon.pkg]

## Architecture Patterns

### System Architecture Diagram

```text
ImageView + requested Rect/angle + Budget
              |
              v
capability gate (packed U8 sRGB RGB/RGBA) ----unsupported----> CoreError(CapabilityUnavailable)
              |
              v
checked region/dimension/byte/work calculations ----invalid----> CoreError(InvalidRange/InvalidDimensions/ArithmeticOverflow)
              |
              v
validated tight ImageDescriptor + metadata disposition
              |
              v
OwnedImage::new_operation (one authoritative budget charge) ----limit----> CoreError(BudgetExceeded)
              |
              v
with_mut_view: stored-coordinate pixel permutation/copy
              |
              v
ImageOperationResult { OwnedImage, MetadataDisposition }
```

### Recommended Project Structure

```text
modules/mb-image/ops/
├── copy_flip.mbt                 # retain shared result/capability/allocation helpers
├── orientation.mbt               # retain metadata-driven realization
├── resize.mbt                    # retain nearest-neighbor baseline
├── geometry.mbt                  # new crop + explicit 90/180/270 operations
├── geometry_test.mbt             # new public behavior/error tests
└── geometry_wbtest.mbt           # new arithmetic/budget/oracle tests
```

### Pattern 1: Validate then allocate once
**What:** Each operation rejects unsupported input and constructs a fully validated tight descriptor before calling `OwnedImage::new_operation`; only then does it enter `with_mut_view`. [CITED: modules/mb-image/ops/copy_flip.mbt; modules/mb-image/ops/resize.mbt]

**Use for crop:** First reject unsupported input; reject `Rect::is_empty()` with `InvalidInput/InvalidDimensions`; require `rect.right() <= source.width()` and `rect.bottom() <= source.height()` with `InvalidInput/InvalidRange`; construct all output multiplications with `@checked`; then allocate. `Rect::new` already checked `x + width` and `y + height`, but callers can pass a valid `Rect` whose endpoint lies outside the source, so both checks remain necessary. [CITED: modules/mb-image/model/descriptor.mbt; modules/mb-image/ops/copy_flip.mbt]

### Pattern 2: Source-to-destination mapping for rotations
**What:** Iterate source pixels once and compute a destination coordinate, as `apply_orientation` does. [CITED: modules/mb-image/ops/orientation.mbt]

**Use for explicit rotations:** For stored source dimensions `(w,h)`, use these clockwise mappings; `90` and `270` outputs are `(h,w)`, while `180` remains `(w,h)`:

| Operation | Source `(x,y)` → destination `(dx,dy)` |
|-----------|-----------------------------------------|
| `rotate_90` | `(h - 1 - y, x)` |
| `rotate_180` | `(w - 1 - x, h - 1 - y)` |
| `rotate_270` | `(y, w - 1 - x)` |

These maps correspond respectively to the existing `RightTop`, `BottomRight`, and `LeftBottom` orientation destination cases. [CITED: modules/mb-image/ops/orientation.mbt]

### Pattern 3: Metadata disposition follows physical realization
**What:** Copy/flip/resize preserve all five fields, while `apply_orientation` transforms the orientation disposition and constructs `TopLeft` output metadata. [CITED: modules/mb-image/ops/copy_flip.mbt; modules/mb-image/ops/orientation.mbt; modules/mb-image/ops/resize.mbt]

**Use for crop/rotate:** Crop uses `preserve_all_disposition()` and retains source metadata. Explicit rotations use the orientation disposition/normalizer already present in `orientation.mbt`: preserve alpha/color/opaque/profile, transform orientation, and write `TopLeft`. [CITED: modules/mb-image/ops/orientation.mbt; 09-CONTEXT.md]

### Anti-Patterns to Avoid

- **A crop `ImageView` return:** violates D-01 and bypasses an independently charged, tightly packed output. [CITED: 09-CONTEXT.md]
- **Unchecked `x + width`/`y + height`:** can wrap before the source-bound test; receive `Rect` or use checked arithmetic before allocation. [CITED: modules/mb-image/model/descriptor.mbt]
- **Duplicating the capability predicate:** reuse `supports_copy_flip` (or rename only if all existing callers remain behaviorally identical), so geometry cannot drift to a different accepted format set. [CITED: modules/mb-image/ops/copy_flip.mbt]
- **Calling `apply_orientation` for requested rotations:** its mapping is chosen by metadata and would give the wrong result for arbitrary source orientation metadata. [CITED: modules/mb-image/ops/orientation.mbt]
- **Introducing interpolation, conversion, alpha work, or release scripts:** each is expressly deferred/out of phase. [CITED: 09-CONTEXT.md; .planning/REQUIREMENTS.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Overflow checking | Local `UInt64` arithmetic guards | `@checked.checked_add` / `@checked.checked_mul` and `@model.Rect` | Existing contracts return typed `CoreError` and centralize overflow semantics. [CITED: modules/mb-image/model/descriptor.mbt; modules/mb-image/ops/resize.mbt] |
| Output budgeting | Per-pixel or post-allocation counters | `OwnedImage::new_operation` | It charges storage, allocation, dimensions, pixels, and explicit work atomically before write access. [CITED: modules/mb-image/storage/owned_image.mbt] |
| Format eligibility | New crop/rotation-specific rules | `supports_copy_flip` | Maintains D-04 with existing RGB/RGBA alpha/color rules. [CITED: modules/mb-image/ops/copy_flip.mbt] |
| Orientation metadata policy | New ad-hoc disposition | `orientation_disposition` and `normalized_orientation_metadata` | Existing physical-orientation realization already defines the correct observable contract. [CITED: modules/mb-image/ops/orientation.mbt] |

## Common Pitfalls

### Pitfall 1: Validation after allocation
**What goes wrong:** A bad crop or unsupported format consumes a budget counter or allocates before returning its typed failure. [CITED: modules/mb-image/ops/copy_flip_wbtest.mbt; modules/mb-image/ops/resize_convert_wbtest.mbt]

**Avoid:** Order checks as capability → empty/bounds/arithmetic → descriptor → `new_operation`; test the complete `Budget::remaining()` snapshot is unchanged for every pre-allocation failure. [CITED: modules/mb-image/ops/resize.mbt; modules/mb-image/storage/owned_image.mbt]

### Pitfall 2: Rotating dimensions but retaining orientation metadata
**What goes wrong:** Pixels are physically reoriented but downstream display logic applies stale metadata a second time. [CITED: modules/mb-image/ops/orientation.mbt]

**Avoid:** Explicit rotations must use `TopLeft` metadata and mark orientation transformed, just as `apply_orientation` does. [CITED: 09-CONTEXT.md; modules/mb-image/ops/orientation.mbt]

### Pitfall 3: Treating padded source storage as packed output
**What goes wrong:** Copying rows wholesale includes source padding or preserves a non-tight stride. [CITED: modules/mb-image/ops/copy_flip_test.mbt]

**Avoid:** Create a descriptor from output width, height, pixel byte width, and tight row bytes; copy logical pixels/channels with accessors. [CITED: modules/mb-image/ops/copy_flip.mbt]

### Pitfall 4: Replacing stable resize while adding diagnostics
**What goes wrong:** A change to nearest-neighbor mapping alters GEOM-03 behavior outside the need for crop/rotation. [CITED: modules/mb-image/ops/resize.mbt; .planning/REQUIREMENTS.md]

**Avoid:** Leave `resize_nearest`, `nearest_source_index`, and generated resize vectors intact; only test/document their existing contract as phase evidence. [CITED: modules/mb-image/ops/resize.mbt; modules/mb-image/ops/reference_vectors_wbtest.mbt]

## Code Examples

### Planned public API shape

```moonbit
pub fn crop(
  source : @storage.ImageView,
  region : @model.Rect,
  budget : @budget.Budget,
) -> Result[ImageOperationResult, @error.CoreError]

pub fn rotate_90(source : @storage.ImageView, budget : @budget.Budget)
  -> Result[ImageOperationResult, @error.CoreError]

pub fn rotate_180(source : @storage.ImageView, budget : @budget.Budget)
  -> Result[ImageOperationResult, @error.CoreError]

pub fn rotate_270(source : @storage.ImageView, budget : @budget.Budget)
  -> Result[ImageOperationResult, @error.CoreError]
```

The names are a prescriptive planning recommendation, not a pre-existing API. They match the package's existing free-function style (`flip_horizontal`, `resize_nearest`, `apply_orientation`). [CITED: modules/mb-image/ops/copy_flip.mbt; modules/mb-image/ops/resize.mbt; modules/mb-image/ops/orientation.mbt]

### Crop write-loop shape

```moonbit
// After capability, empty/bounds, descriptor, and budget checks succeed.
output.with_mut_view(fn(destination) {
  for y = 0UL; y < region.height(); y = y + 1UL {
    for x = 0UL; x < region.width(); x = x + 1UL {
      for channel = 0UL; channel < source.format().channel_count(); channel = channel + 1UL {
        let value = source.get_byte(region.x() + x, region.y() + y, channel)?
        destination.set_byte(x, y, channel, value)?
      }
    }
  }
  Ok(())
})
```

This is a shape-only sketch: MoonBit implementation should use the existing explicit `match ... Err(error) => return Err(error)` style if postfix `?` is unavailable in the current compiler mode. [CITED: modules/mb-image/ops/copy_flip.mbt]

## State of the Art

| Existing capability | Phase 9 disposition | Impact |
|---------------------|---------------------|--------|
| `copy_image`, horizontal and vertical flips | Preserve unchanged | GEOM-02's flip portion already exists; add regression coverage only as needed. [CITED: modules/mb-image/ops/copy_flip.mbt] |
| Metadata-driven `apply_orientation` for all eight EXIF-style orientations | Preserve unchanged and reuse internals | It remains the metadata realization API; explicit rotation is additional. [CITED: modules/mb-image/ops/orientation.mbt; 09-CONTEXT.md] |
| `resize_nearest` floor mapping | Preserve unchanged | It is the sole phase resampling baseline. [CITED: modules/mb-image/ops/resize.mbt; 09-CONTEXT.md] |
| RGB/RGBA conversion helpers | Preserve unchanged | Pixel format conversion is not a geometry fallback. [CITED: modules/mb-image/ops/convert.mbt; 09-CONTEXT.md] |

## Test and Verification Plan

### Files to add

| File | Tests |
|------|-------|
| `modules/mb-image/ops/geometry_test.mbt` | Public crop result is tight/fresh; RGB and RGBA pixels; all three rotations on a non-square matrix; dimensions; metadata/disposition; deterministic error category/code/context. |
| `modules/mb-image/ops/geometry_wbtest.mbt` | Empty/out-of-bounds/overflow crop, unsupported formats, output/work/allocation budgets, and complete coordinate-oracle mappings. |
| `modules/mb-image/ops/reference_vectors_wbtest.mbt` | Extend generated/static operation-vector count only if the repository's fixture generator is updated; do not manually change generated content. [CITED: modules/mb-image/ops/reference_vectors_wbtest.mbt] |

### Assertions required

- Crop a padded 3×2 source at `(1,0,2,2)`: verify output width/height, tight row stride/storage length, every channel, no source aliasing, and all metadata fields/disposition preserved. [CITED: modules/mb-image/ops/copy_flip_test.mbt]
- For a non-square source, test every source pixel against each of the three mapping formulas; confirm 90/270 swap dimensions and 180 does not. [CITED: modules/mb-image/ops/orientation_wbtest.mbt]
- Confirm rotations output `TopLeft`, preserve opaque/profile/color/alpha, and make exactly orientation transformed in `MetadataDisposition`. [CITED: modules/mb-image/ops/orientation_test.mbt]
- Test `Rect::new(UInt64::max_value(), ..., 1UL, ...)` (or the repository's existing UInt64-max construction) fails before `crop`; test a non-overflowing rect extending past source yields `InvalidRange`; test empty region yields `InvalidDimensions`. [CITED: modules/mb-image/model/descriptor.mbt; modules/mb-core/error/core_error.mbt]
- Test unsupported U16, planar, Gray, non-sRGB, and invalid alpha combinations return `Capability/CapabilityUnavailable` and leave every consumable budget counter unchanged. [CITED: modules/mb-image/ops/copy_flip.mbt; modules/mb-image/ops/orientation_wbtest.mbt]
- For insufficient bytes, allocations, pixels, dimensions, and work, assert the `Budget` snapshot is unchanged when `new_operation` rejects. [CITED: modules/mb-image/storage/owned_image.mbt; modules/mb-image/ops/resize_convert_wbtest.mbt]

### Commands

```powershell
moon test modules/mb-image/ops --target js
moon test modules/mb-image/ops --target wasm
moon test modules/mb-image/ops --target wasm-gc
moon test modules/mb-image/ops --target native
moon info
```

The current untouched `ops` baseline passed 18/18 tests on each of js, wasm, wasm-gc, and native during this research. [VERIFIED: local MoonBit test run, 2026-07-20]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | No authentication surface in portable in-memory geometry. [CITED: .planning/REQUIREMENTS.md] |
| V3 Session Management | No | No session surface. [CITED: .planning/REQUIREMENTS.md] |
| V4 Access Control | No | No authorization surface. [CITED: .planning/REQUIREMENTS.md] |
| V5 Input Validation | Yes | Checked `Rect` endpoints, source bounds, checked byte calculations, capability gate, typed `CoreError`. [CITED: modules/mb-image/model/descriptor.mbt; modules/mb-image/ops/copy_flip.mbt] |
| V6 Cryptography | No | No cryptographic operation. [CITED: .planning/REQUIREMENTS.md] |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Overflowed crop endpoint or byte length | Tampering / denial of service | `Rect::new`, `checked_add`, `checked_mul`, then descriptor validation before allocation. [CITED: modules/mb-image/model/descriptor.mbt; modules/mb-image/ops/resize.mbt] |
| Oversized crop/rotation output | Denial of service | `OwnedImage::new_operation` validates the one budget charge before mutation. [CITED: modules/mb-image/storage/owned_image.mbt] |
| Unsupported layout/color/alpha interpreted as packed pixels | Tampering | `supports_copy_flip` rejects it with `CapabilityUnavailable`; never silently convert. [CITED: modules/mb-image/ops/copy_flip.mbt] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Recommended public function names are `crop`, `rotate_90`, `rotate_180`, and `rotate_270`. | Code Examples | Low: planner must keep names coherent with MoonBit API review, but no locked name decision exists. [ASSUMED] |
| A2 | New code should live in a separate `geometry.mbt` rather than extending existing files. | Recommended Project Structure | Low: locked context leaves file layout to implementer discretion. [ASSUMED] |

## Open Questions

1. **Expose a rotation enum in addition to named functions?**
   - What we know: D-02 requires explicit 90/180/270 operations, and the package uses named operation functions today. [CITED: 09-CONTEXT.md; modules/mb-image/ops/copy_flip.mbt]
   - What's unclear: Whether the project wants a future-friendly enum dispatch API as a public companion.
   - Recommendation: Ship the three named functions now; avoid an enum until a caller requires dynamic angle selection, because it is not a locked requirement. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| `moon` / `moonrun` | Compile and test portable package | ✓ | 0.1.20260713 | — [VERIFIED: local command, 2026-07-20] |
| `moonc` | MoonBit compilation | ✓ | v0.10.4+2cc641edf | — [VERIFIED: local command, 2026-07-20] |
| Native C toolchain | `--target native` test execution | ✓ | Existing suite passed | — [VERIFIED: local MoonBit test run, 2026-07-20] |

**Missing dependencies with no fallback:** None. [VERIFIED: local MoonBit test run, 2026-07-20]

## Sources

### Primary (HIGH confidence)
- `modules/mb-image/ops/copy_flip.mbt` — operation result, capability gate, tight descriptor, allocation/copy/flip conventions.
- `modules/mb-image/ops/orientation.mbt` — all orientation coordinate maps and metadata normalization.
- `modules/mb-image/ops/resize.mbt` — nearest-neighbor mapping and checked allocation/work flow.
- `modules/mb-image/model/descriptor.mbt` — `Rect`, format, descriptor and metadata contracts.
- `modules/mb-image/storage/owned_image.mbt` — authoritative allocation and mutation boundary.
- `modules/mb-image/ops/*_test.mbt`, `*_wbtest.mbt` — public and adversarial test conventions.
- Local `moon test modules/mb-image/ops --target {js,wasm,wasm-gc,native}` — 18/18 baseline on each target, executed 2026-07-20.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — every dependency is existing workspace source and directly inspected.
- Architecture: HIGH — based on the precise package-private helpers and public flows in current code.
- Pitfalls: HIGH — derived from current checked arithmetic, budget tests, and existing metadata behavior.

**Research date:** 2026-07-20  
**Valid until:** Phase 9 implementation begins, or any of the cited `mb-image` operation contracts change.
