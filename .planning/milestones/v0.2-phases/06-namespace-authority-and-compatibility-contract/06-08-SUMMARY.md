---
phase: 06-namespace-authority-and-compatibility-contract
plan: "08"
subsystem: module-source-graph
tags: [moonbit, namespace, package-imports, dependency-dag, four-target]
requires:
  - phase: 06-namespace-authority-and-compatibility-contract
    provides: canonical tchivs module roots and bounded bytes package from plan 06-12
provides:
  - Exact six-core, five-color, and six-image public package graph under tchivs/*
  - Four-target frozen validation of all 17 package paths and the acyclic module DAG
affects: [06-09, 06-13, 06-14, compatibility-baselines, publication-consumers]
tech-stack:
  added: []
  patterns: [bounded-source-rebase, exact-package-inventory, transitional-workspace-overlay]
key-files:
  created:
    - .planning/phases/06-namespace-authority-and-compatibility-contract/06-08-SUMMARY.md
  modified:
    - modules/mb-core/budget/moon.pkg
    - modules/mb-core/checked/moon.pkg
    - modules/mb-core/host/moon.pkg
    - modules/mb-core/io/moon.pkg
    - modules/mb-color/alpha/moon.pkg
    - modules/mb-color/model/moon.pkg
    - modules/mb-color/profile/moon.pkg
    - modules/mb-color/quantize/moon.pkg
    - modules/mb-color/transfer/moon.pkg
    - modules/mb-image/codec/moon.pkg
    - modules/mb-image/metadata/moon.pkg
    - modules/mb-image/model/moon.pkg
    - modules/mb-image/ops/moon.pkg
    - modules/mb-image/ppm/moon.pkg
    - modules/mb-image/storage/moon.pkg
key-decisions:
  - "Preserve all package APIs, aliases, warnings, targets, and algorithms while changing only positive canonical package identities."
  - "Use a disposable modules-only workspace for staged verification because examples remain explicitly owned by plan 06-09."
patterns-established:
  - "Every source-identity wave closes an exact enumerated file budget before downstream consumers migrate."
requirements-completed: [COMP-01, COMP-02, COMP-03, COMP-04]
coverage:
  - id: D1
    description: Six core and five color packages resolve only canonical tchivs identities on four targets
    requirement: COMP-01
    verification:
      - kind: integration
        ref: moon -C modules/mb-core|mb-color check --target js|wasm|wasm-gc|native --frozen in disposable complete-import workspace
        status: pass
    human_judgment: false
  - id: D2
    description: Six image packages resolve the exact canonical lower-layer graph on four targets
    requirement: COMP-02
    verification:
      - kind: integration
        ref: moon -C modules/mb-image check --target js|wasm|wasm-gc|native --frozen in disposable modules-only workspace
        status: pass
    human_judgment: false
  - id: D3
    description: Exact 17-package inventory forms one canonical acyclic 0.1.0 workspace graph
    requirement: COMP-03
    verification:
      - kind: integration
        ref: exact package-path and manifest-DAG assertions plus moon check on four frozen targets
        status: pass
    human_judgment: false
duration: 18m
completed: 2026-07-17
status: complete
---

# Phase 6 Plan 08: Canonical 17-Package Source Graph Summary

**All 17 public MoonBit packages now compile as the exact `tchivs/mb-core` → `tchivs/mb-color` → `tchivs/mb-image` source graph across four frozen targets.**

## Performance

- **Duration:** 18m
- **Started:** 2026-07-17T10:06:00Z
- **Completed:** 2026-07-17T10:24:01Z
- **Tasks:** 3
- **Files modified:** 15

## Accomplishments

- Rebased the nine remaining core/color package manifests to canonical `tchivs/*` imports without changing declarations, targets, aliases, warnings, or behavior.
- Rebased all six image package manifests to the exact canonical core/color/image dependency identities.
- Proved an exact 17-package inventory, unchanged `0.1.0` versions, ordinal module dependencies, and frozen checks for `js`, `wasm`, `wasm-gc`, and `native`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Rebase the nine remaining core and color package files** - `9e6584d` (chore)
2. **Task 2: Rebase the six image package files** - `19f6202` (chore)
3. **Task 3: Close the exact 17-package workspace graph** - `92eab94` (test, verification-only empty commit)

## Files Created/Modified

- `modules/mb-core/{budget,checked,host,io}/moon.pkg` - Canonical core package imports.
- `modules/mb-color/{alpha,model,profile,quantize,transfer}/moon.pkg` - Canonical color/core package imports.
- `modules/mb-image/{codec,metadata,model,ops,ppm,storage}/moon.pkg` - Canonical image/color/core package imports.
- `.planning/phases/06-namespace-authority-and-compatibility-contract/06-08-SUMMARY.md` - Execution evidence and downstream handoff.

## Decisions Made

- Kept the migration strictly identity-only; no public surface, implementation, target condition, warning policy, candidate version, or module family changed.
- Retained MoonBit Native Foundation branding and left manifests, docs, consumers, baselines, validators, generated output, and archived evidence to their owning plans.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Isolated source-graph checks from later-wave example identities**

- **Found during:** Task 1 and plan-level verification
- **Issue:** Moon automatically discovered the parent `moon.work`, whose two example members intentionally retain `moonbit-foundation/*` identities until plan 06-09. The literal module commands therefore attempted unavailable registry resolution before checking the newly canonical package graph.
- **Fix:** Copied the tracked module graph into disposable verification directories, projected only the complete import context needed for Task 1, and removed example members from the Task 2/3 verification workspace. No tracked file outside the 15-file plan budget changed.
- **Files modified:** None beyond the declared 15 package files; verification overlays were untracked system-temporary copies.
- **Verification:** All module checks and the modules-only workspace check passed on `js`, `wasm`, `wasm-gc`, and `native` with `--frozen`; exact path and DAG assertions passed.
- **Committed in:** `92eab94` records the verification outcome.

---

**Total deviations:** 1 auto-fixed blocking issue.
**Impact on plan:** The exact active module source graph is fully proven; only explicitly later-wave example members prevent the root checkout command from being literal until 06-09.

## Issues Encountered

- The first dependency assertion used `Compare-Object` with an empty leaf dependency set, producing a non-terminating PowerShell binding error. It was replaced with strict ordinal string equality and rerun successfully with `$ErrorActionPreference = 'Stop'`.

## User Setup Required

None - this plan performs no login, registration, repository write, publication, or external mutation.

## Verification

- Exact package inventory passed: 6 core + 5 color + 6 image = 17.
- No positive `moonbit-foundation/mb-core`, `mb-color`, or `mb-image` import remains in any module `moon.pkg`.
- Manifest roots are exactly `tchivs/mb-core`, `tchivs/mb-color`, and `tchivs/mb-image` at `0.1.0`, with only the ordered canonical dependency floors.
- Frozen module and modules-only workspace checks passed for `js`, `wasm`, `wasm-gc`, and `native`.
- `git diff --check 5769162..92eab94`, the exact 15-file scope comparison, and the stub scan passed.
- User-dirty governance files, `.codebase-memory/`, and `.planning/research/.cache/` remained unstaged and unchanged by plan commits.

## Known Stubs

None.

## Next Phase Readiness

- Plan 06-09 can now migrate the example and benchmark consumer layer onto the closed canonical source graph.
- Compatibility baselines and validators can consume one exact 17-package `tchivs/*` DAG in their owning downstream plans.
- Live Mooncakes authority remains separately blocked and was not touched.

## Self-Check: PASSED

- All 15 modified package files and this summary exist.
- All three task commits exist; no tracked deletion occurred.
- Every task acceptance criterion and plan-level source-graph criterion passed within the declared staged-migration boundary.

---
*Phase: 06-namespace-authority-and-compatibility-contract*
*Completed: 2026-07-17*
