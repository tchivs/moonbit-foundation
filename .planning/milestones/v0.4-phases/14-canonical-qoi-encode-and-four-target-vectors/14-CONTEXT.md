# Phase 14: Canonical QOI Encode and Four-Target Vectors - Context

**Gathered:** 2026-07-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver a pure-MoonBit, whole-image QOI 1.0 encoder through the existing portable codec contracts. It must produce deterministic canonical bytes for supported RGB and straight-RGBA images, round-trip through the Phase 13 decoder, and prove the byte-level behavior on js, wasm, wasm-gc, and native. This phase does not add a codec registry, streaming APIs, FFI, release automation, benchmarks, or public workflow examples.

</domain>

<decisions>
## Implementation Decisions

### Encoder boundary and representable source images
- **D-01:** Add `QoiEncoder` to the existing independent `mb-image/qoi` package and implement the unchanged `@codec.ImageEncoder` seam; do not modify shared contracts, add a registry, or depend on `ops` or PPM.
- **D-02:** Support packed `U8` RGB and straight-RGBA source views with top-left orientation and the built-in sRGB profile. Map encoded-sRGB and linear-sRGB transfer identities exactly to the QOI color-space byte; reject all unrepresentable component/layout/alpha/metadata/profile semantics with existing typed capability errors before output.
- **D-03:** Preserve the existing codec progress and budget contract: validate the complete source and declared limits before writing, calculate the canonical output length in a deterministic prepass, charge the exact work atomically, then write via the forward-only Writer with exact progress reporting.

### Canonical byte policy and evidence
- **D-04:** Use the standard deterministic QOI chunk preference at each pixel: continue a run when applicable, otherwise reuse a matching index entry, then use DIFF, LUMA, RGB, or RGBA as applicable. Always write the 14-byte header and exact 8-byte end marker.
- **D-05:** Extend the repository-owned QOI fixture authority and checked generator with canonical encoder expectations. Test every opcode family, channel mode, wraparound, index collision, run boundary, header color-space byte, writer failure/progress, and decode(encode(image)) equality on every supported target.

### the agent's Discretion
- Keep private state-machine helpers, writer chunking, fixture record layout, and test factoring minimal and aligned with the existing QOI decoder and PPM encoder patterns.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone scope
- `.planning/ROADMAP.md` — Phase 14 goal and success boundary.
- `.planning/REQUIREMENTS.md` — QOI-03 and QOI-05 acceptance scope; release automation remains out of scope.
- `.planning/PROJECT.md` — portable, MoonBit-native, no-FFI modularity constraints.
- `.planning/phases/13-qoi-format-core-and-safe-decode/13-CONTEXT.md` — locked QOI decoder, resource, and fixture decisions this encoder must preserve.
- `.planning/phases/13-qoi-format-core-and-safe-decode/13-01-SUMMARY.md` — decoder package and fixture-generation outcome.

### Existing codec and implementation patterns
- `modules/mb-image/codec/contracts.mbt` — `ImageEncoder`, `EncodeOptions`, `EncodeResult`, limits, and structured errors.
- `modules/mb-image/ppm/ppm.mbt` — public encoder value pattern.
- `modules/mb-image/ppm/encode.mbt` — source validation, preflight, writer progress, budget, and canonical-output pattern.
- `modules/mb-image/qoi/qoi.mbt` — existing QOI package public surface.
- `modules/mb-image/qoi/decode.mbt` — QOI header/state semantics and metadata mapping to preserve.
- `modules/mb-image/qoi/decode_test.mbt` — public codec, hostile I/O, and resource test patterns.
- `modules/mb-image/qoi/decode_wbtest.mbt` — generated-vector test entry point.
- `scripts/fixtures/Generate-QoiVectors.ps1` — deterministic fixture and provenance checker to extend.
- `fixtures/qoi/cases.json` — repository-owned QOI vector authority.

### External format authority
- `https://qoiformat.org/qoi-specification.pdf` — QOI 1.0 header, hash, chunk, and end-marker definition.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `@codec.ImageEncoder`, `EncodeOptions`, `EncodeResult`, and `CodecLimits` provide the stable encoder seam and resource policy.
- `@storage.ImageView` supplies immutable byte access for a safe deterministic prepass and write pass.
- PPM's `validate_encode_source`, `write_encode_part`, and write-error remapping establish the portable writer/error contract.
- The QOI decoder's descriptor/metadata mapping and checked fixture generator establish the exact QOI-compatible surface.

### Established Patterns
- Public image codecs support all four portable targets and remain independently importable.
- Encode capability and resource failures happen before any writer output; write failures retain exact completed-byte progress.
- Repository-owned JSON vectors plus a local `-Check` generator are the conformance authority, not downloaded assets.

### Integration Points
- Add encoder source and tests under `modules/mb-image/qoi/`; extend only the existing QOI fixture source, generated table, and manifest through its generator.

</code_context>

<specifics>
## Specific Ideas

The user explicitly prioritizes implementation and tests over release or automation work. Keep the Phase 14 plan as a compact encoder-plus-vectors slice.

</specifics>

<deferred>
## Deferred Ideas

- Public QOI decode-process-encode example — Phase 15.
- Benchmarks, streaming, registry composition, FFI, and release automation — future work.

</deferred>

---

*Phase: 14-Canonical QOI Encode and Four-Target Vectors*
*Context gathered: 2026-07-20*
