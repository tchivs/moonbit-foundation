# Phase 78: Resumable Indexed PNG & Qualification - Context

**Gathered:** 2026-07-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Expose the already bounded eager Indexed8 PNG frame through the existing caller-buffered `PngChunkEncoder`, then prove byte parity, leases, terminals, independent wire/decode behavior, compatibility, and portability. This phase finishes v0.24; it does not add a second encoder or a new indexed representation.

</domain>

<decisions>
## Implementation Decisions

### Caller-buffered API and machine reuse
- **D-01:** Add one explicit `PngChunkEncoder` Indexed8 constructor which accepts `PngIndexedImage`, limits, budget, and diagnostics and delegates to the same indexed preflight/frame facts/acknowledged `PngEncodeMachine` used by eager encoding. No generic model widening or parallel traversal. — **Reversibility:** costly — later consumers will use this public constructor and its lifecycle contract.
- **D-02:** Limit the streaming profile to Type-3/8, non-interlaced, Stored DEFLATE, filter None, RGB palette plus Phase 77 canonical optional tRNS. Do not add strategy families, low bit depths, Adam7, quantization, staging, chunks, or FFI.

### Lifecycle and atomicity
- **D-03:** Require chunk output to be byte-identical to eager output under zero-capacity, one-byte, and ragged caller leases; progress and CRC state advance only for bytes the caller accepts. — **Reversibility:** costly — this is the established public streaming ownership rule.
- **D-04:** Preserve atomic preflight before output/lease exposure and retain the established sticky success/error terminals, including repeated pull/finish behavior and rejected or unaccepted leases.

### Qualification evidence
- **D-05:** Use test-local independent PNG wire and CRC parsing, public generic RGB8/RGBA8 decode, hostile lease schedules, frozen opaque compatibility, and the ordinary all-target PNG package test. No copied source trees, release automation, or test wrappers.

### the agent's Discretion
- The exact public constructor spelling should follow the closest existing PNG profile constructor and established error vocabulary.
- The planner may split implementation and qualification into multiple plans only when that makes test ownership clearer; no scope expansion is allowed.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone contracts
- `.planning/PROJECT.md` — v0.24 goal and the project-wide portable, bounded, pure-MoonBit constraints.
- `.planning/REQUIREMENTS.md` — INDEX-04 and INDEX-05 acceptance requirements and exclusions.
- `.planning/ROADMAP.md` — Phase 78 goal and v0.24 completion boundary.

### Indexed PNG decisions
- `.planning/phases/76-indexed8-source-eager-plte/76-CONTEXT.md` — owning Indexed8 source and eager PLTE constraints.
- `.planning/phases/76-indexed8-source-eager-plte/76-01-SUMMARY.md` — implemented source/preflight/frame facts seam.
- `.planning/phases/77-indexed-png-transparency/77-CONTEXT.md` — canonical tRNS and opaque-byte freeze decisions.
- `.planning/phases/77-indexed-png-transparency/77-01-SUMMARY.md` — Phase 77 implementation details and test anchors.
- `.planning/phases/77-indexed-png-transparency/77-VERIFICATION.md` — completed Phase 77 runtime evidence.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `modules/mb-image/png/stream_encode.mbt`: `PngChunkEncoder` already owns caller-buffered lease and terminal behavior and stores the shared `PngEncodeMachine`.
- `modules/mb-image/png/encode.mbt`: Indexed preflight constructs the checked variable `PngFrameFacts` that eager encoding already consumes.
- `modules/mb-image/png/png.mbt`: `PngIndexedImage` is the existing immutable index/RGB/alpha source contract.
- `modules/mb-image/png/stream_encode_test.mbt`: established zero/one/ragged lease and sticky-terminal test helpers for profile factories.
- `modules/mb-image/png/encode_test.mbt` and `encode_wbtest.mbt`: independent Indexed8 wire, CRC, public decode, frozen-vector, and acknowledgement test patterns.

### Established Patterns
- Public chunk encoders preflight completely before the first lease is exposed, then use a single acknowledgement-safe machine.
- Existing profile-specific constructors are additive and preserve generic image model APIs and legacy bytes.
- Four-target qualification uses the ordinary `moon -C modules/mb-image test png --target all --frozen` command, not copied source trees.

### Integration Points
- The new Indexed8 chunk factory must enter the same `PngChunkEncoder` state and pull/finish lifecycle used by RGB, Gray, GrayAlpha, and RGBA16 factories.

</code_context>

<specifics>
## Specific Ideas

The user explicitly authorized autonomous decisions and asked to prioritize implementation and tests over release scripts. Auto-selected decisions above therefore choose the smallest compatible caller-buffered extension and the strongest existing portability evidence.

</specifics>

<deferred>
## Deferred Ideas

None — Indexed1/2/4, indexed Adam7, quantization, strategy expansion, generic model changes, FFI, release automation, target wrappers, and source-tree copying remain out of scope.

</deferred>

---

*Phase: 78-resumable-indexed-png-qualification*
*Context gathered: 2026-07-24*
