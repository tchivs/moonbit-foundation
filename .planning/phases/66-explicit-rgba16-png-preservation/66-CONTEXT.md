# Phase 66: Explicit RGBA16 PNG Preservation - Context

**Gathered:** 2026-07-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Add the eager, opt-in `PngDecoder::decode_rgba16` path for legal encoded-sRGB PNG Type-6/16 input.  It must preserve all source component bytes in the Phase 65 packed `rgba16` identity while the existing generic decoder remains the RGBA8 high-byte projection.  Caller-owned chunk construction belongs to Phase 67.

</domain>

<decisions>
## Implementation Decisions

### Public contract and compatibility
- **D-01:** Expose only `PngDecoder::decode_rgba16` in this phase; it uses the existing byte-fed decode machine with a new explicit profile.  Do not add `PngChunkDecoder::new_rgba16` until Phase 67.
- **D-02:** Preserve the generic façade exactly: the same Type-6/16 input through `decode()` must still return `RGBA8(Rhi,Ghi,Bhi,Ahi)`.  No implicit conversion, alternate generic result shape, or second decoder is allowed. — **Reversibility:** costly — existing consumers depend on the generic RGBA8 result contract.

### Admission and result identity
- **D-03:** Accept only Type-6, 16-bit input with no colour declaration or an `sRGB` declaration; reject unsupported type/depth, `tRNS`, legacy-colour declarations, and ICC declarations before creating or exposing a preservation image.
- **D-04:** Reuse byte-domain unfiltering and the single normal/Adam7 traversal, then perform the sole lossless final store as `Rlo,Rhi,Glo,Ghi,Blo,Bhi,Alo,Ahi`.  No scaling, premultiplication, colour transform, or image-sized staging buffer is permitted.
- **D-05:** Account for eight storage bytes per output pixel in descriptor construction, allocation and resource preflight; keep filtered encoded row accounting unchanged.  Existing GrayAlpha16 resource boundaries must retain their established behaviour.

### the agent's Discretion
- Follow the Phase 62 Type-4/16 profile seam and use the smallest profile-aware changes that cover ordinary rows and Adam7 scatter.  Keep public fixture breadth and hostile chunk lifecycle evidence for Phases 67-68.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### v0.21 scope and representation
- `.planning/REQUIREMENTS.md` — `RGBA16DEC-02` admission, exact-lane, generic-compatibility, and preallocation requirements.
- `.planning/ROADMAP.md` — Phase 66 success criteria and scope guard.
- `.planning/phases/65-packed-rgba16-decode-model/65-CONTEXT.md` — locked packed `rgba16` descriptor and compatibility decisions.
- `.planning/research/v021-DECODE.md` — decoder seams, storage-byte budget risk, normal/Adam7 stores.  Its legacy/ICC recommendation conflicts with the current Phase 66 roadmap and requirements; the current requirements take precedence.

### Established high-precision PNG precedent
- `.planning/milestones/v0.20-phases/62-explicit-grayalpha16-decode-contract/62-CONTEXT.md` — explicit-only high-precision decode and frozen generic façade.
- `modules/mb-image/png/stream_decode.mbt` — profile dispatch, pre-IDAT preflight, eager machine bridge, normal storage, and Adam7 scatter seams.
- `modules/mb-image/png/png.mbt` — public eager decoder surface.
- `modules/mb-image/model/descriptor.mbt` — checked `rgba16` identity introduced by Phase 65.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `PngDecodeProfile::GrayAlpha16` and its eager bridge provide the explicit-profile pattern.
- `PngPackedRows` already reconstructs Type-6/16 in byte space with an eight-byte filter stride.
- Existing Adam7 scatter owns pass-local rows and the final image, so it can store exact lanes without a second raster buffer.

### Established Patterns
- The first authenticated IDAT header is the one allocation boundary; profile and metadata validation must complete before the sink exists.
- High-precision decode stays opt-in and leaves generic high-byte canonicalisation unchanged.

### Integration Points
- `modules/mb-image/png/png.mbt` supplies `decode_rgba16`.
- `modules/mb-image/png/stream_decode.mbt` owns profile admission, layout charging, normal store, and Adam7 final scatter.
- `modules/mb-image/png/*_test.mbt` carries focused eager and frozen-generic regressions.

</code_context>

<specifics>
## Specific Ideas

The explicit result must be a direct, observable packed byte identity; a low-byte loss, endianness reversal, or generic API widening is a correctness failure.

</specifics>

<deferred>
## Deferred Ideas

- `PngChunkDecoder::new_rgba16`, accepted-only progress, terminal replay, and eager/chunk parity — Phase 67.
- Independent all-filter/Adam7 wire literals, hostile resource boundaries, and complete four-target package qualification — Phase 68.
- Non-sRGB/ICC conversion, broad high-precision conversion APIs, alternate decoders, copied source trees, and release automation — out of scope.

</deferred>

---

*Phase: 66-Explicit RGBA16 PNG Preservation*
*Context gathered: 2026-07-23*
