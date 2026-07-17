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

## Cross-Milestone Trends

### Process Evolution

| Milestone | Phases | Plans | Key Change |
|---|---:|---:|---|
| v0.1 | 5 | 41 | Established RFC-led horizontal delivery, independent verification, and closed release evidence. |

### Cumulative Quality

| Milestone | Required tests | Requirements | Integration |
|---|---:|---:|---:|
| v0.1 | 197/197 per required target at the locked baseline | 36/36 | 15/15 contract families, 6/6 flows |

### Top Lessons

1. Preserve exact policy ownership and fail-closed negatives as the ecosystem grows.
2. Re-check these lessons after the next milestone before treating them as cross-milestone invariants.
