---
phase: 08-ordered-mooncakes-publication-and-registry-consumers
plan: "30"
subsystem: release-safety
tags: [powershell, r12, immutable-history, canonical-ref, prepared-bundle]
requires:
  - phase: 08-ordered-mooncakes-publication-and-registry-consumers
    provides: "r11 immutable remote-clone evidence and the non-overridable r12 canonical boundary wrapper"
provides:
  - "r12-only static policy, intent, prepared, authority, receipt, and handoff contracts with twelve exact history digests."
  - "Fixture-qualified r12 preparation that invokes the clone-policy wrapper and preserves r11 only as historical evidence."
affects: [release-qualification, hosted-run, r12-prelive]
tech-stack:
  added: []
  patterns: ["Bind every current artifact to the ordered LF aggregate and every individual immutable history digest.", "Derive the initial release ref only inside the clone-policy boundary wrapper."]
key-files:
  created: []
  modified: [policy/release-control.json, release/intent/schema.json, release/prepared/schema.json, release/qualification/phase-08-authority-schema.json, release/qualification/phase-08-authorization-receipt-schema.json, release/qualification/phase-08-handoff-schema.json, scripts/quality/Invoke-Phase08HostedRun.ps1, scripts/quality/New-PreparedReleaseBundle.ps1, scripts/quality/New-ReleaseIntent.ps1, scripts/quality/ReleaseQualification.Common.ps1, scripts/quality/Test-ReleaseIntent.ps1, scripts/quality/Test-PreparedReleaseBundle.ps1, scripts/quality/Test-Phase08Qualification.ps1]
key-decisions:
  - "r11 records exact tag/peel identity plus distinct canonical-provider and noncanonical-caller facts; it cannot become current state."
  - "r12 requires twelve individual history digests and their LF-ordered aggregate through prepared, authority, receipt, active-attempt, and handoff boundaries."
requirements-completed: []
coverage:
  - id: D1
    description: "Closed r12 schemas bind r11 as the twelfth immutable terminal history and reject missing, reordered, or mutated evidence."
    verification:
      - kind: unit
        ref: "pwsh -NoProfile -File ./scripts/quality/Test-ReleaseIntent.ps1"
        status: pass
    human_judgment: false
  - id: D2
    description: "Fresh r12 preparation requires twelve histories and passes through the canonical clone-policy wrapper before provider work."
    verification:
      - kind: integration
        ref: "pwsh -NoProfile -File ./scripts/quality/Test-PreparedReleaseBundle.ps1; pwsh -NoProfile -File ./scripts/quality/Test-Phase08Qualification.ps1 -FixtureOnly; pwsh -NoProfile -File ./scripts/quality/Test-Phase08RemoteCloneRef.ps1"
        status: pass
    human_judgment: false
metrics:
  duration: 54min
  completed: 2026-07-19
status: complete
---

# Phase 8 Plan 30: r12 Twelve-History Contracts Summary

**r12 now accepts only fresh clone-policy-bound preparation while carrying r11 as exact immutable tag/peel and caller-boundary evidence across all authority contracts.**

## Performance

- **Duration:** 54 min
- **Tasks:** 2
- **Files modified:** 13

## Accomplishments

- Recorded r11's immutable tag object `735ad67910dca97a95cfc1d4e94f6b003bcc3f30`, peeled source `30479a2546e0fc6416a9a26b10e39ed1f686c860`, canonical provider success, and distinct rejected noncanonical caller path.
- Advanced initial intent, prepared bundle, authority, receipt, active-attempt, and handoff contracts to r12 with all twelve individual digests and the canonical LF aggregate.
- Made FixtureOnly preparation exercise `Invoke-Phase08R12Boundary.ps1`; the immutable r11 remote-clone regression remains a credential-free pre-tag gate.

## Task Commits

1. **Task 1 RED: Record immutable r11 evidence and close r12 schemas** — `90186c2` (test)
2. **Task 1 GREEN: Record immutable r11 evidence and close r12 schemas** — `4ab5aea` (feat)
3. **Task 2 RED: Bind fresh r12 preparation to contracts and canonical boundary wrapper** — `4652819` (test)
4. **Task 2 GREEN: Bind fresh r12 preparation to contracts and canonical boundary wrapper** — `21f3d73` (feat)

## Decisions Made

- r11's canonical clone-policy provider path and the rejected noncanonical caller path are independently attested; neither is eligible as r12 state or a reusable input.
- All current r12 authorization-bearing artifacts require the individual digest fields in addition to the aggregate, so the aggregate cannot hide a missing or substituted record.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Critical contract closure] Added authority and receipt schema updates omitted from the file list.**
- **Found during:** Task 1
- **Issue:** `Test-ReleaseIntent.ps1` and the plan's acceptance criteria require r12 authority and receipt schemas, but both were fixed at r11 with only eleven history fields.
- **Fix:** Advanced both closed schemas to r12 and added the exact `historical_r11_sha256` and aggregate bindings.
- **Files modified:** `release/qualification/phase-08-authority-schema.json`, `release/qualification/phase-08-authorization-receipt-schema.json`
- **Verification:** `Test-ReleaseIntent.ps1` passes closed-schema positive and negative checks.
- **Committed in:** `4ab5aea`

**2. [Rule 2 - Critical contract closure] Advanced direct preparation dependencies to r12.**
- **Found during:** Task 2
- **Issue:** The r12 wrapper directly invokes `Invoke-Phase08HostedRun.ps1`, whose hosted, active-attempt, handoff, dispatch, and provider paths still required r11/eleven histories; its provider also invoked `New-ReleaseIntent.ps1`, which rejected r12 before preparation.
- **Fix:** Added r11 history paths/digests and r12 fresh-root/ref checks through both direct dependencies while retaining fail-closed clone-policy binding.
- **Files modified:** `scripts/quality/Invoke-Phase08HostedRun.ps1`, `scripts/quality/New-ReleaseIntent.ps1`
- **Verification:** FixtureOnly qualification and the canonical remote-clone regression pass.
- **Committed in:** `21f3d73`

**Total deviations:** 2 auto-fixed (2 Rule 2 critical contract closures)

## Verification

- `pwsh -NoProfile -File ./scripts/quality/Test-ReleaseIntent.ps1` — PASS
- `pwsh -NoProfile -File ./scripts/quality/Test-PreparedReleaseBundle.ps1` — PASS
- `pwsh -NoProfile -File ./scripts/quality/Test-Phase08Qualification.ps1 -FixtureOnly` — PASS
- `pwsh -NoProfile -File ./scripts/quality/Test-Phase08RemoteCloneRef.ps1` — PASS; immutable r11 object/peel/head/boundary agree, one provider call, zero mutation.
- PowerShell parser checks for all modified scripts — PASS.
- `git diff --check` — PASS.

## Known Stubs

None. The only placeholder match is a negative assertion in `Test-PreparedReleaseBundle.ps1` that rejects placeholders.

## Next Phase Readiness

r12 static and FixtureOnly preparation gates are complete. No r12 tag, push, dispatch, credentials, Mooncakes request, registry operation, receipt/handoff emission, PublishOne call, or publication was performed.

## Self-Check: PASSED

All thirteen scoped files exist and task commits `90186c2`, `4ab5aea`, `4652819`, and `21f3d73` are present. No tracked-file deletion was introduced.
