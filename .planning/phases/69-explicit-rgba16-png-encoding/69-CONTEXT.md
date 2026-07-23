# Phase 69: Explicit RGBA16 PNG Encoding - Context

**Gathered:** 2026-07-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Add the eager, non-interlaced Type-6/16 PNG encoding profile for checked packed `rgba16` images. It must reuse the existing bounded PNG encoder and preserve every U16 lane from little-endian source storage to big-endian PNG wire order. Caller-buffered output and Adam7 selection belong to Phases 70 and 71.

</domain>

<decisions>
## Implementation Decisions

### Profile and public surface

- **D-01:** Add one explicit eager RGBA16 `PngEncoder` selector family that follows the established `GrayAlpha16` factory shape: default Stored/filter-None plus explicit compression and filter variants, all fixed to non-interlaced output. — **Reversibility:** costly — changing public constructor names after publication would require compatibility support for downstream callers.
- **D-02:** Accept only the existing checked `ImageFormat::rgba16()` identity: packed little-endian U16, straight alpha, builtin encoded-sRGB, and top-left orientation. Reject incompatible descriptors before any output is exposed.

### Wire and compatibility behavior

- **D-03:** Emit PNG Type 6 / bit depth 16 samples as `Rhi,Rlo,Ghi,Glo,Bhi,Blo,Ahi,Alo`; no scaling, premultiplication, colour transform, or staging buffer is permitted.
- **D-04:** Keep legacy RGB8 and RGBA8 encoder constructors, output bytes, and generic decoder behaviour unchanged. The new capability is opt-in and non-interlaced in this phase.

### Evidence

- **D-05:** Use a fixed non-symmetric RGBA16 source plus static PNG-wire expectations and explicit `decode_rgba16` round-trip assertions. Do not use the newly implemented encoder as its own oracle.
- **D-06:** Cover descriptor and resource rejection through the established eager preflight path, proving no writer output occurs on failed construction.

### the agent's Discretion

- Match the existing `GrayAlpha16` private profile/preflight/cursor conventions and keep the narrowest file set that achieves the contract.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone contracts
- `.planning/ROADMAP.md` §Phase 69 — fixed goal, requirements, success criteria, and scope guard.
- `.planning/REQUIREMENTS.md` §RGBA16ENC-01 — user-facing completion contract and traceability.
- `.planning/milestones/v0.21-phases/65-packed-rgba16-decode-model/65-01-SUMMARY.md` — checked `rgba16` identity and observable storage order.
- `.planning/milestones/v0.21-phases/68-rgba16-decode-qualification/68-01-SUMMARY.md` — independent RGBA16 decoder vectors and no-encoder-oracle rule.

### Established encoder implementation
- `modules/mb-image/png/png.mbt` — public encoder factories and private `PngEncodeProfile` declaration.
- `modules/mb-image/png/stream_encode.mbt` — shared bounded machine construction and GrayAlpha16 caller-buffered profile precedent.
- `modules/mb-image/png/encode.mbt` — profile-aware U16 wire traversal, filtering, and preflight.
- `modules/mb-image/png/encode_test.mbt` — GrayAlpha16 exact-wire, rejection, and legacy-compatibility test patterns.
- `modules/mb-image/model/descriptor.mbt` — `rgba16` descriptor identity validation.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `PngEncodeProfile::GrayAlpha16`: closest U16 straight-alpha profile, including explicit public factory families and Type-4/16 wire handling.
- `PngEncodeMachine::new_with_profile`: single bounded eager/chunk machine construction seam; Phase 69 must select it rather than add an encoder.
- `_png_profile_uses_u16_component_wire` and profile-aware filtered cursors: existing U16 byte-order and filter traversal seam.

### Established Patterns
- Public format additions are explicit constructor families; legacy constructors remain frozen.
- Profile admission and resource accounting occur before eager writer exposure.
- Fixed, non-symmetric vectors and explicit decoder checks make U16 byte-order errors observable.

### Integration Points
- `PngEncodeProfile` in `png.mbt`, profile-specific public eager factories in the same file, profile admission/IHDR selection in `stream_encode.mbt`, and final raster-byte selection in `encode.mbt`.

</code_context>

<specifics>
## Specific Ideas

No additional product requirements — use standard existing constructor naming and test conventions.

</specifics>

<deferred>
## Deferred Ideas

None — caller-buffered RGBA16 belongs to Phase 70, Adam7 selection to Phase 71, and broader qualification to Phase 72.

</deferred>

---

*Phase: 69-Explicit RGBA16 PNG Encoding*
*Context gathered: 2026-07-23*
