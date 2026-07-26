---
phase: quick-260726-u7d
plan: 01
subsystem: fixture-generation
tags: [powershell, ppm, image, fixtures, manifest, determinism]

requires:
  - phase: quick-260726-toy
    provides: Position-preserving Color manifest generation and evidence exposing the PPM reorder
provides:
  - Position-preserving replacement of the PPM-owned fixture manifest record
  - Fail-closed duplicate detection and deterministic missing-record insertion
  - Production-owned PPM merge self-test and byte-level idempotence evidence
affects: [required-quality, image-fixtures, ppm, fixture-manifest]

tech-stack:
  added: []
  patterns:
    - In-memory single-owner manifest merges preserve foreign object identity and order
    - Generator self-tests exercise production merge policy without file I/O

key-files:
  created:
    - .planning/quick/260726-u7d-preserve-fixture-manifest-ordering-durin/260726-u7d-SUMMARY.md
  modified:
    - scripts/fixtures/Generate-PpmVectors.ps1

key-decisions:
  - "Replace an existing PPM-owned manifest record at its observed index and append only when absent."
  - "Reject a second PPM-owned record with an exact ID-specific error instead of rebuilding or sorting the manifest."

patterns-established:
  - "Composable PPM generation: all foreign manifest records pass through unchanged and in order."

requirements-completed: []

coverage:
  - id: D1
    description: PPM regeneration preserves all foreign manifest records while replacing its owned record in place.
    verification:
      - kind: integration
        ref: "Generate-PpmVectors.ps1 two-pass disposable-checkout hash comparison"
        status: pass
      - kind: integration
        ref: "Generate-ImageVectors.ps1 -Check then Generate-PpmVectors.ps1 -Check"
        status: pass
    human_judgment: false
  - id: D2
    description: Duplicate and missing PPM record cases fail closed or merge deterministically through the production helper.
    verification:
      - kind: unit
        ref: "pwsh -NoProfile -File ./scripts/fixtures/Generate-PpmVectors.ps1 -ManifestSelfTest"
        status: pass
    human_judgment: false

duration: 5min
completed: 2026-07-26
status: complete
---

# Quick 260726-u7d: Preserve PPM Fixture Manifest Ordering Summary

**PPM fixture regeneration now replaces its owned record in place, preserves every foreign manifest record, and remains byte-idempotent across repeated generation.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-07-26T13:44:00Z
- **Completed:** 2026-07-26T13:48:45Z
- **Tasks:** 2
- **Files modified:** 1 source file plus this summary

## Accomplishments

- Added `Merge-PpmManifestRecord`, which passes foreign records through by identity and replaces the canonical PPM record at its original index.
- Added exact duplicate-ID rejection and deterministic append behavior when the PPM record is absent.
- Added a guarded no-write `-ManifestSelfTest` covering duplicate, missing, identity/order, serialized-value, replacement-position, and complete-input idempotence cases.
- Proved the Image → PPM generated-evidence sequence and fixture policy against unchanged canonical bytes.

## Task Commit

1. **Task 1: Replace the owned PPM manifest record in place** — `3e8229f` (`fix`)
2. **Task 2: Prove the focused IMAG generator sequence and record completion** — verification complete; summary intentionally uncommitted per plan

## Verification Evidence

- `pwsh -NoProfile -File ./scripts/fixtures/Generate-PpmVectors.ps1 -ManifestSelfTest`
  - Exit 0
  - Printed `PPM manifest self-test passed.`
- Disposable exact checkout:
  - First PPM generation did not change either canonical artifact hash.
  - Second PPM generation was byte-identical to the first.
  - `Generate-PpmVectors.ps1 -Check` exited 0.
  - Disposable worktree `artifact-596e3751773a459db16fc2802328d105` was restored clean and removed.
- Focused IMAG sequence:
  - `pwsh -NoProfile -File ./scripts/fixtures/Generate-ImageVectors.ps1 -Check` exited 0 and reported every artifact byte-identical.
  - `pwsh -NoProfile -File ./scripts/fixtures/Generate-PpmVectors.ps1 -Check` exited 0.
- Fixture policy:
  - `pwsh -NoProfile -File ./scripts/quality/Test-FixturePolicy.ps1` exited 0.
  - Printed `Fixture identity and containment matrix passed.`
- Artifact diff:
  - `git diff --exit-code -- fixtures/manifest.json modules/mb-image/ppm/generated_vectors.mbt` exited 0.
- Canonical SHA-256 values before and after:
  - `fixtures/manifest.json`: `1b4707387339e2b339915575f2c040650074c51fb98989e5b6b3d697c32a3e7d`
  - `modules/mb-image/ppm/generated_vectors.mbt`: `da850ec87313a0a5168d2d42460e26e02c5c18f2898d2fc17cfd6f31c03efedb`
- `git diff --check` passed.

## Files Created/Modified

- `scripts/fixtures/Generate-PpmVectors.ps1` — position-preserving PPM merge policy and guarded production self-test.
- `.planning/quick/260726-u7d-preserve-fixture-manifest-ordering-durin/260726-u7d-SUMMARY.md` — execution and verification evidence.

## Decisions Made

- Existing PPM records are replaced at their original indexes; a missing record is appended after the ordered walk.
- Foreign manifest objects are reused rather than reconstructed, preserving identity, order, and serialized field values.
- Duplicate PPM IDs fail with the exact owned ID in the error.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None.

## Known Stubs

None.

## Threat Flags

None — the change introduces no network, authentication, filesystem-boundary, or schema trust surface.

## Self-Check: PASSED

- Source commit `3e8229ff1e236b04849b22a3b93fa90830477dae` resolves.
- Modified generator and this summary exist.
- Both canonical hashes and every stated verification command were confirmed from the isolated worktree.

## Next Step

The PPM manifest-ordering blocker is cleared and quick `260726-sss` can resume its detached Required qualification.
