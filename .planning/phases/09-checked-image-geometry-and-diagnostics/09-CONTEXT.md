# Phase 9: Checked Image Geometry and Diagnostics - Context

**Gathered:** 2026-07-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Extend the existing portable `mb-image/ops` reference-operation family with a checked crop and explicit right-angle rotation API, while consolidating the observable failure rules for geometry operations. The phase preserves the existing flip, orientation-normalization, and nearest-neighbor resize implementations rather than replacing them.

</domain>

<decisions>
## Implementation Decisions

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

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone contract
- `.planning/PROJECT.md` — v0.3 code-first scope and portability constraints.
- `.planning/REQUIREMENTS.md` — GEOM-01 through GEOM-03 and RASTER-03 acceptance scope.
- `.planning/ROADMAP.md` — Phase 9 goal, requirements, and success criteria.

### Existing image-operation contracts
- `modules/mb-image/ops/copy_flip.mbt` — `ImageOperationResult`, capability predicate, allocation, error, copy, and flip patterns to extend.
- `modules/mb-image/ops/orientation.mbt` — coordinate mapping and metadata normalization semantics for orientation realization.
- `modules/mb-image/ops/resize.mbt` — deterministic nearest-neighbor mapping and checked allocation/work accounting.
- `modules/mb-image/model/descriptor.mbt` — `Rect`, image format, metadata, orientation, and validated descriptor contracts.
- `modules/mb-image/storage/owned_image.mbt` — owned output allocation and mutable-view access boundary.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ImageOperationResult`, `operation_error`, `supports_copy_flip`, `tight_descriptor`, and `preserve_all_disposition` in `ops/copy_flip.mbt` provide the established portable operation skeleton.
- `orientation_destination` and `orientation_descriptor` in `ops/orientation.mbt` already demonstrate safe swapped-axis output mapping.
- `resized_descriptor` and `nearest_source_index` in `ops/resize.mbt` establish checked multiplication and deterministic resampling behavior.
- `@model.Rect` supplies checked `right` and `bottom` coordinates.

### Established Patterns
- Public operations return `Result[..., @error.CoreError]`, allocate via `OwnedImage::new_operation`, and write only inside `with_mut_view`.
- Image operations accept packed U8 sRGB RGB/RGBA inputs and reject unsupported forms at the capability boundary.
- Black-box `*_test.mbt` and invariant/adversarial `*_wbtest.mbt` are both used for the `ops` package.

### Integration Points
- New geometry code belongs in `modules/mb-image/ops`, exports through its existing package manifest, and must use `mb-core` checked arithmetic and budget accounting.

</code_context>

<specifics>
## Specific Ideas

The user explicitly prioritized function code and tests over further release automation. This phase should therefore create reusable MoonBit image transformations with tests rather than any publication scripts.

</specifics>

<deferred>
## Deferred Ideas

- High-quality interpolation kernels belong to a later milestone requirement (`RESIZE-01`).
- Alpha compositing and filters belong to Phase 10.
- Registry publication automation remains deferred outside v0.3.

</deferred>

---

*Phase: 9-Checked Image Geometry and Diagnostics*
*Context gathered: 2026-07-20*
