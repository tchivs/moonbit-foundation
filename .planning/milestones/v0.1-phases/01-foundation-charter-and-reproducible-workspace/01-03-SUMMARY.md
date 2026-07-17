---
phase: 01-foundation-charter-and-reproducible-workspace
plan: "03"
subsystem: workspace
tags: [moonbit, workspace, manifests, targets, dependency-dag]

requires:
  - phase: 01-foundation-charter-and-reproducible-workspace
    provides: Canonical module identities, versions, targets, license, and allowed dependency edges
provides:
  - Exact three-member MoonBit workspace
  - Independent 0.1.0 module publication manifests
  - Explicit four-target root package contracts with inward-only imports
affects: [phase-01-module-scaffolds, quality-validation, packaging, release-qualification]

tech-stack:
  added: [moon.work, moon.mod.json, moon.pkg]
  patterns:
    - Named workspace dependencies without path overrides
    - Explicit module-level and package-level portable target sets

key-files:
  created:
    - moon.work
    - modules/mb-core/moon.mod.json
    - modules/mb-core/moon.pkg
    - modules/mb-color/moon.mod.json
    - modules/mb-color/moon.pkg
    - modules/mb-image/moon.mod.json
    - modules/mb-image/moon.pkg
  modified: []

key-decisions:
  - "Use normal 0.1.0 named dependencies so moon.work substitutes local members without path dependencies."
  - "Declare the same explicit +js+wasm+wasm-gc+native set at module and public root package levels."
  - "Use the pinned CLI's canonical supported_targets moon.pkg assignment while retaining the locked moon.mod.json compatibility floor."

patterns-established:
  - "Workspace DAG: mb-core has no inward dependency, mb-color imports mb-core, and mb-image imports mb-core plus mb-color."
  - "Publication units retain independent manifests and versions even while coordinated by one root workspace."

requirements-completed: [WORK-01, WORK-03, GOV-04]

coverage:
  - id: D1
    description: "moon.work coordinates exactly the three final-name independent publication units with versioned, path-free named dependencies."
    requirement: WORK-01
    verification:
      - kind: integration
        ref: "PowerShell exact-member, identity, version, and DAG assertions plus moon check --target all"
        status: pass
    human_judgment: false
  - id: D2
    description: "Every module and public root package declares +js+wasm+wasm-gc+native, with imports restricted to the approved inward DAG."
    requirement: WORK-03
    verification:
      - kind: integration
        ref: "PowerShell module/package target and import assertions plus moon check --target all"
        status: pass
    human_judgment: false
  - id: D3
    description: "Final moonbit-foundation/mb-* identities and Apache-2.0 metadata are concrete without an umbrella module or lockstep mechanism."
    requirement: GOV-04
    verification:
      - kind: other
        ref: "ConvertFrom-Json identity, license, unique-name, and no-umbrella assertions"
        status: pass
    human_judgment: false

duration: 6min
completed: 2026-07-16
status: complete
---

# Phase 1 Plan 3: Three-Member Workspace Contracts Summary

**Exact three-member MoonBit workspace with independent module identities, an inward-only dependency DAG, and explicit Native plus portable package targets**

## Performance

- **Duration:** 6 min
- **Started:** 2026-07-16T07:30:00Z
- **Completed:** 2026-07-16T07:36:27Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Created one `moon.work` containing exactly `mb-core`, `mb-color`, and `mb-image`.
- Established independent Apache-2.0 `0.1.0` manifests under the final intended `moonbit-foundation/mb-*` identities.
- Declared the complete `+js+wasm+wasm-gc+native` contract at module and root package levels while preserving the approved acyclic import direction.

## Task Commits

Each task was committed atomically:

1. **Task 1: Define workspace membership and independent manifests** - `babaa9b` (chore)
2. **Task 2: Declare every public root package target contract** - `c71d98d` (chore)

## Files Created/Modified

- `moon.work` - Exact three-member workspace inventory.
- `modules/mb-core/moon.mod.json` - Independent core module identity and four-target metadata.
- `modules/mb-core/moon.pkg` - Dependency-free core root package target contract.
- `modules/mb-color/moon.mod.json` - Independent color identity with a named core dependency.
- `modules/mb-color/moon.pkg` - Color root package target contract and inward core import.
- `modules/mb-image/moon.mod.json` - Independent image identity with named core and color dependencies.
- `modules/mb-image/moon.pkg` - Image root package target contract and approved inward imports.

## Decisions Made

- Used registry-style `0.1.0` named dependencies in manifests; workspace resolution supplies local members without path metadata.
- Kept package imports explicit even before private scaffold code exists so the intended public-root DAG is machine-inspectable.
- Used `supported_targets = "+js+wasm+wasm-gc+native"` in `moon.pkg`, which is the canonical form reported by the pinned CLI formatter.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Replaced deprecated package target option syntax**

- **Found during:** Task 2 workspace parsing and formatting inspection
- **Issue:** The prose research example led to `options("supported-targets": ...)`, but the pinned `moon 0.1.20260713` CLI reports that form as deprecated and formats it to `supported_targets = ...`.
- **Fix:** Used the canonical assignment form while preserving the exact required target-set value.
- **Files modified:** `modules/mb-core/moon.pkg`, `modules/mb-color/moon.pkg`, `modules/mb-image/moon.pkg`
- **Verification:** The exact-set assertions and `moon check --target all` passed.
- **Committed in:** `c71d98d`

**2. [Rule 1 - Bug] Repaired malformed generated roadmap and stale state fields**

- **Found during:** Post-summary GSD state synchronization
- **Issue:** `roadmap.update-plan-progress` shifted the Phase 1 progress row columns, while generic state handlers retained stale activity, velocity, phase labels, blocker, and resume text.
- **Fix:** Restored the four-column roadmap row and synchronized all affected state fields with Plan 01-03 completion.
- **Files modified:** `.planning/ROADMAP.md`, `.planning/STATE.md`
- **Verification:** Re-read both files and checked the 3/8 plan count, 7/36 validated requirements, next-plan pointer, and intact progress-table schema.
- **Committed in:** final state-sync commit

---

**Total deviations:** 2 auto-fixed (2 bugs).
**Impact on plan:** Syntax and generated planning metadata were corrected without changing package identities, imports, targets, or scope.

## Issues Encountered

- `moon check --target all` succeeds but reports expected unused-package warnings because the root package imports are declared before Plans 01-04 through 01-06 add private scaffold code that consumes them.
- A diagnostic `moon fmt --check` proposes migration from the deliberately locked `moon.mod.json` compatibility floor to transitional `moon.mod`. The manifests were not migrated; Plan 01-07 must preserve the locked format when implementing format validation.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plans 01-04 through 01-06 can add private build, test, documentation, and release-ledger surfaces to each established member independently.
- Plan 01-07 can validate exact workspace membership, manifest/package equality, target sets, and DAG edges against `policy/foundation.json`.
- `EDGE-WORK-01-UNCLASSIFIED` remains flagged for manual independent package/publication behavior review after the member scaffolds exist.

## Self-Check: PASSED

- All seven workspace and module artifacts exist.
- Both atomic task commits are present in repository history.
- Exact metadata assertions and the full four-target workspace parse completed successfully.

---
*Phase: 01-foundation-charter-and-reproducible-workspace*
*Completed: 2026-07-16*
