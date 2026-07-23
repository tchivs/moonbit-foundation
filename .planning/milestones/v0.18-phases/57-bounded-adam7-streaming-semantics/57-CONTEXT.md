# Phase 57: Bounded Adam7 Streaming Semantics - Context

**Gathered:** 2026-07-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Extend the completed legal GrayAlpha16 Adam7 public factories through the existing bounded filter, compression, atomic admission, and caller-buffered replay semantics. Public all-target compatibility vectors and hostile schedule evidence remain Phase 58.

</domain>

<decisions>
## Implementation Decisions

### Shared bounded route

- **D-01:** Keep every legal GrayAlpha16 Adam7 None/Adaptive × Stored/FixedOrStored/DynamicOrFixedOrStored selection on the existing single profile-aware machine, using Adam7 pass-local predictor history. — **Reversibility:** costly — splitting this route would duplicate resource, replay, and compatibility semantics.
- **D-02:** Retain preflight atomicity: incompatible capability, geometry, output, work, or budget failure must occur before writer output or a caller-buffered lease is exposed.

### Replay and compatibility boundary

- **D-03:** Replay validates the source before any caller lease write after a checked U16 source mutation, reports accepted-only progress, and retains sticky terminals for all supported Adam7 strategy choices.
- **D-04:** Keep strict legal little-endian admission, Big-endian descriptor rejection, explicit opt-in Adam7 selection, and frozen non-interlaced routes unchanged.

### the agent's Discretion

- Reuse the smallest existing Adam7 and GrayAlpha16 strategy/replay regression helpers; production changes are allowed only where the shared path demonstrably lacks the profile/pass behavior.
- Keep this phase inside the PNG package, without staging, alternative machines, target branches, FFI, release work, or source copies.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md` — Phase 57 goals and success criteria.
- `.planning/REQUIREMENTS.md` — GRAYA16A7-02 and exclusions.
- `.planning/phases/56-grayalpha16-adam7-factory-and-pass-profile/56-VERIFICATION.md` — verified public factory/profile handoff.
- `.planning/milestones/v0.13-phases/42-bounded-adam7-encoder-path/42-CONTEXT.md` — Adam7 bounded/replay analogue.
- `.planning/milestones/v0.17-phases/54-bounded-type-4-16-encoder/54-02-SUMMARY.md` — GrayAlpha16 atomic/replay analogue.
- `modules/mb-image/png/encode.mbt` — shared bounded profile, filtering, compression, and replay machine.
- `modules/mb-image/png/stream_encode.mbt` — chunk construction and caller-owned lease behavior.
- `modules/mb-image/png/encode_test.mbt` and `modules/mb-image/png/stream_encode_test.mbt` — strategy, admission, and mutation regression patterns.

</canonical_refs>

<code_context>
## Existing Code Insights

- Phase 56 already composes GrayAlpha16 with the Adam7 cursor and `_png_wire_byte` through the existing machine.
- Existing Adam7 tests cover RGB/RGBA pass-local filtering and replay; v0.17 tests cover U16 GrayAlpha atomicity and mutation boundaries.
- The only permitted implementation path is their composition, not a format-specific planner or output buffer.

</code_context>

<deferred>
## Deferred Ideas

- Public literal multi-pass vectors, zero/one/ragged schedule matrix, frozen baselines, and independent full all-target evidence — Phase 58.
- Big-endian GrayAlpha16 admission, colour conversion, decoder widening, palette/low-bit formats, release automation, and copied-source workflows.

</deferred>

---

*Phase: 57-bounded-adam7-streaming-semantics*
*Context gathered: 2026-07-23*
