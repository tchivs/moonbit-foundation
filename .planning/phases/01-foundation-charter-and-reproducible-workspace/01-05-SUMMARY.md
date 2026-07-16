---
phase: 01-foundation-charter-and-reproducible-workspace
plan: "05"
subsystem: color-foundation
tags: [moonbit, mb-color, tdd, documentation, targets]

requires:
  - phase: 01-foundation-charter-and-reproducible-workspace/01-03
    provides: Independent mb-color manifest, named mb-core module dependency, and explicit four-target root package contract
provides:
  - Warning-free private mb-color build surface with deterministic white-box proof
  - Exact empty public color interface classification
  - Checked candidate documentation and independent Unreleased ledger
affects: [phase-03-color-semantics, quality-validation, packaging, release-qualification]

tech-stack:
  added: []
  patterns:
    - Package-private underscore-prefixed scaffold for warning-free empty public surfaces
    - Module dependencies remain in moon.mod.json until public package symbols exist to justify source imports

key-files:
  created:
    - modules/mb-color/scaffold.mbt
    - modules/mb-color/scaffold_wbtest.mbt
    - modules/mb-color/README.mbt.md
    - modules/mb-color/CHANGELOG.md
  modified:
    - modules/mb-color/moon.pkg

key-decisions:
  - "Keep the Phase 1 mb-color proof package-private and expose no numeric, tolerance, conversion, alpha, or other color API."
  - "Retain the mb-core module dependency while omitting a package import that cannot be used before mb-core has a public contract."
  - "Describe candidate status and the namespace publication block without fabricating a public example API or released version."

patterns-established:
  - "Private scaffold pattern: an underscore-prefixed deterministic definition plus a _wbtest.mbt proof leaves pkg.generated.mbti with only the package declaration."
  - "Empty dependent packages declare future release dependencies at module level but only import packages when a real public symbol is consumed."

requirements-completed: [WORK-01, WORK-03, GOV-03]

coverage:
  - id: D1
    description: "mb-color builds and its package-private deterministic scaffold passes a white-box test on js, wasm, wasm-gc, and native without exporting a public color contract."
    requirement: WORK-01
    verification:
      - kind: unit
        ref: "modules/mb-color/scaffold_wbtest.mbt#private scaffold is deterministic"
        status: pass
      - kind: integration
        ref: "moon -C modules/mb-color check . --target all --deny-warn --frozen; moon -C modules/mb-color test . --target all --frozen; moon -C modules/mb-color info --target all --frozen; exact semantic-line classifier"
        status: pass
    human_judgment: false
  - id: D2
    description: "mb-color documentation states candidate status, ownership boundaries, exact four-target support, mb-core dependency, independent versioning, and blocked publication, with an Unreleased ledger."
    requirement: GOV-03
    verification:
      - kind: other
        ref: "PowerShell README token, manifest/package target-set equality, manifest dependency, and CHANGELOG Unreleased assertions plus checked-document build"
        status: pass
    human_judgment: false

duration: 5min
completed: 2026-07-16
status: complete
---

# Phase 01 Plan 05: Private mb-color Publication Scaffold Summary

**A deterministic package-private MoonBit probe now proves mb-color across four targets while its generated interface stays limited to the package declaration and checked docs state the candidate color boundary.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-07-16T07:54:47Z
- **Completed:** 2026-07-16T07:59:18Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added a package-private deterministic mb-color probe through a fail-first white-box test and warning-free implementation.
- Proved the generated interface has exactly one semantic line, `package "moonbit-foundation/mb-color"`, with no public color API.
- Added checked candidate status, ownership boundaries, four-target support, mb-core dependency, independent versioning, publication block, and an Unreleased changelog.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: Add failing private scaffold proof** - `fdb0f09` (test)
2. **Task 1 GREEN: Implement private mb-color scaffold** - `0ff8406` (feat)
3. **Task 2: Document the mb-color publication unit** - `9e882dc` (docs)
4. **Overall verification fix: Remove unusable empty-package import** - `af809a8` (fix)

## Files Created/Modified

- `modules/mb-color/scaffold.mbt` - Warning-free package-private deterministic build probe.
- `modules/mb-color/scaffold_wbtest.mbt` - White-box test that exercises the private probe on all declared targets.
- `modules/mb-color/README.mbt.md` - Checked candidate status, boundaries, target matrix, dependency, independent versioning, and publication block.
- `modules/mb-color/CHANGELOG.md` - Independent Unreleased ledger without a false release claim.
- `modules/mb-color/moon.pkg` - Four-target empty root package with no unusable source import.

## Decisions Made

- Used `_scaffold_probe` rather than a public declaration so deny-warn checks pass without widening the interface.
- Kept `moonbit-foundation/mb-core` as the module-level release dependency, but removed its root-package import because mb-core deliberately exports no symbol in Phase 1.
- Kept documentation executable but example-free because Phase 1 intentionally has no public color API to demonstrate.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Removed the unusable package-level mb-core import**

- **Found during:** Task 1 GREEN deny-warn verification
- **Issue:** `mb-color/moon.pkg` imported mb-core, but Plan 01-04 intentionally leaves mb-core's generated interface with only its package declaration. No legal symbol could consume that import, so the pinned compiler emitted `unused_package` and failed `--deny-warn`.
- **Fix:** Removed the source-package import while preserving the normal `0.1.0` mb-core dependency in `mb-color/moon.mod.json`, the documented inward boundary, and the exact package target set. This follows the compiler's fail-closed guidance without suppressing warnings or inventing public API.
- **Files modified:** `modules/mb-color/moon.pkg`
- **Verification:** Module-scoped four-target deny-warn check passed; test passed 1/1 on every target; info and exact semantic-interface classification passed.
- **Committed in:** `af809a8`

**2. [Rule 3 - Blocking] Scoped execution-time deny-warn validation to the current package**

- **Found during:** Overall Plan 01-05 verification
- **Issue:** The exact unscoped module command traverses the ancestor workspace and still encounters mb-image's intentionally unused imports before Plan 01-06 creates its empty dependent package surface.
- **Fix:** Used the current-package selector (`check .`) for Plan 01-05 execution without altering warning policy. The plan's original unscoped workspace deny-warn command remains unchanged and must be rerun after Plan 01-06.
- **Files modified:** None.
- **Verification:** mb-color itself passes the exact four-target deny-warn policy; only the not-yet-executed mb-image member remains outside this plan's scope.
- **Committed in:** No code change; verification sequencing only.

---

**Total deviations:** 2 auto-fixed (2 blocking issues).
**Impact on plan:** Both fixes preserve the empty public interface and strict warning policy. The module-level dependency, documentation, target equality, and independent publication unit remain intact; workspace aggregation is deferred only until its planned sibling scaffold exists.

## Issues Encountered

- `moon info` operates in workspace context and reports the remaining mb-image unused-package warnings. Its generated mb-color interface is nevertheless exact; the aggregate deny-warn rerun remains a post-Wave-2 obligation after Plan 01-06.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 01-06 can apply the same empty-dependent-package rule to mb-image while retaining its module dependencies.
- After Plan 01-06, rerun the plan's exact unscoped workspace deny-warn command without warning suppression.
- Phase 3 can add real mb-core imports only when mb-color consumes actual public core contracts.

## Self-Check: PASSED

- All five created or modified artifacts exist.
- RED `fdb0f09`, GREEN `0ff8406`, documentation `9e882dc`, and verification fix `af809a8` commits exist in repository history.
- Module-scoped four-target deny-warn check, four-target tests, info generation, exact interface classifier, README/metadata target-set equality, module dependency, and changelog assertions passed.
- Stub and threat-surface scans found no unplanned public or security-relevant surface; the private scaffold is the intentional deliverable.

---
*Phase: 01-foundation-charter-and-reproducible-workspace*
*Completed: 2026-07-16*
