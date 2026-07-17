# Phase 6: Namespace Authority and Compatibility Contract - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md; this log preserves the alternatives considered.

**Date:** 2026-07-17
**Phase:** 6-namespace-authority-and-compatibility-contract
**Mode:** `--auto`, using the user's standing instruction to select the optimal option
**Areas discussed:** Registry authority evidence, safe capability probing, public-interface baselines, candidate policy and publication documentation

---

## Registry Authority Evidence

| Option | Description | Selected |
|--------|-------------|----------|
| Machine-readable contract plus evidence | Closed, credential-redacted facts with linked observations and digests | ✓ |
| Prose-only runbook | Easy to read but weak against drift and automation ambiguity | |
| CI-log-only evidence | Ephemeral and difficult to audit after retention expires | |

**Choice:** Machine-readable contract plus evidence.
**Notes:** Existing policy/schema patterns make this the smallest consistent option. Current module identities remain provisional until authenticated evidence confirms them.

---

## Safe Capability Probing

| Option | Description | Selected |
|--------|-------------|----------|
| Safe tiered capability matrix | Mark facts documented, safely observed, or unknown and assign a disposition | ✓ |
| Probe all behaviors live | Risks polluting immutable public versions merely to learn destructive semantics | |
| Assume common registry semantics | Would make recovery unsafe and evidence misleading | |

**Choice:** Safe tiered capability matrix.
**Notes:** Phase 6 performs no production module publication. Unknown destructive behavior selects forward-only recovery.

---

## Public-Interface Baselines

| Option | Description | Selected |
|--------|-------------|----------|
| Raw plus normalized baselines | Retain diagnostic source evidence and compare a deterministic canonical form | ✓ |
| Normalized text only | Smaller, but loses evidence needed to diagnose toolchain/parser changes | |
| Tests only | Behavioral tests cannot enumerate or classify all public declaration deltas | |

**Choice:** Raw plus normalized per-module/package/target baselines.
**Notes:** Classification is four-state and explicitly not a full semantic compatibility proof.

---

## Candidate Policy and Publication Documentation

| Option | Description | Selected |
|--------|-------------|----------|
| Central checked policy plus module docs | One version rule owner with registry-renderable consumer documentation | ✓ |
| Module-local prose only | Duplicates policy and permits inconsistent interpretation | |
| Release checklist only | Cannot deterministically classify future candidate changes | |

**Choice:** Central machine-checked policy plus module-owned changelog and public documentation.
**Notes:** RFC evidence is conditional on existing governance rules, not required for every pre-1.0 API change.

## the agent's Discretion

- Exact schema filenames, normalization implementation, and diagnostic phrasing within the locked evidence boundaries.

## Deferred Ideas

- OIDC federation, destructive registry recovery, new module families, and stable 1.0 guarantees.
