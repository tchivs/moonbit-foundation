---
phase: 06-namespace-authority-and-compatibility-contract
plan: "25"
subsystem: release-qualification
tags: [moonbit, namespace, manifests, release-policy, qualification]
requires:
  - phase: 06-namespace-authority-and-compatibility-contract
    provides: canonical tchivs policy and module roots from plans 06-07, 06-09, and 06-12
provides:
  - Repository-correct canonical manifests for tchivs/mb-core, tchivs/mb-color, and tchivs/mb-image
  - Shared positive qualification constants aligned with the active tchivs source graph
affects: [06-13, release-qualification, publication-readiness]
tech-stack:
  added: []
  patterns: [policy-projected-repository-metadata, canonical-positive-qualification-constants]
key-files:
  created:
    - .planning/phases/06-namespace-authority-and-compatibility-contract/06-25-SUMMARY.md
  modified:
    - modules/mb-core/moon.mod.json
    - modules/mb-color/moon.mod.json
    - modules/mb-image/moon.mod.json
    - scripts/quality/ReleaseQualification.Common.ps1
key-decisions:
  - "Treat https://github.com/tchivs/moonbit-foundation as intended metadata only; this credential-free repair makes no external liveness or authority claim."
patterns-established:
  - "Qualification constants must project the exact active policy owner, dependency DAG, publication order, and repository metadata before the positive path runs."
requirements-completed: [COMP-01, COMP-02, COMP-03, COMP-04, PROV-03]
coverage:
  - id: D1
    description: The three canonical module manifests project the exact intended tchivs repository while preserving identity and version floors
    requirement: COMP-03
    verification:
      - kind: integration
        ref: PowerShell manifest-to-policy repository, name, and version projection command
        status: pass
    human_judgment: false
  - id: D2
    description: Shared qualification constants accept the canonical tchivs graph with publication still credential-free and blocked
    requirement: PROV-03
    verification:
      - kind: integration
        ref: pwsh Invoke-ReleaseQualification.ps1 -Check -StaticOnly
        status: pass
      - kind: integration
        ref: PowerShell stale old-owner and repository literal scan
        status: pass
    human_judgment: false
duration: 13m
completed: 2026-07-17
status: complete
---

# Phase 6 Plan 25: Canonical Metadata Prerequisite Repair Summary

**Three canonical manifests and the shared release validator now agree on the exact `tchivs/*` identity graph and intended repository metadata without claiming external liveness.**

## Performance

- **Duration:** 13m
- **Started:** 2026-07-17T10:53:00Z
- **Completed:** 2026-07-17T11:06:27Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Reconciled all three module manifest repository fields with active foundation and release policy while preserving their `tchivs/*@0.1.0` identities and dependency floors.
- Rebased the shared validator's canonical higher-layer matchers, PPM package/import contract, repository assertion, publication order, and dependency graph onto `tchivs/*`.
- Passed the real static release-policy qualification with publication still non-executing, credential-free, namespace-unverified, and explicitly blocked.

## Task Commits

Each task was committed atomically:

1. **Task 1: Reconcile the three manifest repository fields** - `e16c51b` (fix)
2. **Task 2: Reconcile shared positive qualification constants** - `db40f92` (fix)

## Files Created/Modified

- `modules/mb-core/moon.mod.json` - Intended `tchivs` repository metadata for the leaf module.
- `modules/mb-color/moon.mod.json` - Intended `tchivs` repository metadata for the middle module.
- `modules/mb-image/moon.mod.json` - Intended `tchivs` repository metadata for the top module.
- `scripts/quality/ReleaseQualification.Common.ps1` - Canonical `tchivs/*` qualification constants and matchers.
- `.planning/phases/06-namespace-authority-and-compatibility-contract/06-25-SUMMARY.md` - Execution evidence and 06-13 handoff.

## Decisions Made

- The repository URL remains intended metadata only. No repository was created, contacted, authenticated, or represented as live.
- Existing rule IDs, exact set/sequence checks, blocked publication outcomes, and credential-free behavior remain unchanged.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected inconsistent GSD state progress after out-of-order repair completion**

- **Found during:** Plan metadata synchronization.
- **Issue:** `state.advance-plan` updated the structured total to 25 but left prose counters at 24, and `state.update-progress` could not recognize the structured progress block, producing `percent: 0`.
- **Fix:** Reconciled `STATE.md` to the verified 9/25 summary count, 36% progress, and the repaired graph's next step at 06-13 Task 2.
- **Files modified:** `.planning/STATE.md`.
- **Verification:** `ROADMAP.md` independently reports 9/25 and marks 06-25 complete; disk contains nine Phase 6 summaries.

---

**Total deviations:** 1 auto-fixed state-synchronization bug.
**Impact on plan:** Source scope and qualification behavior are unchanged; planning metadata now reflects the actual completed-plan count.

## Issues Encountered

- The GSD progress updater did not recognize this repository's structured `progress` frontmatter; the resulting metadata inconsistency was corrected and verified against summaries on disk.

## User Setup Required

None - this prerequisite repair is credential-free and performs no external mutation.

## Verification

- Exact manifest-to-policy repository, name, and version assertions passed for all three modules.
- The shared helper contains no obsolete canonical module or repository literal.
- `Invoke-ReleaseQualification.ps1 -Check -StaticOnly` passed its closed module, manifest, dependency, content, provenance, outcome, and post-publication-order checks.
- `git diff --check` passed.
- The two task commits contain exactly the four declared source files.
- The uncommitted 06-13 Task 2 scripts and pre-existing governance changes retained their original SHA-256 hashes and were never staged.

## Known Stubs

None.

## Next Phase Readiness

- Plan 06-13 can resume at Task 2 using the canonical prerequisite graph and its preserved partial commit `9f05754`.
- Live Mooncakes authority and repository liveness remain intentionally unverified and must be handled only by their explicit later gates.

## Self-Check: PASSED

- All four declared source files and this summary exist.
- Task commits `e16c51b` and `db40f92` are present in git history.
- Coverage metadata classifies both deliverables as fully automated and passing.
- No stub pattern or unplanned threat surface was introduced.

---
*Phase: 06-namespace-authority-and-compatibility-contract*
*Completed: 2026-07-17*
