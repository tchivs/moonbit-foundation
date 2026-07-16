---
phase: 01-foundation-charter-and-reproducible-workspace
plan: "04"
subsystem: core-foundation
tags: [moonbit, mb-core, tdd, documentation, targets]

requires:
  - phase: 01-foundation-charter-and-reproducible-workspace/01-03
    provides: Independent mb-core manifest and explicit four-target root package contract
provides:
  - Warning-free private mb-core build surface with deterministic white-box proof
  - Exact empty public-domain interface classification
  - Checked candidate documentation and independent Unreleased ledger
affects: [phase-02-core-primitives, quality-validation, packaging, release-qualification]

tech-stack:
  added: []
  patterns:
    - Package-private underscore-prefixed scaffold for warning-free empty public surfaces
    - White-box tests prove private build behavior without creating compatibility debt

key-files:
  created:
    - modules/mb-core/scaffold.mbt
    - modules/mb-core/scaffold_wbtest.mbt
    - modules/mb-core/README.mbt.md
    - modules/mb-core/CHANGELOG.md
  modified: []

key-decisions:
  - "Keep the Phase 1 mb-core proof package-private and expose no function, type, trait, alias, error, or method."
  - "Use an underscore-prefixed private probe so the pinned compiler accepts the source under --deny-warn while white-box tests still exercise it."
  - "Describe candidate status and the namespace publication block without fabricating a public example API or released version."

patterns-established:
  - "Private scaffold pattern: an underscore-prefixed deterministic definition plus a _wbtest.mbt proof leaves pkg.generated.mbti with only the package declaration."
  - "Module documentation mirrors root Status, scope, and design commitments while adding checked target, versioning, and publication facts."

requirements-completed: [WORK-01, WORK-03, GOV-03]

coverage:
  - id: D1
    description: "mb-core builds and its package-private deterministic scaffold passes a white-box test on js, wasm, wasm-gc, and native without emitting public domain API."
    requirement: WORK-01
    verification:
      - kind: unit
        ref: "modules/mb-core/scaffold_wbtest.mbt#private scaffold is deterministic"
        status: pass
      - kind: integration
        ref: "moon -C modules/mb-core check . --target all --deny-warn --frozen; moon -C modules/mb-core test --target all --frozen; moon -C modules/mb-core info --target all --frozen; exact semantic-line classifier"
        status: pass
    human_judgment: false
  - id: D2
    description: "mb-core documentation states candidate status, ownership boundaries, exact four-target support, independent versioning, and blocked publication, with an Unreleased ledger."
    requirement: GOV-03
    verification:
      - kind: other
        ref: "PowerShell README token, manifest/package equality, and CHANGELOG Unreleased assertions plus targeted checked-document build"
        status: pass
    human_judgment: false

duration: 11min
completed: 2026-07-16
status: complete
---

# Phase 01 Plan 04: Private mb-core Publication Scaffold Summary

**A deterministic package-private MoonBit probe now proves mb-core across four targets while its generated interface stays limited to the package declaration and checked docs state the candidate release contract.**

## Performance

- **Duration:** 11 min
- **Started:** 2026-07-16T07:38:44Z
- **Completed:** 2026-07-16T07:49:12Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added a package-private deterministic mb-core probe through a fail-first white-box test and warning-free implementation.
- Proved the generated interface has exactly one semantic line, `package "moonbit-foundation/mb-core"`, with no public domain API.
- Added checked candidate status, scope, target, versioning, and publication documentation plus an independent Unreleased changelog.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: Add failing private scaffold proof** - `b971ca8` (test)
2. **Task 1 GREEN: Implement private mb-core scaffold** - `484b430` (feat)
3. **Task 2: Document the mb-core publication unit** - `9ba18d4` (docs)

## Files Created/Modified

- `modules/mb-core/scaffold.mbt` - Warning-free package-private deterministic build probe.
- `modules/mb-core/scaffold_wbtest.mbt` - White-box test that exercises the private probe on all declared targets.
- `modules/mb-core/README.mbt.md` - Checked candidate status, boundaries, target matrix, independent versioning, and publication block.
- `modules/mb-core/CHANGELOG.md` - Independent Unreleased ledger without a false release claim.

## Decisions Made

- Used `_scaffold_probe` rather than a public declaration; the underscore suppresses the pinned compiler's unused-private-value warning without widening the interface.
- Kept documentation executable but example-free because Phase 1 intentionally has no public API to demonstrate.
- Recorded only an Unreleased changelog section because version `0.1.0` remains a candidate publication unit, not a claimed public release.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Scoped the deny-warn check to the mb-core package during Wave 2 sequencing**

- **Found during:** Task 1 GREEN verification
- **Issue:** The exact `moon -C modules/mb-core check --target all --deny-warn --frozen` command traverses the ancestor `moon.work` and fails on pre-existing unused imports in mb-color and mb-image, whose private scaffolds are intentionally deferred to Plans 01-05 and 01-06.
- **Fix:** Added the CLI's package path selector (`check .`) for the deny-warn proof of mb-core itself; retained the exact module-local test, info, and semantic-interface commands. The unscoped command must be rerun after the remaining Wave 2 scaffolds consume their imports.
- **Files modified:** None outside the planned mb-core files.
- **Verification:** Targeted mb-core check passed on all four targets; exact test passed 1/1 on every target; info plus the exact semantic-line classifier passed.
- **Committed in:** No separate code change; verification sequencing adjustment only.

---

**Total deviations:** 1 auto-fixed (1 blocking issue).
**Impact on plan:** The mb-core artifact and acceptance criteria are fully proven. Only the workspace-wide deny-warn aggregate is deferred until its planned sibling scaffolds exist.

## Issues Encountered

- The unscoped deny-warn command remains expected to fail on mb-color/mb-image unused-package warnings until Plans 01-05 and 01-06 complete; this is the Wave 2 ordering condition already noted by Plan 01-03.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 01-05 can apply the same private-scaffold and documentation pattern to mb-color while consuming its declared mb-core import.
- After Plans 01-05 and 01-06, rerun the exact unscoped Wave 2 check to close the transient workspace warning condition.
- Phase 2 can replace the private mb-core probe with bounded public primitives without inheriting a placeholder API contract.

## Self-Check: PASSED

- All four planned mb-core artifacts exist.
- RED `b971ca8`, GREEN `484b430`, and documentation `9ba18d4` commits exist in repository history in the required order.
- Targeted four-target deny-warn check, exact four-target test, exact info generation, semantic-line classifier, README claims, and changelog assertions passed.
- Stub and threat-surface scans found no unplanned public or security-relevant surface; the private scaffold is the intentional deliverable.

---
*Phase: 01-foundation-charter-and-reproducible-workspace*
*Completed: 2026-07-16*
