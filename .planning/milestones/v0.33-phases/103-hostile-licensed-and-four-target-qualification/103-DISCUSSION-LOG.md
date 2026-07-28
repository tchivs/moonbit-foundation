# Phase 103: Hostile, Licensed, and Four-Target Qualification - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-28
**Phase:** 103-hostile-licensed-and-four-target-qualification
**Areas discussed:** phase boundary, licensed fixture strategy, oracle/provenance, hostile corpus, four-target evidence, policy/CI/documentation, plan sequencing

---

## Phase Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Qualification-only | Add fixtures, tests, evidence, policy, CI, and docs; change runtime only for an exposed defect | ✓ |
| Rework parser coverage | Reimplement or broadly refactor already verified Phase 101/102 paths | |
| Expand formats | Add WOFF/CFF/variable execution during qualification | |

**User's choice:** Auto-selected the strongest scope-preserving option.
**Notes:** The user authorized optimal automatic choices. TTC-04/TTC-05 require canonical qualification, not a new runtime contract.

---

## Licensed Collection Specimen

| Option | Description | Selected |
|--------|-------------|----------|
| New upstream TTC | Intake another licensed collection and its new legal/source risks | |
| DejaVu two-face derivative | Deterministically derive TTC v1 from the committed DejaVu Sans 2.37 source with exact sharing | ✓ |
| Standalone-only claim | Reuse the TTF without a real collection artifact | |

**User's choice:** Auto-selected the existing licensed-source derivative.
**Notes:** The repository already has confirmed redistribution, modification terms, fixed digests, notice, and an independent oracle.

---

## Provenance and Oracle

| Option | Description | Selected |
|--------|-------------|----------|
| Self-certified fixture | Let production MoonBit output certify the TTC it consumes | |
| Independent closed oracle | PowerShell verifies TTC structure/sharing/checksums and reuses the independent SFNT facts | ✓ |
| External font engine | Add a third-party runtime/tool dependency | |

**User's choice:** Auto-selected the independent closed oracle.
**Notes:** The derivative remains externally derived DejaVu content under the upstream license; it is not relabeled project-generated.

---

## Hostile and Mutation Corpus

| Option | Description | Selected |
|--------|-------------|----------|
| Existing test names only | Treat scattered inline cases as release evidence | |
| Extend standalone corpus | Mix collection outcomes into the frozen Phase 100 file | |
| Separate closed collection matrix | Version exact errors, publication facts, and complete budget equality in a dedicated corpus | ✓ |

**User's choice:** Auto-selected the dedicated collection matrix.
**Notes:** Public evidence covers pre/post mutation; deterministic private hooks cover mid-open/mid-selection windows without threads.

---

## Four-Target Evidence

| Option | Description | Selected |
|--------|-------------|----------|
| Console comparison | Compare formatting-sensitive command output | |
| Silent v1 schema expansion | Add collection keys without changing workflow identity | |
| Closed v2 record | Fresh managed directory and schema with exact four-target semantic payload comparison | ✓ |

**User's choice:** Auto-selected the versioned v2 record.
**Notes:** Only `target` and `runner` may be normalized; the existing FontQualification runner/job and hardened ownership boundary are reused.

---

## Policy, Documentation, and Sequencing

| Option | Description | Selected |
|--------|-------------|----------|
| New qualification lane/release policy | Duplicate CI/evidence logic and widen into publication | |
| Tests only | Leave fixtures, policy, README, and changelog contradictory or untracked | |
| Extend existing lane in three dependent slices | Fixture/oracle → hostile/workflow tests → v2 evidence/policy/docs | ✓ |

**User's choice:** Auto-selected the strict dependent three-plan shape.
**Notes:** Preserve the 85-line API, existing runtime dependency, and 20-minute timeout unless measured evidence requires a minimal adjustment.

---

## the agent's Discretion

- Closed schema field names and ordering.
- Generated helper layout that avoids duplicating large licensed bytes.
- Hostile case grouping/order while retaining complete TTC-04 coverage.
- A measured minimal CI timeout adjustment only if the complete final lane exceeds the current cap.

## Deferred Ideas

- WOFF1/WOFF2, CFF/CFF2, variable-font execution, shaping, hinting, and rasterization.
- Registry publication/release-policy changes.
- Intake of a distinct upstream TTC in a future interoperability milestone.
