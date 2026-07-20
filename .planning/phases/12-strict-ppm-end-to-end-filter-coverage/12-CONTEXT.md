# Phase 12: Strict PPM End-to-End Filter Coverage - Context

**Gathered:** 2026-07-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Close the v0.3 audit's only partial integration path with one deterministic strict-PPM decode-to-encode vector that actually invokes crop, named rotation, grayscale, alpha-aware box blur, and the established RGBA source-over bridge. This is test/example evidence only: no new public API, algorithm, codec, benchmark, or release work.

</domain>

<decisions>
## Implementation Decisions

### Pipeline contract
- **D-01:** Use a small fixed strict PPM RGB input, decode through the public PPM API, crop and rotate before conversion, then grayscale and blur the straight RGBA result before source-over and RGB conversion/encoding.
- **D-02:** Preserve the existing metadata compatibility and budget contracts; every step receives an explicit budget and the vector asserts deterministic encoded bytes/digest plus selected semantic pixels.
- **D-03:** Use one named right-angle rotation and a radius-zero or one clamp-edge blur chosen by research for a compact, non-degenerate filter proof.

### Evidence scope
- **D-04:** The vector and at least one hostile resource/error boundary must execute on js, wasm, wasm-gc, and native with output assertions that prove the new sequence, not a pre-existing PPM path.
- **D-05:** Keep the change in Phase-11 portable pipeline tests/example support files; do not modify release scripts, benchmark harnesses, or public APIs.

### the agent's Discretion
- Select exact image dimensions/pixels, crop rectangle, rotation direction, blur radius, overlay pixels, expected byte encoding, and helper placement from existing test patterns.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/v0.3-v0.3-MILESTONE-AUDIT.md` — audit source and exact integration debt.
- `.planning/phases/11-portable-processing-pipeline-evidence/11-VERIFICATION.md` — current verified PPM route and evidence conventions.
- `examples/ppm-portable/main/main.mbt` — current public strict PPM pipeline.
- `modules/mb-image/ops/geometry.mbt` — crop and named rotation API.
- `modules/mb-image/ops/processing.mbt` — grayscale and box blur API.
- `modules/mb-image/ops/processing_pipeline_test.mbt` and `processing_pipeline_wbtest.mbt` — existing composed pipeline test patterns.
- `modules/mb-image/README.mbt.md` — public executable documentation constraints.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The Phase 11 strict PPM vector already proves decode, resize, conversion, source-over, RGB conversion, and encode.
- Phase 9 and 10 public operations return owned results and share typed budget/error conventions.

### Established Patterns
- Public/white-box test pairs must provide named four-target evidence.
- Deterministic bytes/digest and semantic pixel assertions avoid opaque snapshots.

### Integration Points
- Extend the existing portable pipeline test/example support without changing package APIs.

</code_context>

<specifics>
## Specific Ideas

This phase is an audit-driven proof closure. Its goal is not broader feature delivery; it makes the already-delivered crop/rotate/filter API visible in the real strict PPM end-to-end path.

</specifics>

<deferred>
## Deferred Ideas

- Additional codecs, filter families, optimized paths, and release automation remain outside this proof-only phase.

</deferred>

---

*Phase: 12-Strict PPM End-to-End Filter Coverage*
*Context gathered: 2026-07-20*
