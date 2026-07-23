# Phase 63: Resumable GrayAlpha16 Decode - Context

**Gathered:** 2026-07-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Expose the Phase 62 Type-4/16 preservation result through caller-owned chunks
using `PngChunkDecoder::new_graya16`, with the existing bounded decoder lifecycle
and eager-equivalent terminal result.

</domain>

<decisions>
## Implementation Decisions

- **D-01:** Add only `PngChunkDecoder::new_graya16`; it selects the same private
  GrayAlpha16 profile and `DecodeResult` shape as eager `decode_graya16`.
- **D-02:** Reuse existing chunk framing, accepted-only byte progress, finish,
  atomic failure, and sticky terminal state. Do not build a second chunk machine
  or retain a second image representation.
- **D-03:** Prove arbitrary hostile split schedules against a fresh eager peer,
  including zero/one/ragged chunks, early finish, malformed/metadata rejection,
  and unchanged generic chunk decoding.

### the agent's Discretion

- Reuse the closest GrayAlpha16/streaming helper. Adam7/filter breadth and
  four-target qualification remain Phase 64.

</decisions>

<canonical_refs>
## Canonical References

- `.planning/ROADMAP.md` and `.planning/REQUIREMENTS.md` — GRA16DEC-02 contract.
- `.planning/phases/62-explicit-grayalpha16-decode-contract/62-VERIFICATION.md` — eager profile handoff.
- `.planning/research/v020-SUMMARY.md` — one-machine/no-staging constraints.
- `modules/mb-image/png/stream_decode.mbt` and `stream_decode_test.mbt` — chunk lifecycle and public schedule patterns.
- `modules/mb-image/png/png.mbt` and `raster_decode.mbt` — eager profile/result seam.

</canonical_refs>

<code_context>
## Existing Code Insights

- Phase 62 already proves the profile's final sink and typed admission.
- The established chunk decoder owns framing, accepted counts, `finish()`, and
  sticky outcomes; profile selection must flow through that machine rather than
  create a separate transport or output buffer.

</code_context>

<deferred>
## Deferred Ideas

- Adam7/filter variants, broad resource matrix, frozen legacy matrix, and all
  targets are reserved for Phase 64; no conversion API or generic decoder
  change is allowed.

</deferred>
