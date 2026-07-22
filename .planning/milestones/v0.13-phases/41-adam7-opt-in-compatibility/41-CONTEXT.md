# Phase 41: Adam7 Opt-In Compatibility - Context

**Gathered:** 2026-07-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Publish the explicit Adam7 selection seam for the existing RGB8 and straight-RGBA8 PNG encoders while retaining every legacy non-interlaced byte route. Seven-pass pixel traversal, filtering, compression planning, and replay belong to Phase 42.

</domain>

<decisions>
## Implementation Decisions

### Public Strategy Shape
- **D-01:** Add a separate public `PngInterlaceStrategy` enum with `None` and `Adam7`; do not overload compression or filter strategies.
- **D-02:** Keep every existing factory signature unchanged and explicitly default it to `PngInterlaceStrategy::None`.
- **D-03:** Add narrow interlace-only and all-strategy factories for both eager and caller-buffered encoders. The all-strategy factory is additive; existing `new_with_strategies` stays source and byte compatible.

### Pre-Implementation Behavior
- **D-04:** Before Phase 42 provides real seven-pass bytes, an Adam7-configured compatible source must fail deterministically before eager output or a caller lease rather than silently emit non-interlaced data.
- **D-05:** Reuse the project’s typed PNG capability/error path with a stable Adam7-pending context; do not add FFI, staging, a new image representation, or a provisional encoder backend.

### Compatibility Evidence
- **D-06:** Freeze the complete-PNG bytes of all legacy eager and chunk factories, including compression-only and compression/filter combined routes; tests must show explicit `None` produces those same bytes.
- **D-07:** Test both RGB8 and straight-RGBA8 configured Adam7 rejection for eager and chunk construction/first output boundaries, including zero/tiny caller capacities where applicable.

### the agent's Discretion
- Exact public factory names, internal field names, documentation wording, and focused test selector names should follow the closest existing strategy-factory conventions.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone contract
- `.planning/ROADMAP.md` — Phase 41 goal, scope boundary, and observable success criteria.
- `.planning/REQUIREMENTS.md` — PNGI-01 compatibility requirement and explicit out-of-scope boundaries.
- `.planning/PROJECT.md` — v0.13 compatibility, boundedness, and portability constraints.

### Existing public and private contracts
- `modules/mb-image/png/png.mbt` — existing public compression/filter strategy types and eager factories that must remain compatible.
- `modules/mb-image/png/stream_encode.mbt` — caller-buffered public factories and one shared private machine construction path.
- `modules/mb-image/png/encode.mbt` — preflight/error routing and existing bounded filtering/compression integration.
- `modules/mb-image/png/structural.mbt` — tested Adam7 pass geometry reusable by Phase 42; Phase 41 must not duplicate it.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `PngCompressionStrategy` and `PngFilterStrategy`: separate equality-comparable public selection enums establish the API pattern for interlace selection.
- `PngEncoder::new_with_strategies` and `PngChunkEncoder::new_with_strategies`: existing additive combined-factory seams.
- `PngEncodeMachine::new_with_strategies`: the sole private construction boundary that can retain an interlace intent without changing legacy routes.
- `_png_adam7_passes` in `structural.mbt`: checked pass geometry already used by decoder-side logic and reserved for Phase 42.

### Established Patterns
- Default and compression-only constructors pass explicit `None` strategies into the common machine.
- Constructor/preflight failures occur before eager bytes or a caller-buffered encoder lease is visible.
- Public byte compatibility uses immutable complete PNG vectors, not a second live encoder route as an oracle.

### Integration Points
- Add the interlace choice through `png.mbt` public configuration, forward it through `stream_encode.mbt`, and retain it in the shared machine/preflight boundary in `encode.mbt` without adding seven-pass emission yet.

</code_context>

<specifics>
## Specific Ideas

No visual or product-specific reference applies; follow the established additive strategy API and typed-error vocabulary.

</specifics>

<deferred>
## Deferred Ideas

- Phase 42 owns real Adam7 seven-pass traversal, bounded filter/compression planning, and acknowledgement-safe replay.
- Phase 43 owns generated public fidelity and independent four-target evidence.
- Palette, grayscale, 16-bit, APNG, metadata, and colour-conversion encoding remain outside v0.13.

</deferred>

---

*Phase: 41-adam7-opt-in-compatibility*
*Context gathered: 2026-07-22*
