---
phase: 08-ordered-mooncakes-publication-and-registry-consumers
plan: "29"
subsystem: release-safety
tags: [powershell, git, remote-clone, canonical-ref, zero-publish]
requires:
  - phase: 08-ordered-mooncakes-publication-and-registry-consumers
    provides: "r11 immutable remote tag evidence and the HostedRun clone-policy ref gate"
provides:
  - "A non-overridable boundary wrapper that derives the release ref from clone-local policy."
  - "A default runnable real remote-clone regression for immutable r11 tag identity."
affects: [r12-boundary, HostedRun, release-safety]
tech-stack:
  added: []
  patterns: ["Derive release refs at the clone boundary rather than accepting caller substitutions."]
key-files:
  created: [scripts/quality/Invoke-Phase08R12Boundary.ps1, scripts/quality/Test-Phase08R12Boundary.ps1]
  modified: [scripts/quality/Test-Phase08RemoteCloneRef.ps1]
key-decisions:
  - "The r12 wrapper exposes no ReleaseRef parameter and uses only clone-local policy for the HostedRun invocation."
  - "Immutable r11 remains the real remote-clone regression fixture; r12 creates no tag or release action."
requirements-completed: []
coverage:
  - id: D1
    description: "Canonical clone-policy boundary wrapper rejects tag-identity disagreement before boundary state or provider work."
    verification:
      - kind: integration
        ref: "pwsh -NoProfile -File ./scripts/quality/Test-Phase08R12Boundary.ps1"
        status: pass
    human_judgment: false
  - id: D2
    description: "Disposable real remote clone proves r11 tag object, peel, HEAD, boundary, policy ref, and pre-provider rejection of a derived ref."
    verification:
      - kind: integration
        ref: "pwsh -NoProfile -File ./scripts/quality/Test-Phase08RemoteCloneRef.ps1"
        status: pass
    human_judgment: false
duration: 18min
completed: 2026-07-19
status: complete
---

# Phase 8 Plan 29: r12 Remote-Clone Canonical-Ref Wrapper Summary

**A credential-free r12 boundary wrapper now derives the only release ref from clone-local policy, while real r11 remote-clone coverage proves that identity reaches the provider and rejects substitutions before provider or active-state effects.**

## Performance

- **Duration:** 18 min
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added `Invoke-Phase08R12Boundary.ps1`, which validates policy-selected tag object, peel, detached HEAD, and durable boundary before calling `PrepareAttempt` with the internally derived literal.
- Added TDD coverage that proves the wrapper has no caller-controlled `ReleaseRef` and rejects a mismatching immutable tag before state or provider work.
- Made the real r11 remote-clone suite runnable without arguments and asserted `InitializeBoundary` equals the detached clone HEAD.

## Task Commits

1. **Task 1: Harden the real remote-clone canonical-ref gate** — `ba1cf54` (test)
2. **Task 2 RED: Add failing boundary contract** — `45154c1` (test)
3. **Task 2 GREEN: Create non-overridable r12 boundary invocation contract** — `1158cfc` (feat)

## Files Created/Modified

- `scripts/quality/Invoke-Phase08R12Boundary.ps1` — clone-policy-only r12 boundary wrapper with immutable tag/peel/head validation.
- `scripts/quality/Test-Phase08R12Boundary.ps1` — disposable clone regression for canonical provider propagation and fail-before-state mismatch behavior.
- `scripts/quality/Test-Phase08RemoteCloneRef.ps1` — default real remote r11 identity inputs plus durable boundary assertion.

## Decisions Made

- The wrapper cannot receive a release-ref override; it reads `policy/release-control.json` inside its supplied clone and passes only that value to `PrepareAttempt`.
- No r12 tag, push, dispatch, credentials, Mooncakes request, registry operation, handoff, or publication was performed. r11 remains immutable remote evidence.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Configure identity in the disposable test clone**
- **Found during:** Task 2 GREEN verification.
- **Issue:** The temporary clone had no local Git user identity, so its fixture-only annotated policy tag could not be created.
- **Fix:** Set a fixture-only `user.name` and invalid fixture email in the disposable clone before creating the tag.
- **Files modified:** `scripts/quality/Test-Phase08R12Boundary.ps1`
- **Verification:** The wrapper regression passes without changing global Git configuration or any real tag.
- **Committed in:** `1158cfc`

**Total deviations:** 1 auto-fixed (1 blocking fixture setup)

## Verification

- `pwsh -NoProfile -File ./scripts/quality/Test-Phase08R12Boundary.ps1` — PASS
- `pwsh -NoProfile -File ./scripts/quality/Test-Phase08RemoteCloneRef.ps1` — PASS; object `735ad67910dca97a95cfc1d4e94f6b003bcc3f30`, peel/HEAD/boundary `30479a2546e0fc6416a9a26b10e39ed1f686c860`, one provider call, zero mutation.
- PowerShell parser checks for the wrapper, both tests, and HostedRun — PASS.
- `git diff --check` — PASS.

## Next Phase Readiness

Future r12 boundary work must invoke `Invoke-Phase08R12Boundary.ps1`; it cannot manually assemble or override a release ref. Live release authorization remains pending and outside this plan.

## Self-Check: PASSED

All three scoped scripts and commits `45154c1`, `ba1cf54`, and `1158cfc` exist. No tracked-file deletion was introduced.
