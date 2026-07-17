---
phase: 06-namespace-authority-and-compatibility-contract
plan: "07"
subsystem: registry-authority
tags: [mooncakes, namespace, compatibility, policy, fail-closed]
requires:
  - phase: 06-namespace-authority-and-compatibility-contract
    provides: completed compatibility and publication-source contracts through plan 06-05
provides:
  - Canonical personal owner policy for tchivs/mb-core, tchivs/mb-color, and tchivs/mb-image at 0.1.0
  - Closed blocked-state authority schema and deterministic sanitized tracked seed
  - Policy-first identity contract for the later module-root and source-graph migration
affects: [06-12, 06-08, 06-13, 06-14, 06-01, registry-authority, compatibility]
tech-stack:
  added: []
  patterns: [policy-first-identity-rebase, unknown-first-authority-seed, forward-only-owner-migration]
key-files:
  created:
    - .planning/phases/06-namespace-authority-and-compatibility-contract/06-07-SUMMARY.md
  modified:
    - policy/foundation.json
    - policy/registry-authority.json
    - policy/release-qualification.json
    - policy/compatibility.json
    - release/qualification/package-schema.json
    - release/registry/authority-observation-schema.json
    - release/registry/authority-observation.json
    - scripts/quality/Test-RegistryAuthority.ps1
key-decisions:
  - "Use tchivs as the canonical initial personal Mooncakes owner while preserving MoonBit Native Foundation branding."
  - "Keep candidate versions at 0.1.0 because the owner correction precedes any publication."
  - "Reset the tracked authority observation to unknown-first evidence; only the pinned toolchain is documented."
  - "Treat future owner changes as new forward-only module identities without rename, transfer, overwrite, delete, unpublish, or yank assumptions."
patterns-established:
  - "Canonical identity moves from policy to roots, imports, consumers, documentation, and regenerated evidence in bounded downstream plans."
  - "A tracked seed never inherits stale operator authentication or timestamps as current authority proof."
requirements-completed: [COMP-03, COMP-04]
requirements-pending: [REG-01, REG-02, REG-03]
coverage:
  - id: D1
    description: Canonical closed policy uses exactly the ordered tchivs module family at candidate 0.1.0
    requirement: COMP-03
    verification:
      - kind: integration
        ref: pwsh blocked-state policy closure and scripts/quality/Test-RegistryAuthority.ps1
        status: pass
    human_judgment: false
  - id: D2
    description: Sanitized tracked authority seed retains every unobserved live fact as unknown and publication-blocking
    requirement: REG-03
    verification:
      - kind: integration
        ref: pwsh authority observation JSON Schema validation and -AssertPublishReady fail-closed check
        status: pass
    human_judgment: false
  - id: D3
    description: Historical Phase 1 evidence, completed summaries, module roots, and the identity-neutral capability matrix remain unchanged
    requirement: COMP-04
    verification:
      - kind: integration
        ref: SHA-256 and git diff-tree bounded history/root checks
        status: pass
    human_judgment: false
duration: 8m
completed: 2026-07-17
status: complete
---

# Phase 6 Plan 07: Personal Namespace Policy Rebase Summary

**Canonical machine policy now names the unpublished `tchivs/*@0.1.0` family while live registry authority remains explicitly unknown and fail-closed.**

## Performance

- **Duration:** 8m
- **Started:** 2026-07-17T09:56:01Z
- **Completed:** 2026-07-17T10:03:30Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments

- Rebased foundation, authority, release-qualification, compatibility, and closed schema facts onto `tchivs/mb-core`, `tchivs/mb-color`, and `tchivs/mb-image` at `0.1.0`.
- Replaced stale operator evidence with a deterministic `tracked_seed` whose account, namespace authority, exact identities, version availability, publish seam, observation, and resolution facts remain unknown and publication-blocking.
- Preserved the four compatibility classes, intended-but-unverified repository route, forward-only future-owner rule, module roots for 06-12, and immutable historical evidence.

## Task Commits

Each task was committed atomically:

1. **Task 1: Rebase closed policy and schema identities** - `30fe4a9` (feat)
2. **Task 2: Prove bounded policy closure without touching roots or historical evidence** - `76fb7fe` (test)

## Files Created/Modified

- `policy/foundation.json` - Canonical personal identities, package identities, dependency edges, repository intent, and blocked owner state.
- `policy/registry-authority.json` - Exact personal owner and ordered module authority.
- `policy/release-qualification.json` - Candidate manifests, package identities, dependencies, and ordered post-publish intent.
- `policy/compatibility.json` - Personal-namespace dependency floors while retaining the four-class model.
- `release/qualification/package-schema.json` - Closed post-publish ordering for the personal module family.
- `release/registry/authority-observation-schema.json` - Closed owner, namespace, and exact-identity constraints.
- `release/registry/authority-observation.json` - Deterministic unknown-first tracked seed with recomputed stable SHA-256.
- `scripts/quality/Test-RegistryAuthority.ps1` - Positive personal-owner and exact-identity expectations.
- `.planning/phases/06-namespace-authority-and-compatibility-contract/06-07-SUMMARY.md` - Plan evidence and downstream readiness.

## Decisions Made

- The GitHub route `https://github.com/tchivs/moonbit-foundation` is policy intent, not live repository proof; publication remains blocked and repository-liveness negatives remain owned by later plans.
- The authority seed records no inherited session result or timestamp. Unknown account/namespace facts cannot be promoted from a prior local observation.
- The identity correction does not create a compatibility class or version bump because no old registry identity was published.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Metadata correctness] Kept live authority requirements pending**

- **Found during:** Plan close-out
- **Issue:** The plan frontmatter lists REG-01 through REG-03, but its own success criteria require account and repository liveness to remain unverified. Marking those requirements complete would falsely green the external authority gate.
- **Fix:** Recorded COMP-03 and COMP-04 as preserved/completed and kept REG-01 through REG-03 explicitly pending for the revised 06-01 human OAuth and sanitized observation checkpoint.
- **Files modified:** `.planning/phases/06-namespace-authority-and-compatibility-contract/06-07-SUMMARY.md`
- **Verification:** `release/registry/authority-observation.json` remains unknown-first and `Test-RegistryAuthority.ps1 -AssertPublishReady` fails with `REG03-REQUIRED-FACT-UNKNOWN`.
- **Committed in:** plan metadata commit

---

**Total deviations:** 1 auto-fixed metadata correctness issue.
**Impact on plan:** Repository-local policy work is complete without overstating external authority or weakening the release gate.

## Issues Encountered

- An initial capability-matrix unchanged check used an incorrect PowerShell external-command conditional. The check was corrected to inspect `$LASTEXITCODE`; the matrix has no diff.

## User Setup Required

None for this plan. Mooncakes registration/login remains deferred to revised plan 06-01 after the credential-free migration chain completes.

## Verification

- Closed JSON parsing and JSON Schema validation passed for the policy and authority observation files.
- `scripts/quality/Test-RegistryAuthority.ps1` passed in credential-free blocked-state mode.
- `scripts/quality/Test-RegistryAuthority.ps1 -AssertPublishReady` failed closed with `REG03-REQUIRED-FACT-UNKNOWN`, as required.
- `policy/phase-01-source-audit.json` retained SHA-256 `52f118333892cfe1044b8105a6ea5d03f1ab087d3f7875d13b79c4e5b7640a7a`.
- Module roots, archived v0.1 paths, completed Phase 6 summaries, and `release/registry/capability-matrix.json` have no task diff.
- `git diff --check 30fe4a9^..HEAD` passed.

## Known Stubs

None. Null timestamps and the empty exact-identity list are intentional fail-closed evidence, not implementation stubs.

## Next Phase Readiness

- Plan 06-12 can now rebase the three module roots against one closed canonical policy.
- REG-01 through REG-03 remain pending until the later external OAuth/account checkpoint produces fresh sanitized authority proof.
- No repository creation, push, login, registration, publication, credential read, or registry mutation occurred.

## Self-Check: PASSED

- All nine key files exist.
- Both task commits exist.
- Both task verification commands and plan-level bounded checks passed.
- Historical evidence and user-dirty paths remain outside the plan commits.

---
*Phase: 06-namespace-authority-and-compatibility-contract*
*Completed: 2026-07-17*
