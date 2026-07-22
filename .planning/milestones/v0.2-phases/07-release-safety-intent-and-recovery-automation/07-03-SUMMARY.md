---
phase: 07-release-safety-intent-and-recovery-automation
plan: "03"
subsystem: hosted-release-control
tags: [github-actions, powershell, prepared-bundle, required, hosted-settings]
requires:
  - plan: "01"
    provides: Canonical initial and correction release intents
  - plan: "02"
    provides: Monotonic publisher reducer and recovery rehearsals
provides:
  - SHA-pinned manual publisher workflow with immutable-root concurrency
  - Closed content-addressed prepared-bundle handoff
  - Reciprocal REL-01 through REL-05 Required evidence
  - Verified GitHub environment, secret name, and exact tag protection
affects: [phase-08-live-publication, phase-09-provenance]
key-files:
  created:
    - .github/workflows/publish-modules.yml
    - release/prepared/schema.json
    - release/qualification/phase-07-requirements.json
    - scripts/quality/Test-Phase07Qualification.ps1
  modified:
    - .planning/phases/07-release-safety-intent-and-recovery-automation/COVERAGE.md
    - scripts/quality/Invoke-MoonQuality.ps1
key-decisions:
  - "Concurrency uses repository plus immutable root_intent_sha256; current intent is validated separately."
  - "Publisher has actions-read only, no checkout, and consumes one exact current-run prepared artifact."
  - "MOONCAKES_TOKEN appears once at LiveOneStep; Required cannot reach hosted or live paths."
requirements-completed: [REL-01, REL-02, REL-03, REL-04, REL-05]
duration: 20min
completed: 2026-07-18
status: complete
---

# Phase 7 Plan 3: Hosted Release Control Summary

**Phase 7 now closes an exact, resumable, credential-minimal publisher control plane while leaving the first irreversible Mooncakes mutation blocked for Phase 8.**

## Accomplishments

- Added a manual-only, full-SHA-pinned workflow with exact start/resume inputs, immutable-root concurrency, non-cancelling serialization, and separate current-intent validation.
- Added a closed prepared-bundle schema binding source, intent, journal, toolchain, payload roles, sizes, and SHA-256 digests without self-hash cycles.
- Confined publisher permissions to actions read, removed checkout, and required exact current-run artifact validation before the single environment-secret step.
- Integrated reciprocal REL-01 through REL-05 intent, reducer, recovery, workflow, and ledger checks into the real credential-free Required lane.
- Verified the mooncakes-production environment, exact MOONCAKES_TOKEN secret name, and one active exact tag ruleset with deletion/non-fast-forward protection and no bypass actors.

## Task Commits

1. Task 1, isolated publisher workflow and prepared handoff: dbd2dfa
2. Task 2, reciprocal Phase 7 Required evidence: 73fd39c
3. Task 3, detailed hosted ruleset inspection: 0e717f0
4. Phase tracking closure: 5209c52

## Verification

- WorkflowOnly, LedgerOnly, Focused, and HostedSettings passed.
- Full Required passed with 197/197 MoonBit tests on required targets, deterministic archives, unchanged tracked state, and Phase 7 report validation.
- HostedSettings used names and structural rule fields only; no secret value was inspected.

## Decisions Made

- Initial and correction dispatches share the canonical initial-root lock; distinct correction digests cannot create separate concurrency domains.
- Exact current-run prepared artifacts flow only through preparation outputs, and publisher validation precedes any environment-secret reference.
- Hosted readiness does not authorize publication. No tag was created and no live workflow or Mooncakes mutation was dispatched.

## Deviations from Plan

### Auto-fixed Issues

1. **Rule 3, blocking:** Task 1 required WorkflowOnly before the Task 2 validator existed. A minimal selector was added in dbd2dfa and expanded in Task 2.
2. **Rule 1, bug:** The ruleset list endpoint omitted detailed conditions. HostedSettings now fetches each candidate detail before exact structural validation; fixed in 0e717f0.

No scope expansion or live mutation occurred.

## User Setup Required

Completed at the Task 3 checkpoint:

- GitHub environment mooncakes-production exists.
- Exact environment secret name MOONCAKES_TOKEN exists.
- Active exact tag ruleset exists with required protections and no bypass actors.

## Next Phase Readiness

- Phase 8 may plan the explicit first irreversible core publication, authoritative read-only observation, and cold registry-only consumer before color and image advance.
- The release tag, workflow dispatch, and Mooncakes mutation remain intentionally unperformed.

## Self-Check: PASSED

- All plan-owned workflow, schema, ledger, validator, and Required integration files exist.
- Local selectors, full Required, report verification, and hosted settings verification pass.
- No secret value was inspected; no tag, workflow dispatch, or live Mooncakes mutation occurred.
- Unrelated config, governance, codebase-memory, and research-cache changes remain unstaged.

---
*Phase: 07-release-safety-intent-and-recovery-automation*
*Completed: 2026-07-18*
