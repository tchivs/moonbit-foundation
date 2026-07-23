# Phase 58: Portable Adam7 Public Evidence - Context

**Gathered:** 2026-07-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Prove through public PNG APIs that legal packed little-endian GrayAlpha16 Adam7 output is literally pass-faithful on the wire, decodes through the documented straight-RGBA8 high-byte boundary, remains caller-buffered safe under hostile schedules, preserves frozen legacy output, and works on every supported target.

</domain>

<decisions>
## Implementation Decisions

### Public multipass fidelity

- **D-01:** Use a deliberately non-symmetric multi-pass GrayAlpha16 vector and public eager factories to inspect literal Type-4/16 Adam7 `Ghi,Glo,Ahi,Alo` output, then decode it only through the documented straight-RGBA8 high-byte canonicalization. — **Reversibility:** costly — changing this boundary would alter public decoding expectations and fixture provenance.
- **D-02:** Keep the evidence independent of private cursor/profile helpers: public APIs and deterministic PNG wire parsing are the proof boundary.

### Caller-buffer schedules

- **D-03:** For every legal None/Adaptive × Stored/FixedOrStored/DynamicOrFixedOrStored pair, drain a fresh encoder under zero-capacity, one-byte, and ragged leases; require eager-byte identity, accepted-only totals, untouched tails, and sticky terminal outcomes.

### Compatibility and portability

- **D-04:** Freeze existing non-interlaced and legacy Gray8, Gray16, GrayAlpha8, RGB8, and straight-RGBA8 byte baselines; do not widen descriptor admission, add a staging encoder, or change published non-interlaced output.
- **D-05:** Final evidence runs only public PNG tests on js, wasm, wasm-gc, and native; target-specific expectations are out of scope.

### the agent's Discretion

- Reuse the smallest existing public wire parser, decoder assertions, schedule drainer, and frozen-baseline fixtures from Phase 55 and earlier Adam7 evidence.
- Add production code only if a public proof reveals a real contract defect; do not add release automation, FFI, source-tree copies, Big-endian GrayAlpha16 support, colour conversion, or decoder-model widening.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and requirement

- `.planning/ROADMAP.md` — Phase 58 goal and success criteria.
- `.planning/REQUIREMENTS.md` — GRAYA16A7-03 and locked exclusions.
- `.planning/phases/57-bounded-adam7-streaming-semantics/57-VERIFICATION.md` — verified shared traversal, replay, and strategy handoff.

### Proven public-evidence analogues

- `.planning/milestones/v0.17-phases/55-portable-public-evidence/55-CONTEXT.md` — GrayAlpha16 public wire/decode/schedule evidence pattern.
- `.planning/milestones/v0.16-phases/52-portable-gray-alpha-public-evidence/52-CONTEXT.md` — public GrayAlpha schedule and frozen-vector evidence pattern.
- `.planning/milestones/v0.13-phases/42-bounded-adam7-pass-encoding/42-CONTEXT.md` — public Adam7 pass/wire and drain evidence pattern.

### Public PNG seams

- `modules/mb-image/png/encode.mbt` — eager public factories and decoder contract.
- `modules/mb-image/png/stream_encode.mbt` — public chunk encoder and caller lease semantics.
- `modules/mb-image/png/encode_test.mbt` — public eager literal wire and decode assertions.
- `modules/mb-image/png/stream_encode_test.mbt` — public hostile-schedule, tail, and sticky-terminal assertions.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `PngEncoder` / `PngChunkEncoder` explicit GrayAlpha16 Adam7 factories provide the only intended public selection seam.
- Existing public PNG wire parsers, `png_chunk_test_drain_encoder`, and decoder corpus helpers already express literal, schedule, tail, and terminal checks.

### Established Patterns

- Public evidence uses fresh encoders per schedule and compares full bytes to eager output.
- U16 PNG wire fidelity is distinct from public RGBA8 high-byte canonicalization.

### Integration Points

- Add Phase 58 proof in `encode_test.mbt` and `stream_encode_test.mbt`, then use the package's full public PNG target matrix as final evidence.

</code_context>

<specifics>
## Specific Ideas

No additional user-specific requirements; automatic selections follow the milestone's locked public-contract boundary.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within the Phase 58 scope.

</deferred>

---

*Phase: 58-portable-adam7-public-evidence*
*Context gathered: 2026-07-23*
