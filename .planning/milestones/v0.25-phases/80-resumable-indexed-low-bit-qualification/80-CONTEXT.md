# Phase 80: Resumable Indexed Low-Bit Qualification - Context

**Gathered:** 2026-07-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Expose the completed Phase 79 Type-3/1, /2, and /4 eager machine through the existing caller-owned `PngChunkEncoder`, then prove eager-identical bytes, accepted-only lease progression, sticky terminals, independent wire/decode behavior, Indexed8 compatibility, and the ordinary four-target PNG package gate. This phase adds no second transport, Adam7, generic model, strategy, or staging path.

</domain>

<decisions>
## Implementation Decisions

### Thin public adapter
- **D-01:** Add one additive `PngChunkEncoder` indexed low-bit factory taking the same `PngIndexedImage`, finite `PngIndexedBitDepth`, limits, budget, and diagnostics inputs as the eager low-bit route. It delegates to Phase 79's selector-aware private machine constructor; `new_indexed8` remains unchanged. — **Reversibility:** costly — its public lease lifecycle becomes a consumer contract.
- **D-02:** Do not duplicate traversal, framing, or CRC state. Eager and caller-buffered low-bit outputs must use one profile-aware machine and identical preflight facts.

### Caller-owned lifecycle
- **D-03:** For every depth, prove zero-capacity, one-byte, and ragged leases are eager-byte-identical; only accepted bytes advance progress/CRC; lease tails keep sentinels; success and error terminals stay sticky. Include a released-lease failure without later-lease mutation.
- **D-04:** Retain atomic selected-depth preflight: rejected construction exposes no lease and changes no budget state. Keep all Phase 79 eager and fixed Indexed8 chunk behavior frozen.

### Qualification evidence
- **D-05:** Reuse independent Type-3 wire/CRC and public RGB8/RGBA8 decode assertions, not production packing helpers. Run the ordinary frozen PNG package command on wasm, wasm-gc, js, and native. No wrappers, copied source trees, or release automation.

### the agent's Discretion
- Follow the closest existing chunk-constructor spelling and capability-error vocabulary.
- Reuse existing hostile-drain helpers rather than creating a second transport-test harness.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and completed dependency
- `.planning/PROJECT.md` — v0.25 goal and portable/bounded constraints.
- `.planning/REQUIREMENTS.md` — INDEXLOW-04 and INDEXLOW-05 acceptance requirements and exclusions.
- `.planning/ROADMAP.md` — Phase 80 goal, dependency, and scope guard.
- `.planning/research/v025-INDEXED-LOW-BIT-ENCODE.md` — low-bit framing, hostile lease, and qualification evidence anchors.
- `.planning/phases/79-indexed-low-bit-eager-packing/79-CONTEXT.md` — locked eager API and machine decisions.
- `.planning/phases/79-indexed-low-bit-eager-packing/79-RESEARCH.md` — resolved eager API seam and compatibility rules.
- `.planning/phases/79-indexed-low-bit-eager-packing/79-01-SUMMARY.md` — implemented low-bit profile facts and tests.
- `.planning/phases/79-indexed-low-bit-eager-packing/79-VERIFICATION.md` — verified Phase 79 outcomes and explicit Phase 80 boundary.

### Code and test seams
- `modules/mb-image/png/stream_encode.mbt` — `PngChunkEncoder`, `pull`, terminals, and selector-aware shared machine.
- `modules/mb-image/png/stream_encode_test.mbt` — zero/one/ragged leases, sentinels, released leases, and sticky-terminal patterns.
- `modules/mb-image/png/encode_test.mbt` — independent low-bit wire/CRC and public decode vectors.
- `modules/mb-image/png/encode.mbt` — eager selected-depth preflight and Indexed8 compatibility wrappers.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `PngChunkEncoder::new_indexed8`: the fixed-eight thin adapter to preserve while adding the selector-bearing companion.
- `PngChunkEncoder::pull`: accepted-only acknowledgement, lease ownership, zero-capacity, and sticky terminal implementation shared by every profile.
- Existing packed-gray and Indexed8 hostile drain tests: schedules, sentinel tail checks, release-failure assertions, and terminal test vocabulary.
- Phase 79 independent wire/decode vectors: eager oracle for every streaming comparison.

### Established Patterns
- Chunk factories preflight fully before exposing a lease and hold one `PngEncodeMachine`.
- Public streaming compatibility is byte parity under hostile capacities, not merely successful decode.
- New profile-specific APIs are additive and old route bytes remain frozen.

### Integration Points
- The new selector-bearing constructor should call Phase 79's selector-aware private constructor and then initialize existing `PngChunkEncoderState::Active` exactly as `new_indexed8` does.
- Qualification belongs in `stream_encode_test.mbt`, with eager test-local wire/decode helpers retained as independent evidence.

</code_context>

<specifics>
## Specific Ideas

The user authorized autonomous choices and prioritizes implementation and tests over release scripts. The selected path is therefore a single thin constructor plus hostile ownership proof and ordinary four-target qualification.

</specifics>

<deferred>
## Deferred Ideas

Indexed Adam7, compression/filter strategy choices, generic model widening, quantization, source packing models, staging buffers, FFI, wrappers, copied source trees, and release automation remain out of scope.

</deferred>

---

*Phase: 80-resumable-indexed-low-bit-qualification*
*Context gathered: 2026-07-24*
