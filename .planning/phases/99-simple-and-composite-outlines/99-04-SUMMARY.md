---
phase: 99-simple-and-composite-outlines
plan: 04
subsystem: font-publication
tags: [moonbit, truetype, policy, documentation, conformance]

requires:
  - phase: 99-simple-and-composite-outlines
    provides: "Verified simple and bounded one-level composite Path2 outlines from Plans 99-01 through 99-03."
provides:
  - "Exact policy-to-manifest Phase 99 mb-font description synchronization."
  - "Focused manifest-description drift rejection in Assert-FontFoundationPolicy."
  - "Executable maxp/Data and FontLimits/max_work/Budget/Resource README taxonomy enforcement."
affects: [phase-99-verification, phase-100-font-qualification, mb-font-publication]

tech-stack:
  added: []
  patterns:
    - "Focused policy selectors independently enforce publication metadata required by their closure lane."
    - "Documentation taxonomy checks isolate semantic bullets before asserting required and forbidden terms."

key-files:
  created:
    - .planning/phases/99-simple-and-composite-outlines/99-04-SUMMARY.md
  modified:
    - modules/mb-font/moon.mod.json
    - scripts/quality/Assert-Policy.ps1
    - modules/mb-font/README.mbt.md

key-decisions:
  - "The focused font selector owns a case-sensitive manifest-description equality check in addition to the repository-wide selector."
  - "README taxonomy enforcement is bullet-scoped: maxp underclaims are Data, while only retained FontLimits, cumulative max_work, and caller Budget exhaustion are Resource."

patterns-established:
  - "Publication drift tests use a committed failing oracle, a real-data correction, and a temporary negative fixture."
  - "Public error-taxonomy prose is checked at the individual category-bullet boundary."

requirements-completed: [FONT-03]

coverage:
  - id: D1
    description: "The mb-font manifest carries the exact approved Phase 99 description and the focused selector rejects future description drift."
    requirement: FONT-03
    verification:
      - kind: integration
        ref: "Assert-FontFoundationPolicy and Assert-FoundationPolicy against policy/foundation.json, plus a temporary manifest-description drift fixture"
        status: pass
    human_judgment: false
  - id: D2
    description: "The executable README classifies maxp underclaims as Data and retained FontLimits, max_work, and Budget exhaustion as Resource on all four targets."
    requirement: FONT-03
    verification:
      - kind: integration
        ref: "moon -C modules/mb-font check README.mbt.md --target <native|js|wasm|wasm-gc> --frozen --target-dir <unique> --serial"
        status: pass
      - kind: integration
        ref: "moon -C modules/mb-font test font --target <native|js|wasm|wasm-gc> --frozen --target-dir <unique> --no-parallelize (92/92 each)"
        status: pass
    human_judgment: false

duration: 4min
completed: 2026-07-27
status: complete
---

# Phase 99 Plan 04: Publication Gap Closure Summary

**Case-sensitive manifest synchronization and bullet-scoped error-taxonomy policy checks close the two Phase 99 publication gaps without changing runtime code or the public interface.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-07-27T12:34:29Z
- **Completed:** 2026-07-27T12:37:58Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added an independent focused manifest-description equality check and proved it red against both the stale manifest and a temporary drift fixture.
- Synchronized only the mb-font manifest description with the exact approved Phase 99 policy text.
- Added bullet-scoped README taxonomy assertions and corrected the public contract so maxp underclaims are Data while retained FontLimits, cumulative max_work, and caller Budget exhaustion are Resource.
- Re-ran focused and repository-wide policy gates, four executable README targets, and the complete 92-test font package on all four supported targets.

## Task Commits

Each task used the required failing-first TDD sequence:

1. **Task 1 RED: Add focused manifest drift proof** - `80382125` (test)
2. **Task 1 GREEN: Synchronize approved manifest description** - `b0f14623` (feat)
3. **Task 2 RED: Add focused README taxonomy proof** - `1cc30308` (test)
4. **Task 2 GREEN: Correct the outline failure taxonomy** - `a0d6d50f` (feat)

## Files Created/Modified

- `modules/mb-font/moon.mod.json` - Publishes the exact approved Phase 99 outline-capable module description.
- `scripts/quality/Assert-Policy.ps1` - Independently rejects font manifest-description drift and bullet-level README taxonomy drift.
- `modules/mb-font/README.mbt.md` - Documents maxp underclaims as malformed Data and caller-controlled ceiling exhaustion as Resource.
- `.planning/phases/99-simple-and-composite-outlines/99-04-SUMMARY.md` - Records gap-closure evidence and handoff metadata.

## Verification Evidence

- Pre-fix focused manifest gate: expected `Manifest description drift in modules/mb-font.` failure.
- Temporary policy fixture: expected focused manifest-description drift failure.
- Pre-fix focused README gate: expected Resource-taxonomy failure because the stale bullet included maxp.
- Final `Assert-FontFoundationPolicy -PolicyPath ./policy/foundation.json`: passed.
- Final `Assert-FoundationPolicy -PolicyPath ./policy/foundation.json`: passed.
- Literate `README.mbt.md` checks: passed independently on native, js, wasm, and wasm-gc using unique target directories.
- Full isolated font regression: 92/92 passed independently on native, js, wasm, and wasm-gc.
- `git diff --check`: passed.

## Decisions Made

- Kept the focused check intentionally narrow: it compares only the selected font policy description with the actual manifest and leaves name, version, target, dependency, and license ownership with the repository-wide selector.
- Scoped taxonomy checks to the individual Data and Resource bullets so unrelated README occurrences cannot produce a false green result.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Known Stubs

None.

## Security and Threat Review

- T-99-04-01 is mitigated by case-sensitive focused and repository-wide description checks plus the negative fixture.
- T-99-04-02 is mitigated by bullet-scoped Data/Resource assertions and the pre-fix red proof.
- T-99-04-03 is mitigated by both final policy gates, four-target literate checks, and four-target font regressions.
- No new network endpoint, authentication path, file-access boundary, schema, dependency, runtime behavior, or public interface was introduced.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 99 goal verification can refresh `99-VERIFICATION.md`; both previously failed publication truths now have fresh deterministic evidence.
- Phase 100 can retain its licensed real-font and complete-workflow qualification boundary unchanged.

## Self-Check: PASSED

- All three implementation/documentation artifacts and this summary exist.
- All four TDD task commits are present in repository history.

---
*Phase: 99-simple-and-composite-outlines*
*Completed: 2026-07-27*
