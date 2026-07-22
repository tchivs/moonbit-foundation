# Phase 43: Portable Adam7 Public Evidence - Context

**Gathered:** 2026-07-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Prove, through the public PNG API, that bounded Adam7 RGB8 and straight-RGBA8 encoding round-trips exactly, preserves eager/chunk identity under hostile capacities, preserves frozen non-interlaced output, and runs independently on js, wasm, wasm-gc, and native.
</domain>

<decisions>
## Implementation Decisions

### Public evidence corpus
- **D-01:** Generate deterministic, bounded RGB8 and straight-RGBA8 source cases that exercise all Adam7 passes; decode only through the public API and compare every output pixel to the source.
- **D-02:** Keep generated cases in public black-box tests. Do not add image-sized fixtures, private cursor assertions, or new encoder algorithms.

### Compatibility and streaming evidence
- **D-03:** Drain Adam7 chunk output using zero, one-byte, and ragged capacities, and compare the complete result byte-for-byte with the eager route.
- **D-04:** Retain existing immutable legacy and explicit-None byte vectors as compatibility baselines; Adam7 must use IHDR method 1 without changing those vectors.

### Portable execution
- **D-05:** Execute public Adam7 selectors independently on js, wasm, wasm-gc, and native through a quality runner that uses unique, owned temporary target directories and always removes them.

### the agent's Discretion
Choose deterministic case dimensions, selector names, and the smallest reusable public test helpers, provided they cover both profiles and all three compression strategies without broadening Phase 43.
</decisions>

<canonical_refs>
## Canonical References

- `.planning/ROADMAP.md` — Phase 43 goal and success criteria.
- `.planning/REQUIREMENTS.md` — PNGI-04 acceptance boundary.
- `.planning/phases/42-bounded-adam7-pass-encoding/42-CONTEXT.md` — frozen Adam7 and None compatibility decisions.
- `.planning/phases/42-bounded-adam7-pass-encoding/42-VERIFICATION.md` — verified algorithm/replay guarantees to expose publicly.
- `scripts/quality/Invoke-PngAdam7Compatibility.ps1` — existing independent-target cleanup pattern.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `modules/mb-image/png/encode_test.mbt` and `stream_encode_test.mbt`: public eager, immutable-vector, and hostile-capacity patterns.
- `scripts/quality/Invoke-PngAdam7Compatibility.ps1`: owned temporary target-directory lifecycle.

### Integration Points
- Public `PngEncoder`, `PngChunkEncoder`, and `PngDecoder` are the sole evidence surface.
</code_context>

<specifics>
## Specific Ideas

No additional product behavior — this phase exposes already implemented Adam7 behavior through public tests and portable evidence.
</specifics>

<deferred>
## Deferred Ideas

None — release automation, new codecs, and encoder heuristics remain out of scope.
</deferred>

---

*Phase: 43-portable-adam7-public-evidence*
*Context gathered: 2026-07-22*
