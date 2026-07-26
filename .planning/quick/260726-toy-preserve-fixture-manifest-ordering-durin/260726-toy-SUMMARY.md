---
phase: quick-260726-toy
plan: 01
subsystem: fixture-generation
tags: [powershell, color, fixtures, manifest, determinism]

requires:
  - phase: quick-260726-sss
    provides: Required-lane evidence identifying Color manifest regeneration as the next blocker
provides:
  - Position-preserving replacement of Color-owned fixture manifest records
  - Fail-closed duplicate detection and deterministic missing-record insertion
  - Production-owned merge-helper self-test and byte-level idempotence evidence
affects: [required-quality, color-fixtures, fixture-manifest]

tech-stack:
  added: []
  patterns:
    - In-memory owned-record merge helpers preserve foreign object identity and order
    - Generator self-tests exercise production merge policy without file I/O

key-files:
  created:
    - .planning/quick/260726-toy-preserve-fixture-manifest-ordering-durin/260726-toy-SUMMARY.md
  modified:
    - scripts/fixtures/Generate-ColorVectors.ps1

key-decisions:
  - "Replace each existing Color-owned manifest record in place and append only missing owned records in canonical sRGB-then-derived order."
  - "Treat duplicate owned IDs as an exact, ID-specific failure rather than selecting an arbitrary record."

patterns-established:
  - "Composable fixture generation: generators preserve every foreign manifest record and its relative position."

requirements-completed: []

coverage:
  - id: D1
    description: Color regeneration preserves foreign manifest ordering while canonically replacing its two owned records.
    verification:
      - kind: integration
        ref: "Generate-ColorVectors.ps1 two-pass disposable-checkout hash comparison"
        status: pass
      - kind: integration
        ref: "pwsh -NoProfile -File ./scripts/fixtures/Generate-ColorVectors.ps1 -Artifacts all -Check"
        status: pass
    human_judgment: false
  - id: D2
    description: Duplicate and missing Color record cases fail closed or merge deterministically through the production helper.
    verification:
      - kind: unit
        ref: "pwsh -NoProfile -File ./scripts/fixtures/Generate-ColorVectors.ps1 -ManifestSelfTest"
        status: pass
    human_judgment: false

duration: 4min
completed: 2026-07-26
status: complete
---

# Quick 260726-toy: Preserve Color Fixture Manifest Ordering Summary

**Color fixture regeneration now replaces owned records in place, preserves unrelated manifest ordering and identity, and remains byte-idempotent across repeated generation.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-07-26T13:31:44Z
- **Completed:** 2026-07-26T13:34:46Z
- **Tasks:** 2
- **Files modified:** 1 source file plus this summary

## Accomplishments

- Added `Merge-ColorManifestRecords`, which preserves foreign record objects and positions while replacing existing Color records at their original indexes.
- Added exact duplicate-ID rejection and deterministic insertion of missing sRGB and derived records.
- Added a no-write `-ManifestSelfTest` seam covering duplicate, missing, identity/order, serialized-value, and complete-input idempotence cases.
- Proved the canonical seven artifacts remain byte-identical through two generations and the exact focused COLR check.

## Task Commit

1. **Task 1: Replace owned Color manifest records in place** — `f11d085` (`fix`)
2. **Task 2: Prove the focused COLR gate and record the quick** — verification complete; summary intentionally uncommitted per plan

## Verification Evidence

- `pwsh -NoProfile -File ./scripts/fixtures/Generate-ColorVectors.ps1 -ManifestSelfTest`
  - Exit 0
  - Printed `Color manifest self-test passed.`
- Disposable exact checkout:
  - First generation did not change any of the seven canonical artifact hashes.
  - Second generation was byte-identical to the first.
  - `-Artifacts all -Check` passed for all seven artifacts.
  - Disposable worktree `artifact-ec50c17e635a42db8520978910a0cfe7` was restored clean and removed.
- Focused COLR command:
  - `pwsh -NoProfile -File ./scripts/fixtures/Generate-ColorVectors.ps1 -Artifacts all -Check`
  - Exit 0; every Color fixture and generated MoonBit vector reported byte-identical.
- Fixture policy:
  - `pwsh -NoProfile -File ./scripts/quality/Test-FixturePolicy.ps1`
  - Exit 0; printed `Fixture identity and containment matrix passed.`
- Artifact diff:
  - `git diff --exit-code -- fixtures/manifest.json fixtures/color modules/mb-color/*/reference_vectors_wbtest.mbt`
  - Exit 0.
- Manifest SHA-256 before and after: `1b4707387339e2b339915575f2c040650074c51fb98989e5b6b3d697c32a3e7d`.
- `git diff --check` passed.

## Files Created/Modified

- `scripts/fixtures/Generate-ColorVectors.ps1` — position-preserving merge policy and guarded production self-test.
- `.planning/quick/260726-toy-preserve-fixture-manifest-ordering-durin/260726-toy-SUMMARY.md` — execution and verification evidence.

## Decisions Made

- Existing owned records are replaced at their observed indexes; missing records are appended only after the ordered walk.
- Foreign records pass through by object reference, preventing accidental reconstruction or field-order changes.
- Duplicate owned IDs are rejected with the exact duplicate ID in the error.

## Deviations from Plan

None — plan executed as specified.

## Issues Encountered

- The first self-test run exposed a nested PowerShell array return shape. The helper was corrected to return the merged record sequence, after which all self-tests and artifact checks passed.

## User Setup Required

None.

## Known Stubs

None.

## Threat Flags

None — the change introduces no network, authentication, filesystem-boundary, or schema trust surface.

## Self-Check: PASSED

- Source commit `f11d0853d3120fa8b6524287d223fb3beea9d486` resolves.
- Modified generator and this summary exist.
- Manifest hash and all stated verification commands were confirmed from the isolated worktree.

## Next Step

The Color generated-evidence blocker is cleared and quick `260726-sss` can resume its detached Required qualification.
