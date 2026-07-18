---
phase: 08-ordered-mooncakes-publication-and-registry-consumers
plan: "05"
subsystem: release-safety
tags: [mooncakes, release-intent, publisher-guard, actor-evidence, tdd]

requires:
  - phase: 08-04
    provides: prepared bundle and isolated one-module live adapter seams
provides:
  - Fresh immutable r1 initial-intent contract with terminal attempt-zero history
  - Closed sanitized tchivs actor evidence required by publisher and live guards
  - Exact-existing zero-mutation checkpoint validation bound to r1 evidence
affects: [08-06, 08-07, 08-08, ordered-publication]

tech-stack:
  added: []
  patterns: [immutable attempt families, closed actor projection, pre-credential validation]

key-files:
  created: []
  modified:
    - policy/release-control.json
    - release/intent/schema.json
    - release/prepared/schema.json
    - scripts/quality/New-ReleaseIntent.ps1
    - scripts/quality/ReleaseQualification.Common.ps1
    - scripts/quality/Invoke-ReleaseQualification.ps1
    - scripts/quality/Invoke-ReleasePublisher.ps1
    - scripts/quality/Invoke-MooncakesLiveMutation.ps1
    - scripts/quality/Test-ReleaseIntent.ps1
    - scripts/quality/Test-ReleasePublisherNegative.ps1

key-decisions:
  - "Keep refs/tags/modules-v0.1.0, source 198436a, and run 29652468948/1 as terminal historical evidence; only refs/tags/modules-v0.1.0-r1 may be current initial authority."
  - "Require the exact closed tchivs whoami projection and prepared-manifest digest before publisher or live mutation eligibility."
  - "Represent exact-existing registry authority as a bound zero-mutation checkpoint that cannot enter the mutation adapter."

patterns-established:
  - "Attempt-family separation: setup failure retries use a fresh immutable initial ref and root, while modules-correction-N remains exclusive to published-content mismatch."
  - "Credential boundary: request, actor, prepared, and reducer bindings validate before credential availability is checked."

requirements-completed: []

coverage:
  - id: D1
    description: "Fresh r1 intent and terminal attempt-zero actor-policy boundary"
    verification:
      - kind: unit
        ref: "pwsh -NoProfile -File scripts/quality/Test-ReleaseIntent.ps1 -ContractOnly"
        status: pass
      - kind: integration
        ref: "pwsh -NoProfile -File scripts/quality/Test-ReleaseIntent.ps1 -Focused and -QualificationIntegration"
        status: pass
    human_judgment: false
  - id: D2
    description: "Prepared, publisher, live, and exact-existing guards accept only the exact r1 static authority boundary"
    verification:
      - kind: unit
        ref: "pwsh -NoProfile -File scripts/quality/Test-ReleasePublisherNegative.ps1"
        status: pass
      - kind: integration
        ref: "pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Required"
        status: pass
    human_judgment: false

duration: 9min
completed: 2026-07-19
status: complete
---

# Phase 08 Plan 05: Static r1 Authority Boundary Summary

**Fresh r1 intent, prepared, actor, publisher, and live guards with immutable failed-attempt history and a zero-mutation exact-existing path**

## Performance

- **Duration:** 9 min
- **Started:** 2026-07-18T18:46:28Z
- **Completed:** 2026-07-18T18:55:24Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments

- Preserved the protected attempt-zero tag, source SHA, and failed hosted run as terminal negative evidence while making `refs/tags/modules-v0.1.0-r1` the only current initial-attempt ref.
- Added one closed sanitized actor projection and propagated exact r1 source/root/current/prepared/actor checks through qualification, publisher, and live mutation validation.
- Added a verified exact-existing authority contract with zero mutation and reordered live validation so all static bindings pass before credential availability is considered.

## Task Commits

Each task followed a RED/GREEN TDD pair:

1. **Task 1 RED: r1 intent and actor contract fixtures** - `b4c14bc` (test)
2. **Task 1 GREEN: fresh r1 intent and actor policy** - `6141680` (feat)
3. **Task 2 RED: r1 publisher guard fixtures** - `61db52c` (test)
4. **Task 2 GREEN: exact static publisher boundary** - `7492d1d` (feat)

## Files Created/Modified

- `policy/release-control.json` - Defines attempt-zero history, current r1 profile, and exact actor policy.
- `release/intent/schema.json` - Restricts initial intents to the fresh r1 ref.
- `release/prepared/schema.json` - Excludes the terminal base ref from prepared publisher bundles.
- `scripts/quality/New-ReleaseIntent.ps1` - Rejects reuse of the terminal attempt-zero source.
- `scripts/quality/ReleaseQualification.Common.ps1` - Validates r1 source separation and the closed actor projection.
- `scripts/quality/Invoke-ReleaseQualification.ps1` - Emits r1 intent and root bindings.
- `scripts/quality/Invoke-ReleasePublisher.ps1` - Requires exact actor/prepared evidence and validates exact-existing checkpoints.
- `scripts/quality/Invoke-MooncakesLiveMutation.ps1` - Requires identical r1 bindings and validates them before credential access.
- `scripts/quality/Test-ReleaseIntent.ps1` - Covers historical/current attempt separation, determinism, and actor ambiguity.
- `scripts/quality/Test-ReleasePublisherNegative.ps1` - Covers publisher/live drift and zero-mutation exact-existing authority.

## Existing Work Attribution

The interrupted commits `89cdf8a`, `9570958`, `2ed9865`, and `198436a` were audited as historical Phase 8/debug context. They did not modify any of the revised plan's ten declared files and are not claimed as revised 08-05 task commits. Commit `6fe0c1f` remains 08-06 hosted-toolchain context and is likewise not claimed here.

## Decisions Made

- The old base ref is retained exactly and never moved, reused, or treated as current authority.
- Actor evidence is an allowlisted classification rather than persisted command output.
- `DIST-01` remains incomplete because this plan performed no live publication or registry observation; `requirements-completed` is intentionally empty.

## Deviations from Plan

None - the revised plan was executed exactly within its ten-file ownership boundary.

## Issues Encountered

The safe-resume audit confirmed the prior interrupted work belonged to the superseded hosted flow rather than the revised static slices. No code was duplicated or reverted.

## Known Stubs

None.

## User Setup Required

None - all work and verification were local, credential-free, and inert.

## Next Phase Readiness

- Plan 08-06 can now bind its clean-clone controller, hosted workflow, observation, and cold-proof fixtures to the exact r1 and actor contracts.
- Live distribution requirements remain intentionally open; no tag, push, workflow dispatch, secret access, registry mutation, or publication occurred.

## Self-Check: PASSED

All ten declared files and all four revised-plan task commits were found. The owned-file stub scan returned no matches.

---
*Phase: 08-ordered-mooncakes-publication-and-registry-consumers*
*Completed: 2026-07-19*
