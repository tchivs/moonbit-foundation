---
phase: 08-ordered-mooncakes-publication-and-registry-consumers
plan: "26"
subsystem: release-safety
tags: [r11, clean-clone, immutable-tag, qualification, powershell]
requires:
  - phase: 08-25
    provides: r10 hosted pre-live seam and immutable terminal history contracts
provides:
  - clone-local initial intent policy/ref/source/tag-peel validation
  - real disposable clean-clone PrepareAttempt regression with fetched dedicated tag
  - pre-provider rejection of absent or peel-drifted tags
affects: [08-27, r11-boundary, release-qualification, hosted-preflight]
tech-stack:
  added: []
  patterns: [clone-scoped policy binding, pre-boundary release-ref gate, disposable local Git fixture]
key-files:
  created: []
  modified: [scripts/quality/New-ReleaseIntent.ps1, scripts/quality/ReleaseQualification.Common.ps1, scripts/quality/Invoke-Phase08HostedRun.ps1, scripts/quality/Test-ReleaseIntent.ps1, scripts/quality/Test-Phase08Qualification.ps1]
key-decisions:
  - "Initial qualification resolves only the policy-selected immutable tag in the supplied clean clone; no workspace ref or policy fallback is allowed."
  - "PrepareAttempt validates the clone-local tag before boundary execution or material-provider work, keeping credentials, providers, locators, and network paths unreachable on ref failure."
patterns-established:
  - "Release intent callers bind source root, clone-local release-control path, release ref, source SHA, clone HEAD, and tag peel as one identity."
  - "Disposable Git fixtures use a local bare origin and explicit tag fetches; they never contact a production remote."
requirements-completed: []
coverage:
  - id: D1
    description: Initial intent accepts only a clone-local policy-selected tag whose peel and HEAD match the bound source SHA.
    requirement: DIST-01
    verification:
      - kind: integration
        ref: pwsh -NoProfile -File ./scripts/quality/Test-ReleaseIntent.ps1
        status: pass
    human_judgment: false
  - id: D2
    description: Real InitializeBoundary to PrepareAttempt qualification crosses the fetched-tag seam only when the clone-local binding is valid and fails before provider or locator effects otherwise.
    requirement: DIST-04
    verification:
      - kind: integration
        ref: pwsh -NoProfile -File ./scripts/quality/Test-Phase08Qualification.ps1 -FixtureOnly
        status: pass
      - kind: integration
        ref: pwsh -NoProfile -File ./scripts/quality/Test-Phase08PrepareHistorySchema.ps1
        status: pass
    human_judgment: false
duration: 10min
completed: 2026-07-19
status: complete
---

# Phase 8 Plan 26: Clean-Clone Qualification Ref Binding Summary

**Initial release qualification now binds the policy-selected immutable tag, clone HEAD, source SHA, and clone-local policy before PrepareAttempt can reach provider work.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-07-19T17:41:36+08:00
- **Completed:** 2026-07-19T17:50:59+08:00
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added an explicit initial-intent binding that rejects absent tags, peel drift, non-clone policy paths, and ref substitutions with `REL01-REF`.
- Passed clone-local source/policy/ref context through the real HostedRun provider seam.
- Added a disposable bare-origin clean-clone regression that fetches the policy-selected tag and proves missing or altered tags stop before provider calls or locator creation.
- Preserved the r8/r9 strict-history regression and made no production tag, push, dispatch, credential, network, registry, handoff, or publish operation.

## Task Commits

1. **Task 1: Bind initial intent validation to its clean clone and fetched tag** — `c67c86c` (RED), `5333235` (GREEN)
2. **Task 2: Reproduce and close the real clean-clone PrepareAttempt ref seam** — `8f0113e` (RED), `b2367ec` (GREEN)

## Files Created/Modified

- `scripts/quality/New-ReleaseIntent.ps1` — derives initial qualification artifacts from the supplied clone and enforces its policy/tag identity.
- `scripts/quality/ReleaseQualification.Common.ps1` — provides the fail-closed clone-local initial binding helper.
- `scripts/quality/Invoke-Phase08HostedRun.ps1` — validates the clone-local tag before boundary processing and passes the binding context to material providers.
- `scripts/quality/Test-ReleaseIntent.ps1` — covers fetched-tag success, absent tag, and ambient-policy rejection.
- `scripts/quality/Test-Phase08Qualification.ps1` — executes the actual clean-clone `InitializeBoundary` to `PrepareAttempt` path with positive and adversarial fixtures.

## Decisions Made

- Treat the configured initial release ref as clone-local evidence, not a name that can be resolved from an ambient checkout.
- Place the ref gate before boundary execution so an absent or altered tag cannot cause locator, provider, credential, network, or publication activity.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Normalize a missing `git rev-parse` result before checking it.**
- **Found during:** Task 1
- **Issue:** A missing clone tag produced a PowerShell null-method error instead of the required `REL01-REF` result.
- **Fix:** Joined the Git output before calling `Trim()`, allowing the explicit absent-tag rejection to run.
- **Files modified:** `scripts/quality/ReleaseQualification.Common.ps1`
- **Verification:** `Test-ReleaseIntent.ps1` passes the missing-tag regression.
- **Committed in:** `5333235`

---

**Total deviations:** 1 auto-fixed (1 Rule 1 bug)
**Impact on plan:** The fix is necessary for deterministic fail-closed ref handling and does not broaden release scope.

## Known Stubs

None. The null-valued fields found by the scan are intentional closed-schema negative-fixture and mutually exclusive authority fields, not UI or runtime placeholders.

## Issues Encountered

- The existing fixture used a Git callback that simulated a matching tag. It was replaced in the regression path with an actual tag fetched from a disposable local bare repository.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 08-27 can use the verified clean-clone tag gate before considering an r11 boundary. r10 remains immutable terminal evidence; no live-release action was attempted.

## Verification

- `Test-ReleaseIntent.ps1` — PASS
- `Test-Phase08Qualification.ps1 -FixtureOnly` — PASS
- `Test-Phase08PrepareHistorySchema.ps1` — PASS
- PowerShell parse checks and `git diff --check` — PASS

## Self-Check: PASSED

- Confirmed all five scoped source/test files and this summary exist.
- Confirmed RED/GREEN commits `c67c86c`, `5333235`, `8f0113e`, and `b2367ec` exist.
