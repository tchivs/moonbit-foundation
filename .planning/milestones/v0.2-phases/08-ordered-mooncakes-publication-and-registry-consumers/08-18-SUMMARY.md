---
phase: 08-ordered-mooncakes-publication-and-registry-consumers
plan: "18"
subsystem: release-safety
tags: [mooncakes, r7, hosted-preflight, exact14, cross-platform, pre-live]

requires:
  - phase: 08-17
    provides: r7 prepared, authority, receipt, and handoff contracts over seven terminal histories
provides:
  - r7-only publisher, live adapter, workflow, and hosted controller seam
  - Exact 14-field hosted dispatch with unique workflow environment mappings
  - Cross-platform LF archive identity regression
  - Read-only r7 pre-live selector over seven immutable histories
affects: [08-19, 08-20, DIST-01]

tech-stack:
  added: []
  patterns: [seven-history binding, exact14 propagation, remote-tag authority, zero-write pre-live selection]

key-files:
  created:
    - scripts/quality/Invoke-Phase08R7PreLive.ps1
    - scripts/quality/Test-Phase08R7PreLive.ps1
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
  - "Publisher, adapter, workflow, and hosted controller accept only r7 and bind seven individual histories plus their canonical LF-ordered set."
  - "The r7 pre-live selector treats remote tag rows as authority, preserves rootless attempt-zero, and requires rooted persisted evidence for r1 through r6."
  - "The r6 terminal record is accepted only with run 29671691604/1, prepare job 88151792308, P08-PREPARED-INTENT-BINDING, and zero downstream effects."
  - "DIST-01 remains pending because Plan 08-18 performs no push, tag, dispatch, registry access, credential access, StateRoot mutation, PublishOne, or publication."

requirements-completed: []
duration: 32min
completed: 2026-07-19
status: complete
---

# Phase 08 Plan 18: r7 Hosted Seam and Pre-Live Selector Summary

**The static release seam now carries r7 and all seven immutable failures through publisher, exact14 hosted dispatch, cross-platform archive identity, and a fail-closed zero-write pre-live selector.**

## Performance

- **Duration:** 32 min
- **Completed:** 2026-07-19
- **Tasks:** 3
- **Files modified:** 10

## Accomplishments

- Advanced publisher request validation, the isolated one-module mutation adapter, and the workflow from r6/six histories to r7/seven histories without widening credential or mutation reachability.
- Preserved the exact 14 ordered controller/workflow fields for both start-empty HostedPreflight and packet-plus-receipt PublishOne resume, with duplicate environment keys rejected structurally.
- Advanced the hosted controller, active-attempt projection, authorization packet, receipt, handoff, and LibraryOnly fixtures to the fixed r7 contract while retaining UTC, snapshot, LF, no-tags, and production-handoff isolation guards.
- Added a read-only r7 selector that validates seven remote-authoritative tags, rootless attempt-zero, rooted r1-r6 evidence, exact r6 hosted prepare failure, committed-clean 08-17/18 ownership, summary ancestry, and r7 tag/handoff absence.
- Reconfirmed that opposing `core.autocrlf` clean clones produce byte-identical mb-core archives with SHA-256 `8029970aa96774627b0aec5c3b4a9293dbffe428e0b8b1624ff16b0f9a8609b3` under the existing committed LF policy.

## Task Commits

1. **Task 1: Enforce r7 and seven histories in publisher and workflow** — `4b029fb` (RED), `fefa15f` (GREEN)
2. **Task 2: Preserve hosted exact14, snapshot, UTC, LF, no-tags, and isolation protections** — `45c4e47` (RED), `9b563e0` (GREEN)
3. **Task 3: Preserve cross-platform archive identity and add the zero-write r7 pre-live selector** — `17bc9ef` (RED), `4a4e7da` (GREEN)

## Decisions Made

- Kept the workflow dispatch inventory at exactly 14 fields; the seventh history remains represented by the canonical `historical_attempts_sha256` input and is expanded and validated inside the workflow and controller.
- Required r5 and r6 annotated tag objects and peeled sources from one fail-closed remote-tag result; no local or remote-tracking tag is trusted as publication authority.
- Kept attempt-zero rootless and bound to its immutable terminal artifact while requiring state-root containment, locator/index/store digests, and immutable files for every r1-r6 history.
- Reused the already committed `.gitattributes` and cross-platform archive regression unchanged because they already satisfy Plan 08-18's LF and byte-identity contract.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Made `-WorkflowOnly` stop after workflow validation**
- **Found during:** Task 1 GREEN verification
- **Issue:** The switch continued into hosted-controller fixtures, making the task-local workflow gate depend on the still-r6 Task 2 controller.
- **Fix:** Returned after the complete workflow/adapter validation block; `-HostedFieldsOnly` and the full suite continue to exercise hosted behavior separately.
- **Files modified:** `scripts/quality/Test-Phase08LiveSeam.ps1`
- **Verification:** Task 1 WorkflowOnly passed; Task 2 HostedFieldsOnly and full live-seam suites passed.
- **Commit:** `fefa15f`

**Total deviations:** 1 auto-fixed blocking test-routing issue. **Impact:** No production behavior or external-effect boundary changed; verification modes now match their names.

## Issues Encountered

- The first r7 selector GREEN retained the old six-item validation loop after the mechanical stage advance, causing a history-set mismatch. Extending the loop to seven restored the canonical `93523aa1...` set and the complete negative matrix passed.

## Known Stubs

None.

## Verification

- `Test-ReleasePublisherNegative.ps1`: PASS.
- `Test-ReleaseQualificationNegative.ps1`: PASS.
- `Test-Phase08LiveSeam.ps1`: PASS, including WorkflowOnly, HostedFieldsOnly, exact14, duplicate-env, start/resume, snapshot, UTC, and fixed-handoff isolation.
- `Test-Phase08Qualification.ps1`: PASS.
- `Test-MooncakesObservation.ps1`: PASS.
- `Test-CrossPlatformReleaseArchive.ps1`: PASS with byte-identical archive SHA-256 `8029970a...`.
- `Test-Phase08R7PreLive.ps1`: PASS, including remote-tag, rootless/rooted histories, r6 run/job/failure/downstream-zero, committed-clean, summary, tag, handoff, and zero-write negatives.
- `git diff --check`: PASS.
- Schema drift gate: PASS, no drift detected.
- Codebase drift gate: skipped because no structure map exists.
- UI safety gate: PASS, no UI files changed.

## Security and External-Effect Boundary

- Critical/high mitigations cover archive-byte tampering, exact14/env shadowing, history spoofing, fabricated r6 success, hosted evidence disclosure, and pre-live writes.
- No push, fetch, tag creation, workflow dispatch, `gh` invocation, secret access, StateRoot creation, registry request, handoff creation, PublishOne call, mutation, or publication occurred.
- The production `%TEMP%/mnf-phase08-r7-handoff.json` and local `refs/tags/modules-v0.1.0-r7` remained absent.

## TDD Gate Compliance

- Task 1 RED failed with `PUB01-CLOSED` because the publisher did not accept the seventh history; GREEN passed publisher and workflow-only matrices.
- Task 2 RED failed with `P08-R7-HOSTED` because the hosted controller still named r6; GREEN passed hosted and complete qualification/observation suites.
- Task 3 RED failed with `P08-R7-PRELIVE-MISSING`; GREEN passed the cross-platform and full r7 selector matrices.

## Next Phase Readiness

- Plan 08-19 may perform only the separately defined non-publishing hosted preflight path after the orchestrator reviews this committed boundary.
- DIST-01 remains pending until exact live publication and registry-only consumer evidence exist.

## Self-Check: PASSED

- Both created files and all eight modified implementation/test files exist.
- All six RED/GREEN commits exist in order and the complete local verification matrix passes.
- Unrelated user dirt remains unstaged and no production r7 tag or handoff exists.

---
*Phase: 08-ordered-mooncakes-publication-and-registry-consumers*
*Completed: 2026-07-19*
