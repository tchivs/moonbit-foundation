# Phase 54: Bounded Type-4/16 Encoder - Context

**Gathered:** 2026-07-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Route the locked packed U16 GrayAlpha16 model through explicit eager and caller-buffered PNG factories as non-interlaced Type 4 / bit-depth 16 output. Reuse the existing bounded machine; public hostile schedule, frozen vector, and independent four-target qualification remain Phase 55.

</domain>

<decisions>
## Implementation Decisions

### Public route and representation
- **D-01:** Mirror the existing Gray16 and GrayAlpha8 factory families with explicit `graya16` eager and caller-buffered default, compression-only, filter-only, and combined-strategy APIs. — **Reversibility:** one-way — public factory spellings are API contract.
- **D-02:** Add one private `GrayAlpha16` encode profile that emits IHDR colour type 4, bit depth 16, methods 0, and interlace 0. Adam7 and other U16 alpha variants remain out of scope.

### Admission and bounded replay
- **D-03:** Admit only Phase 53's packed U16 GrayAlpha, straight-alpha, encoded builtin sRGB, top-left identity; retain typed metadata/capability errors and reject before source reads, output, budget charge, or caller lease exposure.
- **D-04:** Generalize the existing U16 wire/replay seam to emit `Ghi,Glo,Ahi,Alo` for two U16 components while retaining Gray16's two-byte source behavior. Profile stride, filter cursor, limit, budget, compression planner, and acknowledgement-safe replay must use four bytes per pixel through the single `PngEncodeMachine`.
- **D-05:** Support existing None/Adaptive filters and Stored/FixedOrStored/DynamicOrFixedOrStored compression selections without staging buffers, alternate encoder paths, source-tree copies, or target-specific branches.

### Compatibility boundary
- **D-06:** Legacy Gray8, Gray16, GrayAlpha8, RGB8, and straight-RGBA8 factories, bytes, descriptor behavior, and atomic failure semantics remain unchanged. Public literal vectors and hostile schedules belong to Phase 55.

### the agent's Discretion
- Follow the closest Gray16 + GrayAlpha8 code/test patterns, make profile matches exhaustive, and keep changes limited to existing PNG package files.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md` — Phase 54 goal, GRAYA16-02/03, and Phase 55 evidence boundary.
- `.planning/REQUIREMENTS.md` — Type 4/16 wire and bounded atomicity contract.
- `.planning/research/SUMMARY.md` — approved three-phase architecture and risks.
- `.planning/phases/53-grayalpha16-model-and-checked-storage/53-VERIFICATION.md` — verified model identity.
- `.planning/milestones/v0.15-phases/48-bounded-gray16-encoder-path/48-CONTEXT.md` — U16 scalar wire/replay precedent.
- `.planning/milestones/v0.16-phases/51-bounded-gray-alpha-png-encoding/51-CONTEXT.md` — Type 4 U8 profile/factory precedent.
- `modules/mb-image/png/png.mbt` — public factory/profile seam.
- `modules/mb-image/png/encode.mbt` — admission, wire mapping, and bounded preflight.
- `modules/mb-image/png/stream_encode.mbt` — chunk construction, machine, IHDR, and replay.
- `modules/mb-image/png/encode_test.mbt` and `modules/mb-image/png/stream_encode_test.mbt` — Gray16/GrayAlpha test patterns.

</canonical_refs>

<code_context>
## Existing Code Insights

- Gray16 supplies U16 scalar byte-order and GrayAlpha8 supplies Type 4 factory/profile structure.
- `PngEncodeMachine::new_with_profile` owns the bounded preflight/filter/compression/replay transaction and must remain the only construction route.
- Decoder support already canonicalizes Type-4/16 to straight RGBA8 high bytes; Phase 54 proves local tracer behavior only, while public evidence is Phase 55.

</code_context>

<specifics>
## Specific Ideas

Use non-symmetric U16 gray and alpha samples with distinct high/low bytes to expose both component swaps and endianness errors.

</specifics>

<deferred>
## Deferred Ideas

- Public hostile schedules, frozen legacy vectors, and independent four-target PNG qualification — Phase 55.
- GrayAlpha16 Adam7, colour conversion, palettes/low-bit, FFI, release automation, and source copies.

</deferred>

---

*Phase: 54-bounded-type-4-16-encoder*
*Context gathered: 2026-07-23*
