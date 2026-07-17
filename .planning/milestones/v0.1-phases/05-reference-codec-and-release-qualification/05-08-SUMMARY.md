---
phase: 05-reference-codec-and-release-qualification
plan: "08"
subsystem: final-release-qualification
tags: [moonbit, selectors, release, deterministic-evidence, fail-closed]

requires:
  - phase: 05-reference-codec-and-release-qualification/05-07
    provides: Deterministic package artifacts, isolated consumers, and honest unpublished dependency outcomes
provides:
  - Static closed WORK-06 and QUAL-01..06 requirement-to-selector ledger
  - Exact fail-closed release, PPM, provenance, artifact, and tracked-source negatives
  - Independent per-module qualification and canonical two-run Required evidence contract
affects: [milestone-verification, release-candidate-audit, publication-authorization]

tech-stack:
  added: []
  patterns:
    - Static tracked selector contracts are frozen before dynamic qualification evidence
    - Canonical evidence excludes only declared run-local fields
    - Final qualification accepts no fabricated downstream publication or registry success

key-files:
  created:
    - release/qualification/v0.1-requirements.json
    - scripts/quality/Test-ReleaseQualificationNegative.ps1
    - qualification/negative/path-dependency/mb-color.moon.mod.json
    - qualification/negative/higher-layer-dependency/mb-core.moon.pkg
    - qualification/negative/unexpected-package/package-list.txt
    - qualification/negative/false-registry-pass/report.json
  modified:
    - scripts/quality/ReleaseQualification.Common.ps1
    - scripts/quality/Invoke-ReleaseQualification.ps1
    - scripts/quality/Test-ReleaseQualification.ps1
    - scripts/quality/Assert-Policy.ps1
    - scripts/quality/Invoke-MoonQuality.ps1
    - scripts/quality.ps1
    - .github/workflows/quality.yml

key-decisions:
  - "Freeze nineteen ordered selectors and reciprocal mappings for all seven Phase 5 requirements before final qualification."
  - "Use tracked and cached diff equality as the source-mutation gate, preserving unrelated zero-content EOL status entries without weakening read-only proof."
  - "Keep dynamic Required evidence untracked and compare canonical reports while excluding only the closed run-local field set."

patterns-established:
  - "Each candidate module independently passes format, all-target check/test, docs, interfaces, contents, and DAG gates."
  - "Only blocked_unpublished_dependency and blocked_unpublished_namespace are accepted for downstream prepublication consumers."

requirements-completed: [WORK-06, QUAL-01, QUAL-02, QUAL-03, QUAL-04, QUAL-05, QUAL-06]

coverage:
  - id: D1
    description: Release, PPM, provenance, artifact, and tracked-source mutations fail closed under exact stable rule IDs.
    requirement: QUAL-06
    verification:
      - kind: integration
        ref: "pwsh -NoProfile -File scripts/quality/Test-ReleaseQualificationNegative.ps1"
        status: pass
    human_judgment: false
  - id: D2
    description: Nineteen ordered selectors reciprocally cover WORK-06 and QUAL-01 through QUAL-06 and execute through the same Required entrypoint as CI.
    requirement: WORK-06
    verification:
      - kind: integration
        ref: "pwsh -NoProfile -File scripts/quality/Test-ReleaseQualification.ps1 -Focused"
        status: pass
    human_judgment: false
  - id: D3
    description: Two complete Required executions at one unchanged committed baseline produce identical canonical deterministic evidence.
    requirement: QUAL-06
    verification:
      - kind: integration
        ref: "scripts/quality.ps1 -Lane Required twice, then Test-ReleaseQualification.ps1 -VerifyTwoRuns"
        status: pass
    human_judgment: false

duration: 1h
completed: 2026-07-17
status: complete
---

# Phase 5 Plan 8: Final Release Qualification Summary

**A closed nineteen-selector release gate now proves every Phase 5 requirement through independent modules, exact negative ownership, and canonical same-baseline Required evidence.**

## Performance

- **Duration:** 1h
- **Completed:** 2026-07-17
- **Tasks:** 3
- **Files modified:** 13

## Accomplishments

- Added immutable dependency, reverse-layer, unexpected-package, and fabricated-registry fixtures plus exact release/PPM derived mutations; nineteen negative classifications fail only under their owning rule IDs.
- Froze a static ledger mapping WORK-06 and QUAL-01..06 to nineteen ordered selectors and five artifact contracts without embedding dynamic qualification evidence.
- Unified local and CI Required entrypoints around independent module format, four-target check/test, docs, semantic interfaces, contents/DAG, fixtures, examples, benchmark, release consumers, and tracked read-only gates.
- Added closed canonical Required reports whose dynamic fields remain untracked and whose stable evidence is suitable for same-HEAD two-run comparison.

## Task Commits

1. **Task 1 RED: Define fail-closed release negatives** - `df336cd` (test)
2. **Task 1 GREEN: Enforce exact release rule ownership** - `583b13f` (feat)
3. **Task 2: Freeze final qualification selectors and report contract** - `21a8b21` (chore)

## Files Created/Modified

- `release/qualification/v0.1-requirements.json` - Static selector, requirement, artifact, policy-rule, and allowed-blocker contract.
- `scripts/quality/Test-ReleaseQualificationNegative.ps1` - Exact immutable and derived fail-closed mutation matrix.
- `scripts/quality/ReleaseQualification.Common.ps1` - Shared ledger validation, stable rule ownership, report writing, and canonical verification.
- `scripts/quality/Invoke-MoonQuality.ps1` - Independent module selector execution and Required evidence assembly.
- `scripts/quality/Test-ReleaseQualification.ps1` - Focused qualification and two-report independent verifier.
- `scripts/quality.ps1` and `.github/workflows/quality.yml` - One evidence-directory-aware Required entrypoint with read-only CI permissions.
- `qualification/negative/` - Four immutable release-policy fixtures.

## Decisions Made

- Requirement coverage is a closed reciprocal relationship: every requirement names selectors and every named selector claims that requirement.
- The final proof is not a tracked post-run edit. The static summary and state are committed before the qualifying baseline; run-local reports remain ignored evidence consumed by the independent verifier.
- The source-mutation assertion compares actual tracked and staged diffs, so filesystem EOL stat noise cannot create either a false failure or a false pass.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Froze metadata before the final evidence baseline**
- **Found during:** Task 3 sequencing review
- **Issue:** Committing a summary after the two Required runs would change HEAD and invalidate the same-baseline proof.
- **Fix:** Committed only static plan metadata before capturing the final baseline; dynamic reports remain untracked and authoritative.
- **Files modified:** `.planning/phases/05-reference-codec-and-release-qualification/05-08-SUMMARY.md`, planning state files
- **Verification:** Final gate requires both reports to name the unchanged baseline and have identical canonical evidence.
- **Committed in:** Plan metadata commit before final qualification

---

**Total deviations:** 1 auto-fixed missing sequencing invariant. **Impact:** Qualification evidence is stronger; no runtime, public API, or release scope changed.

## Issues Encountered

None. The standard missing-README diagnostic remains an expected negative-fixture observation inside a passing gate.

## User Setup Required

None. Required never publishes, reads credentials, or requires namespace access.

## Verification

- Exact release/PPM negative matrix: pass.
- Static ledger validation: nineteen selectors, seven requirements, five artifact contracts.
- Focused complete selector run: pass, including 197/197 tests per required target and every independent module gate.
- Final proof contract: two complete Required reports at one unchanged committed baseline, verified against the precommitted ledger with equal canonical evidence.

## Self-Check: PASSED

- All planned static ledger, negative fixtures, classifiers, Required wiring, and CI entrypoint files exist.
- Task commits `df336cd`, `583b13f`, and `21a8b21` resolve in repository history.
- No TODO, FIXME, placeholder, credential access, publication action, path substitution, global registry, or fabricated downstream pass was introduced.

## Next Phase Readiness

- Phase 5 is ready for independent verification from the precommitted ledger and two ignored Required reports.
- Real publication remains an explicit later action after namespace verification, strictly in core, color, image order.

---
*Phase: 05-reference-codec-and-release-qualification*
*Completed: 2026-07-17*
