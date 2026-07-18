---
phase: 08-ordered-mooncakes-publication-and-registry-consumers
plan: "04"
subsystem: live-publication-seam
tags: [mooncakes, powershell, github-actions, secret-isolation, reducer, cold-consumer]
requires:
  - phase: 07-release-safety-intent-and-recovery-automation
    provides: Explicit live authorization guard, monotonic journal reducer, immutable-root workflow
  - phase: 08-ordered-mooncakes-publication-and-registry-consumers
    plans: ["01", "02", "03"]
    provides: Prepared bundle, sanitized observation, and cold registry proof contracts
provides:
  - Reducer-backed single-module live mutation selector
  - Ephemeral pinned-toolchain Mooncakes credential boundary
  - Sanitized publisher-to-observer-to-cold-consumer workflow chain
affects: [08-05-hosted-preflight, 08-06-ordered-publication, phase-09-provenance]
tech-stack:
  added: []
  patterns: [one-call-adapter, reducer-replay, ephemeral-moon-home, sanitized-cross-job-handoff]
key-files:
  created:
    - scripts/quality/Invoke-MooncakesLiveMutation.ps1
    - scripts/quality/Test-Phase08LiveSeam.ps1
  modified:
    - scripts/quality/Invoke-ReleasePublisher.ps1
    - scripts/quality/New-PreparedReleaseBundle.ps1
    - scripts/quality/Test-PreparedReleaseBundle.ps1
    - scripts/quality/Test-Phase07Qualification.ps1
    - .github/workflows/publish-modules.yml
key-decisions:
  - "Replay every supplied checkpoint through the Phase 7 reducer before deriving the next module."
  - "Expose the token only through one temporary credentials file under a child-only MOON_HOME and persist only an allowlisted classification."
  - "Carry the tracked live adapter as the eighteenth exact prepared payload so the publisher remains artifact-only."
requirements-completed: []
metrics:
  duration: 29min
  completed: 2026-07-18
  tasks: 3
  files: 7
status: complete
---

# Phase 8 Plan 4: One-Step Mooncakes Live Seam Summary

**A reducer-backed adapter can now attempt exactly one dependency-safe prepared module under an ephemeral credential boundary, then hand only a sanitized outcome to separate credential-free observation and cold-consumer jobs.**

## Performance

- **Duration:** 29 minutes
- **Started:** 2026-07-18T11:17:50Z
- **Completed:** 2026-07-18T11:46:51Z
- **Tasks:** 3
- **Files:** 7

## Accomplishments

- Added a tracked one-step adapter that replays journal records through the Phase 7 reducer, accepts only exact content-addressed live registry proofs, and selects core, color, or image without a module loop.
- Revalidated the prepared bundle immediately before mutation, expanded only the selected exact archive, bound the pinned toolchain, and invoked one `moon publish --frozen` child classification.
- Materialized the fixture token only in a disposable `MOON_HOME` credential file, excluded it from arguments/results/prepared files, and proved teardown on success and failure.
- Routed `LiveOneStep` through the tracked adapter and extended the closed prepared artifact from 17 to 18 exact payloads so the isolated publisher does not depend on a checkout.
- Added ordered publisher, credential-free observer, and cold-consumer jobs with step-only secret mapping, sanitized output, exact source checkout, and full-SHA action pins.

## Task Commits

1. **Task 1 RED: failing live seam contract** - `a8389e1`
2. **Task 1 GREEN: single-module eligibility and secret isolation** - `30c07db`
3. **Task 2: ephemeral one-step publisher integration** - `f3d757a`
4. **Task 3: mutation-to-observation/cold-proof workflow** - `8c77382`

## Verification

- `pwsh -NoProfile -File scripts/quality/Test-Phase08LiveSeam.ps1` - PASS
- `pwsh -NoProfile -File scripts/quality/Test-PreparedReleaseBundle.ps1` - PASS
- `pwsh -NoProfile -File scripts/quality/Test-Phase07Qualification.ps1 -WorkflowOnly` - PASS
- `pwsh -NoProfile -File scripts/quality/Test-ReleasePublisherNegative.ps1` - PASS
- `pwsh -NoProfile -File scripts/quality/Test-MooncakesObservation.ps1` - PASS
- `pwsh -NoProfile -File scripts/quality/Test-ColdRegistryConsumer.ps1` - PASS
- `git diff --check` - PASS

The broader Phase 7 `-Focused` selector reaches its immutable ledger check and reports the expected `publisher-workflow` digest drift. Its workflow and reducer contracts pass independently; the historical Phase 7 artifact digest was intentionally not rewritten by Phase 8.

## Decisions Made

- The adapter does not infer eligibility from a terminal state string alone. It reconstructs every command and requires the exact canonical reducer hash at each transition.
- A completed cold proof must be marked `live_registry`, retain exact field order, prove all isolation flags and four runtime targets, and match its own canonical content digest.
- Missing or unavailable structured public surfaces stop the credential-free observation job. They cannot become absence, exactness, retry authority, or downstream publication.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical Functionality] Added the live adapter to the prepared inventory**

- **Found during:** Task 2
- **Issue:** The artifact-only publisher had no checkout and the 17-payload bundle did not carry the new tracked adapter, making the live seam unreachable.
- **Fix:** Added the adapter as an exact eighteenth payload and updated preparation plus deterministic inventory tests.
- **Files modified:** `scripts/quality/New-PreparedReleaseBundle.ps1`, `scripts/quality/Test-PreparedReleaseBundle.ps1`, `.github/workflows/publish-modules.yml`
- **Verification:** Prepared-bundle adversarial selector and live-seam selector pass.
- **Commit:** `f3d757a`, completed in workflow by `8c77382`

**2. [Rule 1 - Regression] Scoped the Phase 7 publisher static check to its job**

- **Found during:** Task 3 regression verification
- **Issue:** The historical selector treated every later workflow job as part of `publisher`, so the new credential-free observer checkout appeared to grant checkout permission to the publisher.
- **Fix:** Bounded extraction at the next job while preserving the original publisher permission assertions.
- **Files modified:** `scripts/quality/Test-Phase07Qualification.ps1`
- **Verification:** `-WorkflowOnly` passes and the observer/consumer secret-isolation checks pass.
- **Commit:** `8c77382`

**Total deviations:** 2 auto-fixed: 1 missing critical artifact handoff and 1 regression in historical static job scoping. **Impact:** Both preserve the intended artifact-only and least-privilege boundaries without any live action.

## Known Stubs

None. The structured-public-surface availability gate is an intentional fail-closed injected boundary: unavailable surfaces stop before proof or downstream eligibility rather than fabricate live evidence.

## Threat Flags

No unmodeled trust boundary was introduced. The credential file, prepared/journal inputs, sanitized mutation outcome, and observation/consumer handoffs are the four plan-modeled boundaries and are covered by adversarial fixtures.

## Live Requirement Status

`DIST-01`, `DIST-02`, `DIST-03`, `DIST-04`, and `PROV-05` remain pending. This plan produced fixture evidence only and made no tag, dispatch, secret access, credential use, registry request, or Mooncakes mutation.

## Next Phase Readiness

- Plan 08-05 can add the exact hosted dry-run/native-preflight packet and explicit operator checkpoint against this one-step seam.
- A non-dry publication remains unreachable without explicit authorization, exact prepared/journal eligibility, and the environment-scoped credential.

## Self-Check: PASSED

- Both created selectors and the modified workflow exist.
- Commits `a8389e1`, `30c07db`, `f3d757a`, and `8c77382` exist in history.
- All Plan 04 acceptance selectors and plan-level regression commands pass.

---
*Phase: 08-ordered-mooncakes-publication-and-registry-consumers*
*Completed: 2026-07-18*
