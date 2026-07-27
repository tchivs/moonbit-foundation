---
phase: 100-portable-font-qualification
plan: "04"
subsystem: quality
tags: [moonbit, powershell, font-policy, fixtures, cross-target, release-qualification]

requires:
  - phase: 100-portable-font-qualification
    provides: Plans 01-03 licensed fixtures, closed oracle/case schemas, public workflow tests, and evidence runner
provides:
  - Dedicated FontQualification quality lane separate from the repository Required lane
  - Exact font fixture, publication, test-source, interface, dependency, and capability-boundary audits
  - Fail-closed js, wasm, wasm-gc, and native semantic evidence comparison
affects: [100-05, font-release-qualification, fixture-policy, dependency-policy]

tech-stack:
  added: []
  patterns:
    - Source-aware portable-capability audits strip comments and literals before checking executable calls
    - Target evidence is written only after every isolated check and test succeeds

key-files:
  created: []
  modified:
    - scripts/quality/Invoke-FontQualification.ps1
    - scripts/quality/Assert-Policy.ps1
    - scripts/quality/Test-FixturePolicy.ps1
    - scripts/quality.ps1
    - policy/foundation.json

key-decisions:
  - "Keep FontQualification as a dedicated selector that forwards EvidenceDirectory and never invokes or replaces Required."
  - "Audit executable MoonBit source separately from comments and string literals so provenance text and unsupported-profile test data cannot self-trigger capability gates."
  - "Remove only target and runner metadata from comparison; every public, hostile, fixture, toolchain, and dependency fact remains byte-visible."

patterns-established:
  - "Qualification inventory: production files remain frozen while generated, workflow, and hostile tests are explicitly ordered."
  - "Evidence closure: require exact target order, closed record schemas, all hostile IDs, and negative missing/divergent probes."

requirements-completed: [FONT-05]

coverage:
  - id: D1
    description: Dedicated focused selector freezes fixtures, schemas, inventories, interface, and dependency scope without entering Required.
    requirement: FONT-05
    verification:
      - kind: integration
        ref: "./scripts/quality.ps1 -Lane FontQualification -EvidenceDirectory artifacts/release-qualification/font-plan04"
        status: pass
    human_judgment: false
  - id: D2
    description: Source-aware policy rejects forbidden host, FFI, GUI, shaping, hinting, CFF, and rasterization execution plus public API or dependency expansion.
    requirement: FONT-05
    verification:
      - kind: integration
        ref: "Assert-FontFoundationPolicy and embedded negative probes in scripts/quality/Assert-Policy.ps1"
        status: pass
      - kind: unit
        ref: "./scripts/quality/Test-FixturePolicy.ps1"
        status: pass
    human_judgment: false
  - id: D3
    description: All four production targets pass the complete 102-test font suite and emit identical normalized semantic evidence.
    requirement: FONT-05
    verification:
      - kind: e2e
        ref: "artifacts/release-qualification/font-plan04/comparison.json equal=true, semantic SHA-256 c152549e7077ed1a79397b6f38818bdf523c596a72dd4188dc7cc21159cdcefc"
        status: pass
    human_judgment: false

duration: 10min
completed: 2026-07-27
status: complete
---

# Phase 100 Plan 04: Focused Font Qualification Boundary Summary

**One fail-closed selector now proves exact font provenance, policy, interface, dependency, and byte-equivalent semantics across all four production targets.**

## Performance

- **Duration:** 10 minutes
- **Started:** 2026-07-27T14:50:42Z
- **Completed:** 2026-07-27T15:00:08Z
- **Tasks:** 1
- **Files modified:** 5

## Accomplishments

- Closed the Plan 01 policy inventory mismatch by adding the generated, workflow, and hostile qualification tests without changing production sources or the 56-line public interface.
- Added exact DejaVu font/notice provenance, oracle/case schema, manifest-order, generator-header, module/package dependency, and executable capability audits with focused negative probes.
- Added the standalone `FontQualification` lane and required four isolated check/test runs, four evidence records, strict semantic comparison, and four literate README checks.

## Task Commits

Each task was committed atomically:

1. **Task 1: Freeze the focused selector, exact inventories, and negative capability boundary** - `a46bd8ce` (feat)

## Files Created/Modified

- `scripts/quality/Invoke-FontQualification.ps1` - Runs ordered policy, four-target, evidence, divergence, and README gates.
- `scripts/quality/Assert-Policy.ps1` - Freezes Phase 100 artifacts and source-aware capability/dependency boundaries.
- `scripts/quality/Test-FixturePolicy.ps1` - Rejects font/notice digest, license, redistribution, containment, and ordering drift.
- `scripts/quality.ps1` - Dispatches the focused lane while preserving the existing Required dispatch.
- `policy/foundation.json` - Inventories the three Phase 100 test sources and publication files.

## Decisions Made

- Kept the focused lane independent from `Required`; Plan 05 remains the owner of documentation, CI, and any bounded Required wrapper.
- Treated comments, string literals, and hostile unsupported-format tags as non-executable evidence while rejecting forbidden imports, annotations, and calls.
- Required evidence targets in canonical `js`, `wasm`, `wasm-gc`, `native` order and normalized only top-level target/runner fields.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Synchronized GSD state advancement metadata**

- **Found during:** Final state validation
- **Issue:** `state.advance-plan` moved the Current Position body to Plan 5 but left `current_plan: 4` in frontmatter; decision records were also labeled `Phase ?`.
- **Fix:** Synchronized the frontmatter counter, attributed the three decisions to Phase 100, and updated the last-activity and operator-next-step fields.
- **Files modified:** `.planning/STATE.md`
- **Verification:** Machine-readable and prose state both identify Plan 5 of 5, and no unattributed Phase 100 decisions remain.
- **Committed in:** Final plan metadata commit.

---

**Total deviations:** 1 auto-fixed (Rule 3 blocking metadata inconsistency)
**Impact on plan:** Planning metadata only; selector behavior and qualification evidence are unchanged.

## Issues Encountered

- The inherited policy expected only the pre-Phase-100 package inventory. This was the planned Plan 01 mismatch and was resolved by the exact three-file inventory update; no additional policy mismatch was found.

## Verification

- Focused selector passed generation, policy, interface, dependency, portable-source, and README gates.
- `moon check` and the complete `moon test font` suite passed independently on `js`, `wasm`, `wasm-gc`, and `native`; each target reported 102/102 passing tests.
- Fixture policy passed its generic matrix and eight font-specific provenance/order negatives.
- Comparison records all four targets, `equal=true`, and semantic SHA-256 `c152549e7077ed1a79397b6f38818bdf523c596a72dd4188dc7cc21159cdcefc`.
- Direct module dependency remains exactly `tchivs/mb-core`.

## Known Stubs

None.

## User Setup Required

None - qualification is offline against committed immutable fixtures.

## Next Phase Readiness

- Plan 100-05 can consume the validated focused evidence directory without changing selector semantics.
- Documentation, CI upload semantics, and bounded Required execution remain intentionally reserved for Plan 100-05.

## Self-Check: PASSED

- All five task artifacts, this summary, and the five generated evidence records exist.
- Task commit `a46bd8ce` resolves in repository history.
- The exact plan verification block completed successfully after the task commit.

---
*Phase: 100-portable-font-qualification*
*Completed: 2026-07-27*
