# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v0.1 — Foundation

**Shipped:** 2026-07-17  
**Phases:** 5 | **Plans:** 41 | **Tasks:** 93

### What Was Built

- An accepted RFC-led governance and compatibility foundation with a reproducible three-module MoonBit workspace.
- Bounded `mb-core` safety, I/O, diagnostic, budget, storage, and explicit host-capability contracts.
- Typed `mb-color` semantics and a safe `mb-image` model with deterministic operations and codec-facing contracts.
- A strict bounded PPM P6 decoder/encoder, portable and Native CLI-shaped public examples, and generated conformance evidence.
- Reproducible benchmark and release qualification with deterministic packages, isolated consumers, fail-closed negatives, and canonical same-HEAD reports.

### What Worked

- Horizontal layering kept the dependency DAG explicit and let each phase consume already verified contracts.
- Independent phase verification found real lifecycle, provenance, generated-evidence, allocation-accounting, and planar-authority gaps before closeout.
- Closed machine-readable policy owners, exact interfaces, package inventories, and negative fixtures prevented documentation or topology drift.
- Generated fixtures and public-API consumers provided stronger evidence than example-only or snapshot-only checks.
- Freezing the final static ledger before two Required runs preserved a trustworthy unchanged-HEAD release proof.

### What Was Inefficient

- Early phase state and summary metadata occasionally lagged the actual phase position and required closeout normalization.
- Full Required grew to roughly three minutes, making repeated end-to-end runs expensive even though the selector structure remained valuable.
- The milestone helper emitted every plan one-liner into `MILESTONES.md`; a concise curated milestone summary is easier to review.
- Registry-independent downstream artifact proof cannot fully close until the namespace and dependency versions are actually published.

### Patterns Established

- Use exact named dependencies plus workspace substitution; prohibit path dependencies in candidate release topology.
- Keep portable algorithms MoonBit-owned and inject narrow host/Native adapters through explicit capabilities.
- Preflight checked arithmetic and budgets before allocation, mutation, or output; charge once through an authoritative owner.
- Treat generated evidence as canonical data with provenance, byte-stable check mode, and package-local behavioral consumers.
- Separate source isolation, exact artifact consumption, and real registry resolution; never convert an external blocker into a fabricated pass.

### Key Lessons

1. Phase-level green tests do not replace adversarial verification of ownership and cross-layer wiring; independent verifier passes should remain mandatory.
2. Release evidence must be frozen before execution and stored separately from tracked planning edits when same-HEAD reproducibility matters.
3. A small reference codec is enough to validate deep infrastructure contracts when its grammar, limits, progress, and EOF semantics are strict.
4. Single-maintainer governance can be authentic when authority, eligibility, expiry, and evidence are explicit and fail closed.

### Cost Observations

- Model mix: not captured by the local GSD runtime.
- Sessions: not reliably derivable from repository history.
- Notable: 292 commits and targeted parallel agents kept 41 plans atomic; the principal cost was repeated four-target Required qualification.

---

## Milestone: v0.8 — Resumable PNG Decode

**Shipped:** 2026-07-21  
**Phases:** 3 | **Plans:** 5

### What Was Built

- A private, pause-safe MoonBit PNG framing, DEFLATE, and raster state machine retained eager API compatibility.
- A public `PngChunkDecoder` with exact caller-buffered progress, explicit strict completion, and sticky typed terminal errors.
- A 3,850-record public hostile-schedule corpus and one portable decode → resize → eager-encode workflow, proven on all four targets.

### What Worked

- Final verification and the milestone audit found and closed real public EOF-classifier gaps before shipment.
- Isolated clean-worktree testing avoided stale native build artifacts and reconfirmed 84/84 PNG tests per target.

### What Was Inefficient

- Historical verification reports and stale roadmap metadata confused GSD's current-status parser during closeout.
- The milestone archive helper misclassified historical roadmap details under `--force`; the unrelated Phase 9 and 20-25 directories were immediately restored before any commit.

### Key Lessons

1. Keep only the final current verification report under the active verifier naming convention; retain prior gap reports as explicit history.
2. Scope archive tooling from canonical milestone phase numbers, not permissive roadmap prose parsing.
3. Public streaming contracts need both arbitrary-schedule corpus evidence and a small runnable consumer flow.

## Milestone: v0.12 — PNG Filter Optimization

**Shipped:** 2026-07-22  
**Phases:** 3 | **Plans:** 9

### What Was Built

- An additive, legacy-compatible Adaptive PNG filter API for eager and caller-buffered output.
- Deterministic bounded selection across the five standard method-0 PNG row filters.
- Bounded, acknowledgement-safe replay and complete preflight accounting for Stored, FixedOrStored, and DynamicOrFixedOrStored routes.
- Four-target generated-corpus proof of strict Adaptive wins, eager/chunk identity, and public decode fidelity.

### What Worked

- Independent verifier passes caught two real planner-accounting/replay gaps before the milestone was closed.
- Selector-isolated evidence with GUID-owned temporary target roots avoided repeated source-tree copies and left no test residues.
- Preserving frozen filter-None vectors kept the new API additive instead of silently changing existing users' bytes.

### What Was Inefficient

- Intermediate red/recovery artifacts and generated planning output accumulated faster than the active milestone needed.
- Automatic milestone accomplishment extraction included superseded failed-attempt notes; the closeout summary now curates final shipped behavior instead.

### Key Lessons

1. For streaming encoders, planner work must be accounted for on candidate-decline paths as well as selected paths.
2. A focused cross-target evidence runner is more useful than repeatedly running a broad suite that can stall without producing failure evidence.
3. Planning directories should be archived at milestone close, not left beside the next active phase.

---

## Milestone: v0.15 — Gray16 PNG Interchange

**Shipped:** 2026-07-22  
**Phases:** 3 | **Plans:** 3

### What Was Built

- Explicit U16 Gray16 PNG factories for eager and caller-buffered consumers.
- One shared bounded path for Gray16 filtering, DEFLATE strategy selection, atomic admission, and acknowledgement-safe replay.
- Public wire-byte, hostile-capacity, legacy-compatibility, and independent four-target evidence.

### What Worked

- Extending the existing profile-aware scalar producer avoided a second encoder implementation and image-sized staging.
- Public tests used non-symmetric U16 data and both storage byte orders, which made wire-order mistakes observable.

### What Was Inefficient

- Historical debug metadata blocked closeout despite v0.15 passing all verification; it required an explicit historical-deferred record.

### Patterns Established

- For widened sample formats, test exact encoded wire semantics separately from any intentionally lossy public decode canonicalization.

### Key Lessons

1. Add new PNG profiles through explicit factories and the shared admission/replay machinery, never a special staging route.
2. Archive completed phase artifacts immediately at milestone close so active planning stays small.

### Cost Observations

- Model mix and session count are not reliably captured by the local GSD runtime.
- Notable: all four supported targets completed the PNG suite at 190/190 tests.

---

## Milestone: v0.17 — GrayAlpha16 PNG Interchange

**Shipped:** 2026-07-23
**Phases:** 3 | **Plans:** 4 | **Tasks:** 8

### What Was Built

- Packed U16 Gray+Alpha descriptor admission with checked per-component storage and preserved fail-closed operations.
- Explicit bounded eager and caller-buffered non-interlaced Type-4/16 PNG factories with `Ghi,Glo,Ahi,Alo` wire output.
- Public U16 wire/RGBA8 canonicalization evidence, hostile lease schedules, frozen legacy bytes, and four-target qualification.

### What Worked

- Extending the existing profile-aware bounded machine avoided staging and kept eager/chunk behavior identical.
- Non-symmetric U16 fixtures and literal raster assertions made byte-order mistakes directly observable.
- Independent code review, security audit, phase verification, and milestone integration audit found no implementation gap.

### What Was Inefficient

- Historical `quick/` and `debug/` records were left outside milestone archives, obscuring the active planning view.

### Patterns Established

- For U16 alpha profiles, retain a strict source-storage admission contract and test it separately from PNG wire order and intentionally lossy decoder canonicalization.

### Key Lessons

1. Reuse the shared bounded pipeline for a new format profile; do not add a format-specific output buffer or replay path.
2. Archive all historical planning artifacts at milestone close, not only phase directories.

### Cost Observations

- All four supported targets completed the PNG package at 204/204 tests.

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Phases | Plans | Key Change |
|---|---:|---:|---|
| v0.1 | 5 | 41 | Established RFC-led horizontal delivery, independent verification, and closed release evidence. |
| v0.8 | 3 | 5 | Added byte-resumable public PNG decode with corpus-wide four-target streaming evidence. |
| v0.15 | 3 | 3 | Extended the bounded PNG profile path to U16 grayscale with wire-level portability evidence. |
| v0.17 | 3 | 4 | Extended the same bounded profile path to U16 Gray+Alpha with explicit type-4 wire and lease ownership evidence. |

### Cumulative Quality

| Milestone | Required tests | Requirements | Integration |
|---|---:|---:|---:|
| v0.1 | 197/197 per required target at the locked baseline | 36/36 | 15/15 contract families, 6/6 flows |
| v0.8 | 84/84 PNG tests per target | 4/4 | 6/6 phase handoffs, 2/2 public flows |
| v0.15 | 190/190 PNG tests per target | 3/3 | 3/3 phase verifications, 100/100 milestone audit |
| v0.17 | 204/204 PNG tests per target | 4/4 | 3/3 phase verifications, 5/5 handoffs, 3/3 flows |

### Top Lessons

1. Preserve exact policy ownership and fail-closed negatives as the ecosystem grows.
2. Re-check these lessons after the next milestone before treating them as cross-milestone invariants.
