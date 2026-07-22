# Phase 52: Portable Gray+Alpha Public Evidence - Context

**Gathered:** 2026-07-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Turn the completed Gray+Alpha8 model and bounded PNG encoder into portable public evidence: freeze exact wire/decode expectations, exercise hostile caller-buffered schedules, retain legacy byte vectors, and run the complete evidence independently on js, wasm, wasm-gc, and native. No new encoder capability is introduced.

</domain>

<decisions>
## Implementation Decisions

### Public vectors and decode contract
- **D-01:** Use compact, public package tests with non-symmetric GrayAlpha8 fixture pairs and explicit expected PNG bytes (or small checked byte slices where framing is already covered). Assert decoded public pixels canonicalize to straight RGBA8 with gray replicated into R/G/B and source alpha unchanged. — **Reversibility:** costly — frozen public byte vectors become the compatibility baseline for future encoder work.
- **D-02:** Keep the public evidence at existing `mb-image/png` API seams: construct through `PngEncoder`/`PngChunkEncoder` and decode through the package's public decoder; do not test private profiles or add a test-only encoder path.

### Caller-buffered hostile schedules
- **D-03:** For every existing compression/filter pair, drain valid GrayAlpha8 chunk encoders under zero-capacity, one-byte, and deterministic ragged capacities. Each schedule must match eager bytes, report only accepted progress, and retain the established sticky terminal outcome. — **Reversibility:** costly — weakening this matrix would remove the public bounded ownership guarantee from the portable contract.
- **D-04:** Reuse the existing streaming test drivers, sentinels, and terminal-error helpers. Do not add staging buffers, retry logic, target branches, or copied source trees merely to make hostile schedules pass.

### Compatibility and portability
- **D-05:** Freeze the already-established Gray8, Gray16, RGB8, and straight-RGBA8 eager vectors byte-for-byte beside the GrayAlpha evidence. Treat any change as a regression, not a new expected baseline.
- **D-06:** Run the same package test invocation with `--target all` and keep tests portable MoonBit only; no native FFI, platform-specific fixtures, release automation, or registry work belongs in this phase.

### the agent's Discretion
- Choose the smallest readable fixture/vector layout consistent with the existing Gray16 public-evidence pattern.
- Reuse the existing assertion helpers where they already capture accepted-only progress and sticky terminals; add focused helpers only when GrayAlpha component fidelity is not otherwise observable.
- Keep tests localized to the PNG package unless a public model fixture genuinely needs an adjacent existing test helper.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone contract
- `.planning/ROADMAP.md` — Phase 52 goal and all four public-evidence success criteria.
- `.planning/REQUIREMENTS.md` — `GRAYA-04` and `GRAYA-05` acceptance requirements.
- `.planning/PROJECT.md` — portability, compatibility, and no-release-automation constraints.
- `.planning/phases/50-gray-alpha-image-model/50-CONTEXT.md` — locked packed U8 GrayAlpha descriptor identity.
- `.planning/phases/51-bounded-gray-alpha-png-encoding/51-CONTEXT.md` — bounded encoder decisions and Phase 52 ownership boundary.
- `.planning/phases/51-bounded-gray-alpha-png-encoding/51-VERIFICATION.md` — verified Phase 51 factory, wire, and atomicity baseline.
- `.planning/milestones/v0.15-phases/49-portable-gray16-public-evidence/49-CONTEXT.md` — closest existing portable public-evidence conventions.

### Existing PNG implementation and tests
- `modules/mb-image/png/png.mbt` — public eager encoder factory families.
- `modules/mb-image/png/stream_encode.mbt` — public caller-buffered encoder construction and acknowledgement-safe replay behavior.
- `modules/mb-image/png/encode_test.mbt` — eager public wire/decode and legacy-vector regression patterns.
- `modules/mb-image/png/stream_encode_test.mbt` — hostile capacity, accepted-progress, terminal, and strategy-matrix test helpers.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Phase 51 `graya8` eager and chunk factory families cover every public bounded compression/filter selection.
- Existing Gray16 portable-evidence regressions supply the closest public wire/decode and frozen-vector pattern.
- Streaming helpers already drain arbitrary capacity schedules and inspect accepted bytes, budget, sentinels, and terminal behavior.

### Established Patterns
- PNG public compatibility is protected with compact frozen byte vectors, not opaque snapshots or generated release fixtures.
- Portable target proof is a single MoonBit test suite invoked with `--target all`; tests must not rely on target-specific behavior.
- Existing encoder routes remain stable through additive profile factories, never altered defaults.

### Integration Points
- Extend only `modules/mb-image/png/encode_test.mbt` and `modules/mb-image/png/stream_encode_test.mbt` unless the existing Gray16 evidence shows a narrowly necessary adjacent test location.

</code_context>

<specifics>
## Specific Ideas

Every GrayAlpha fixture uses distinct gray and alpha values so component swaps, accidental opacity, and decode canonicalization errors remain observable.

</specifics>

<deferred>
## Deferred Ideas

- Gray+Alpha16, Adam7, palettes/low-bit modes, colour conversion, and new encoder architecture.
- Release automation, publication work, native adapters, generated source copies, and per-target implementations.

</deferred>

---

*Phase: 52-portable-gray-alpha-public-evidence*
*Context gathered: 2026-07-23*
