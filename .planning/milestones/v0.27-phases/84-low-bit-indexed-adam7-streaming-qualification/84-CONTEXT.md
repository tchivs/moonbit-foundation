# Phase 84: Low-Bit Indexed Adam7 Streaming Qualification - Context

**Gathered:** 2026-07-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Qualify the Phase 83 low-bit Adam7 machine through caller-owned leases and independent chunk-origin evidence. Do not create another encoder or alter packed-pass production logic.
</domain>

<decisions>
## Implementation Decisions

- **D-01:** Exercise the existing selected low-bit chunk API with Adam7 over the Phase 83 machine; no production transport replacement is permitted.
- **D-02:** Cover zero, one-byte and ragged leases at depths One/Two/Four, accepted-only totals, sentinel tails, released-lease failure and repeated Finished/Failed sticky outcomes.
- **D-03:** Independently parse drained output for IHDR/PLTE/tRNS/CRC, packed pass raw raster and public RGB8/RGBA8 decode; eager equality alone is insufficient.
- **D-04:** Freeze established non-interlaced low-bit, Indexed8 Adam7 and legacy vectors; run the ordinary package gate on all four targets.
</decisions>

<canonical_refs>
## Canonical References

- `.planning/REQUIREMENTS.md` — INDEXLOWADAM7-05 and -06.
- `.planning/ROADMAP.md` — Phase 84 success criteria.
- `.planning/phases/83-low-bit-indexed-adam7-machine-and-eager-contract/83-VERIFICATION.md` — Phase 83 verified packing contract.
- `.planning/research/v027-LOWBIT-ADAM7.md` — low-bit Adam7 risk and evidence recommendations.
</canonical_refs>

<code_context>
## Existing Code Insights

- `modules/mb-image/png/stream_encode.mbt` owns the acknowledged caller-buffered facade.
- `modules/mb-image/png/stream_encode_test.mbt` owns hostile drain and sticky lease evidence.
- `modules/mb-image/png/encode_test.mbt` owns independent low-bit Adam7 wire/decode fixtures.
</code_context>

<deferred>
## Deferred Ideas

Generic model widening, new filters/compression, palette generation, staging, a second encoder, FFI, wrappers and release automation remain excluded.
</deferred>
