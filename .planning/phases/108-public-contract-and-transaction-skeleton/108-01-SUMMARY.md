---
phase: 108-public-contract-and-transaction-skeleton
plan: "01"
subsystem: text-shaping
tags: [moonbit, text-shaping, budget, transaction, immutable-api]

requires:
  - phase: 107-hostile-licensed-and-four-target-qualification
    provides: qualified retained-font authority, revision guards, and four-target font baseline
provides:
  - checked immutable ResourceCharge composition
  - request-scoped FontShapeScope authority with one guarded budget commit
  - portable tchivs/mb-text public contract and production empty-shape tracer
  - opaque immutable shaped-run values and fail-closed nonempty behavior
affects: [108-02, 108-03, 109-layout-admission, 110-gsub, 111-gpos]

tech-stack:
  added: [tchivs/mb-text]
  patterns:
    - generic continuation stages value plus immutable charge
    - final retained-source guard precedes the sole hierarchical budget commit
    - public-abstract scope invalidates shared authority on callback exit

key-files:
  created:
    - modules/mb-font/font/shape_transaction.mbt
    - modules/mb-text/text/tags.mbt
    - modules/mb-text/text/options.mbt
    - modules/mb-text/text/limits.mbt
    - modules/mb-text/text/run.mbt
    - modules/mb-text/text/shape.mbt
  modified:
    - modules/mb-core/budget/budget.mbt
    - modules/mb-core/budget/budget_test.mbt
    - modules/mb-font/font/shape_transaction_test.mbt
    - modules/mb-text/text/contract_test.mbt
    - modules/mb-text/text/moon.pkg
    - modules/mb-text/moon.mod.json
    - moon.work

key-decisions:
  - "ResourceCharge composition adds consumable dimensions with checked arithmetic and takes maxima for per-operation ceilings."
  - "Font::with_shape_transaction owns scope invalidation, final source validation, and the only Budget::charge call."
  - "The public nonempty shaping route returns CapabilityUnavailable until selected layout authority is admitted."

patterns-established:
  - "Stage-guard-commit: callbacks return an immutable value/charge pair; the owner composes, preflights, guards, charges once, then publishes."
  - "Escapable nominal scope, unusable authority: every alias shares an active cell closed by defer."

requirements-completed: [TXT-01, TXT-02]

coverage:
  - id: D1
    description: "Closed public shape contract validates explicit inputs and returns an opaque empty run through the real three-module path."
    requirement: TXT-01
    verification:
      - kind: integration
        ref: "modules/mb-text/text/contract_test.mbt#empty shape traverses one transaction and charges work exactly once"
        status: pass
      - kind: other
        ref: "moon -C modules/mb-text info --target all --frozen"
        status: pass
    human_judgment: false
  - id: D2
    description: "Checked charge composition and font-owned transaction commit preserve caller and ancestor budget atomicity."
    requirement: TXT-02
    verification:
      - kind: unit
        ref: "modules/mb-core/budget/budget_test.mbt#resource charge checked composition"
        status: pass
      - kind: integration
        ref: "modules/mb-font/font/shape_transaction_test.mbt#exact, one-short, drift, and escaped-scope cases"
        status: pass
    human_judgment: false
  - id: D3
    description: "The new module and affected contracts compile and pass focused tests on js, wasm, wasm-gc, and native."
    requirement: TXT-02
    verification:
      - kind: other
        ref: "four-target affected-module check and focused-test matrix"
        status: pass
    human_judgment: false

duration: 21min
completed: 2026-07-30
status: complete
---

# Phase 108 Plan 01: Empty Shaping Transaction Tracer Summary

**A closed `mb-text` shaping API now carries valid empty requests through retained-font authority and one checked hierarchical budget commit on all four MoonBit targets.**

## Performance

- **Duration:** 21 min
- **Started:** 2026-07-29T21:04:01Z
- **Completed:** 2026-07-29T21:24:29Z
- **Tasks:** 1
- **Files modified:** 13

## Accomplishments

- Added pure checked `ResourceCharge` composition with exact overflow diagnostics and max-ceiling semantics.
- Added the exact generic `Font::with_shape_transaction[T]` seam, shared-cell scope invalidation, entry/final revision guards, and one commit point.
- Added `tchivs/mb-text@0.1.0` with closed tags/options/limits, opaque run values, an exact-work empty tracer, and a fail-closed nonempty route.
- Proved success, one-short failure, invalid-input precedence, source drift, escaped-scope invalidation, and ancestor budget atomicity on all four targets.

## Task Commits

TDD gates and implementation were committed atomically:

1. **Task 1 RED: Add failing shaping transaction tracer tests** - `6942cd67` (test)
2. **Task 1 GREEN: Implement empty shaping transaction tracer** - `85f765ad` (feat)

## Files Created/Modified

- `modules/mb-core/budget/budget.mbt` - Checked immutable charge composition.
- `modules/mb-font/font/shape_transaction.mbt` - Opaque scope and sole guarded commit harness.
- `modules/mb-text/moon.mod.json` - Independent portable text module manifest.
- `modules/mb-text/text/tags.mbt` - Checked script and language tags.
- `modules/mb-text/text/options.mbt` - Closed language, direction, and feature policy values.
- `modules/mb-text/text/limits.mbt` - Exact two-field nonzero shaping limits.
- `modules/mb-text/text/run.mbt` - Opaque positioned glyph and immutable run contracts.
- `modules/mb-text/text/shape.mbt` - Public empty tracer and nonempty capability boundary.
- `modules/mb-core/budget/budget_test.mbt` - Composition, ceiling, and overflow evidence.
- `modules/mb-font/font/shape_transaction_test.mbt` - Commit, drift, ancestor, and escaped-scope evidence.
- `modules/mb-text/text/contract_test.mbt` - Public contract and error-precedence evidence.
- `modules/mb-text/text/moon.pkg` - Exact package imports and four-target support.
- `moon.work` - Local workspace membership for `mb-text`.

## Decisions Made

- Kept the compile-proved generic tuple callback unchanged; no separate transaction outcome type or public commit handle was introduced.
- Made scope closure observable by every escaped alias through the scope's shared mutable active cell.
- Kept nonempty requests behind a stable Capability error instead of approximating shaping from cmap or metrics.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Replaced a malformed hand-transcribed test font with a deterministic valid fixture builder**

- **Found during:** Task 1 GREEN verification
- **Issue:** The initial embedded font bytes were truncated, so the public tracer test failed during font admission rather than exercising shaping.
- **Fix:** Built the minimal font fixture deterministically with exact table offsets and checksums.
- **Files modified:** `modules/mb-text/text/contract_test.mbt`
- **Verification:** Text contract tests pass on js, wasm, wasm-gc, and native.
- **Committed in:** `85f765ad`

**2. [Rule 3 - Blocking] Repaired stale plan position before state advancement**

- **Found during:** Plan metadata update
- **Issue:** `.planning/STATE.md` still said `Plan: Not planned`, so `state.advance-plan` could not parse the current and total plan numbers.
- **Fix:** Restored the actual `Plan: 1 of 5` position, reran the SDK successfully, and normalized the resulting Plan 2 activity and Phase 108 decision labels.
- **Files modified:** `.planning/STATE.md`
- **Verification:** `state.advance-plan` reported `previous_plan: 1`, `current_plan: 2`, `total_plans: 5`.
- **Committed in:** Plan metadata commit

---

**Total deviations:** 2 auto-fixed (1 bug, 1 blocking state repair).
**Impact on plan:** The repairs keep test evidence deterministic and planning state accurate; production scope is unchanged.

## Issues Encountered

- `moon -C modules/mb-text check --target native --deny-warn --frozen` is blocked by pre-existing unused-code warnings in out-of-scope `mb-font` CFF files. The ordinary check and all focused core/font/text tests pass on js, wasm, wasm-gc, and native. The exact warning gate is recorded in `.planning/WINDOWS.md`.
- A package-wide formatter touched unrelated font files; those exact accidental edits were restored before the GREEN commit.

## Deferred Issues

- Clear the pre-existing `mb-font` CFF warning backlog before requiring dependency-wide `--deny-warn` from `mb-text`.

## Known Stubs

None. The empty record array is the required production empty result, and the nonempty Capability failure is the explicit Phase 108 boundary.

## Threat Flags

None. New caller-input, retained-font, budget, and generated-interface trust boundaries are all covered by the plan threat model and black-box tests.

## TDD Gate Compliance

- RED gate: `6942cd67`
- GREEN gate: `85f765ad`
- RED precedes GREEN and the RED suites failed for the intended missing symbols before implementation.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The exact public call, value names, generic font seam, and sole commit path are ready for Plan 108-02 numeric/run hardening and Plan 108-03 ownership enforcement.
- Nonempty layout remains deliberately unavailable until selected layout authority is admitted.

## Self-Check: PASSED

All 13 planned files and both TDD task commits were found, and RED precedes GREEN in history.

---
*Phase: 108-public-contract-and-transaction-skeleton*
*Completed: 2026-07-30*
