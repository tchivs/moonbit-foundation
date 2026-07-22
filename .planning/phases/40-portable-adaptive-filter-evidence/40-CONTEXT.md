# Phase 40: Portable Adaptive-Filter Evidence - Context

**Gathered:** 2026-07-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Produce reproducible, public-API evidence that the opt-in PNG Adaptive filter route gives a strict encoded-size win on deliberately selected RGB8 and straight-RGBA8 inputs, while preserving hostile-capacity eager/chunk byte identity and complete public decoding on js, wasm, wasm-gc, and native.

</domain>

<decisions>
## Implementation Decisions

### Evidence corpus and comparison

- **D-01:** Use small deterministic, generated MoonBit RGB8 and straight-RGBA8 fixtures in the PNG public-test layer; do not add external binary fixtures or a new runtime dependency.
- **D-02:** Compare Adaptive against filter-None under the same explicit compression strategy. Each selected fixture must show a strict byte-length improvement, not merely non-regression.
- **D-03:** Keep the corpus intentionally diagnostic: horizontal/vertical predictor-friendly patterns and a fixed expected winner/size relation, rather than benchmark-style broad claims.

### Portable public proof

- **D-04:** Exercise only public eager/chunk encoder factories and `PngDecoder`; do not expose test-only APIs or add a public metrics surface.
- **D-05:** Use a fixed hostile caller-output schedule including zero, one-byte, and ragged capacities. Chunk bytes must exactly equal eager bytes for every evidence case.
- **D-06:** Run each named public evidence case independently on js, wasm, wasm-gc, and native with a cleaned temporary target root; each decoded result must match source dimensions, format, and bytes completely.

### Scope fence

- **D-07:** Do not change Adaptive filtering, compression-selection, resource accounting, factory signatures, or legacy None bytes in this phase. It is evidence-only unless an evidence test proves a Phase 39 regression.

### the agent's Discretion

- Choose the smallest deterministic RGB8 and straight-RGBA8 patterns that produce stable strict wins across all four targets, and encode their expected relations as executable tests.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase contract

- `.planning/ROADMAP.md` — Phase 40 goal, PNGF-04, and three success criteria.
- `.planning/REQUIREMENTS.md` — PNGF-04 traceability.
- `.planning/phases/39-bounded-filter-planning-and-replay/39-VERIFICATION.md` — completed bounded Adaptive cursor, selection, and resource-accounting contracts that evidence must preserve.

### Existing public evidence patterns

- `modules/mb-image/png/encode_test.mbt` — eager public PNG encoder test patterns and semantic decode assertions.
- `modules/mb-image/png/stream_encode_test.mbt` — hostile caller-buffer chunk encoder, byte-parity, and sticky-terminal public patterns.
- `modules/mb-image/png/png_test.mbt` — public decoder equality and portable PNG evidence patterns.
- `scripts/quality/Invoke-PngEncodeEvidence.ps1` — target-isolated four-target evidence command convention.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `PngEncoder::new_with_strategies` and `PngChunkEncoder::new_with_strategies`: public combined compression/filter construction.
- Existing deterministic image builders and chunk-drain helpers in `encode_test.mbt` and `stream_encode_test.mbt`: reusable source and hostile-capacity helpers.
- `PngDecoder`: public complete-decode oracle already exercised across portable targets.

### Established Patterns

- Test generated source pixels and decode semantic equality rather than opaque binary snapshots alone.
- Keep every portable target as independent evidence with one explicit temporary target directory and cleanup.
- Preserve exact legacy filter-None compatibility routes while testing explicit Adaptive opt-in.

### Integration Points

- Add evidence to existing PNG public eager/chunk tests and the focused PNG evidence script only if needed for reproducible target invocation.

</code_context>

<specifics>
## Specific Ideas

No external visual or product requirements — use standard deterministic public PNG evidence patterns.

</specifics>

<deferred>
## Deferred Ideas

None — this phase is intentionally evidence-only and stays within the v0.12 PNG Adaptive-filter milestone.

</deferred>

---

*Phase: 40-portable-adaptive-filter-evidence*
*Context gathered: 2026-07-22*
