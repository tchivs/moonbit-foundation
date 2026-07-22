---
phase: 06-namespace-authority-and-compatibility-contract
plan: "01"
subsystem: release-security
tags: [mooncakes, registry-authority, fail-closed, sanitized-evidence]
requires:
  - phase: 06-namespace-authority-and-compatibility-contract
    provides: canonical tchivs identities, immutable compatibility baselines, and credential-free authority validators
provides:
  - Truthful sanitized Mooncakes account and exact-version observations
  - Explicit unknown namespace and current-token publish authority with blocking dispositions
  - Exact REG03-REQUIRED-FACT-UNKNOWN publication-readiness rejection
affects: [06-06, phase-07-release-safety, phase-08-publication]
tech-stack:
  added: []
  patterns: [allowlisted observation projection, fail-closed external authority handoff]
key-files:
  created: []
  modified:
    - release/registry/authority-observation.json
    - scripts/quality/Invoke-RegistryObservation.ps1
    - scripts/quality/Test-RegistryAuthorityNegative.ps1
key-decisions:
  - "Account identity, public user presence, documented namespace syntax, and version absence do not prove current-token namespace or publish authority."
  - "Phase 6 completes REG-03 by proving the publication gate rejects unknown required authority; Phase 7 must validate the authenticated publish seam before mutation."
patterns-established:
  - "External authority evidence persists only allowlisted scalar projections and never raw command output."
  - "Unknown required registry facts carry block_publication and are an expected safety result, not fabricated readiness."
requirements-completed: [REG-01, REG-02, REG-03]
coverage:
  - id: D1
    description: Sanitized authority and capability evidence remains truthful and credential-redacted.
    requirement: REG-01
    verification:
      - kind: integration
        ref: "scripts/quality/Test-RegistryAuthority.ps1"
        status: pass
      - kind: integration
        ref: "scripts/quality/Test-RegistryAuthorityNegative.ps1"
        status: pass
    human_judgment: false
  - id: D2
    description: Required publication readiness rejects unknown namespace and authenticated-publish authority under one exact owning rule.
    requirement: REG-03
    verification:
      - kind: integration
        ref: "scripts/quality/Test-RegistryAuthority.ps1 -AssertPublishReady (expected REG03-REQUIRED-FACT-UNKNOWN rejection)"
        status: pass
    human_judgment: false
  - id: D3
    description: The collector remains read-only and leaves production registry mutation and credential handling outside Phase 6.
    requirement: REG-02
    verification:
      - kind: other
        ref: "Invoke-RegistryObservation.ps1 static boundary scan plus expected blocked collector exit 3"
        status: pass
    human_judgment: false
duration: 50min
completed: 2026-07-17
status: complete
---

# Phase 6 Plan 01: Registry Authority Contract Summary

**Sanitized personal-owner evidence now records only safely observed facts while the publication gate deterministically blocks on unproven namespace and current-token authority.**

## Performance

- **Duration:** 50 min across the OAuth continuation and fail-closed closure
- **Started:** 2026-07-17T14:13:00Z
- **Completed:** 2026-07-17T15:03:00Z
- **Tasks:** 2
- **Files modified:** 3 implementation/evidence files plus this summary and planning state

## Accomplishments

- Recorded the authenticated `tchivs` account and exact `0.1.0` absence through sanitized, repository-bound evidence without persisting raw authentication output.
- Kept namespace authority and the authenticated publish seam explicitly `unknown` with `block_publication`; public identity and version absence cannot be conflated with authorization.
- Proved the normal authority validator and exact negative matrix pass, while `-AssertPublishReady` rejects only with `REG03-REQUIRED-FACT-UNKNOWN`.
- Transferred the actual current-token publish-seam check to Phase 7's isolated publisher preflight before any production publication.

## Task Commits

1. **Task 1: Freeze truthful sanitized authority and capability evidence**
   - `917b48a` — hardened personal authority negatives
   - `d392c31` — projected official registry evidence
   - `816eb1f` — recorded sanitized Mooncakes authority
   - `894bedb` — kept token authority fail closed
   - `e8857a7` — classified namespace evidence precisely
   - `b03157a` — recorded final fail-closed authority evidence
2. **Task 2: Prove fail-closed readiness and transfer the publish seam**
   - `f03ddf9` — aligned the plan and downstream closure with fail-closed semantics

## Files Created/Modified

- `release/registry/authority-observation.json` — sanitized account, registry, version-absence, and explicit unknown authority facts.
- `scripts/quality/Invoke-RegistryObservation.ps1` — allowlisted `moon whoami` projection and GET-only official registry observations.
- `scripts/quality/Test-RegistryAuthorityNegative.ps1` — exact identity-conflation, malformed, unsafe, stale, and disposition negatives.
- `.planning/phases/06-namespace-authority-and-compatibility-contract/06-01-SUMMARY.md` — canonical plan closure and Phase 7 handoff.

## Decisions Made

- A locally authenticated account, matching public account record, documented username namespace, and absent module versions are necessary observations but insufficient proof of current-token authorization.
- REG-03 is satisfied by a fail-closed gate: publication readiness must remain rejected until Phase 7 validates the authenticated publish seam inside its isolated credential boundary.
- No production module publication, repository creation/push, credential-file access, or registry mutation is used as an authority probe.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Prevented public identity evidence from authorizing namespace ownership**
- **Found during:** Task 1
- **Issue:** Early observation projections could conflate GitHub/public account identity with Mooncakes namespace authority.
- **Fix:** Kept namespace authority unknown and added exact identity-conflation negatives.
- **Files modified:** `scripts/quality/Invoke-RegistryObservation.ps1`, `scripts/quality/Test-RegistryAuthorityNegative.ps1`
- **Verification:** Normal and negative authority suites pass; readiness rejects under the exact required-fact rule.
- **Committed in:** `894bedb`, `e8857a7`

**2. [Rule 1 - Bug] Kept the authenticated publish seam separate from account observation**
- **Found during:** Task 1
- **Issue:** Authentication status cannot demonstrate that the current token may publish the canonical modules.
- **Fix:** Preserved `authenticated_publish_seam` as unknown with `block_publication`.
- **Files modified:** `scripts/quality/Invoke-RegistryObservation.ps1`, `release/registry/authority-observation.json`
- **Verification:** `-AssertPublishReady` fails exactly with `REG03-REQUIRED-FACT-UNKNOWN`.
- **Committed in:** `894bedb`, `b03157a`

---

**Total deviations:** 2 auto-fixed bugs
**Impact on plan:** Both corrections strengthened the required safety boundary without expanding Phase 6 or performing external mutation.

## Authentication Gate

The human Mooncakes OAuth checkpoint was completed outside repository automation. The collector subsequently persisted only the allowlisted `tchivs` identity projection and did not persist raw output or credential material.

## Verification

- Collector: expected blocked exit `3`, outcome `unknown`, with no raw command output.
- Normal authority validator: passed.
- Negative authority matrix: passed with exact rule ownership.
- Publish-ready assertion: rejected exactly as `REG03-REQUIRED-FACT-UNKNOWN`; no second owning rule appeared.
- Static boundary: no `moon register`, `moon login`, `moon publish`, `gh repo create`, `git push`, or non-GET registry request path exists in the collector.
- Worktree: only pre-existing user changes and caches remained after verification.

## Known Stubs

None. The `unknown` facts are intentional fail-closed evidence, not implementation placeholders.

## Issues Encountered

Mooncakes exposes no safe read-only current-token publish-authority probe. The revised plan resolves this honestly by retaining the seam as unknown and making Phase 7 validate it before publication.

## User Setup Required

None for Phase 6. Phase 7 must define the isolated least-privilege publisher credential boundary before any registry mutation.

## Next Phase Readiness

- Plan 06-06 may now integrate the completed credential-free authority, compatibility, documentation, edge, and prohibition gates.
- Phase 7 receives an explicit pre-publication obligation to validate the actual authenticated publish seam; Phase 6 provides no publish-readiness claim.

## Self-Check: PASSED

- Summary file exists.
- Commits `917b48a`, `d392c31`, `816eb1f`, `894bedb`, `e8857a7`, `b03157a`, and `f03ddf9` exist in repository history.
- Both task verifications and the exact expected rejection were rerun successfully on 2026-07-17.

---
*Phase: 06-namespace-authority-and-compatibility-contract*
*Completed: 2026-07-17*
