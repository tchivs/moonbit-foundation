---
phase: 99-simple-and-composite-outlines
plan: 01
subsystem: font
tags: [moonbit, truetype, glyf, path2, q15, budget]
requires:
  - phase: 98-unicode-mapping-and-kerning
    provides: admitted Font values, opaque glyph identifiers, guarded queries, cmap, and kerning
provides:
  - guarded Font::outline query returning an exact Path2 for simple TrueType glyphs
  - strict simple-glyf decoding with checked Q15 geometry and transactional publication
  - retained outline limits, maxp validation, cumulative max_work, and caller Budget enforcement
affects: [99-02, 99-03, 100-real-font-qualification]
tech-stack:
  added: []
  patterns:
    - guard-decode-guard-publish
    - checked-int64-q15
    - staged-resource-charging
key-files:
  created:
    - modules/mb-font/font/outline.mbt
  modified:
    - modules/mb-font/font/font.mbt
    - modules/mb-font/font/limits.mbt
    - modules/mb-font/font/tables.mbt
    - modules/mb-font/font/moon.pkg
    - modules/mb-font/font/font_test.mbt
    - modules/mb-font/font/font_wbtest.mbt
    - modules/mb-font/font/generated_fonts_wbtest.mbt
key-decisions:
  - Keep all simple-outline format arithmetic in private checked Int64 Q15 until final Point2 construction.
  - Enforce maxp claims, retained FontLimits/max_work, and caller Budget cumulatively before traversal or allocation.
  - Keep pkg.generated.mbti as ignored local tool output while recording its semantic baseline and final hashes.
patterns-established:
  - Public font queries use pre-revision guard, receiving-font glyph validation, private decode, post-revision guard, then single-value publication.
  - Hostile variable-length font data is validated and charged before scratch or output allocation.
requirements-completed: [FONT-03]
coverage:
  - dimension: guarded direct Path2 query
    reference: focused native outline tests
    status: pass
  - dimension: exact simple-glyf decoding and Q15 lowering
    reference: 12 focused native outline tests
    status: pass
  - dimension: limits, maxp, max_work, Budget, and hostile boundaries
    reference: 75 native font package tests
    status: pass
metrics:
  duration: 21min
  completed: 2026-07-27
status: complete
---

# Phase 99 Plan 01: Transactional Simple TrueType Outlines Summary

**Strict, budgeted simple-glyf decoding now produces exact Q15 `Path2` geometry through a guarded, no-partial-publication `Font::outline` query.**

## Performance

- **Duration:** 21 minutes
- **Started:** 2026-07-27T10:06:20Z
- **Completed:** 2026-07-27T10:27:00Z
- **Tasks:** 2
- **Tracked files changed:** 8

## Accomplishments

- Added the public `Font::outline` query with pre/post revision validation, receiving-font glyph checks, and one-shot publication of a private decoded path.
- Implemented the complete simple TrueType outline path: strict loca/glyf framing, endpoints and instruction handling, repeated flags, every coordinate delta form, implied on-curve lowering, contours, and exact close behavior.
- Enforced `maxp`, retained `FontLimits`, cumulative `max_work`, and independent caller `Budget` limits before traversal and allocation.
- Added hostile-boundary coverage for reserved flags, repeat overflow, trailing padding, malformed geometry, resource limits, Q15 overflow, mutation during decode, zero-contour glyphs, and degenerate contours.

## Task Commits

### Task 1: Repair the interface baseline and trace guarded simple-outline extraction

- `e091fc0f` — test(99-01): add failing simple outline tracer
- `55f78671` — test(99-01): extend failing outline transaction cases
- `bd5f776d` — feat(99-01): trace guarded simple outline extraction

### Task 2: Complete strict simple-outline hostile boundaries and resource enforcement

- `47b518f8` — test(99-01): add failing full simple outline boundaries
- `00f73565` — feat(99-01): complete bounded simple outline decoding

## Files Created/Modified

- `modules/mb-font/font/outline.mbt` — Private strict simple-glyf decoder, resource ledger, checked Q15 lowering, and transactional outline result.
- `modules/mb-font/font/font.mbt` — Public guarded `Font::outline` query and private post-decode hook.
- `modules/mb-font/font/limits.mbt` — Nonzero outline point, contour, component, and instruction-byte limits.
- `modules/mb-font/font/tables.mbt` — Retained TrueType `maxp` version-1 outline maxima.
- `modules/mb-font/font/moon.pkg` — Narrow `tchivs/mb-core/math` dependency for `Path2` and geometry values.
- `modules/mb-font/font/font_test.mbt` — Public exact-path and transactional-query tests.
- `modules/mb-font/font/font_wbtest.mbt` — Private hostile-decoder, Q15, and resource-boundary tests.
- `modules/mb-font/font/generated_fonts_wbtest.mbt` — Checksum-correct simple, empty, degenerate, and configurable-maxp font fixtures.
- `modules/mb-font/font/pkg.generated.mbti` — Locally regenerated ignored interface evidence; intentionally not force-staged.

## Decisions Made

- Simple-glyf arithmetic remains private and uses checked `Int64` Q15 values until `Point2` creation, avoiding silent narrowing and floating-point drift.
- Resource accounting is cumulative and ordered: table-declared maxima, retained admission limits/max_work, and the per-call `Budget` all pass before scratch or output allocation.
- The generated interface remains normal ignored tool output. The repaired Phase 98 baseline semantic hash was `f8058722f34e1f54a6c5dcbd5e8960a4d29a48d9561382599c9ec20e56d92ade`; the final Phase 99 interface hash is `d5bb5e76fe1448554aff2cf58e84b7a316d6f2255740736540cca956d89906e0`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Regenerated the absent ignored interface baseline**

- **Found during:** Pre-task Phase 98 baseline repair
- **Issue:** A clean worktree omitted `pkg.generated.mbti` because repository policy ignores generated interface artifacts, so the stale baseline named by research was not present locally.
- **Fix:** Ran the required all-target `moon info` command before public source edits, verified the repaired baseline contained only the Phase 98 API additions, recorded its semantic hash, and left the regenerated artifact ignored rather than force-staging it.
- **Files modified:** `modules/mb-font/font/pkg.generated.mbti` (ignored local evidence)
- **Commit:** Not committed by repository policy

**2. [Rule 3 - Blocking] Repaired legacy plan-position fields for the state SDK**

- **Found during:** Final state update
- **Issue:** `STATE.md` still encoded Phase 99 as `Plan: Not started` with zero-valued plan counters, so `state.advance-plan` could not parse the current/total position after Plan 01 completed.
- **Fix:** Initialized the existing Phase 99 position to `1 of 3` and reran the SDK handler so it could advance the project to Plan 02 without bypassing normal progress bookkeeping.
- **Files modified:** `.planning/STATE.md`
- **Commit:** Included in the plan metadata commit

## Issues Encountered

- The first exact-budget test accidentally used its small query `max_work` value during `Font::open`, constraining admission instead of only the outline call. The fixture now retains the normal admission limit and asserts exact-fit/one-short behavior with an independent caller `Budget`.

## Verification

- `moon -C modules/mb-font check --target native --frozen` — passed.
- `moon -C modules/mb-font test font --target native --frozen --target-dir target/phase99-simple-full-postfmt --no-parallelize -f '*outline*'` — 12/12 passed.
- `moon -C modules/mb-font test font --target native --frozen --target-dir target/phase99-plan01-native --no-parallelize` — 75/75 passed.
- `moon -C modules/mb-font info --target all --frozen --target-dir target/phase99-plan01-interface` — passed.
- `git diff --check` — passed before the final task commit.

## Known Stubs

None. Empty arrays found by the stub scan are live decoder/builders populated during strict parsing and lowering; no placeholder data path, TODO, FIXME, skipped test, or incomplete publication remains.

## User Setup Required

None.

## Next Phase Readiness

- The direct simple-glyph path and resource ledger are ready for Plan 99-02 to add composite traversal without changing the public query contract.
- Retained composite `maxp` facts and the four component-related `FontLimits` inputs are already available for the next plan.

## Self-Check: PASSED

- All eight tracked source/test files and the ignored local generated interface exist.
- All five RED/GREEN task commits are present in repository history.
- Required focused, full native package, native check, and all-target interface gates passed.
