# Phase 67: Resumable RGBA16 PNG Preservation - Context

**Gathered:** 2026-07-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Expose the exact Phase 66 Type-6/16 preservation profile through the established caller-owned chunk decoder.  The result, resource limits, error precedence, and lifecycle must remain one shared machine contract; this phase adds selection and parity proof, not another PNG decoder.

</domain>

<decisions>
## Implementation Decisions

### Public lifecycle
- **D-01:** Add only `PngChunkDecoder::new_rgba16` and construct the existing byte-fed machine with `PngDecodeProfile::Rgba16`; eager `decode_rgba16` stays the identity oracle.
- **D-02:** Preserve the established chunk lifecycle exactly: empty, one-byte, and ragged input schedules count only accepted bytes; the only image is obtained from successful `finish()`; no caller source view or partial image is retained or exposed.
- **D-03:** Preserve sticky typed terminal errors for malformed, truncated, profile-invalid and resource-limited input, including later pushes and repeated `finish()` calls.

### Compatibility and scope
- **D-04:** Chunk Rgba16 uses the same strict default/sRGB Type-6/16 admission, exact normal/Adam7 final store, eight-byte output accounting, and no-staging guarantee as Phase 66; generic chunk Type-6/16 remains frozen on RGBA8 high bytes.
- **D-05:** Do not add new profiles, alternate parser/raster state, source-tree copying, release automation, or broad independent qualification fixtures.  Phase 68 owns the adversarial and portable qualification matrix.

### the agent's Discretion
- Use the closest `new_graya16` constructor and chunk test harness, adding only Rgba16-specific parity and terminal evidence.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### v0.21 contracts
- `.planning/REQUIREMENTS.md` — `RGBA16DEC-03` chunk lifecycle and result requirements.
- `.planning/ROADMAP.md` — Phase 67 success criteria and scope guard.
- `.planning/phases/66-explicit-rgba16-png-preservation/66-CONTEXT.md` — strict profile, exact lane, and generic compatibility contract.
- `.planning/phases/66-explicit-rgba16-png-preservation/66-01-SUMMARY.md` — completed eager profile and all-target evidence.
- `.planning/phases/66-explicit-rgba16-png-preservation/66-VERIFICATION.md` — evidence-backed Phase 66 acceptance report.

### Existing chunk seam
- `modules/mb-image/png/png.mbt` — public chunk constructor seam, including the closest `new_graya16` selector.
- `modules/mb-image/png/stream_decode.mbt` — accepted-only accounting, terminal state, and private profile machine.
- `modules/mb-image/png/stream_decode_test.mbt` — nearest public chunk parity/schedule tests.
- `modules/mb-image/png/stream_decode_wbtest.mbt` — internal lifecycle, budget and sticky error tests.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `PngChunkDecoder::new_graya16` already selects an explicit high-precision profile through the shared machine.
- The chunk wrapper already owns zero-byte pushes, accepted counts, private lifecycle, terminal transfer and sticky errors.

### Established Patterns
- Explicit precision is opt-in; generic interfaces retain high-byte canonicalisation.
- The sink owns output privately until strict PNG completion and `finish()` transfer.

### Integration Points
- `modules/mb-image/png/png.mbt` supplies the public `new_rgba16` constructor; `stream_decode.mbt` remains its shared private lifecycle implementation.
- Existing public and white-box stream decode tests are extended; Phase 66 source stores remain untouched unless a narrow shared-constructor necessity is proven.

</code_context>

<specifics>
## Specific Ideas

Eager and chunk results must be component-byte-identical under all accepted schedules; the chunk facade must never gain a weaker error or result-visibility contract.

</specifics>

<deferred>
## Deferred Ideas

- Independent all-filter/all-Adam7 wire literals, hostile resource matrix, full portable qualification, copied source workflows and release automation — Phase 68 or out of scope.

</deferred>

---

*Phase: 67-Resumable RGBA16 PNG Preservation*
*Context gathered: 2026-07-23*
