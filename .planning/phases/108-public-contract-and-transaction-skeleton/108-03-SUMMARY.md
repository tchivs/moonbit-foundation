---
phase: 108-public-contract-and-transaction-skeleton
plan: "03"
subsystem: font-authority
tags: [moonbit, font, glyph-identity, transactions, budgets]

requires:
  - phase: 108-01
    provides: checked charge composition and the public shaping transaction tracer
  - phase: 108-02
    provides: portable checked signed arithmetic for downstream shaping
provides:
  - opaque GlyphId values bound to physical Font identity
  - runtime-inert escaped FontShapeScope values
  - named private source-revision probes and one atomic hierarchy charge
affects: [108-04, mb-text-shaping, glyph-consumers]

tech-stack:
  added: []
  patterns:
    - private physical owner identity checked before glyph range or table access
    - defer-closed shared scope capability with active-first operations
    - immutable charge composition followed by preflight, final guard, and one commit

key-files:
  created:
    - modules/mb-font/font/shape_transaction_wbtest.mbt
  modified:
    - modules/mb-core/budget/budget_wbtest.mbt
    - modules/mb-font/font/font.mbt
    - modules/mb-font/font/font_test.mbt
    - modules/mb-font/font/font_wbtest.mbt
    - modules/mb-font/font/shape_transaction.mbt
    - modules/mb-font/font/shape_transaction_test.mbt
    - modules/mb-font/CHANGELOG.md

key-decisions:
  - "GlyphId stores a private Font reference and validates it with physical_equal; no registry or public owner token is introduced."
  - "The exact public generic tuple callback delegates to a private probe harness while FontShapeScope remains public-abstract and runtime-invalidated with defer."
  - "Font and text charges compose immutably, preflight the complete hierarchy, pass one final source guard, and reach exactly one Budget::charge call."

patterns-established:
  - "Opaque authority values retain their physical issuer and reject foreign values before numeric or storage work."
  - "Escapable generic capabilities become inert through shared runtime state rather than unsupported static lifetime claims."

requirements-completed: [TXT-01, TXT-02]

coverage:
  - id: D1
    description: "Aliases accept their GlyphId while distinct same-range Fonts fail with stable owner errors before metrics, kerning, outline, or budget work."
    requirement: TXT-01
    verification:
      - kind: unit
        ref: "modules/mb-font/font/font_test.mbt#same-range glyph authority accepts aliases and rejects distinct Fonts before work"
        status: pass
      - kind: unit
        ref: "modules/mb-font/font/font_wbtest.mbt#glyph owner identity is the physical Font and remains private"
        status: pass
    human_judgment: false
  - id: D2
    description: "Escaped scopes close on success and error; every named mutation probe returns State before later faults and preserves complete caller/ancestor budgets."
    requirement: TXT-01
    verification:
      - kind: unit
        ref: "modules/mb-font/font/shape_transaction_test.mbt"
        status: pass
      - kind: unit
        ref: "modules/mb-font/font/shape_transaction_wbtest.mbt"
        status: pass
    human_judgment: false
  - id: D3
    description: "Checked combined charges succeed exactly once and fail atomically for one-short and every additive overflow dimension."
    requirement: TXT-02
    verification:
      - kind: unit
        ref: "modules/mb-core/budget/budget_wbtest.mbt"
        status: pass
      - kind: unit
        ref: "modules/mb-font/font/shape_transaction_wbtest.mbt#combined transaction charge commits exact hierarchy once and fails atomically"
        status: pass
    human_judgment: false
  - id: D4
    description: "The generated mb-font interface preserves all v0.34 Font/GlyphId signatures and exposes no owner, probe, or charge authority."
    requirement: TXT-01
    verification:
      - kind: other
        ref: "moon -C modules/mb-font info --target all --frozen"
        status: pass
    human_judgment: false
  - id: D5
    description: "Focused core budget and font tests pass on js, wasm, wasm-gc, and native."
    requirement: TXT-02
    verification:
      - kind: other
        ref: "moon -C modules/mb-core test budget --target <js|wasm|wasm-gc|native> --frozen"
        status: pass
      - kind: other
        ref: "moon -C modules/mb-font test font --target <js|wasm|wasm-gc|native> --frozen"
        status: pass
    human_judgment: false

duration: 17min
completed: 2026-07-30
status: complete
---

# Phase 108 Plan 03: Font Authority and Transaction Summary

**Physical Font-owned glyph identities and defer-closed shaping scopes now enforce same-font access, retained-source precedence, and one atomic combined budget commit.**

## Performance

- **Duration:** 17 min
- **Started:** 2026-07-29T21:37:42Z
- **Completed:** 2026-07-29T21:54:21Z
- **Tasks:** 1
- **Files modified:** 8

## Accomplishments

- Bound every constructed `GlyphId` to its physical `Font` and rejected distinct same-range fonts before glyph range, table, or outline budget work.
- Preserved the exact public transaction callback while adding private post-structure, post-capability, post-staging, and pre-final-guard revision probes.
- Proved runtime scope closure, complete charge composition, hierarchy-wide failure atomicity, and one exact success commit across all four production targets.
- Preserved the v0.34 public Font/GlyphId surface; generated interface evidence exposes only abstract private fields and the planned public transaction seam.

## Task Commits

TDD gates and implementation were committed atomically:

1. **Task 1 RED: Add failing font authority tests** - `f66b83ce` (test)
2. **Task 1 GREEN: Enforce font-owned shaping authority** - `4d566a59` (feat)

## Files Created/Modified

- `modules/mb-core/budget/budget_wbtest.mbt` - Per-dimension immutable charge composition and overflow coverage.
- `modules/mb-font/font/font.mbt` - Private Font ownership on GlyphId and owner-first validation at every consumer.
- `modules/mb-font/font/font_test.mbt` - Public alias/foreign-font matrix and complete outline budget snapshots.
- `modules/mb-font/font/font_wbtest.mbt` - Physical identity representation evidence.
- `modules/mb-font/font/shape_transaction.mbt` - Private revision probes, defer closure, combined preflight, final guard, and sole charge.
- `modules/mb-font/font/shape_transaction_test.mbt` - Captured/returned/error-path closed-scope behavior.
- `modules/mb-font/font/shape_transaction_wbtest.mbt` - Mutation precedence, ancestor atomicity, exact fit, one-short, and composition overflow evidence.
- `modules/mb-font/CHANGELOG.md` - Candidate-compatible owner and transaction contract record.

## Decisions Made

- Used direct private `Font` ownership plus `physical_equal`, preserving aliases without a global registry or forgeable numeric owner token.
- Kept all source probes and the aggregate font charge private; the public generic tuple callback remains byte-for-byte compatible.
- Performed no fallible callback or publication work after the sole `Budget::charge` call.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Replaced an outline-incomplete owner test fixture**

- **Found during:** Task 1 GREEN native verification
- **Issue:** The initial same-range owner matrix reused a metrics-focused fixture that did not contain a valid outline for its alias-success assertion.
- **Fix:** Reused the existing minimal valid TrueType fixture, preserving the intended equal-range/different-Font condition while making alias outline success meaningful.
- **Files modified:** `modules/mb-font/font/font_test.mbt`
- **Verification:** All 284 focused font tests pass on js, wasm, wasm-gc, and native.
- **Committed in:** `4d566a59`

**2. [Rule 3 - Blocking] Matched a scoped Result without requiring unavailable debug formatting**

- **Found during:** Task 1 GREEN verification
- **Issue:** Direct inspection of a `Result` containing `CoreError` required a debug representation that the error type intentionally does not expose.
- **Fix:** Matched the successful `units_per_em` result and propagated the typed error branch.
- **Files modified:** `modules/mb-font/font/shape_transaction_wbtest.mbt`
- **Verification:** The exact combined-charge and complete four-target font matrices pass.
- **Committed in:** `4d566a59`

---

**Total deviations:** 2 auto-fixed (1 fixture bug, 1 blocking test-harness correction).
**Impact on plan:** Both corrections improve test fidelity only; the production contract and planned scope are unchanged.

## Issues Encountered

- The exact `mb-font check --deny-warn` gate remains blocked by the pre-existing, out-of-scope CFF unused-field/function warnings already recorded by Plans 108-01 and 108-02. Warning-tolerant checks report zero errors on every target, all 284 font tests and all 14 budget tests pass per target, and `moon info --target all --frozen` succeeds.
- `moon fmt` expanded beyond the requested file list. Every formatter-only change was restored before commit; no out-of-scope file remains modified.

## Deferred Issues

- Clear the existing CFF warning backlog before treating module-wide `mb-font --deny-warn` as a clean phase gate.

## Known Stubs

None. The pre-existing `placeholder_top` local in the deterministic CFF test encoder is a computed offset-sizing pass, not a user-visible or unwired stub.

## Threat Flags

None. Glyph spoofing, retained-source mutation, escaped callback capability, and budget hierarchy tampering are the plan's declared threat surface and are covered by the focused tests.

## TDD Gate Compliance

- RED gate: `f66b83ce`
- GREEN gate: `4d566a59`
- RED failed on the absent GlyphId owner representation and private transaction probe harness; GREEN follows it and passes the four-target focused matrix.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 108-04 can consume the exact public generic transaction callback without gaining raw source, probe, scope-lifetime, or commit authority.
- Same-font GlyphId validation is ready for all downstream text shaping and projection paths.

## Self-Check: PASSED

All eight planned files, the summary artifact, both TDD commits, the four-target focused test matrix, and generated public interface evidence were verified. Aggregate phase state remains owned by the execute-phase orchestrator, and the pre-existing `.planning/config.json` change was neither staged nor modified.

---
*Phase: 108-public-contract-and-transaction-skeleton*
*Completed: 2026-07-30*
