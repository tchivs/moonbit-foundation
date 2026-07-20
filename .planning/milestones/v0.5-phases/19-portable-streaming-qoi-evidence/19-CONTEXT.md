# Phase 19: Portable Streaming QOI Evidence - Context

**Gathered:** 2026-07-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Prove the completed public streaming QOI contracts through adversarial
decode/encode schedules on every supported target and one runnable portable
decode → image operation → encode example. This phase does not add another
workspace module or another codec capability.

</domain>

<decisions>
## Implementation Decisions

### Public evidence
- **D-01:** Upgrade the existing `examples/qoi-portable` public consumer to
  use `QoiStreamDecoder` and `QoiStreamEncoder`; do not add a seventh workspace
  member or a second near-duplicate example.
- **D-02:** Use a fixed, visible input-chunk schedule and fixed output-capacity
  schedule that split header, token, and end-marker boundaries. Keep the
  existing real horizontal-flip operation and deterministic output evidence.
- **D-03:** Preserve the public import allowlist, portable targets, no-FFI
  boundary, and one deterministic status line; update its exact evidence only
  where the streaming proof needs observable counters/schedule identity.

### Conformance evidence
- **D-04:** Drive every generated QOI decode/encode vector through hostile input
  split schedules and output capacities, including zero/one-byte cases and each
  token/end-marker boundary.
- **D-05:** Assert exact pixels, canonical bytes, per-call progress, cumulative
  counters, finish failures, and sticky post-terminal behavior on all four
  targets; do not reduce this to a native-only test.
- **D-06:** Keep policy/quality scripts QOI-scoped. Do not invoke qualification,
  registry, release, publication, credential, PNG/DEFLATE, or FFI paths.

### the agent's Discretion
- Choose concrete compact schedules and status-line fields that make streaming
 behavior apparent while preserving deterministic public evidence.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md` §Phase 19 — QSTR-06/QSTR-07 success criteria.
- `.planning/REQUIREMENTS.md` §Portable Evidence — QSTR-06 and QSTR-07.
- `.planning/PROJECT.md` §Current Milestone: v0.5 QOI Streaming I/O — scope exclusions.
- `modules/mb-image/qoi/stream_decode.mbt` and `stream_encode.mbt` — public streaming contracts.
- `modules/mb-image/qoi/stream_decode_test.mbt`, `stream_decode_wbtest.mbt`, `stream_encode_test.mbt`, and `stream_encode_wbtest.mbt` — existing contract and vector test patterns.
- `examples/qoi-portable/main/main.mbt` and `main/moon.pkg` — current public eager consumer to upgrade in place.
- `scripts/quality/Test-PublicExamples.ps1` and `scripts/quality/Invoke-MoonQuality.ps1` — QOI-only four-target public evidence lane.
- `policy/foundation.json` and `scripts/quality/Assert-Policy.ps1` — exact QOI public source/interface policy.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Generated QOI vectors and Phase 17/18 stream state tests already supply token,
  marker, capacity, progress, and error fixtures.
- The existing public QOI example already decodes real bytes, flips horizontally,
  verifies canonical output and SHA-256 on four targets.
- The QOI quality lane already selects the example in workspace mode and traps
  forbidden release-governance routes.

### Established Patterns
- All public QOI evidence is deterministic and pure MoonBit on js, wasm,
  wasm-gc, and native.
- Existing quality checks require exact public imports and exact status evidence.

### Integration Points
- Update the existing qoi-portable source and its public-example test contract.
- Extend stream vector tests, then update the QOI quality lane's expected public
  output without widening its route.

</code_context>

<specifics>
## Specific Ideas

The public example remains intentionally small: fixed in-memory input chunks,
one existing image operation, fixed output buffers, exact canonical output, and
a single deterministic line users can run unchanged across all portable targets.

</specifics>

<deferred>
## Deferred Ideas

- A second streaming example/workspace member, dynamic host I/O adapters, and benchmarks are outside this phase.
- PNG/DEFLATE, FFI, registry/publication/release automation, and source snapshot/locking work remain out of scope.

</deferred>

---

*Phase: 19-Portable Streaming QOI Evidence*
*Context gathered: 2026-07-20*
