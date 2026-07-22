# Phase 49: Portable Gray16 Public Evidence - Context

**Gathered:** 2026-07-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Prove the completed public Gray16 PNG path across js, wasm, wasm-gc, and native: exact U16 wire bytes, documented decoder canonicalization, eager/chunk identity under zero/one/ragged caller capacities, and frozen legacy vectors. This phase adds evidence only; it does not add encoding features, APIs, release automation, or staging buffers.
</domain>

<decisions>
## Implementation Decisions

- **D-01:** Reuse the public Gray16 eager and chunk constructors completed in Phases 47-48. Evidence must exercise the explicit public surface, not private encoder seams.
- **D-02:** Use generated non-symmetric U16 Gray fixtures (both source storage endiannesses) and inspect decompressed PNG scanlines to prove every high and low byte survives in standards-required wire order; validate the established public RGB decoder canonicalization separately.
- **D-03:** Exercise zero, one-byte, and deterministic ragged caller leases against eager output for the supported Gray16 strategy combinations. Require byte identity, accepted-only progress, completion, and sticky terminals; do not introduce a second stream driver or fixture staging.
- **D-04:** Run the public evidence as independent js, wasm, wasm-gc, and native commands. Keep frozen Gray8/RGB8/RGBA8 vectors in the same target-level evidence to detect compatibility regressions.

### the agent's Discretion

- Choose the smallest generated corpus and helper set that proves every stated public contract while preserving the existing bounded test patterns.
</decisions>

<canonical_refs>
## Canonical References

### Milestone contract
- `.planning/ROADMAP.md` — Phase 49 goal and all three success criteria.
- `.planning/REQUIREMENTS.md` — `GRAY16-03` public-evidence boundary.
- `.planning/phases/48-bounded-gray16-encoder-path/48-CONTEXT.md` — locked bounded encoding and Phase 49 deferrals.
- `.planning/phases/48-bounded-gray16-encoder-path/48-VERIFICATION.md` — verified strategy/replay baseline.

### Public evidence surface
- `modules/mb-image/png/png.mbt` — explicit Gray16 public constructors.
- `modules/mb-image/png/encode_test.mbt` — eager PNG and decode-canonicalization fixtures.
- `modules/mb-image/png/stream_encode_test.mbt` — caller lease schedules, accepted-progress, and legacy vectors.
- `modules/mb-image/storage/views.mbt` — U16 component storage and endianness access contract.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Public Gray16 strategy factories and the shared eager/chunk encoder path from Phases 47-48.
- Existing Gray8 portable public-evidence tests, one-byte pull helpers, deterministic ragged schedules, and frozen RGB/RGBA vectors.
- Existing PNG decoder test helpers for decompressed payload and documented RGB canonicalization.

### Established Patterns
- Target evidence is run separately with `moon ... --target js`, `wasm`, `wasm-gc`, and `native`.
- Caller-buffered progress counts only accepted bytes and terminal errors remain sticky.
- Wire-level image assertions use semantic payload checks rather than opaque binary snapshots.

### Integration Points
- Extend `encode_test.mbt` and `stream_encode_test.mbt`; do not add a new module, executable, or release script.
</code_context>

<specifics>
## Specific Ideas

No new product behavior: select the existing Gray8 public-evidence shape as the compatibility model, then prove the Gray16-specific two-byte sample invariant.
</specifics>

<deferred>
## Deferred Ideas

Gray16 Adam7, Gray+alpha, RGB/RGBA16, palette/low-bit formats, publication, release automation, and new codec features remain out of scope.
</deferred>

---

*Phase: 49-portable-gray16-public-evidence*
*Context gathered: 2026-07-22*
