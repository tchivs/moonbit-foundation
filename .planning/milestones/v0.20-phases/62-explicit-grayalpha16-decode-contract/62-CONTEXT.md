# Phase 62: Explicit GrayAlpha16 Decode Contract - Context

**Gathered:** 2026-07-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Add the explicit eager `PngDecoder::decode_graya16` contract for legal
encoded-sRGB Type-4/16 input. Preserve four source component bytes into existing
little-endian packed `graya16` storage while leaving generic RGBA8 decoding
unchanged.

</domain>

<decisions>
## Implementation Decisions

- **D-01:** Expose only `PngDecoder::decode_graya16` in this phase; use the
  existing `DecodeResult` and `graya16` storage. Do not introduce a conversion
  API or widen generic decode results.
- **D-02:** Admit only legal encoded-sRGB Type-4/16 input with straight alpha;
  reject non-sRGB/ICC and incompatible descriptors through typed existing-style
  diagnostics before producing a result.
- **D-03:** Reuse the one profile-aware decoder machine, its checked preflight,
  DEFLATE/filter framing, and raster ownership. Preserve wire MSB-first
  `Ghi,Glo,Ahi,Alo` into model LE `Glo,Ghi,Alo,Ahi` only at the final sink.
- **D-04:** Freeze the generic Type-4/16 path as `RGBA8(Ghi,Ghi,Ghi,Ahi)` and
  prove explicit preservation with an independent non-symmetric vector.

### the agent's Discretion

- Reuse the smallest existing GrayAlpha16 model and PNG decode fixtures. Chunk
  decoding, Adam7, broad hostile schedules, and all-target qualification remain
  in Phases 63–64.

</decisions>

<canonical_refs>
## Canonical References

- `.planning/ROADMAP.md` — Phase 62 goal and GRA16DEC-01 success criteria.
- `.planning/REQUIREMENTS.md` — v0.20 scope and exclusions.
- `.planning/research/v020-SUMMARY.md` — locked additive decoder profile.
- `.planning/research/v020-ARCHITECTURE.md` — public API and machine integration points.
- `.planning/research/v020-PITFALLS.md` — precision, endianness, and compatibility guards.
- `modules/mb-image/png/raster_decode.mbt` — current Type-4/16 narrowing sink.
- `modules/mb-image/png/png.mbt` and `modules/mb-image/png/*_test.mbt` — public decoder and evidence patterns.

</canonical_refs>

<code_context>
## Existing Code Insights

- The current generic decoder intentionally maps Type-4/16 to high-byte RGBA8;
  its behavior is a compatibility baseline, not a defect to change.
- Existing `graya16` storage is packed little-endian and can retain all four
  component bytes without a new model or dependency.
- The existing decoder owns framing, checked limits, decompression, filtering,
  and raster lifecycle; the preservation profile must only select a final sink.

</code_context>

<deferred>
## Deferred Ideas

- Caller-buffered public preservation, Adam7/filter qualification, broad hostile
  schedules, four-target gates, colour-managed conversion, and any conversion
  API belong to later phases or milestones.

</deferred>
