---
phase: 08-ordered-mooncakes-publication-and-registry-consumers
plan: "01"
subsystem: prepared-release-handoff
tags: [powershell, github-actions, prepared-bundle, sha256, release-safety]
requires:
  - phase: 07-release-safety-intent-and-recovery-automation
    provides: Prepared schema, immutable intent, publisher reducer, and hosted secret boundary
provides:
  - Deterministic closed 17-payload prepared release bundle
  - Adversarial fail-closed bundle selector
  - Credential-free hosted preparation and repeated publisher-side validation
affects: [phase-08-live-adapter, phase-08-registry-consumers, phase-09-provenance]
tech-stack:
  added: []
  patterns: [canonical-json-manifest, fixed-payload-inventory, repeated-cross-job-validation]
key-files:
  created:
    - scripts/quality/New-PreparedReleaseBundle.ps1
    - scripts/quality/Test-PreparedReleaseBundle.ps1
  modified:
    - .github/workflows/publish-modules.yml
key-decisions:
  - "Use one fixed ordered 17-payload inventory and treat the manifest digest as artifact identity without self-reference."
  - "Carry the prepared validator inside the bundle so the publisher reruns the identical closed validation before secret materialization."
requirements-completed: [DIST-04]
duration: 24min
completed: 2026-07-18
status: complete
---

# Phase 8 Plan 1: Executable Prepared Release Handoff Summary

**A deterministic 17-payload bundle now binds exact module archives, intent, journal request, policies, schemas, qualification evidence, authority observation, source SHA, toolchain, and run identity before any secret-bearing publisher step.**

## Accomplishments

- Added a deterministic generator that copies only a fixed payload inventory, writes canonical UTF-8 JSON, computes exact sizes and SHA-256 digests, and returns a content-addressed artifact name.
- Added positive and adversarial tests for clean-run equality plus missing, empty, extra, traversal, reordered, digest, size, source, intent, journal, toolchain, self-reference, and secret-material drift.
- Replaced the hosted `{}` placeholder with credential-free qualification, exact module packaging, fixed-input staging, closed validation, and upload only after validation succeeds.
- Made the publisher job verify the artifact digest and rerun the bundled validator with exact dispatch and prior-chain bindings before the environment-secret step.

## Task Commits

1. **Task 1 RED, prepared-bundle boundary:** `5a8cdb7`
2. **Task 1 GREEN, deterministic generator:** `bf7d468`
3. **Task 2, hosted preparation wiring:** `87cacfa`

## Verification

- `pwsh -NoProfile -File scripts/quality/Test-PreparedReleaseBundle.ps1` passed twice from independent disposable roots.
- `pwsh -NoProfile -File scripts/quality/Test-PreparedReleaseBundle.ps1 -WorkflowOnly` passed.
- `pwsh -NoProfile -File scripts/quality/Test-Phase07Qualification.ps1 -WorkflowOnly` passed, preserving the Phase 7 workflow/schema contract.
- Static inspection confirms the prepare job has no environment, secret reference, tag creation, push, workflow dispatch, live adapter, or `moon publish` path.

## Decisions Made

- The payload order is authority-bearing rather than set-like; reordered records fail even when their bytes and digests are otherwise valid.
- Initial publication preparation is the only hosted profile qualified by this plan. Correction preparation fails closed until a future plan supplies fresh correction-specific evidence instead of fabricating it.
- The shared validator is itself an inventoried publisher-script payload, so cross-job validation cannot silently diverge from preparation validation.

## Deviations from Plan

### Auto-fixed Issues

1. **[Rule 1 - Bug] Corrected selector validation parameter routing**
   - **Found during:** Task 1 GREEN
   - **Issue:** The first test run passed the generation-only input root to the validation parameter set and used a literal wildcard in the fixture copy helper.
   - **Fix:** Split generation and validation argument maps and copy fixture children explicitly.
   - **Files modified:** `scripts/quality/Test-PreparedReleaseBundle.ps1`
   - **Verification:** Full adversarial selector passed.
   - **Commit:** `bf7d468`

2. **[Rule 2 - Missing Critical Functionality] Inventoried the shared validator**
   - **Found during:** Task 2
   - **Issue:** Publisher-side repeated validation would otherwise require an untracked or duplicated validator.
   - **Fix:** Added `New-PreparedReleaseBundle.ps1` as the seventeenth closed payload and invoked it after artifact download.
   - **Files modified:** `scripts/quality/New-PreparedReleaseBundle.ps1`, `scripts/quality/Test-PreparedReleaseBundle.ps1`, `.github/workflows/publish-modules.yml`
   - **Verification:** Phase 8 focused and workflow selectors passed.
   - **Commit:** `87cacfa`

3. **[Rule 1 - Regression] Preserved Phase 7 workflow diagnostics**
   - **Found during:** Task 2 regression verification
   - **Issue:** Replacing inline checks removed static compatibility markers required by the Phase 7 workflow contract.
   - **Fix:** Retained exact-inventory enforcement and compatibility aliases while delegating stronger checks to the shared validator.
   - **Files modified:** `.github/workflows/publish-modules.yml`
   - **Verification:** Phase 7 WorkflowOnly selector passed.
   - **Commit:** `87cacfa`

**Total deviations:** 3 auto-fixed: 2 bugs and 1 missing critical validation handoff. **Impact:** All fixes strengthened or preserved the planned fail-closed boundary without adding live mutation.

## Known Stubs

None. The placeholder diagnostic in the selector verifies the old `{}` workflow body is absent; it is not runtime placeholder behavior.

## Next Phase Readiness

- The prepared handoff is ready for the one-module live adapter and explicit first-core authorization checkpoint.
- No tag, workflow dispatch, hosted secret inspection, `moon publish`, or registry mutation occurred.

## Self-Check: PASSED

- Both created scripts and the modified workflow exist.
- Commits `5a8cdb7`, `bf7d468`, and `87cacfa` are present in history.
- All task acceptance criteria and plan-level verification commands pass.

---
*Phase: 08-ordered-mooncakes-publication-and-registry-consumers*
*Completed: 2026-07-18*
