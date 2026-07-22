# Phase 50: Gray+Alpha Image Model - Context

**Gathered:** 2026-07-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Add the smallest first-class packed U8 Gray+Alpha image-model contract: two components per pixel and explicit straight-alpha metadata. Preserve existing Gray/RGB/RGBA descriptors, storage, views, and operations; PNG emission is a later phase.
</domain>

<decisions>
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
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone contract
- `.planning/ROADMAP.md` — Phase 50 goal and success criteria; Phases 51-52 own PNG encoding and public evidence.
- `.planning/REQUIREMENTS.md` — `GRAYA-01` boundary and v0.16 exclusions.
- `.planning/PROJECT.md` — current milestone objective, portability, compatibility, and MoonBit-native constraints.

### Established image and PNG contracts
- `modules/mb-image/model/descriptor.mbt` — `ChannelOrder`, `ImageFormat`, component count, and metadata validation surface.
- `modules/mb-image/storage/owned_image.mbt` — owned image construction and callback-scoped storage pattern.
- `modules/mb-image/storage/views.mbt` — checked component access and image view behavior.
- `modules/mb-image/png/encode.mbt` — current profile admission boundaries; Phase 50 must not alter PNG output behavior.
- `.planning/milestones/v0.15-phases/49-portable-gray16-public-evidence/49-CONTEXT.md` — shared bounded-path and evidence conventions that later v0.16 phases must retain.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ImageFormat::rgb8()` and `ImageFormat::rgba8()` establish the public convenience-factory shape.
- `ChannelOrder` and `ImageFormat::channel_count()` centralize component-count semantics.
- Storage views already expose checked packed-component access, so Gray+Alpha can use the existing packed storage model.

### Established Patterns
- Alpha-bearing `Rgba` images require explicit straight-alpha metadata; opaque Gray images reject alpha metadata.
- PNG profile admission is explicit and fail-closed before reading pixels or exposing output.
- Public packages use black-box `*_test.mbt` coverage alongside focused internal invariant tests.

### Integration Points
- Model descriptor and its tests define the new order; storage tests cover construction and indexed components.
- Later PNG phases extend `modules/mb-image/png/png.mbt`, `encode.mbt`, and `stream_encode.mbt` rather than adding a parallel encoder.
</code_context>

<specifics>
## Specific Ideas

Use non-symmetric gray/alpha component pairs in tests so swapped order and omitted alpha cannot pass accidentally.
</specifics>

<deferred>
## Deferred Ideas

- Gray+Alpha16 and Gray+Alpha Adam7 — future requirements after the 8-bit non-interlaced contract is verified.
- Gray+Alpha PNG factories and wire behavior — Phase 51.
- Portable hostile-capacity and four-target public evidence — Phase 52.
</deferred>

---

*Phase: 50-gray-alpha-image-model*
*Context gathered: 2026-07-22*
