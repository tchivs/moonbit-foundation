---
phase: 06-namespace-authority-and-compatibility-contract
plan: "14"
subsystem: release-validation
tags: [mooncakes, namespace, compatibility, support, security, fail-closed]
requires:
  - phase: 06-namespace-authority-and-compatibility-contract
    provides: canonical tchivs policy, source graph, documentation, and shared qualification constants through plans 06-10 and 06-25
provides:
  - Honest local support and security contracts with intended external routes explicitly unverified
  - Canonical tchivs source, policy, documentation, and compatibility validators
  - Blocked-state authority enforcement for Mooncakes identity, repository liveness, tracked-seed evidence, and forward-only recovery
affects: [06-15, 06-11, 06-01, 06-06, publication-readiness]
tech-stack:
  added: []
  patterns: [intended-versus-verified-routes, canonical-production-parser, unknown-first-authority-seed, forward-only-recovery]
key-files:
  created:
    - .planning/phases/06-namespace-authority-and-compatibility-contract/06-14-SUMMARY.md
  modified:
    - docs/support.md
    - SECURITY.md
    - scripts/quality/Assert-Policy.ps1
    - scripts/quality/Test-CandidateDocumentation.ps1
    - scripts/quality/Compare-PublicInterfaceBaseline.ps1
    - scripts/quality/Test-PublicCompatibility.ps1
    - scripts/quality/Test-RegistryAuthority.ps1
key-decisions:
  - "Treat the intended GitHub repository and its issue/advisory routes as metadata only until a read-only existence proof passes."
  - "Reject canonical tchivs dependency floors in production if and only if they violate the same closed four-class compatibility rules; no test-only parser override is permitted."
  - "A tracked authority seed may document the pinned toolchain but cannot infer account, namespace, module, command, timestamp, or freshness evidence."
patterns-established:
  - "External routes remain locally usable through private checkout records while absent infrastructure is never presented as operational."
  - "GitHub identity and repository metadata cannot substitute for separately observed Mooncakes authority."
requirements-completed: [COMP-02, COMP-03, COMP-04, PROV-03]
requirements-pending: [REG-01, REG-02, REG-03]
coverage:
  - id: D1
    description: Shared support and security contracts name the exact tchivs module family and keep intended repository/reporting routes unverified and non-operational
    requirement: PROV-03
    verification:
      - kind: integration
        ref: PowerShell route identity and unverified-boundary assertion from 06-14 Task 1
        status: pass
    human_judgment: false
  - id: D2
    description: Production policy, documentation, and compatibility validators consume canonical tchivs identities while retaining exact positive and negative rule ownership
    requirement: COMP-02
    verification:
      - kind: integration
        ref: scripts/quality/Test-CandidateDocumentation.ps1 -Module all
        status: pass
      - kind: integration
        ref: scripts/quality/Test-PublicCompatibility.ps1
        status: pass
      - kind: integration
        ref: scripts/quality/Invoke-ReleaseQualification.ps1 -Check -StaticOnly
        status: pass
    human_judgment: false
  - id: D3
    description: Blocked registry authority rejects GitHub substitution, tracked-seed overclaims, fabricated route liveness, and destructive recovery assumptions
    requirement: REG-03
    verification:
      - kind: integration
        ref: scripts/quality/Test-RegistryAuthority.ps1
        status: pass
      - kind: integration
        ref: static collector-call prohibition scan
        status: pass
    human_judgment: false
duration: 16m
completed: 2026-07-17
status: complete
---

# Phase 6 Plan 14: Shared Route and Collective Validator Reconciliation Summary

**Canonical `tchivs/*` source and compatibility checks now pass while repository, reporting, and Mooncakes authority claims remain explicitly unknown and fail closed.**

## Performance

- **Duration:** 16m
- **Started:** 2026-07-17T11:40:00Z
- **Completed:** 2026-07-17T11:56:15Z
- **Tasks:** 3
- **Implementation files modified:** 7

## Accomplishments

- Replaced absent GitHub issue/advisory links with locally usable support and private security-reporting instructions while retaining intended repository metadata as unverified and not operational.
- Reconciled foundation, publication-source, production comparator, and four-class compatibility validators with the exact `tchivs/mb-core` -> `tchivs/mb-color` -> `tchivs/mb-image` graph.
- Added stable blocked-state rules for GitHub-versus-Mooncakes authority, exact unknown-first tracked seeds, repository-route liveness, and forward-only destructive recovery.

## Task Commits

1. **Task 1: Reconcile the two shared routes** - `02aa144` (docs)
2. **Rule 3 plan correction: Include the production comparator parser** - `b46880b` (docs)
3. **Task 2: Reconcile source, compatibility, and policy validators** - `cf26180` (fix)
4. **Task 3: Enforce authority and repository-liveness negatives** - `b4f5e40` (test)

## Files Created/Modified

- `docs/support.md` and `SECURITY.md` - Exact module scope plus local reporting guidance and explicit intended/unverified external-route boundaries.
- `scripts/quality/Assert-Policy.ps1` - Exact canonical module, package, import, DAG, and owner expectations.
- `scripts/quality/Test-CandidateDocumentation.ps1` - Canonical publication-source rows, import parser, repository negative, DAG negative, and extra-identity fixture.
- `scripts/quality/Compare-PublicInterfaceBaseline.ps1` - Production candidate dependency-floor parser for `tchivs/mb-{core,color,image}`.
- `scripts/quality/Test-PublicCompatibility.ps1` - Canonical exact/additive/incompatible facts and dependency-floor negative.
- `scripts/quality/Test-RegistryAuthority.ps1` - Exact authority-source, tracked-seed, route-liveness, and recovery-semantics rules.

## Decisions Made

- External repository and reporting routes cannot be operational merely because the canonical URL is present in policy or documentation.
- The production comparator must accept the same canonical dependency identities used by its test harness; a test-only override would hide a release-blocking parser defect.
- REG-01 through REG-03 remain pending live Mooncakes evidence even though the blocked-state REG-03 enforcement path is now verified.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added the omitted production compatibility parser to the plan boundary**

- **Found during:** Task 2 full verification.
- **Issue:** `Test-PublicCompatibility.ps1` emitted canonical `tchivs/*` dependency floors, but `Compare-PublicInterfaceBaseline.ps1` still rejected every canonical floor with `COMP02-INPUT-CLOSED`; no later remediation plan owned that parser.
- **Fix:** Corrected 06-14 from six to seven implementation files and updated the production parser regex instead of masking the defect inside the test.
- **Files modified:** `06-14-PLAN.md`, `scripts/quality/Compare-PublicInterfaceBaseline.ps1`.
- **Verification:** The complete four-class positive/negative compatibility suite passed.
- **Committed in:** `b46880b`, `cf26180`.

**2. [Rule 3 - Blocking] Reused the installed LLVM-MinGW Clang for native example verification**

- **Found during:** Task 2 full verification.
- **Issue:** A fresh shell could not discover a system C compiler for the native public example.
- **Fix:** Prepended the installed LLVM-MinGW UCRT `bin` directory and set `CC` to its `clang.exe` for verification only.
- **Files modified:** None.
- **Verification:** Workspace examples and the complete candidate-documentation suite passed with native runtime execution.
- **Committed in:** Not applicable; environment-only correction.

---

**Total deviations:** 2 auto-fixed blocking issues.
**Impact on plan:** The implementation boundary expanded by one required production validator; no external state, credentials, publication, or unrelated source changed.

## Issues Encountered

- The first Task 2 run correctly exposed one remaining hardcoded import-regex identity in the documentation validator; it was corrected before the task commit and the entire suite was rerun.

## User Setup Required

None - this plan performed no authentication, repository creation, publication, or external write.

## Verification

- Task 1 shared-route identity and liveness-boundary assertion passed.
- `Invoke-ReleaseQualification.ps1 -Check -StaticOnly`, `Test-CandidateDocumentation.ps1 -Module all`, and `Test-PublicCompatibility.ps1` passed with explicit installed Clang available for native examples.
- `Test-RegistryAuthority.ps1` passed in blocked mode, and its source contains no operator collector invocation.
- `git diff --check` passed; the implementation diff contains exactly the seven corrected plan files plus the committed plan-boundary correction.

## Known Stubs

None. Unknown Mooncakes authority and unverified GitHub routes are explicit external blockers, not implementation placeholders.

## Next Phase Readiness

- Plan 06-15 can capture the immutable source anchor at this completed 06-14 boundary and begin bounded baseline regeneration.
- Live Mooncakes account, namespace, and exact module authority remain intentionally unknown; REG-01 through REG-03 and publication stay blocked until revised 06-01 completes its OAuth boundary and sanitized proof.

## Self-Check: PASSED

- All seven implementation files, corrected plan, and this summary exist.
- Task commits `02aa144`, `cf26180`, and `b4f5e40`, plus correction commit `b46880b`, exist in git history.
- Every task and plan-level verification passed from a fresh shell with the installed LLVM-MinGW Clang explicitly configured.
- User-dirty governance files, caches, credentials, external services, and archived v0.1 artifacts were not modified by this plan.

---
*Phase: 06-namespace-authority-and-compatibility-contract*
*Completed: 2026-07-17*
