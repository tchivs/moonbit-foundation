# Phase 51: Bounded Gray+Alpha PNG Encoding - Context

**Gathered:** 2026-07-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Add explicit eager and caller-buffered PNG routes for the Phase 50 packed U8 straight-alpha Gray+Alpha model. The routes emit standards-compliant, non-interlaced PNG type 4 / bit depth 8 through the established bounded encoder; public four-target and hostile-schedule evidence remains Phase 52.

</domain>

<decisions>
## Implementation Decisions

### Public route shape
- **D-01:** Mirror the established Gray16 factory family with explicit `graya8` eager and caller-buffered factories for default, compression-only, filter-only, and combined strategy selection. — **Reversibility:** one-way — factory spellings become public package API.
- **D-02:** Admit only the Phase 50 locked descriptor identity: packed U8 `GrayAlpha`, straight alpha, encoded sRGB, builtin sRGB, top-left. Reject incompatible inputs through the existing typed PNG capability boundary before output or caller lease exposure. — **Reversibility:** costly — widening changes a public PNG compatibility contract and bounded preflight matrix.

### PNG representation and bounded execution
- **D-03:** Introduce one internal GrayAlpha8 encode profile that emits IHDR bit depth 8, colour type 4, compression/filter method 0, and interlace method 0. Gray+Alpha Adam7 and Gray+Alpha16 are out of scope. — **Reversibility:** costly — extending the profile changes raster traversal and conformance obligations.
- **D-04:** Reuse the shared preflight, filter cursor, compression planner, and acknowledgement-safe replay machine. Support `None` and `Adaptive` filters with `Stored`, `FixedOrStored`, and `DynamicOrFixedOrStored`; do not create a parallel encoder, pixel staging path, or source-tree copy.
- **D-05:** Preserve source gray/alpha component order at the PNG wire boundary. Decoder canonicalization proof, hostile caller schedules, frozen legacy vectors, and independent four-target public evidence belong to Phase 52.

### Compatibility boundary
- **D-06:** Existing Gray8, Gray16, RGB8, and straight-RGBA8 factories and bytes remain unchanged. Phase 51 adds no release automation, registry work, FFI, low-bit/palette support, colour conversion, or target-specific implementation.

### the agent's Discretion
- Follow the established Gray16 test-helper structure and typed error-context naming, using the smallest focused Phase 51 regressions for factory admission, IHDR, eager decode fidelity, strategy pairing, and pre-exposure failures.
- Keep internal implementation changes localized to the existing PNG package and make every new `PngEncodeProfile` match explicit.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone contract
- `.planning/ROADMAP.md` — Phase 51 goal, requirements, success criteria, and Phase 52 evidence boundary.
- `.planning/REQUIREMENTS.md` — `GRAYA-02` and `GRAYA-03` acceptance and atomicity requirements.
- `.planning/PROJECT.md` — v0.16 compatibility, portability, and no-release-automation constraints.
- `.planning/phases/50-gray-alpha-image-model/50-CONTEXT.md` — locked GrayAlpha descriptor identity and excluded model variations.
- `.planning/milestones/v0.15-phases/49-portable-gray16-public-evidence/49-CONTEXT.md` — established bounded eager/chunk and wire-evidence conventions.

### Existing PNG implementation
- `modules/mb-image/png/png.mbt` — public encoder factory families and `PngEncodeProfile` seam.
- `modules/mb-image/png/encode.mbt` — profile admission, pixel-wire mapping, and shared bounded preflight.
- `modules/mb-image/png/stream_encode.mbt` — caller-buffered constructors, profile-aware replay machine, and IHDR emission.
- `modules/mb-image/png/encode_test.mbt` — eager Gray8/Gray16 profile and decode-fidelity test patterns.
- `modules/mb-image/png/stream_encode_test.mbt` — caller-buffered factory, atomicity, and strategy-pair test patterns.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `PngEncoder::new_gray16*` and `PngChunkEncoder::new_gray16*` provide the complete explicit factory-family pattern.
- `PngEncodeMachine::new_with_profile` owns shared bounded admission, filter, compression, and replay setup.
- The current Gray16 profile provides the closest non-interlaced grayscale specialization; GrayAlpha8 differs only in channel count, colour type, and U8 component mapping.

### Established Patterns
- PNG profile admission is explicit and fail-closed before source reads, output bytes, or caller-owned leases are exposed.
- `PngFilterStrategy::{None, Adaptive}` and all three bounded compression strategies are orthogonal public selections.
- Existing routes retain legacy byte baselines by adding explicit profile factories rather than changing defaults.

### Integration Points
- Extend `PngEncodeProfile`, `PngEncoder`, and `PngChunkEncoder` in the PNG package; route the profile through existing raster and IHDR helpers.
- Add focused eager and caller-buffered tests beside the established Gray16 tests, without new modules or scripts.

</code_context>

<specifics>
## Specific Ideas

Use non-symmetric gray/alpha pairs in all new fixtures so swapped components or accidental alpha loss cannot satisfy the route tests.

</specifics>

<deferred>
## Deferred Ideas

- Gray+Alpha16, Gray+Alpha Adam7, palette/low-bit support, colour transforms, and any new codec architecture.
- Generated public four-target wire vectors, hostile zero/one/ragged schedules, and frozen legacy-vector evidence — Phase 52.
- Publication, release automation, and copied-source workflows.

</deferred>

---

*Phase: 51-bounded-gray-alpha-png-encoding*
*Context gathered: 2026-07-23*
