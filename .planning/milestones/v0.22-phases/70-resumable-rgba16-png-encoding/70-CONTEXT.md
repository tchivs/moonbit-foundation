# Phase 70: Resumable RGBA16 PNG Encoding - Context

**Gathered:** 2026-07-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Expose Phase 69's exact non-interlaced Type-6/16 RGBA16 profile through the established caller-owned `PngChunkEncoder`. The chunk facade must have byte parity with eager encoding and retain the shared atomic-admission, accepted-only progress, lease isolation, and sticky-terminal contract.

</domain>

<decisions>
## Implementation Decisions

### Public chunk selection
- **D-01:** Add the four `PngChunkEncoder::new_rgba16*` factory shapes matching the eager RGBA16 family; each selects `PngEncodeProfile::Rgba16` with `PngInterlaceStrategy::None`.
- **D-02:** Reuse `PngEncodeMachine::new_with_profile` and the existing `pull` lifecycle unchanged; a fresh eager encoder remains the byte-identity oracle.

### Hostile caller contract
- **D-03:** Prove parity under zero-capacity, one-byte, and ragged leases; count only acknowledged bytes and retain the one-pull lease boundary.
- **D-04:** Incompatible profiles, output/work/budget rejection, replay mutation, destination failure, and later pulls after failure retain existing atomic and sticky typed-terminal semantics.

### Scope and compatibility
- **D-05:** Keep the generic caller-buffered constructor frozen on RGB8/RGBA8 and do not add RGBA16 Adam7 selection, output staging, a new encoder machine, FFI, copied source trees, or release automation. Phase 71 owns Adam7; Phase 72 owns broad qualification.

### the agent's Discretion
- Use the closest `new_graya16` constructor family and existing stream-encode schedule harness; add only RGBA16-specific parity and lifecycle evidence.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### v0.22 contracts
- `.planning/REQUIREMENTS.md` — `RGBA16ENC-02` caller-buffered contract.
- `.planning/ROADMAP.md` — Phase 70 success criteria and scope guard.
- `.planning/phases/69-explicit-rgba16-png-encoding/69-CONTEXT.md` — eager profile decisions carried forward.
- `.planning/phases/69-explicit-rgba16-png-encoding/69-01-SUMMARY.md` — completed eager implementation and evidence.
- `.planning/phases/69-explicit-rgba16-png-encoding/69-VERIFICATION.md` — verified eager acceptance boundary.

### Existing chunk seam
- `modules/mb-image/png/png.mbt` — public `PngChunkEncoder` contract and profile enum.
- `modules/mb-image/png/stream_encode.mbt` — closest GrayAlpha16 factories plus shared `pull` lifecycle.
- `modules/mb-image/png/stream_encode_test.mbt` — caller-buffered schedule and terminal test harness.
- `modules/mb-image/png/stream_encode_wbtest.mbt` — internal resource, mutation, and sticky-terminal evidence.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `PngChunkEncoder::new_graya16*` already constructs a U16 high-precision profile through `PngEncodeMachine::new_with_profile`.
- `PngChunkEncoder::pull` already owns accepted-only acknowledgement, destination failure, revision validation, and sticky terminal state.

### Established Patterns
- Explicit high precision remains opt-in; generic eager and chunk routes remain unchanged.
- The chunk wrapper has no raster buffer: the immutable source and private canonical machine are the only retained encoding state.

### Integration Points
- Add public factory declarations in `stream_encode.mbt`; profile admission, wire mapping, accounting, and output emission continue through Phase 69's shared code.

</code_context>

<specifics>
## Specific Ideas

The caller-buffered output must be byte-identical to a fresh eager Type-6/16 encoding, including the exact U16 component-byte wire order.

</specifics>

<deferred>
## Deferred Ideas

- RGBA16 Adam7 selector and multipass evidence — Phase 71.
- Independent hostile matrix and portable qualification — Phase 72.
- Staging buffers, FFI, release automation, and copied-source workflows — out of scope.

</deferred>

---

*Phase: 70-Resumable RGBA16 PNG Encoding*
*Context gathered: 2026-07-23*
