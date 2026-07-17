# Phase 6: Namespace Authority and Compatibility Contract - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md; this log preserves the alternatives considered.

**Date:** 2026-07-17
**Phase:** 6-namespace-authority-and-compatibility-contract
**Mode:** `--auto`, using the user's standing instruction to select the optimal option
**Areas discussed:** Registry authority evidence, safe capability probing, public-interface baselines, candidate policy and publication documentation, personal registry namespace, pre-publication identity migration, future organization migration, repository metadata boundary

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
- Optional future migration from `tchivs/*` to an organization-owned namespace after that namespace is real and independently verified.

---

## Personal Registry Namespace (2026-07-17 update)

| Option | Description | Selected |
|--------|-------------|----------|
| Use `tchivs/*` now | Publish under the verified personal GitHub identity and retain the foundation brand | ✓ |
| Wait for `moonbit-foundation/*` | Keep all publication blocked until a separate organization identity exists | |

**User's choice:** Use the personal namespace.
**Notes:** Local read-only GitHub identity is `tchivs`; public Mooncakes lookup is still absent, so registration and sanitized authority proof remain required.

## Pre-publication Identity Migration

| Option | Description | Selected |
|--------|-------------|----------|
| Bootstrap correction | Rewrite active canonical identities and regenerate 0.1.0 baselines because nothing is published | ✓ |
| SemVer breaking release | Increment the candidate as though an external consumer already depended on the old identity | |

**User's choice:** The agent selected the bootstrap correction as the optimal implementation.
**Notes:** Archived v0.1 artifacts stay historical; active sources and evidence move together.

## Future Organization Migration

| Option | Description | Selected |
|--------|-------------|----------|
| New identities plus migration | Publish under a verified future namespace with explicit forward migration | ✓ |
| In-place rename | Assume registry ownership transfer or rename support | |

**User's choice:** The agent selected forward-only migration.
**Notes:** No rename, overwrite, delete, unpublish, or yank capability is assumed.

## Repository Metadata Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Intended URL plus fail-closed proof | Use the personal repository route only as intent until external creation and read-only verification | ✓ |
| Claim it exists now | Treat the currently missing repository as a live support/provenance route | |

**User's choice:** The agent selected intended metadata with later verification.
**Notes:** Creating or pushing a GitHub repository is an external mutation and is not performed by this context update.
