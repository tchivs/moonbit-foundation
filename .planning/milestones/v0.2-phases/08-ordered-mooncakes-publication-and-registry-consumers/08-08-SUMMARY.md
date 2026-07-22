---
phase: 08-ordered-mooncakes-publication-and-registry-consumers
plan: "08"
subsystem: release-safety
tags: [mooncakes, r2, publisher, utc, authorization-receipt, handoff, powershell]

requires:
  - phase: 08-07
    provides: r2 attempt-family, receipt, authority-union, and handoff schemas
provides:
  - Sole-current r2 publisher, live adapter, and hosted workflow bindings
  - UTC-stable literal authorization receipt and active-attempt persistence
  - Non-overridable production fixed handoff with LibraryOnly GUID-isolated fixtures
affects: [08-09, 08-10, DIST-01]

tech-stack:
  added: []
  patterns: [atomic exclusive JSON, canonical UTC hashing, production-fixed test-injected paths]

key-files:
  created: []
  modified:
    - scripts/quality/Invoke-ReleasePublisher.ps1
    - scripts/quality/Invoke-MooncakesLiveMutation.ps1
    - .github/workflows/publish-modules.yml
    - scripts/quality/Test-ReleasePublisherNegative.ps1
    - scripts/quality/Invoke-Phase08HostedRun.ps1
    - scripts/quality/Test-Phase08LiveSeam.ps1
    - scripts/quality/Test-Phase08Qualification.ps1
    - scripts/quality/Test-MooncakesObservation.ps1

key-decisions:
  - "The publisher and adapter accept only r2 initial authority plus two distinct terminal-negative history digests; r1 is historical only."
  - "Production computes the fixed r2 handoff path internally and rejects caller HandoffPath or TempRoot overrides."
  - "LibraryOnly handoff fixtures use independent GUID-owned roots and never create or remove the production fixed handoff."

patterns-established:
  - "Hosted state timestamps canonicalize DateTime, DateTimeOffset, offset strings, and JSON-reloaded values to second-precision UTC Z before hashing."
  - "Receipt, active-attempt, and handoff persistence is exclusive, digest-bound, reload-validated, and authority-variant closed."

requirements-completed: []
coverage:
  - id: D1
    description: "Static r2 publisher and hosted handoff seams are implemented without live effects."
    requirement: DIST-01
    verification:
      - kind: integration
        ref: "Test-ReleasePublisherNegative.ps1; Test-Phase08LiveSeam.ps1; Test-Phase08Qualification.ps1; Test-MooncakesObservation.ps1"
        status: pass
    human_judgment: false

duration: 18min
completed: 2026-07-19
status: complete
---

# Phase 08 Plan 08: r2 Hosted Publisher Seam Summary

**The hosted release seam now accepts only the fresh r2 authority family and persists canonical-UTC receipt, active-attempt, and exclusive handoff evidence without exposing a test override in production.**

## Performance

- **Duration:** 18 min
- **Started:** 2026-07-18T21:32:26Z
- **Completed:** 2026-07-18T21:50:00Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Replaced r1 current publisher, live adapter, and workflow authority with r2 plus both immutable terminal-negative history digests.
- Enforced one-module mutation outcomes, sanitized actor evidence, isolated credential state, and prepared-bundle history revalidation.
- Migrated PrepareAttempt to r2, indexed attempt-zero and r1 negative evidence separately, and canonicalized boundary/live locator time.
- Added literal `authorize-core` receipt persistence, digest-bound active-attempt state, and mutually exclusive mutation/exact-existing handoff creation.
- Made the production `%TEMP%/mnf-phase08-r2-handoff.json` path non-overridable while keeping LibraryOnly fixtures isolated by independent GUID roots.

## Task Commits

1. **Task 1: Enforce r2 in publisher, one-step adapter, and hosted workflow** — `2b7ba9b` (RED), `6f92210` (GREEN)
2. **Task 2: Implement UTC-stable r2 hosted state, receipt, and fixed handoff** — `880a8b0` (RED), `51740de` (GREEN)

## Decisions Made

- Kept correction helpers available for historical reducer testing, but made the live initial publisher lane r2-only and rejected r1, old source SHAs, missing/equal history digests, and multi-mutation outcomes before credential use.
- Stored active-attempt evidence as a closed self-digesting projection so the fixed handoff remains a small immutable pointer rather than reusable attempt state.
- Kept `DIST-01` pending because this plan performs no tag, dispatch, publication, registry observation, or cold public consumer proof.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Migrated adjacent observation and qualification fixtures from stale r1 boundary setup**
- **Found during:** Task 2 GREEN regression
- **Issue:** Adjacent fixtures still called the old r1/legacy store initialization contract and failed before testing observation behavior.
- **Fix:** Moved them to r2 and the current v2 indexed fixture seam, preserving credential-free local-only behavior.
- **Files modified:** `scripts/quality/Test-Phase08Qualification.ps1`, `scripts/quality/Test-MooncakesObservation.ps1`
- **Commit:** `51740de`

**2. [Rule 1 - Bug] Preserved UTC identity across PowerShell JSON DateTime reload**
- **Found during:** Task 2 GREEN regression
- **Issue:** `ConvertFrom-Json` materializes canonical ISO timestamps as DateTime values, so string-only comparison rejected an equivalent reloaded instant.
- **Fix:** Canonicalized the reloaded DateTime before digest comparison while still rejecting noncanonical string values and changed instants.
- **Files modified:** `scripts/quality/Invoke-Phase08HostedRun.ps1`
- **Commit:** `51740de`

## Known Stubs

- `.github/workflows/publish-modules.yml` retains an intentional fail-closed `unknown` public-surface projection when no structured provider facts are available. It cannot authorize publication and is consumed by the later live observation plan.

## Verification

- Publisher reducer/controller negative suite: PASS.
- Live adapter and workflow fixture suite: PASS.
- r2 receipt/handoff qualification suite: PASS.
- Full static qualification fixture suite: PASS.
- Mooncakes observation selector suite: PASS.
- Production fixed handoff absence before and after all static fixtures: PASS.
- `git diff --check`: PASS.
- Schema drift gate: PASS, no drift.
- Codebase drift gate: skipped because no structure map exists.
- UI safety gate: PASS, no UI files changed.

## Security and External-Effect Boundary

- No push, tag, GitHub dispatch, network call, secret access, registry mutation, or Mooncakes publication occurred.
- No production fixed handoff was created.
- All planned critical/high threats are covered by r2/history validation, atomic digest-bound writes, actor/raw-output controls, and test/production path separation.

## Next Phase Readiness

- Plan 08-09 can consume the static r2 seam to execute the separately guarded live core-entry decision flow.
- Plan 08-10 remains untouched.

## Self-Check: PASSED

- All eight planned files exist.
- All four RED/GREEN task commits exist.
- The summary exists and all plan tests/capability gates passed.

---
*Phase: 08-ordered-mooncakes-publication-and-registry-consumers*
*Completed: 2026-07-19*
