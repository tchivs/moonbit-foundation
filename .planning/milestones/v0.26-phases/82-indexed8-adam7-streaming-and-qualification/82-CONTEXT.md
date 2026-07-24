# Phase 82: Indexed8 Adam7 Streaming and Qualification - Context

**Gathered:** 2026-07-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Qualify the Phase 81 Indexed8 Adam7 machine through caller-owned leases and independent stream-origin evidence. This phase must not create or replace the encoder transport.
</domain>

<decisions>
## Implementation Decisions

### Streaming lifecycle

- **D-01:** Exercise the existing `PngChunkEncoder::new_indexed8_with_interlace_strategy(..., Adam7, ...)` as a thin facade over the Phase 81 machine; no new stream or encoder is permitted.
- **D-02:** Prove zero-capacity, one-byte, and ragged leases against fresh eager bytes, including accepted-only totals and sentinel-preserved unaccepted tails.
- **D-03:** Prove released-lease failure is sticky and writes zero bytes thereafter; prove repeated finished pulls write zero bytes and preserve later destinations.

### Independent qualification

- **D-04:** Parse chunk-origin bytes independently for IHDR, PLTE, canonical tRNS, CRCs and the seven-pass inflated Type-3/8 raster; also use public decode. Do not accept eager/chunk equality as sole evidence.
- **D-05:** Retain opaque/transparent Indexed8 and Indexed1/2/4 literal compatibility vectors, and run the ordinary frozen PNG package gate on all four targets.

### the agent's Discretion

- Reuse existing hostile-drain helpers where they preserve independent assertions and avoid copying transport logic.
</decisions>

<canonical_refs>
## Canonical References

- `.planning/REQUIREMENTS.md` — INDEXADAM7-05 and INDEXADAM7-06.
- `.planning/ROADMAP.md` — Phase 82 success criteria and scope guard.
- `.planning/phases/81-indexed8-adam7-machine-and-eager-wire-contract/81-CONTEXT.md` — frozen machine and compatibility decisions.
- `.planning/phases/81-indexed8-adam7-machine-and-eager-wire-contract/81-VERIFICATION.md` — verified Phase 81 behavior.
</canonical_refs>

<code_context>
## Existing Code Insights

- `modules/mb-image/png/stream_encode.mbt` owns the caller-buffered `present → write → acknowledge` lifecycle.
- `modules/mb-image/png/stream_encode_test.mbt` and `stream_encode_wbtest.mbt` contain the hostile lease patterns to extend.
- `modules/mb-image/png/encode_test.mbt` contains the independent Adam7 wire/decode oracle introduced in Phase 81.
</code_context>

<specifics>
## Specific Ideas

No release automation or model work. The user-directed priority is the code path and portability proof.
</specifics>

<deferred>
## Deferred Ideas

Indexed Type-3/1, /2, /4 Adam7, adaptive filters, alternative compression, staging, a second encoder, FFI, wrappers, copied trees, and release automation remain excluded.
</deferred>
