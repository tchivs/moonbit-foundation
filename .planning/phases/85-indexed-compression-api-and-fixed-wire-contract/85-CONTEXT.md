# Phase 85: Indexed Compression API and Fixed Wire Contract - Context

**Gathered:** 2026-07-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Add an explicit, opt-in compression choice to non-interlaced Type-3 indexed PNG
encoding at 1, 2, 4, and 8 bits. It must retain the current Stored/filter-None
wire bytes for every legacy/default indexed entry point and establish the single
bounded raw-byte/match source needed for deterministic Fixed-or-Stored output.

</domain>

<decisions>
## Implementation Decisions

### Public selector boundary
- **D-01:** Add exactly four additive APIs: eager and chunk constructors for
  Indexed8 and selected low-bit indexed sources, each taking the existing
  `PngCompressionStrategy`. They are non-interlaced only; do not create a
  combined compression/filter/interlace API in this milestone. —
  **Reversibility:** costly — adding a different public selector later would
  require preserving the published API contract and test matrix.
- **D-02:** Existing/default Indexed8 and Indexed1/2/4 APIs remain literal
  forwards to `Stored` plus filter `None`; indexed Adam7 remains an explicit
  Stored/None compatibility baseline.

### Unavailable and selection semantics
- **D-03:** The new selectors admit only `Stored` and `FixedOrStored`.
  `DynamicOrFixedOrStored` fails with a stable indexed-dynamic-unavailable
  capability error before planning, writer output, chunk lease exposure, or a
  budget charge. — **Reversibility:** costly — callers must be able to rely on
  truthful capability failure rather than a silent fallback.
- **D-04:** `FixedOrStored` compares exact *complete Type-3 frame* sizes,
  including IHDR, PLTE, canonical shortest tRNS, IDAT, and IEND. Fixed wins on
  a tie (`fixed_frame <= stored_frame`); otherwise use literal Stored output.

### Shared bounded production and compatibility proof
- **D-05:** Reuse one immutable, bounded, filter-None indexed raw-byte/match
  producer for Stored traversal, Fixed planning, and Fixed acknowledgement-safe
  replay. Reuse the existing 1--4-distance matcher, Fixed emitter, and sole
  acknowledged machine; do not stage pixels/tokens/output, widen the matcher,
  or create a second encoder.
- **D-06:** Phase-85 evidence focuses on API shape, literal Stored forwarding,
  Dynamic atomic rejection, and deterministic Fixed-or-Stored wire selection.
  Hostile leases, ancillary-aware admission boundaries, independent wire
  parsing, and four-target package qualification remain owned by Phases 86--87.

### the agent's Discretion
- Use existing public naming and error-construction patterns when resolving the
  concrete method and capability-error spellings; preserve the decisions above.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone contract
- `.planning/ROADMAP.md` — Phase 85 goal, success criteria, and scope guard.
- `.planning/REQUIREMENTS.md` — active v0.28 indexed-compression requirements.
- `.planning/research/v028-INDEXED-PNG-COMPRESSION.md` — verified seams,
  public-surface recommendation, exact selection policy, and scope fences.

### Established indexed behaviour
- `.planning/milestones/v0.27-phases/84-low-bit-indexed-adam7-streaming-qualification/84-CONTEXT.md`
  — frozen low-bit/Adam7 machine and qualification decisions.
- `.planning/milestones/v0.27-phases/84-low-bit-indexed-adam7-streaming-qualification/84-VERIFICATION.md`
  — shipped compatibility baseline to preserve.

### Production integration
- `modules/mb-image/png/encode.mbt` — indexed eager API forwards, indexed
  preflight, match cursor, Fixed planning, and frame facts.
- `modules/mb-image/png/stream_encode.mbt` — sole acknowledged machine and
  caller-buffered indexed construction.
- `modules/mb-image/png/png.mbt` — public compression strategy vocabulary and
  indexed source contract.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `PngCompressionStrategy`, `PngFilteredMatchCursor`, Fixed planning/emission,
  and `PngFrameFacts` already express generic Stored/Fixed selection.
- `PngEncodeMachine::new_with_indexed_profile` is the single indexed machine
  construction seam and currently hard-wires Stored/None.

### Established Patterns
- Existing indexed eager APIs forward through their interlace selectors; chunk
  APIs call the same private machine before any caller lease is exposed.
- Public compression constructors use the shared strategy enum rather than
  duplicate indexed-only profile types.

### Integration Points
- `modules/mb-image/png/encode.mbt` owns eager selector forwards and indexed
  preflight; `modules/mb-image/png/stream_encode.mbt` owns chunk forwards and
  output replay; their tests own compatible regression coverage.

</code_context>

<specifics>
## Specific Ideas

No additional user-specific presentation requirements. The user explicitly
prioritizes code and tests over release automation and authorizes the optimal
scoped implementation choice.

</specifics>

<deferred>
## Deferred Ideas

- Indexed Dynamic DEFLATE, adaptive filtering, and Adam7 compression selection
  are separate future capabilities.
- Ancillary-aware selected admission is Phase 86; hostile streaming and
  independent four-target qualification are Phase 87.
- Release automation, registry work, FFI, generic model changes, and copied
  source trees are outside this milestone.

</deferred>

---

*Phase: 85-Indexed Compression API and Fixed Wire Contract*
*Context gathered: 2026-07-24*
