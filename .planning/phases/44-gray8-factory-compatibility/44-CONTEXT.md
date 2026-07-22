# Phase 44: Gray8 Factory Compatibility - Context

**Gathered:** 2026-07-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver standards-compliant, non-interlaced, 8-bit Gray PNG output through one explicit eager factory and one matching caller-buffered factory. The phase preserves every existing RGB8/RGBA8 factory and byte stream; Phase 45 extends this working Stored route to the existing filter and Fixed/Dynamic strategy families.

</domain>

<decisions>
## Implementation Decisions

### Explicit Gray8 selection
- **D-01:** Add one small, symmetric explicit `new_gray8` factory on each eager/chunk surface rather than changing existing factories or inferring a new output profile from `ImageView` alone.
- **D-02:** These Phase 44 factories produce working PNG colour type 0, bit depth 8, non-interlaced output through the established Stored route. Phase 45 may add explicit Gray8 strategy variants only after it extends the shared bounded filter and Fixed/Dynamic planning path.

### Compatibility and rejection boundary
- **D-03:** Existing constructors retain their present RGB8/straight-RGBA8 admission and frozen output exactly. Gray8 factories admit only packed, tightly-rowed `ChannelOrder::Gray` + `U8`, top-left, opaque-metadata-free inputs with the current canonical metadata contract.
- **D-04:** Wrong profile/source pairs, Gray16, planar rows, alpha/transparency conversion, and Gray8+Adam7 fail before output or a chunk encoder is made available, with stable typed capability contexts. No implicit RGB-to-Gray conversion is introduced.

### Verification posture
- **D-05:** Phase 44 tests prove real eager and caller-buffered Stored Gray8 output, source rejection, and legacy RGB/RGBA byte compatibility. Cross-strategy bounded planning, broad hostile schedules, and independent four-target public fidelity remain the explicit responsibility of Phases 45 and 46.

### the agent's Discretion
Use the smallest public names and internal profile representation that follow the existing `new_with_*` constructor style without multiplying duplicate implementations.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone contract
- `.planning/ROADMAP.md` — Phase 44 goal, ordering, and scope boundary.
- `.planning/REQUIREMENTS.md` — `GRAYPNG-01` and the deliberately deferred Gray PNG features.

### Public encoder and data model
- `modules/mb-image/png/png.mbt` — existing eager/chunk constructor families and strategy types.
- `modules/mb-image/png/encode.mbt` — shared source admission, preflight, and filtering constraints.
- `modules/mb-image/png/stream_encode.mbt` — caller-buffered construction and terminal behavior.
- `modules/mb-image/model/descriptor.mbt` — `ChannelOrder::Gray` and packed U8 image-format semantics.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `PngEncoder` and `PngChunkEncoder` in `png.mbt`: expose the parallel default construction surfaces that the two Gray8 factories extend.
- `_png_encode_source` and the common Stored preflight in `encode.mbt`: one admission gate can receive a profile selection instead of duplicating limits, budget, and layout checks.
- Existing `stream_encode_test.mbt` hostile-lease helpers: public chunk constructor behavior already has an established test shape.

### Established Patterns
- Optional PNG features are additive explicit selections; default and legacy constructors must retain frozen bytes.
- The encoder performs all semantic/resource preflight before bytes are exposed or caller-buffered state begins.

### Integration Points
- Eager `@codec.ImageEncoder::encode(PngEncoder, ImageView, Writer)` flows through the `PngEncoder` stored selection.
- `PngChunkEncoder` retains an immutable image plus private emitter state, so its Gray8 factory must reject before a usable encoder is returned.

</code_context>

<specifics>
## Specific Ideas

No additional user-facing requirements: use the standard PNG Gray8 representation and keep the API deliberately narrow.

</specifics>

<deferred>
## Deferred Ideas

- Palette/indexed output, 1/2/4-bit Gray packing, Gray16, `tRNS`/alpha conversion, Gray8 Adam7, and Gray8 Fixed/Dynamic/adaptive-filter variants are later additive contracts.
- Registry publication and release automation remain outside this code-first milestone.

</deferred>

---

*Phase: 44-Gray8 Factory Compatibility*
*Context gathered: 2026-07-22*
