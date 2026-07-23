# Phase 71: RGBA16 Adam7 PNG Encoding - Context

**Gathered:** 2026-07-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Extend the completed explicit RGBA16 encode profile through the existing Adam7 traversal. Library users can choose Type-6/16 interlaced output from checked `rgba16` images through both eager and caller-buffered APIs, without changing the established non-interlaced routes.

</domain>

<decisions>
## Implementation Decisions

### Explicit Adam7 selection
- **D-01:** Add exactly `PngEncoder::new_rgba16_with_interlace_strategy`, `PngEncoder::new_rgba16_with_all_strategies`, `PngChunkEncoder::new_rgba16_with_interlace_strategy`, and `PngChunkEncoder::new_rgba16_with_all_strategies`, matching the established GrayAlpha16 Adam7 families.
- **D-02:** The existing four eager and four chunk RGBA16 constructors remain explicitly non-interlaced. The new selection APIs accept the established `PngInterlaceStrategy`; Adam7 is opt-in rather than a default.

### Shared pipeline and fidelity
- **D-03:** Route both new families to `PngEncodeProfile::Rgba16` through the existing profile-aware encoder machine and Adam7 traversal/pass planner; do not duplicate byte emission, filtering, admission, progress, or terminal logic.
- **D-04:** Prove a non-symmetric 5x5 packed little-endian RGBA16 source uses legal seven-pass Type-6/16 output, and `PngDecoder::decode_rgba16` reconstructs every source component byte at its original coordinate.
- **D-05:** For Stored, FixedOrStored, and DynamicOrFixedOrStored with None and Adaptive filtering, fresh eager and caller-buffered Adam7 encodes are byte-identical and retain the existing atomic admission, accepted-only progress, lease isolation, and sticky-terminal behaviour.

### Scope and compatibility
- **D-06:** Preserve existing RGB8/RGBA8 and Gray/GrayAlpha interlace routes, generic constructors, non-interlaced RGBA16 output, colour identity gates, and source layout. Do not add colour transforms, staging, another pass planner or encoder machine, FFI, copied source trees, release automation, or broad four-target qualification; Phase 72 owns qualification.

### the agent's Discretion
- Reuse the closest GrayAlpha16 Adam7 eager/chunk constructors and their public schedule/decode harnesses; add only RGBA16-specific factory and fidelity/lifecycle evidence.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### v0.22 contracts
- `.planning/REQUIREMENTS.md` — `RGBA16ENC-03` Adam7 output requirement.
- `.planning/ROADMAP.md` — Phase 71 goal, success criteria, and scope guard.
- `.planning/phases/69-explicit-rgba16-png-encoding/69-CONTEXT.md` — RGBA16 source/profile and wire-lane contract.
- `.planning/phases/69-explicit-rgba16-png-encoding/69-VERIFICATION.md` — verified Type-6/16 eager source fidelity.
- `.planning/phases/70-resumable-rgba16-png-encoding/70-CONTEXT.md` — caller-buffered contract carried into Adam7 selection.
- `.planning/phases/70-resumable-rgba16-png-encoding/70-VERIFICATION.md` — verified chunk parity, admission, and terminal semantics.

### Existing Adam7 and RGBA16 seams
- `modules/mb-image/png/png.mbt` — eager `new_graya16_with_interlace_strategy` / `with_all_strategies` and RGBA16 non-interlaced family.
- `modules/mb-image/png/stream_encode.mbt` — chunk GrayAlpha16 Adam7 factories and shared profile-aware machine.
- `modules/mb-image/png/encode.mbt` — existing Adam7 pass traversal and filtered emission.
- `modules/mb-image/png/stream_encode_test.mbt` — eager/chunk Adam7 parity and hostile schedule patterns.
- `modules/mb-image/png/encode_test.mbt` — explicit RGBA16 decode and coordinate-fidelity oracle.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- GrayAlpha16 eager and chunk `with_interlace_strategy` / `with_all_strategies` families already supply the exact public API and construction pattern.
- The profile-aware machine already performs atomic admission, Adam7 traversal, filter/compression selection, acknowledgement-safe chunk progress, and sticky failures.
- Phase 69/70 RGBA16 sources and eager/chunk helpers expose non-symmetric U16 lanes and caller-owned lease schedules.

### Established Patterns
- High-precision interlacing is opt-in through explicit selectors; previous non-interlaced constructors are immutable compatibility baselines.
- Fresh eager bytes are the caller-buffered parity oracle; exact decode is independent of the encoder's output construction.

### Integration Points
- Add public selectors in `png.mbt` and `stream_encode.mbt`; extend existing PNG tests only. The pass planner and generic APIs remain unchanged.

</code_context>

<specifics>
## Specific Ideas

The proof source must keep all seven Adam7 passes nonempty and expose every U16 byte order at distinct coordinates; the explicit decoder must restore the original packed little-endian storage lanes.

</specifics>

<deferred>
## Deferred Ideas

- Independent hostile matrix, frozen legacy compatibility sweep, and four-target portable qualification — Phase 72.
- Colour-managed/non-sRGB RGBA16 output, conversions, staging, FFI, release automation, target wrappers, and copied source workflows — out of scope.

</deferred>

---

*Phase: 71-rgba16-adam7-png-encoding*
*Context gathered: 2026-07-23*
