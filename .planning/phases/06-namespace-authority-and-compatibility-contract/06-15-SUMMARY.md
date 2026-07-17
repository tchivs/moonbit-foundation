---
phase: 06-namespace-authority-and-compatibility-contract
plan: "15"
subsystem: compatibility
tags: [moonbit, baselines, reproducibility, source-anchor, powershell]
requires:
  - phase: 06-14
    provides: canonical tchivs module routes and completed source boundary
provides:
  - immutable 0.1.0 source snapshot anchored to the exact 06-14 commit
  - exact-package deterministic batch generation isolated from mutable HEAD
  - guarded complete-tree finalization for 17 packages and 102 package files
affects: [06-16, 06-17, 06-18, 06-19, 06-20, 06-21, 06-22, 06-23, 06-24]
tech-stack:
  added: []
  patterns: [immutable source snapshot, exact package ownership, finalize-only manifest]
key-files:
  created: [compatibility/source-snapshots/0.1.0.json]
  modified: [scripts/quality/New-PublicInterfaceBaseline.ps1, scripts/quality/Test-PublicInterfaceBaseline.ps1]
key-decisions:
  - "Bind 0.1.0 baseline evidence to the exact completed 06-14 commit and deterministic tracked module-tree digest."
  - "Permit package batches to replace only selected six-file package subtrees; reserve manifest publication for complete-tree Finalize mode."
patterns-established:
  - "Anchor-first generation: archive the recorded commit twice and never inspect mutable HEAD or the old manifest for source identity."
  - "Fail-closed finalization: require exactly 17 canonical packages, 102 package files, and 68 target records before atomic manifest publication."
requirements-completed: [COMP-01, COMP-02, COMP-03, COMP-04]
coverage:
  - id: D1
    description: Immutable source snapshot binds canonical modules, pinned toolchain, 06-14 source commit, and deterministic module tree.
    requirement: COMP-01
    verification:
      - kind: integration
        ref: "scripts/quality/Test-PublicInterfaceBaseline.ps1 -ToolingOnly#immutable anchor and later HEAD negatives"
        status: pass
    human_judgment: false
  - id: D2
    description: Exact package batches are reproducible and cannot mutate another batch or manifest.json.
    requirement: COMP-02
    verification:
      - kind: integration
        ref: "scripts/quality/Test-PublicInterfaceBaseline.ps1 -ToolingOnly#batch isolation and read-only check"
        status: pass
    human_judgment: false
  - id: D3
    description: Finalization rejects incomplete, extra, stale, mixed-identity, or anchor-mismatched trees.
    requirement: COMP-03
    verification:
      - kind: integration
        ref: "scripts/quality/Test-PublicInterfaceBaseline.ps1 -ToolingOnly#102-file finalization negatives"
        status: pass
    human_judgment: false
  - id: D4
    description: Obsolete manifest metadata and later HEAD cannot influence anchored records or finalization.
    requirement: COMP-04
    verification:
      - kind: integration
        ref: "scripts/quality/Test-PublicInterfaceBaseline.ps1 -ToolingOnly#obsolete manifest and later synthetic HEAD"
        status: pass
    human_judgment: false
duration: 25min
completed: 2026-07-17
status: complete
---

# Phase 6 Plan 15: Anchored Baseline Batching Summary

**Immutable 06-14 source anchoring now drives isolated exact-package baseline batches and complete-tree-only manifest finalization.**

## Performance

- **Duration:** 25 min
- **Started:** 2026-07-17T11:49:00Z
- **Completed:** 2026-07-17T12:14:00Z
- **Tasks:** 1
- **Files modified:** 3

## Accomplishments

- Captured `0.1.0` once at commit `b81cff59d4d1bd371b250ed0fd314ca1a6a008e7` with canonical `tchivs/*` module identities and deterministic module-tree SHA-256.
- Added parameter-set-separated Batch and Finalize modes that materialize all source input from the anchored commit and regenerate every selected package twice.
- Added full tooling-only positives and negatives for batch ownership, exact 102-file finalization, anchor mutation, obsolete manifest metadata, and later HEAD isolation.

## Task Commits

1. **Task 1: Implement exact package batching and guarded finalization** - `e36a93f` (feat)

## Files Created/Modified

- `compatibility/source-snapshots/0.1.0.json` - Immutable canonical source and toolchain anchor.
- `scripts/quality/New-PublicInterfaceBaseline.ps1` - Anchor validation, exact-package generation, atomic batch replacement, and guarded Finalize mode.
- `scripts/quality/Test-PublicInterfaceBaseline.ps1` - Tooling-only positive and negative contract suite.

## Decisions Made

- The module tree digest hashes sorted tracked paths, a separator, a fixed-width byte length, and exact file bytes from the anchored commit.
- Batch mode owns only its selected package directories; `manifest.json` is exclusively owned by Finalize mode after exact-tree validation.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- PowerShell canonical JSON output used platform newlines; canonicalization was made explicitly LF-only so tracked anchor bytes are stable across hosts.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plans 06-16 through 06-24 can generate bounded package batches against the immutable source snapshot.
- No external registry writes were performed.

## Self-Check: PASSED

- All three declared task files exist and commit `e36a93f` is present.
- The complete tooling-only positive/negative suite and plan verification command passed.

---
*Phase: 06-namespace-authority-and-compatibility-contract*
*Completed: 2026-07-17*
