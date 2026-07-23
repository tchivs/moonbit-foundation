# Phase 61: Portable GrayAlpha8 Adam7 Public Evidence - Context

**Gathered:** 2026-07-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Publish independent public evidence that legal GrayAlpha8 Adam7 Type-4/8 output
is wire-faithful, caller-buffered-safe, compatible with frozen legacy routes,
and portable on wasm, wasm-gc, js, and native.

</domain>

<decisions>
## Implementation Decisions

- **D-01:** Use a non-symmetric all-seven-pass `G,A` image and independently
  enumerate/inflate the Adam7 raster before proving decode canonicalization as
  `(G,G,G,A)`; do not rely on encoder internals as the sole oracle.
- **D-02:** For a fresh public caller-buffered Adam7 encoder, prove zero, one,
  and ragged lease schedules preserve eager bytes, accepted-only counters,
  untouched lease tails, and sticky terminal behavior.
- **D-03:** Run the ordinary frozen full PNG package command on each supported
  production target. Retain current GrayAlpha8 non-interlaced and Gray8,
  Gray16, GrayAlpha16, RGB8, and straight-RGBA8 compatibility vectors.

### the agent's Discretion

- Reuse established public fixture/drain helpers and keep scope to evidence and
  regressions; no new production encoder/decoder capability is permitted.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md` — Phase 61 success criteria and scope boundary.
- `.planning/REQUIREMENTS.md` — GRAYA8A7-03 requirement and exclusions.
- `.planning/phases/59-grayalpha8-adam7-factory-and-pass-profile/59-CONTEXT.md` — factory, `G,A`, and legacy decisions.
- `.planning/phases/60-bounded-adam7-streaming-semantics/60-VERIFICATION.md` — shared replay and six-strategy handoff.
- `modules/mb-image/png/encode_test.mbt` — independent wire/inflate and PNG decode evidence.
- `modules/mb-image/png/stream_encode_test.mbt` — caller lease schedule, tail, progress, and sticky terminal patterns.
- `modules/mb-image/png/png.mbt`, `modules/mb-image/png/stream_encode.mbt` — public selectors to exercise only.

</canonical_refs>

<code_context>
## Existing Code Insights

- Phase 59 already supplies a non-symmetric GrayAlpha8 seven-pass eager wire
  tracer and normal chunk/eager parity.
- Phase 60 supplies measured all-seven-pass strategy corpora and shared
  pre-lease replay safety.
- Existing GrayAlpha16 public hostile-drain tests provide the closest reusable
  zero/one/ragged and frozen-vector pattern.

</code_context>

<specifics>
## Specific Ideas

The user authorized autonomous optimal decisions and prioritizes code and test
evidence over release automation or copied-source workflows.

</specifics>

<deferred>
## Deferred Ideas

No decoder widening, Big-endian model work, staging, alternate encoders, native
FFI, release automation, registry work, target wrappers, or source copies.

</deferred>
