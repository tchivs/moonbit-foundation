# Phase 73: Explicit Packed Grayscale PNG - Context

**Gathered:** 2026-07-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Add explicit, non-interlaced PNG Type-0 output at bit depths 1, 2, and 4 from
the existing canonical byte-per-pixel Gray/U8 image source. This phase packs
the PNG wire only; it does not introduce a bit-packed image model, implicit
level conversion, Adam7, palette, or a second encoder.
</domain>

<decisions>
## Implementation Decisions

- **D-01:** Add explicit eager public selectors for Gray1, Gray2, and Gray4,
  parallel to existing explicit Gray8/Gray16 selectors. Generic and Gray8
  behavior stays byte-identical.
- **D-02:** Accept only canonical opaque Gray/U8 packed sources with exact
  levels: `{0,255}` for Gray1, `{0,85,170,255}` for Gray2, and multiples of
  17 for Gray4. Reject every other sample before output/budget exposure; never
  scale, quantize, or dither.
- **D-03:** Pack samples MSB-first per PNG row and force unused final-byte bits
  to zero. Stored/None output receives an independently authored wire oracle
  for odd widths and all three depths.
- **D-04:** Reuse the existing profile-aware bounded machine, admission,
  compression/filter plumbing, and Type-0 IHDR emission seam. No staging
  buffer, duplicate traversal, or model-layout change.
- **D-05:** Phase 73 owns eager non-interlaced output and atomic invalid-level
  admission only. Caller-buffered surface, hostile lease schedules, broader
  strategy matrix, Adam7, and four-target qualification are deferred to
  Phases 74–75.
</decisions>

<canonical_refs>
## Canonical References

- `.planning/REQUIREMENTS.md` and `.planning/ROADMAP.md` — requirements and
  scope guard.
- `modules/mb-image/model/descriptor.mbt` — Gray/U8 packed source contract.
- `modules/mb-image/png/encode.mbt` — profile admission, row provider, and
  bounded machine.
- `modules/mb-image/png/png.mbt`, `stream_encode.mbt`, and `encode_test.mbt`
  — public selectors, IHDR, and independent wire-test patterns.
- `modules/mb-image/png/raster_decode.mbt` — authoritative low-bit MSB-first
  unpacking semantics to mirror on encode.
</canonical_refs>

<deferred>
## Deferred Ideas

Caller-buffered low-bit factories, all strategy matrices, Adam7, palette/index
encoding, implicit conversion, a bit-packed source model, FFI, release scripts,
target wrappers, and copied-source workflows.
</deferred>
