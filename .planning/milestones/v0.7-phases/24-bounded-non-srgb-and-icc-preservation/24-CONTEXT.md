# Phase 24: Bounded Non-sRGB and ICC Preservation - Context

**Gathered:** 2026-07-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Extend the eager portable PNG decoder so legal `gAMA`, `cHRM`, and bounded
`iCCP` declarations survive as explicit non-sRGB metadata. The decoder must
not perform a colour transform or relabel source samples, and operations that
would discard the declaration must return a typed capability result.

</domain>

<decisions>
## Implementation Decisions

### Non-sRGB Representation
- **D-01:** Decode legal non-sRGB PNGs into an image with explicit,
  deterministic opaque metadata for the authoritative declaration; keep the
  image metadata outside the encoded-sRGB identity so reference operations
  remain unavailable.
- **D-02:** Preserve `gAMA` and `cHRM` in their validated, canonical PNG byte
  representation, with deterministic metadata keys and declared precedence.
  Do not add a new general public colour-transform or profile-model API in
  this phase.

### ICC Envelope and Bounds
- **D-03:** Parse and inflate `iCCP` only through a bounded pure-MoonBit path,
  validate the profile envelope sufficiently to determine compatible RGB/gray
  input and preserve a bounded opaque profile payload plus profile name.
- **D-04:** Treat malformed names/methods/zlib streams, invalid or
  incompatible ICC colour spaces, and compressed/inflated/allocation/work
  limit breaches as deterministic errors before an image is visible. Use the
  repository's existing checked budgets and metadata limits rather than an
  unbounded side buffer.

### Capability Boundaries
- **D-05:** `PngDecoder` may successfully return non-sRGB images with retained
  metadata, but reference operations and canonical PNG encoding must return a
  typed capability-unavailable result whenever they would silently transform,
  reinterpret, or drop that colour information.
- **D-06:** Keep valid `sRGB` behaviour from Phase 23 unchanged. `iCCP` takes
  precedence where PNG rules require it; conflicting or unsupported declared
  semantics fail explicitly rather than selecting an arbitrary interpretation.

### Evidence
- **D-07:** Add independent small positive/hostile fixtures for gamma,
  chromaticity, ICC profile envelopes and bounded expansion. Run them through
  the public decoder and affected operation/encoding boundaries on js,
  wasm, wasm-gc, and native.

### the agent's Discretion

Choose private parser state, exact bounded limits, metadata key spelling, and
the minimum ICC header checks that meet the roadmap criteria while preserving
the existing acyclic package boundary.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase contract
- `.planning/ROADMAP.md` §Phase 24 — goals, requirements, and success criteria.
- `.planning/REQUIREMENTS.md` §PNGCM-03/PNGCM-04 — required externally visible behaviour.
- `.planning/phases/23-png-colour-declaration-and-srgb-semantics/23-CONTEXT.md` — prior colour-declaration scope fence and sRGB decision.
- `.planning/phases/23-png-colour-declaration-and-srgb-semantics/23-VERIFICATION.md` — verified strict parser and existing capability boundary to extend.

### Existing contracts
- `modules/mb-image/png/structural.mbt` — recognised colour grammar, bounded chunk reader, and current non-sRGB rejection.
- `modules/mb-image/png/png.mbt` — decoder result construction and image metadata integration.
- `modules/mb-image/metadata/metadata.mbt` — bounded canonical opaque metadata storage.
- `modules/mb-color/profile/profile.mbt` — bounded opaque profile ownership contract.
- `modules/mb-image/model/descriptor.mbt` — metadata identities and reference-operation eligibility.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `PngColourFacts` and `_png_read_colour_chunk` already recognise and validate
  `gAMA`, `cHRM`, and the streamed `iCCP` envelope before raster allocation.
- `OpaqueMetadata::from_entries` provides deterministic keys, checked limits,
  copy ownership, and atomic budget charging for retained declaration bytes.
- `@profile.OpaqueProfile::from_bytes` is the existing bounded profile holder
  if a retained ICC payload needs a dedicated profile representation.

### Established Patterns
- PNG decoding is strict and eager: no image becomes visible until framing,
  chunks, raster, and EOF pass.
- `ImageDescriptor::supports_reference_operations` is the central encoded-sRGB
  gate; it must remain false for retained non-sRGB images.
- Generated PNG fixtures and `Invoke-MoonQuality.ps1 -Lane Png` are the
  established portable evidence route.

### Integration Points
- Replace the Phase 23 `PngColourDeclaration::NonSrgb` early decode rejection
  with a bounded transport-to-metadata path.
- Ensure `PngEncoder` and reference operations retain their typed boundary
  instead of serializing or processing non-sRGB metadata implicitly.

</code_context>

<specifics>
## Specific Ideas

Automatic choices use the project-wide priority of correctness, explicit
capability boundaries, and bounded pure-MoonBit processing over broad ICC
compatibility. No release or registry automation is part of this phase.

</specifics>

<deferred>
## Deferred Ideas

Full ICC transforms, cICP/HDR, profile conversion, preservation by the
canonical PNG encoder, and public resumable PNG streaming remain out of scope.

</deferred>

---

*Phase: 24-bounded-non-srgb-and-icc-preservation*
*Context gathered: 2026-07-21*
