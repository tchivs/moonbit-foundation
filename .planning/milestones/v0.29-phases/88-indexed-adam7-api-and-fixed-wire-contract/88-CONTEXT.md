# Phase 88: Indexed Adam7 API and Fixed Wire Contract - Context

**Gathered:** 2026-07-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Add the public and private contract for explicit Adam7 `Stored`/`FixedOrStored`
compression on Indexed1/2/4/8 eager and caller-buffered encoding. Existing
Adam7 selectors remain literal Stored/filter-None compatibility forwards, and
the v0.28 non-interlaced selectors remain unchanged. This phase defines the
additive API and exact pass-aware Fixed-vs-Stored wire contract; admission,
shared-machine integration, and hostile qualification are Phase 89/90 work.

</domain>

<decisions>
## Implementation Decisions

### Additive API and compatibility surface

- **D-01:** Add paired eager and caller-buffered methods named with the existing
  selector vocabulary (`...with_interlace_and_compression_strategy`) rather
  than changing or overloading the existing interlace-only methods. Existing
  interlace-only methods remain literal `Stored` forwards.
- **D-02:** Expose the same `Stored` and `FixedOrStored` strategy enum already
  used by v0.28; do not add a new indexed-specific enum or widen the source
  model. `DynamicOrFixedOrStored` remains an unavailable future capability.
- **D-03:** Cover all four indexed wire depths (1, 2, 4, and 8) in this API
  contract, including the selected-depth low-bit family and the established
  Indexed8 family.

### Exact Adam7 Fixed wire contract

- **D-04:** The Adam7 raw stream is pass-local and deterministic: each non-empty
  pass starts at local column zero, emits filter byte `0`, packs low-bit codes
  MSB-first, and zeroes unused tail bits. Pass order and geometry come from the
  established `_png_adam7_passes(width, height, 1, depth)` contract.
- **D-05:** `FixedOrStored` means compare complete PNG frame facts, including
  PLTE/tRNS and IDAT framing, and choose Fixed on a strict win or tie. The
  contract never stages pass rows, compressed output, or a second encoder.
- **D-06:** Legacy/default output remains byte-frozen. New API routes are
  opt-in only, and any unsupported strategy must fail before output, lease, or
  budget mutation.

### the agent's Discretion

- Exact private type/function names may follow the existing `PngMatchProducer`,
  `PngFilteredMatchCursor`, and `PngEncodeMachine` naming if the compiler or
  plan review identifies a more idiomatic spelling.
- Planner may split the public API red tests from the private pass cursor tests
  as long as every decision above is represented by executable evidence.

</decisions>

<canonical_refs>
## Canonical References

### Requirements and roadmap

- `.planning/ROADMAP.md` — Phase 88 goal, scope guard, and success criteria.
- `.planning/REQUIREMENTS.md` — ADAM7COMP-01 contract and v0.29 out-of-scope boundary.

### Existing indexed and Adam7 contracts

- `.planning/milestones/v0.28-phases/87-hostile-indexed-streaming-and-independent-qualification/87-01-SUMMARY.md` — hostile indexed streaming and independent oracle baseline.
- `.planning/milestones/v0.27-ROADMAP.md` — frozen low-bit Indexed Adam7 Stored/filter-None contract.
- `modules/mb-image/png/png.mbt` — public compression/interlace strategy enums and indexed bit-depth contract.
- `modules/mb-image/png/encode.mbt` — indexed preflight, Adam7 pass geometry, frame facts, and Fixed plan boundaries.
- `modules/mb-image/png/stream_encode.mbt` — acknowledged eager/chunk machine, indexed cursor seam, and replay state.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `_png_adam7_passes(width, height, 1, depth)` already computes pass geometry and packed row bytes for all indexed depths.
- `_png_frame_facts`, `_png_indexed_stored_idat_length`, `PngDeflatePlan::Fixed`, and the v0.28 matcher define the complete-frame selection contract.
- `PngEncodeMachine` and `PngChunkEncoder` already provide the sole acknowledged `present → accept → acknowledge` path.

### Established Patterns

- Additive profile factories preserve old APIs as literal forwards and keep legacy bytes frozen.
- Resource arithmetic and capability rejection happen before writer progress, lease exposure, or budget mutation.
- Packed Adam7 rows restart at local pass columns and explicitly zero unused tail bits.

### Integration Points

- Public eager factories in `modules/mb-image/png/encode.mbt` and caller-buffered factories in `modules/mb-image/png/stream_encode.mbt` must converge on one indexed machine constructor.
- The pass-aware producer must become the indexed branch of the existing bounded matcher without changing generic `ImageView` filtering or compression paths.

</code_context>

<specifics>
## Specific Ideas

Use v0.28's non-interlaced API and qualification matrix as the naming and
compatibility baseline, then add only the Adam7 dimension. Keep the public
contract explicit enough that a caller can request Stored for deterministic
baseline bytes or FixedOrStored for a bounded candidate comparison.
</specifics>

<deferred>
## Deferred Ideas

- Dynamic indexed DEFLATE, adaptive indexed filtering, wider matching, and a
  32 KiB dictionary remain separate future milestones.
- No decoder, palette generation, quantization, metadata expansion, FFI,
  release automation, or copied source tree work belongs here.

</deferred>

---

*Phase: 88-indexed-adam7-api-and-fixed-wire-contract*
*Context gathered: 2026-07-24*
