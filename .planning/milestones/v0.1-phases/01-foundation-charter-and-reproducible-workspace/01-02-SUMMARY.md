---
phase: 01-foundation-charter-and-reproducible-workspace
plan: "02"
subsystem: governance-policy
tags: [policy, licensing, stability, targets, toolchain, provenance]

requires:
  - phase: 01-foundation-charter-and-reproducible-workspace/01-01
    provides: Proposed foundation charter and auditable RFC lifecycle
provides:
  - Canonical machine-readable foundation policy for identities, versions, targets, stability, RFC evidence, DAG, and publication state
  - Apache-2.0 project license and fail-closed fixture provenance contract
  - Exact Phase 1 source-audit inventory with stable IDs and plan mappings
affects: [workspace-scaffold, module-packages, quality-validation, rfc-acceptance]

tech-stack:
  added: []
  patterns:
    - Single source of machine-compared policy truth
    - Fail-closed fixture provenance and publication gates
    - Exact no-silent-drop source inventory

key-files:
  created:
    - LICENSE
    - policy/foundation.json
    - policy/phase-01-source-audit.json
    - docs/policies/api-stability.md
    - docs/policies/licensing-and-fixtures.md
    - docs/policies/publication.md
    - docs/policies/targets.md
    - docs/policies/toolchain.md
    - fixtures/manifest.json
  modified: []

key-decisions:
  - "Machine-compared module, target, toolchain, stability, RFC, DAG, and publication values have one owner in policy/foundation.json."
  - "All three v0.1 modules begin at independent version 0.1.0 with candidate status, while public publication remains blocked until namespace ownership is verified."
  - "Fixture intake starts with an intentionally empty records array and rejects external content without complete provenance and confirmed redistribution."
  - "Every Phase 1 goal, requirement, decision, research item, edge case, and prohibition remains individually addressable with an explicit covering-plan mapping."

patterns-established:
  - "Policy prose explains and links canonical JSON rather than owning competing executable values."
  - "Exact source sets and counts are preserved for later fail-closed validation."

requirements-completed: [GOV-03, GOV-04, WORK-02, WORK-03]

coverage:
  - id: D1
    description: "Consumers can distinguish experimental, candidate, and stable APIs through adjacent promises, ordered promotion and removal rules, and checked metadata requirements."
    requirement: GOV-03
    verification:
      - kind: other
        ref: "PowerShell plan verification of stability labels, promises, candidate defaults, stable gates, breaking changes, and removals"
        status: pass
    human_judgment: false
  - id: D2
    description: "The exact moon, moonc, and moonrun development identities are single-sourced for reproducible local and CI validation."
    requirement: WORK-02
    verification:
      - kind: other
        ref: "PowerShell plan verification of D-14 toolchain identities in policy/foundation.json"
        status: pass
    human_judgment: false
  - id: D3
    description: "Every public package carries the exact four-target portable contract while LLVM remains explicitly experimental and outside required support."
    requirement: WORK-03
    verification:
      - kind: other
        ref: "PowerShell normalized-set verification of required and experimental targets"
        status: pass
    human_judgment: false
  - id: D4
    description: "Apache-2.0 terms, final namespace and module names, publication blocking, and fixture provenance rules are explicit and machine-readable."
    requirement: GOV-04
    verification:
      - kind: other
        ref: "PowerShell license, publication, identity, fixture field, generated-origin, and redistribution checks"
        status: pass
    human_judgment: false
  - id: D5
    description: "The Phase 1 source audit contains the exact 1/9/16/29/17/5 inventory with unique IDs, non-empty mappings, and covered status."
    verification:
      - kind: other
        ref: "PowerShell exact count, set, uniqueness, non-empty field, and status verification"
        status: pass
    human_judgment: false

duration: 10min
completed: 2026-07-16
status: complete
---

# Phase 01 Plan 02: Single-Sourced Foundation Policy and Source Audit Summary

**An executable foundation policy now fixes compatibility, publication, targets, and toolchain facts while Apache-2.0 provenance rules and an exact source audit prevent silent policy drift.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-07-16T07:18:00Z
- **Completed:** 2026-07-16T07:27:18Z
- **Tasks:** 3
- **Files modified:** 9

## Accomplishments

- Single-sourced the three final module identities, independent versions, candidate labels, exact toolchain, four required targets, allowed DAG, RFC evidence shape, and namespace publication block.
- Added canonical Apache-2.0 terms plus a versioned fixture manifest contract that requires provenance, SHA-256, licensing, redistribution status, and expected use.
- Materialized every Phase 1 goal, requirement, D-01 through D-16 decision, research item, edge item, and prohibition as an exact individually mapped audit row.

## Task Commits

Each task was committed atomically:

1. **Task 1: Single-source stability, publication, targets, and toolchain facts** - `0a4babd` (feat)
2. **Task 2: Establish licensing and fail-closed fixture provenance** - `0808218` (docs)
3. **Task 3: Materialize the complete Phase 1 source audit** - `763bbeb` (docs)

## Files Created/Modified

- `policy/foundation.json` - Canonical module, version, target, toolchain, stability, RFC, DAG, and publication facts.
- `policy/phase-01-source-audit.json` - Exact Phase 1 goal, requirement, decision, research, edge, and prohibition inventory.
- `LICENSE` - Canonical Apache License 2.0 terms.
- `fixtures/manifest.json` - Versioned empty fixture inventory with strict provenance and redistribution schema.
- `docs/policies/api-stability.md` - Experimental, candidate, stable, promotion, breaking-change, and removal promises.
- `docs/policies/licensing-and-fixtures.md` - Project licensing and fail-closed fixture intake rules.
- `docs/policies/publication.md` - Independent module publication model and namespace block.
- `docs/policies/targets.md` - Required portable targets, native adapters, and experimental LLVM boundary.
- `docs/policies/toolchain.md` - Exact-pin enforcement and compatibility-floor policy.

## Decisions Made

- Kept all executable compatibility facts under one structured JSON owner and made prose documents explanatory links.
- Preserved final intended module names locally while keeping publication blocked until mooncakes.io ownership is verified.
- Treated the initial empty fixture record set as an intentional valid state, while making every future record fail closed on missing provenance or unconfirmed external redistribution.
- Mapped cross-plan research and edge obligations explicitly rather than collapsing multiple stable IDs into one row.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Repaired malformed generated roadmap and stale state fields**

- **Found during:** Post-summary GSD state synchronization
- **Issue:** `roadmap.update-plan-progress` rewrote the Phase 1 table row with shifted columns, while generic state handlers left the activity, velocity, decision phase labels, pending-decision text, blocker, and resume text stale.
- **Fix:** Restored the four-column roadmap row and synchronized the affected state fields with the completed Plan 01-02 facts.
- **Files modified:** `.planning/ROADMAP.md`, `.planning/STATE.md`
- **Verification:** Re-read both files and checked the 2/8 plan count, 6/36 validated requirements, next-plan pointer, and intact progress-table schema.
- **Committed in:** final state-sync commit

---

**Total deviations:** 1 auto-fixed (1 bug).
**Impact on plan:** The repair only corrected generated planning metadata; production policy artifacts and scope were unchanged.

## Issues Encountered

- The first generic stub scan matched research descriptions that prohibit placeholder APIs. The scan was narrowed to shipped runtime/policy artifacts; no implementation stubs were present. The intentionally empty fixture records array is required by the plan and schema, not a stub.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 01-03 can generate workspace and module manifests from the canonical identities, versions, targets, and DAG.
- Plan 01-07 can implement exact-set source-audit and policy validators against stable schemas and IDs.
- Public publication remains deliberately blocked until Plan 01-08 records authentic namespace and RFC acceptance evidence.

## Self-Check: PASSED

- All nine created artifacts exist.
- All three task commits are present in repository history.
- Task-level and plan-level verification commands passed, including exact source-audit counts, unique IDs, non-empty mappings, and covered status.
- No implementation stubs or unplanned security-relevant surfaces were introduced.

---
*Phase: 01-foundation-charter-and-reproducible-workspace*
*Completed: 2026-07-16*
