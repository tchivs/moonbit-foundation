# Phase 13: QOI Format Core and Safe Decode - Context

**Gathered:** 2026-07-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver a pure-MoonBit, whole-image-memory QOI 1.0 probe and safe decoder through the existing portable codec contracts. The phase includes spec-derived decode fixtures and hostile-input evidence, but not encoding, streaming state APIs, FFI, release automation, or performance baselines.

</domain>

<decisions>
## Implementation Decisions

### Codec boundary and output semantics
- **D-01:** Add QOI as an independent `mb-image/qoi` package that implements the existing `ImageDecoder` trait; do not alter the shared codec contracts, add a registry, or depend on `ops`.
- **D-02:** Decode complete QOI RGB/RGBA streams without silently losing alpha or declared color-space meaning. Preserve the source semantics through existing image descriptors where representable; otherwise fail with an explicit typed capability/encoding error rather than applying an implicit conversion.
- **D-03:** Keep decoding eager and whole-image-memory in this phase. Forward-only reader behavior still follows the existing codec progress/error contracts.

### Strict input and resources
- **D-04:** Probe is prefix-only: fewer than four bytes yields `NeedMore(4)`, non-`qoif` bytes yield `NoMatch`, and no `Reader` is consumed.
- **D-05:** Validate the 14-byte header, checked dimensions, channels, color-space, codec limits, and allocation budget before creating output storage. Preflight rejection must not mutate the authoritative budget or allocate output.
- **D-06:** With `require_complete_input`, require the exact QOI end marker and reject trailing bytes. Truncated opcode payloads, run overruns, malformed markers, zero-progress reads, and host I/O failures return the existing structured error/progress shape without panics.

### Evidence scope
- **D-07:** Use repository-owned, spec-derived fixture source plus a checked generator rather than network-fetched test data. Cover all QOI opcode families, byte wraparound, index collisions, initial pixel state, run boundaries, and malformed input on all four targets.

### the agent's Discretion
- Select private helper factoring, exact fixture layout, and the smallest representable metadata mapping after checking the existing PPM patterns and model capabilities.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and phase scope
- `.planning/ROADMAP.md` — Phase 13 goal, requirements, and success criteria.
- `.planning/REQUIREMENTS.md` — QOI-01, QOI-02, and QOI-04 acceptance scope.
- `.planning/PROJECT.md` — v0.4 portability and no-FFI boundary.

### Existing codec contracts and reference implementation
- `modules/mb-image/codec/contracts.mbt` — prefix probe, limits, options, decoder, and structured codec contract.
- `modules/mb-image/ppm/moon.pkg` — portable same-layer dependency shape.
- `modules/mb-image/ppm/decode.mbt` — bounded forward-only decoder, metadata, budget, and diagnostics pattern.
- `modules/mb-image/ppm/decode_test.mbt` — public hostile-reader and limit test patterns.
- `modules/mb-image/storage/owned_image.mbt` — checked owned-image allocation seam.

### External format authority
- `https://qoiformat.org/qoi-specification.pdf` — QOI 1.0 header, chunks, hash, and end-marker definition.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `@codec.CodecLimits`, `@codec.DecodeOptions`, and `@codec.ImageDecoder` — required public contracts for QOI probe/decode.
- `@io.Reader` exact-read helpers and PPM's structured progress mapping — forward-only I/O behavior.
- `@storage.OwnedImage::new_operation` plus mutable views — checked output allocation and pixel population.

### Established Patterns
- PPM validates caller limits and authoritative budget before output allocation, then maps reader failures into typed codec diagnostics.
- Public image packages declare all four portable targets and never depend upward on `ops`.

### Integration Points
- New `modules/mb-image/qoi/` imports the same lower-level contracts as PPM and remains independent of PPM and image operations.

</code_context>

<specifics>
## Specific Ideas

QOI is chosen as the first post-PPM lossless interchange format because its stable byte-level algorithm is implementable in MoonBit without DEFLATE, FFI, or a target-specific dependency.

</specifics>

<deferred>
## Deferred Ideas

- Canonical QOI encoding and byte-round-trip proof — Phase 14.
- Public decode-process-encode consumer — Phase 15.
- Streaming APIs, external corpus ingestion, PNG/DEFLATE, FFI, and benchmark baselines — future work.

</deferred>

---

*Phase: 13-QOI Format Core and Safe Decode*
*Context gathered: 2026-07-20*
