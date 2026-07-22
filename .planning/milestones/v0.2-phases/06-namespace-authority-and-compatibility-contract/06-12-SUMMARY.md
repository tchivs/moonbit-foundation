---
phase: 06-namespace-authority-and-compatibility-contract
plan: "12"
subsystem: module-roots
tags: [moonbit, namespace, manifests, dependency-dag, smoke-check]
requires:
  - phase: 06-namespace-authority-and-compatibility-contract
    provides: canonical tchivs personal-namespace policy from plan 06-07
provides:
  - Three canonical tchivs module roots at candidate version 0.1.0
  - Exact mb-core to mb-color to mb-image dependency floors
  - Bounded mb-core bytes package identity migration
affects: [06-08, module-source-graph, compatibility-baselines, publication]
tech-stack:
  added: []
  patterns: [policy-projected-module-roots, bounded-wave-migration, isolated-transitional-verification]
key-files:
  created:
    - .planning/phases/06-namespace-authority-and-compatibility-contract/06-12-SUMMARY.md
  modified:
    - modules/mb-core/moon.mod.json
    - modules/mb-color/moon.mod.json
    - modules/mb-image/moon.mod.json
    - modules/mb-core/bytes/moon.pkg
key-decisions:
  - "Keep all three unpublished candidates at 0.1.0 while rebasing only canonical module and dependency identities."
  - "Validate the transitional leaf graph in an isolated complete-import overlay because the main moon.work intentionally retains later-wave old-owner members until plans 06-08 and 06-09."
patterns-established:
  - "Namespace migration proceeds in bounded waves without rewriting archived v0.1 evidence or broadening a plan's tracked-file budget."
requirements-completed: [COMP-01, COMP-02, COMP-03, COMP-04]
coverage:
  - id: D1
    description: Three module manifests project the exact ordered tchivs 0.1.0 policy DAG
    requirement: COMP-03
    verification:
      - kind: integration
        ref: PowerShell exact manifest name, version, dependency-count, and dependency-floor assertions
        status: pass
    human_judgment: false
  - id: D2
    description: The bounded bytes package uses canonical imports and the fully rebased leaf graph checks on four targets
    requirement: COMP-01
    verification:
      - kind: integration
        ref: isolated moon -C modules/mb-core check --target js|wasm|wasm-gc|native --frozen
        status: pass
      - kind: integration
        ref: policy/phase-01-source-audit.json SHA-256 invariant
        status: pass
    human_judgment: false
duration: 12m
completed: 2026-07-17
status: complete
---

# Phase 6 Plan 12: Canonical Module Roots Summary

**The three unpublished module roots now form the exact `tchivs/*@0.1.0` policy DAG, with the bounded bytes package moved onto the canonical leaf identity.**

## Performance

- **Duration:** 12m
- **Started:** 2026-07-17T10:01:00Z
- **Completed:** 2026-07-17T10:12:59Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Rebased `mb-core`, `mb-color`, and `mb-image` roots to `tchivs/*` while preserving candidate version `0.1.0`, target declarations, descriptions, license, and other non-identity metadata.
- Rebased the exact `mb-color -> mb-core` and `mb-image -> mb-core,mb-color` dependency floors to `tchivs/*@0.1.0`.
- Migrated only `modules/mb-core/bytes/moon.pkg` from the later 17-package source graph and proved four-target leaf compatibility in an isolated full-import overlay.
- Preserved the archived Phase 1 audit at SHA-256 `52f118333892cfe1044b8105a6ea5d03f1ab087d3f7875d13b79c4e5b7640a7a`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Rebase the exact three module roots** - `b7fb464` (chore)
2. **Task 2: Migrate one root-adjacent smoke package and prove bounded closure** - `1477dae` (chore)

## Files Created/Modified

- `modules/mb-core/moon.mod.json` - Canonical `tchivs/mb-core` leaf root at `0.1.0`.
- `modules/mb-color/moon.mod.json` - Canonical middle root with the exact `tchivs/mb-core@0.1.0` floor.
- `modules/mb-image/moon.mod.json` - Canonical top root with exact core and color `0.1.0` floors.
- `modules/mb-core/bytes/moon.pkg` - Canonical bytes package imports for budget, checked, and error.
- `.planning/phases/06-namespace-authority-and-compatibility-contract/06-12-SUMMARY.md` - Execution evidence and downstream handoff.

## Decisions Made

- The owner correction remains a pre-publication identity correction, so it creates neither a compatibility class nor a version bump.
- The plan preserves its four-file budget. Remaining active package manifests, examples, consumers, documentation, and generated baselines stay assigned to their explicit downstream plans.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Isolated the four-target leaf verification from the intentionally mixed-owner workspace**

- **Found during:** Task 2 four-target verification
- **Issue:** From the main checkout, `moon -C modules/mb-core check` discovers the root `moon.work` and attempts to resolve later-wave example modules still using unpublished `moonbit-foundation/*` identities. A module-only copy then correctly exposed the remaining 06-08 package imports, which are outside this plan's file budget.
- **Fix:** Built a disposable module-only verification copy, mechanically projected the remaining leaf-package import manifests to `tchivs/mb-core` inside that disposable copy only, and ran the exact leaf-module check for `js`, `wasm`, `wasm-gc`, and `native`. The disposable copy was removed after all four targets passed.
- **Files modified:** No additional tracked files; the overlay existed only in the disposable verification directory.
- **Verification:** All four isolated `moon -C modules/mb-core check --target <target> --frozen` runs passed; the tracked diff across both task commits contains exactly the four declared files.
- **Committed in:** No extra commit; verification-only adjustment supporting `1477dae`.

---

**Total deviations:** 1 auto-fixed blocking verification issue.
**Impact on plan:** The bounded root/bytes migration is complete and honestly retains the expected transitional main-workspace failure until 06-08 and 06-09 migrate their owned files.

## Issues Encountered

- The literal main-checkout verification command cannot close during this wave because Moon automatically discovers the parent workspace, whose source packages and examples are intentionally owned by later plans. This is an expected staged-migration boundary, not a registry or credential failure.

## User Setup Required

None - this plan performs no login, registration, repository write, or publication.

## Verification

- Exact manifest roots, candidate versions, dependency counts, and dependency floors passed policy projection assertions.
- The bytes package contains exactly the canonical positive imports and no old-owner import.
- The isolated fully rebased `mb-core` leaf checked successfully on `js`, `wasm`, `wasm-gc`, and `native`.
- `policy/phase-01-source-audit.json` retained its locked SHA-256 digest.
- `git diff --check b7fb464^..1477dae` passed, and the two task commits contain exactly the four declared files.

## Next Phase Readiness

- Plan 06-08 can migrate the remaining 15 package files and close the tracked 17-package source graph across all four targets.
- The main workspace is intentionally transitional until the later source/example waves complete; no external identity or publication claim changed.

## Self-Check: PASSED

- All four modified source artifacts exist and match the canonical policy identities.
- Both atomic task commits exist with no tracked deletions.
- Historical evidence and user-dirty governance paths remain outside plan commits.

---
*Phase: 06-namespace-authority-and-compatibility-contract*
*Completed: 2026-07-17*
