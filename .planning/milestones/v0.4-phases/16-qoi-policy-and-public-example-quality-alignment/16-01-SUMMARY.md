---
phase: 16-qoi-policy-and-public-example-quality-alignment
plan: "01"
subsystem: quality-policy
tags: [moonbit, qoi, policy, powershell, public-example, isolation]
requires:
  - phase: 14-canonical-qoi-encode-and-four-target-vectors
    provides: Public QOI encoder/decoder package and generated interface baseline
  - phase: 15-public-qoi-processing-example
    provides: qoi-portable public consumer and deterministic four-target evidence
provides:
  - Exact candidate-policy inventory for tchivs/mb-image/qoi
  - Scoped QOI policy assertions and fail-closed drift fixtures
  - An isolated four-target QOI public-example quality lane
affects: [foundation-policy, moon-quality, public-examples, qoi]
tech-stack:
  added: []
  patterns: [scoped policy helper, exact package inventory filtering, fail-fast lane isolation]
key-files:
  created: []
  modified:
    - policy/foundation.json
    - scripts/quality/Assert-Policy.ps1
    - scripts/quality/Invoke-MoonQuality.ps1
    - scripts/quality/Test-PublicExamples.ps1
key-decisions:
  - "The Qoi lane is independently callable and never delegates to broad foundation, image-negative, qualification, registry, release, publication, or credential routes."
  - "The inherited mb-image ops import-policy drift remains outside this QOI-only plan and is recorded rather than changed or suppressed."
patterns-established:
  - "Scoped policy helpers select one public package and assert its exact source, interface, target, and file inventory."
  - "Isolation proofs use forbidden-stage traps plus an explicit workspace execution trace."
requirements-completed: [QOI-05, QOI-06]
coverage:
  - id: D1
    description: Exact QOI package policy inventory and deterministic policy-drift rejection.
    requirement: QOI-05
    verification:
      - kind: integration
        ref: "Assert-QoiFoundationPolicy and Assert-QoiQualificationNegativeFixtures"
        status: pass
    human_judgment: false
  - id: D2
    description: Isolated qoi-portable public consumer evidence on js, wasm, wasm-gc, and native.
    requirement: QOI-06
    verification:
      - kind: e2e
        ref: "pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Qoi"
        status: pass
    human_judgment: false
metrics:
  duration: 10min
  completed: 2026-07-20
status: complete
---

# Phase 16 Plan 01: QOI policy and public example quality alignment Summary

**Exact QOI package policy, fail-closed scoped drift checks, and an isolated four-target qoi-portable quality lane.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-07-20T12:26:14Z
- **Completed:** 2026-07-20T12:36:48Z
- **Tasks:** 3/3
- **Files modified:** 4

## Accomplishments

- Added the candidate `tchivs/mb-image/qoi` policy record with all eleven imports, four targets, source order, compiler-derived interface, and nine QOI files.
- Added exact scoped QOI policy and negative-fixture helpers without routing the Qoi lane through the unrelated broad image checks.
- Added `Invoke-MoonQuality -Lane Qoi`, four-target qoi-portable verification, and a fail-fast isolation proof for qualification and release-governance paths.

## Task Commits

1. **Task 1: Add the exact QOI record to the foundation policy** — `a3b6f86` (feat)
2. **Task 2: Make foundation policy assertions fail closed for the QOI inventory** — `8e3a540` (feat)
3. **Task 3: Add the bounded QOI public-example quality path** — `e44de6a` (feat)

## Files Created/Modified

- `policy/foundation.json` — exact QOI public-package and publication inventory.
- `scripts/quality/Assert-Policy.ps1` — full workspace QOI membership plus scoped QOI policy and negative helpers.
- `scripts/quality/Invoke-MoonQuality.ps1` — bounded Qoi route, QOI package-list filter, and lane-isolation proof.
- `scripts/quality/Test-PublicExamples.ps1` — qoi workspace selection, four-target evidence, and isolation probe trace.

## Decisions Made

- The Qoi lane uses only QOI helpers and the qoi public example; it does not call broad qualification, registry, reporting, release, publication, or credential paths.
- Qualification-schema parsing is limited to `-Mode qualify`; the qoi workspace route has no qualification-state read or invocation.
- The existing non-QOI ops policy mismatch remains intentionally untouched per the locked phase boundary.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Made the workspace isolation trace capturable by the proof.**
- **Found during:** Task 3
- **Issue:** `Write-Host` did not enter the proof's captured output stream, so the trace assertion could not observe the otherwise-correct QOI workspace route.
- **Fix:** Emitted the isolation trace with `Write-Output`.
- **Files modified:** `scripts/quality/Test-PublicExamples.ps1`
- **Verification:** `Assert-QoiLaneIsolation` passes.
- **Committed in:** `e44de6a`

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** The proof now deterministically observes the direct workspace route; no scope expansion occurred.

## Issues Encountered

- `Assert-FoundationPolicy -PolicyPath policy/foundation.json` has a pre-existing non-QOI failure: `modules/mb-image/ops/moon.pkg` declares 12 imports while the unchanged ops policy allowlist has 10. The locked context excludes reconciling older ops inventory drift, so this plan retains the full assertion's QOI updates and verifies the new scoped QOI helpers/lane independently. The mismatch was reproduced after all QOI verification and was neither modified nor suppressed.

## Verification

- `moon -C modules/mb-image info --target all --frozen` — pass.
- `Assert-QoiFoundationPolicy -PolicyPath policy/foundation.json` and `Assert-QoiQualificationNegativeFixtures -PolicyPath policy/foundation.json` — pass.
- `pwsh -NoProfile -File scripts/quality/Test-PublicExamples.ps1 -Example qoi -Mode workspace -Target all` — pass.
- `Assert-QoiLaneIsolation` — pass.
- `pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Qoi` — pass.

## Known Stubs

None.

## Self-Check: PASSED

- Summary file and all three task commits are present.

## Next Phase Readiness

The QOI package and public consumer now have a bounded, reproducible quality path. A separate non-QOI policy reconciliation is needed before the broad foundation assertion can pass again.

---
*Phase: 16-qoi-policy-and-public-example-quality-alignment*
*Completed: 2026-07-20*
