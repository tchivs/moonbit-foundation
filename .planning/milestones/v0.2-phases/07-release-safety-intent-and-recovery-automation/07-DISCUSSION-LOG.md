# Phase 7: Release Safety, Intent, and Recovery Automation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-18
**Phase:** 7-release-safety-intent-and-recovery-automation
**Areas discussed:** immutable release intent, sole-maintainer authorization, secret isolation, serialization and journal, failure recovery

---

## Immutable Release Intent

| Option | Description | Selected |
|--------|-------------|----------|
| Canonical closed-schema intent | Bind trusted ref, exact SHA, modules, dependencies, inventories, archives, baselines, and evidence under one reproducible SHA-256 digest | ✓ |
| Workflow inputs only | Treat dispatch text fields as the release authority | |
| Mutable branch snapshot | Authorize whatever source is current when the publisher starts | |

**User's choice:** [auto] Canonical closed-schema intent (recommended default)
**Notes:** The existing `v0.1` tag is retained; the module publication uses a distinct immutable release tag/ref.

---

## Sole-Maintainer Authorization

| Option | Description | Selected |
|--------|-------------|----------|
| Exact manual dispatch by `tchivs` | Validate actor, repository, trusted ref, source SHA, and intent digest without adding a second approver | ✓ |
| Automatic publish on merge | Publish every qualifying main-branch change | |
| Multi-person approval | Require organization/quorum infrastructure that the sole maintainer does not have | |

**User's choice:** [auto] Exact manual dispatch by `tchivs` (recommended default)
**Notes:** This respects the user's explicit sole-developer model and skips team ceremony.

---

## Secret Isolation and Authenticated Seam

| Option | Description | Selected |
|--------|-------------|----------|
| Step-scoped credential in isolated publisher | Keep Required credential-free; validate `whoami`, version absence, archives, and dry-run before exposing the secret only to the mutation step | ✓ |
| Job-wide credential | Make the secret available across publisher preparation and third-party actions | |
| Local login as authority proof | Treat `moon whoami` alone as proof of remote publication permission | |

**User's choice:** [auto] Step-scoped credential in isolated publisher (recommended default)
**Notes:** Login success is accepted as proven. It is not misrepresented as remote current-token publication authority; only real successful publication plus read-only observation can establish that fact.

---

## Serialization and Journal

| Option | Description | Selected |
|--------|-------------|----------|
| Release-wide lock plus hash-chained monotonic journal | `cancel-in-progress: false`, exact module order, durable sanitized checkpoints, and registry re-observation on resume | ✓ |
| Per-module independent jobs | Allow modules to race or publish out of dependency order | |
| Restart from the beginning | Republish previously completed modules after timeout or runner failure | |

**User's choice:** [auto] Release-wide lock plus hash-chained monotonic journal (recommended default)
**Notes:** Duplicate dispatches become read-only re-observation and safe resume, never blind republish.

---

## Failure and Recovery

| Option | Description | Selected |
|--------|-------------|----------|
| Observe before retry; recover forward only | Stop on ambiguity, compare registry state to intent, preserve exact matches, and create a new corrected version/advisory for mismatches | ✓ |
| Blind automatic retry | Repeat publish after any timeout or error | |
| Destructive rollback | Assume overwrite, delete, unpublish, or yank is available | |

**User's choice:** [auto] Observe before retry; recover forward only (recommended default)
**Notes:** Invalid credentials and stale evidence fail before mutation whenever observable. A published mismatch becomes incident evidence, not an overwrite attempt.

## the agent's Discretion

- Exact schema filenames, helper boundaries, diagnostic codes, tag spelling, environment name, and artifact retention within the locked contracts.

## Deferred Ideas

- Phase 8 owns live registry distribution and independent consumer proofs.
- Phase 9 owns immutable provenance/ledger closure and milestone audit.
- OIDC, organization namespace migration, destructive recovery, team approvals, and new module families remain deferred.

## Auto-mode Audit

- `[--auto] Selected all gray areas: immutable release intent, sole-maintainer authorization, secret isolation, serialization and journal, failure recovery.`
- `[auto] Immutable Release Intent — Q: "What exactly is authorized?" → Selected: "Canonical closed-schema intent" (recommended default)`
- `[auto] Sole-Maintainer Authorization — Q: "Who may authorize one exact intent?" → Selected: "Exact manual dispatch by tchivs" (recommended default)`
- `[auto] Secret Isolation — Q: "Where can the Mooncakes credential exist?" → Selected: "Step-scoped credential in isolated publisher" (recommended default)`
- `[auto] Serialization — Q: "How are concurrent and resumed releases controlled?" → Selected: "Release-wide lock plus hash-chained monotonic journal" (recommended default)`
- `[auto] Recovery — Q: "What happens after an ambiguous or mismatched publish?" → Selected: "Observe before retry; recover forward only" (recommended default)`
