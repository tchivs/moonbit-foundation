# Phase 60: Bounded Adam7 Streaming Semantics - Context

**Gathered:** 2026-07-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Prove every legal GrayAlpha8 Adam7 strategy pair keeps the existing single
bounded PNG pipeline, including pass-local filtering, atomic admission, and
acknowledgement-safe replay. A source mutation before replay must fail without
writing any byte into the next caller lease.

</domain>

<decisions>
## Implementation Decisions

- **D-01:** Replace the U16-only pre-lease revision check with a profile-neutral
  guard at the shared chunk pull seam. It must run before a lease can receive a
  replay byte, while preserving established terminal diagnostics for existing
  profiles.
- **D-02:** Cover a legal GrayAlpha8 Adam7 image in each None/Adaptive ×
  Stored/FixedOrStored/DynamicOrFixedOrStored combination. Mutate only after
  framing/progress has begun, then require zero bytes in the next lease,
  accepted-only totals, untouched lease tail, and the identical sticky error on
  later pulls.
- **D-03:** Retain the existing pass-local Adam7 traversal, filter contexts,
  preflight ledger, and replay plans. No GrayAlpha8-specific encoder branch,
  image/pass staging, or alternative replay mechanism is allowed.
- **D-04:** Keep incompatible descriptor, capability, geometry, output, work,
  and budget admission atomic before eager output or caller lease exposure;
  preserve legacy non-interlaced behavior.

### the agent's Discretion

- Reuse the smallest existing U16 replay-guard and Adam7 mutation helpers;
  production should change only the common revision-validation seam and tests
  should remain phase-local. Public all-target schedule and wire/decode proof
  stays in Phase 61.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone contract
- `.planning/ROADMAP.md` — Phase 60 goal, four success criteria, and scope boundary.
- `.planning/REQUIREMENTS.md` — GRAYA8A7-02 acceptance requirement and exclusions.
- `.planning/phases/59-grayalpha8-adam7-factory-and-pass-profile/59-CONTEXT.md` — locked factory/profile decisions inherited from Phase 59.
- `.planning/phases/59-grayalpha8-adam7-factory-and-pass-profile/59-VERIFICATION.md` — verified handoff and deferred replay coverage.

### Implementation and evidence
- `modules/mb-image/png/stream_encode.mbt` — shared chunk pull seam, replay plans, stored source revision, and existing U16 guard.
- `modules/mb-image/png/encode.mbt` — profile, checked pass traversal, filtering, preflight, and compression-plan construction.
- `modules/mb-image/png/stream_encode_test.mbt` — caller lease ownership, sticky-terminal, Adam7, and U16 revision-guard patterns.
- `modules/mb-image/png/encode_test.mbt` — eager shared-pipeline and atomic-admission evidence.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `PngEncodeMachine.source_revision`: captures the admitted image revision for O(1) replay validation.
- `PngChunkEncoder::pull`: is the sole caller-lease emission seam and already transitions failures into a sticky state.
- U16 mutation/replay helpers: establish mutation timing, zero-write, accepted-only, lease-tail, and sticky-error assertions.

### Established Patterns
- Adam7 profiles use one profile-aware machine with seven pass-local cursors and filter state.
- Eager and caller-buffered constructors share preflight, geometry, filtering, compression planning, and output facts.
- Constructor failures are atomic; no caller lease is exposed before successful admission.

### Integration Points
- Generalize only the revision-validation call immediately before active-machine lease emission.
- Extend GrayAlpha8 Adam7 replay tests beside the existing caller-buffered PNG evidence.

</code_context>

<specifics>
## Specific Ideas

The user authorized autonomous GSD progression and asked that implementation and
tests take priority over release automation or copied-source workflows.

</specifics>

<deferred>
## Deferred Ideas

- Public literal wire/decode, fresh zero/one/ragged schedules, frozen legacy
  matrix, and four-target package evidence belong to Phase 61.
- Decoder widening, Big-endian changes, staging, alternate encoders, release
  automation, registry publication, target wrappers, and source-tree copies
  remain outside this milestone.

</deferred>

---

*Phase: 60-bounded-adam7-streaming-semantics*
*Context gathered: 2026-07-23*
