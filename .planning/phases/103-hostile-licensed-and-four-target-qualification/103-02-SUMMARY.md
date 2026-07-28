---
phase: 103-hostile-licensed-and-four-target-qualification
plan: 02
subsystem: font-collection-qualification
tags: [moonbit, ttc, hostile-testing, budgets, mutation, portability, tdd]

requires:
  - phase: 103-hostile-licensed-and-four-target-qualification
    plan: 01
    provides: Frozen 97-case collection corpus, exact licensed TTC derivative, independent oracle, and portable generated mirror
  - phase: 102-root-relative-selected-face-admission
    provides: Existing collection-to-Font runtime and deterministic final-revision hooks
provides:
  - Named generated and licensed public collection-to-Font qualification workflows
  - Closed hostile, limit, budget, publication, and mutation qualification identities
  - Exact caller/ancestor atomicity and deterministic mid-operation mutation gates
  - Preserved named standalone baseline with equal four-target package behavior
affects: [103-03-v2-evidence-policy-ci-documentation]

tech-stack:
  added: []
  patterns:
    - Reuse one black-box semantic oracle for standalone and both selected licensed faces
    - Pair closed generated case identities with public runtime family assertions
    - Aggregate only existing deterministic final-revision hooks in white-box qualification

key-files:
  created: []
  modified:
    - modules/mb-font/font/font_qualification_test.mbt
    - modules/mb-font/font/font_qualification_hostile_test.mbt
    - modules/mb-font/font/collection_wbtest.mbt

key-decisions:
  - "Both licensed faces use the exact standalone DejaVu public-fact helper; collection internals never serve as the semantic oracle."
  - "The generated 97-case order is frozen as executable identity metadata while public operations prove structural, profile, resource, publication, and mutation behavior."
  - "Private qualification uses only FontCollection::open_after_normalize and open_face_after_admit, with mutate-then-restore and complete eight-field budget equality."

patterns-established:
  - "Focused evidence identity: each new Plan 103-02 test name independently filters to exactly one passing assertion."
  - "Atomic resource evidence: every failed caller or ancestor transaction compares all eight budget dimensions before and after."

requirements-completed:
  - TTC-04
  - TTC-05

coverage:
  - id: D1
    description: "Generated v1/v2, DSIG, sharing, mixed-profile, non-zero-directory, and licensed two-face workflows complete through public FontCollection and Font APIs."
    requirement: TTC-05
    verification:
      - kind: integration
        ref: "font-complete-public qualifies generated collection workflows"
        status: pass
      - kind: integration
        ref: "font-complete-public qualifies licensed DejaVu collection faces"
        status: pass
    human_judgment: false
  - id: D2
    description: "The closed collection corpus, structural and DSIG failures, unsupported profiles, limits, caller budgets, and ancestor budgets are exact and atomic."
    requirement: TTC-04
    verification:
      - kind: integration
        ref: "font qualification executes the closed collection hostile outcome matrix"
        status: pass
    human_judgment: false
  - id: D3
    description: "Public collection/Font mutation and private mid-open/mid-selection transitions reject stale facts and preserve complete resource state."
    requirement: TTC-04
    verification:
      - kind: integration
        ref: "font qualification preserves public collection mutation atomicity"
        status: pass
      - kind: unit
        ref: "collection qualification preserves mid-operation mutation atomicity"
        status: pass
    human_judgment: false
  - id: D4
    description: "The exact standalone named baseline and complete package pass without source-count locks on all four supported targets."
    requirement: TTC-05
    verification:
      - kind: integration
        ref: "moon -C modules/mb-font test font --target {js,wasm,wasm-gc,native} --frozen --no-parallelize (152 discovered passes each)"
        status: pass
      - kind: other
        ref: "moon -C modules/mb-font check --target all --frozen"
        status: pass
    human_judgment: false

duration: 35min
completed: 2026-07-28
status: complete
---

# Phase 103 Plan 02: Public, Hostile, and Mutation Qualification Summary

**Public collection workflows now reproduce generated and licensed Font facts while a closed, target-neutral hostile/resource/mutation suite preserves complete transaction atomicity and the standalone baseline.**

## Performance

- **Duration:** 35 min
- **Completed:** 2026-07-28T05:31:00Z
- **Tasks:** 2
- **Files modified:** 3
- **Discovered full-package result:** 152/152 on each target

## Accomplishments

- Refactored the independently audited standalone DejaVu assertions into one black-box helper and applied it unchanged to the standalone font and both licensed TTC faces.
- Added focused generated workflow qualification for v1/v2 collections, DSIG absent/present-unverified, exact sharing, mixed profiles, non-zero selected-directory admission, and static face selection.
- Froze all 97 generated identities in exact group order: 8 public, 24 hostile, 9 mutation, 44 limit, and 12 caller/ancestor-budget cases.
- Executed structural, search/tag/range/overlap, DSIG, index/profile, collection-limit, selected-limit, caller-budget, ancestor-budget, and unsupported-profile boundaries with exact public categories, codes, operations, contexts, requested/limit facts, and publication behavior.
- Proved complete eight-field caller and ancestor budget atomicity, permanent mutate-then-restore invalidation for collection and inherited Font queries, and deterministic mid-open/mid-selection rejection without partial objects.
- Preserved all five named standalone locks, frozen fixture hashes, generated symbols, production MoonBit, public interface, dependencies, and package behavior.

## Focused Assertion Identities

Plan 103-03 must consume these exact new identities:

1. `font-complete-public qualifies generated collection workflows`
2. `font-complete-public qualifies licensed DejaVu collection faces`
3. `font qualification executes the closed collection hostile outcome matrix`
4. `font qualification preserves public collection mutation atomicity`
5. `collection qualification preserves mid-operation mutation atomicity`

Each identity independently reports exactly one passing test under a focused native filter.

Inherited mid-query identities remain:

- `glyph_for_scalar rejects post-read revision drift`
- `kerning rejects post-read revision drift`
- `outline rejects post-decode revision drift without path publication`
- `composite outline rejects post-decode revision drift without publication`

## Task Commits

TDD gates and task outcomes were committed atomically:

1. **Task 1 RED: Public collection workflow gates** — `bfe82fd2`
2. **Task 1 GREEN: Generated and licensed public workflows** — `48a11138`
3. **Task 2 RED: Hostile and mutation qualification gates** — `2e7d995d`
4. **Task 2 GREEN: Closed hostile/resource/mutation qualification** — `60a1cc89`

## Files Modified

- `modules/mb-font/font/font_qualification_test.mbt` — reusable DejaVu public oracle plus generated and licensed collection workflows.
- `modules/mb-font/font/font_qualification_hostile_test.mbt` — exact 97-case identity lock, hostile/runtime families, resource atomicity, and public mutation qualification.
- `modules/mb-font/font/collection_wbtest.mbt` — complete eight-field budget helper and one focused mid-open/mid-selection mutation gate.

## Decisions Made

- Kept semantic equivalence entirely on opaque public `Font` observations: units, bounds, line metrics, scalar mappings, glyph identity, horizontal metrics, kerning, and complete simple/composite path commands.
- Treated CFF, CFF2, and variable profiles as inspectable collection facts but selection-local Capability failures; no execution path was added.
- Kept ordinary mutation black-box and used existing private hooks only for the two otherwise unobservable final-revision windows.
- Discovered full-package totals from each actual target run; no aggregate total is frozen in source.

## Deviations from Plan

None - plan executed within the three assigned test files and required no production change.

## Issues Encountered

- None. All failures during implementation were expected TDD RED gates or assertion refinements within the new qualification tests.

## User Setup Required

None - all qualification is deterministic and offline.

## Known Stubs

None.

## Next Phase Readiness

- Plan 103-03 can bind the five focused identities above verbatim into v2 evidence.
- Four-target focused totals are stable: public 5/5, hostile 3/3, collection white-box 14/14, inherited Font white-box 27/27, and full package 152/152 per target.
- The generator `-Check`, frozen standalone/collection fixture hashes, and target-all compile gate pass.
- No production MoonBit, generated fixture, public interface, dependency, policy, CI, documentation, or release artifact changed.
- No blockers remain.

## Self-Check: PASSED

All three assigned test files and this summary exist, all four TDD/task commits resolve, and the worktree contains no out-of-scope implementation changes.

---
*Phase: 103-hostile-licensed-and-four-target-qualification*
*Completed: 2026-07-28*
