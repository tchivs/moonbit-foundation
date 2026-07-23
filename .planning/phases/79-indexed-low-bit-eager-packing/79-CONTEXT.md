# Phase 79: Indexed Low-Bit Eager Packing - Context

**Gathered:** 2026-07-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Add explicit eager Type-3 PNG output at depths 1, 2, and 4 from the existing immutable `PngIndexedImage`, with bounded preflight, canonical MSB-first packed rows, and existing PLTE/tRNS framing. This phase does not add caller-buffered entry points, a second encoder, a new public image model, or additional compression/interlace strategies.

</domain>

<decisions>
## Implementation Decisions

### Public selection and source ownership
- **D-01:** Expose a small public `PngIndexedBitDepth` selector limited to `One`, `Two`, and `Four`, used by an additive eager indexed factory. Keep `encode_indexed8` unchanged. — **Reversibility:** costly — changing a public enum or factory later changes downstream source contracts.
- **D-02:** Keep `PngIndexedImage` as canonical one-byte-per-pixel input. Pack only while emitting the Type-3 scanline; do not introduce a packed model, quantization, scaling, or an extra source copy.

### Wire profile and atomicity
- **D-03:** Use the existing one-machine Stored/None/non-interlaced Type-3 route. For each row, pack indices MSB-first and initialize unused final-byte bits to zero. PLTE and canonical optional tRNS retain the shipped order and representation.
- **D-04:** Before any writer output or budget mutation, enforce palette caps of 2, 4, or 16; compute packed row/frame sizes with checked arithmetic; enforce all limits; then make the single existing budget charge. — **Reversibility:** costly — this preserves the public atomic resource-admission contract.

### Evidence and compatibility
- **D-05:** Prove packing with independent odd-width Stored scanline vectors for every depth, then prove public RGB8/RGBA8 decoding and retain Indexed8/legacy bytes. Private tests own exact row, frame, and budget facts; streaming lifecycle qualification remains Phase 80.

### the agent's Discretion
- Match the closest established PNG constructor naming and existing capability-error vocabulary.
- Keep private profile/fact representation minimal provided eager output remains backed by the same acknowledgement-safe machine.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone contracts
- `.planning/PROJECT.md` — v0.25 goal and project-wide portable, bounded, MoonBit-native constraints.
- `.planning/REQUIREMENTS.md` — INDEXLOW-01 through INDEXLOW-03 acceptance requirements and exclusions.
- `.planning/ROADMAP.md` — Phase 79 goal, dependency, and scope guard.
- `.planning/research/v025-INDEXED-LOW-BIT-ENCODE.md` — packing vectors, checked admission, risks, and test anchors.
- `.planning/research/v025-SUMMARY.md` — approved two-phase milestone split.

### Indexed PNG lineage
- `.planning/milestones/v0.24-phases/76-indexed8-source-eager-plte/76-CONTEXT.md` — owning Indexed8 source and eager PLTE boundary.
- `.planning/milestones/v0.24-phases/77-indexed-png-transparency/77-CONTEXT.md` — canonical tRNS and opaque-byte freeze decisions.
- `.planning/milestones/v0.24-phases/78-resumable-indexed-png-qualification/78-CONTEXT.md` — single-machine and public lifecycle contracts to preserve.

### Implementation seams
- `modules/mb-image/png/png.mbt` — immutable `PngIndexedImage` source validation and accessors.
- `modules/mb-image/png/encode.mbt` — Indexed8 preflight and eager entry point.
- `modules/mb-image/png/stream_encode.mbt` — shared acknowledged state machine, IHDR, and scanline emission.
- `modules/mb-image/png/raster_decode.mbt` — Type-3 low-bit unpacking oracle.
- `modules/mb-image/png/encode_test.mbt` and `modules/mb-image/png/encode_wbtest.mbt` — independent wire, public decode, preflight, and budget-test patterns.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `PngIndexedImage` in `png.mbt`: owns validated unpacked index bytes, RGB palette, and alpha table.
- `_png_encode_indexed_preflight` in `encode.mbt`: current single-charge Type-3 framing and admission seam.
- `PngEncodeMachine::new_with_indexed` and `scanline_byte` in `stream_encode.mbt`: shared pending-byte/CRC machine and existing Indexed8 raster path.
- `raster_decode.mbt`: independently unpacks Type-3 1/2/4-bit samples MSB-first and checks palette bounds.

### Established Patterns
- Profile-specific APIs are additive; existing output stays frozen.
- Preflight completes before observable output and makes exactly one budget charge.
- Exact wire evidence must be test-local, not calculated through production helpers.

### Integration Points
- Depth facts must drive the preflight's row/frame calculation, machine IHDR byte, and indexed branch of scanline-byte emission together.
- Phase 80 will add only a thin caller-buffered adapter once this eager route is authoritative.

</code_context>

<specifics>
## Specific Ideas

The user authorized autonomous choices and asked that implementation and tests take priority over release automation. The selected route is therefore the smallest compatible Type-3 extension with deterministic bytes and strong existing test patterns.

</specifics>

<deferred>
## Deferred Ideas

Indexed caller-buffered lifecycle qualification belongs to Phase 80. Indexed Adam7, quantization, dithering, generic model widening, strategy expansion, image-sized staging, FFI, wrappers, copied source trees, and release automation remain out of scope.

</deferred>

---

*Phase: 79-indexed-low-bit-eager-packing*
*Context gathered: 2026-07-24*
