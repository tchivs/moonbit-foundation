---
phase: 108-public-contract-and-transaction-skeleton
plan: "04"
subsystem: text-shaping
tags: [moonbit, unicode-scalars, immutable-runs, rtl, checked-arithmetic]

requires:
  - phase: 108-01
    provides: public empty shaping tracer and one font-owned transaction
  - phase: 108-02
    provides: checked signed Int64 addition, negation, and narrowing
  - phase: 108-03
    provides: owner-bound GlyphId and guarded single-commit font authority
provides:
  - copied and fully validated scalar and four-byte tag inputs
  - exact two-field nonzero ShapeLimits public contract
  - immutable positioned records with scalar-origin clusters and checked indexed access
  - final-only RTL reversal with advance-only negation and checked totals
  - private generated precedence, mutation, overflow, and atomic-charge fixtures
affects: [109-layout-admission, 110-gsub, 111-gpos, mb-text-public-contract]

tech-stack:
  added: []
  patterns:
    - validate complete mutable input then snapshot before authority access
    - stage logical records and project direction only at immutable publication
    - generated table-free contract facts remain private while public nonempty shaping fails closed

key-files:
  created:
    - modules/mb-text/text/contract_wbtest.mbt
  modified:
    - modules/mb-text/text/tags.mbt
    - modules/mb-text/text/run.mbt
    - modules/mb-text/text/shape.mbt
    - modules/mb-text/text/contract_test.mbt

key-decisions:
  - "Generated nonempty facts remain package-private and contain no GSUB, GPOS, GDEF, kern, source-byte, or selected-format authority."
  - "RTL projection negates checked advances and reverses only completed records; offsets and scalar-origin clusters remain attached unchanged."
  - "The exact two-field ShapeLimits surface from the tracer required no widening: new plus the two accessors remain the complete public limit API."

patterns-established:
  - "Request-owned identity: validate every scalar and copy the array before any Font operation; copy tags and staged records at their boundaries."
  - "Logical-first projection: checked base-plus-adjustment, direction projection, final record order, then checked total."
  - "Fail-closed staging: generated facts prove immutable run semantics privately while the public nonempty route remains CapabilityUnavailable."

requirements-completed: [TXT-01, TXT-02]

coverage:
  - id: D1
    description: "Scalar values, checked tags, closed options, and exact nonzero ShapeLimits are validated before Font authority and mutable scalar storage is snapshotted."
    requirement: TXT-01
    verification:
      - kind: unit
        ref: "modules/mb-text/text/contract_test.mbt#shape limits preserve exact values and reject input zero first"
        status: pass
      - kind: unit
        ref: "modules/mb-text/text/contract_wbtest.mbt#validated scalar snapshot preserves values adjacency and count after caller mutation"
        status: pass
    human_judgment: false
  - id: D2
    description: "Opaque runs preserve same-font glyph values, scalar clusters, exact LTR/RTL order, signed advances, unchanged offsets, and checked totals."
    requirement: TXT-02
    verification:
      - kind: unit
        ref: "modules/mb-text/text/contract_wbtest.mbt#generated logical records publish exact immutable LTR and RTL runs"
        status: pass
      - kind: unit
        ref: "modules/mb-text/text/contract_wbtest.mbt#equal adjacent records stay distinct and ligatures keep minimum scalar cluster"
        status: pass
      - kind: unit
        ref: "modules/mb-text/text/contract_wbtest.mbt#signed offset extremes remain unchanged through RTL projection"
        status: pass
    human_judgment: false
  - id: D3
    description: "Signed overflow, stage precedence, mutation seams, limits, and caller/ancestor charges fail or commit atomically through the real font transaction."
    requirement: TXT-02
    verification:
      - kind: unit
        ref: "modules/mb-text/text/contract_wbtest.mbt#generated projection rejects signed overflow before publication or charge"
        status: pass
      - kind: unit
        ref: "modules/mb-text/text/contract_wbtest.mbt#generated stage precedence is input state data capability then resource"
        status: pass
      - kind: unit
        ref: "modules/mb-text/text/contract_wbtest.mbt#every generated mutation seam returns immediate state with zero charge"
        status: pass
      - kind: unit
        ref: "modules/mb-text/text/contract_wbtest.mbt#generated exact charge commits once through every budget ancestor"
        status: pass
    human_judgment: false
  - id: D4
    description: "The closed public contract and complete workspace remain portable across js, wasm, wasm-gc, and native without exposing private staging machinery."
    requirement: TXT-01
    verification:
      - kind: other
        ref: "moon -C modules/mb-text test text --target <js|wasm|wasm-gc|native> --frozen (17/17 per target)"
        status: pass
      - kind: other
        ref: "moon test --target <js|wasm|wasm-gc|native> --frozen (1321/1321 per target before final test-only evidence addition)"
        status: pass
      - kind: other
        ref: "moon -C modules/mb-text info --target all --frozen"
        status: pass
    human_judgment: false

duration: 28min
completed: 2026-07-30
status: complete
---

# Phase 108 Plan 04: Public Text Contract and Immutable Run Summary

**Copied Unicode-scalar inputs now project through private checked fixtures into immutable LTR/RTL runs with exact clusters, signed design-unit values, deterministic precedence, and one atomic charge.**

## Performance

- **Duration:** 28 min
- **Started:** 2026-07-29T21:57:27Z
- **Completed:** 2026-07-29T22:25:42Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Completed request-owned four-byte tag storage and a mutate-after-snapshot scalar seam that proves caller arrays cannot alter retained count, values, adjacency, or clusters.
- Added copied immutable run publication, checked indexed access, logical-first LTR/RTL projection, minimum consumed-scalar ligature clusters, unchanged signed offsets, and checked total advances.
- Executed generated limit, signed boundary, error-precedence, source-mutation, and hierarchy-charge matrices through the real `Font::with_shape_transaction` authority without exposing any fixture symbol publicly.
- Kept public nonempty shaping fail-closed with CapabilityUnavailable and introduced no GSUB, GPOS, GDEF, legacy-kern, UI, FFI, cache, or raw-font-data execution path.

## Task Commits

TDD gates and contract evidence were committed atomically:

1. **Task 1 RED: Add failing scalar, tag, and limit contract tests** - `ed0816fa` (test)
2. **Task 1 GREEN: Freeze shaping input contracts** - `b324348e` (feat)
3. **Task 2 RED: Add failing immutable-run and stage fixtures** - `cd98518b` (test)
4. **Task 2 GREEN: Implement checked immutable run projection** - `199cf4c6` (feat)
5. **Task 2 boundary evidence: Close signed-offset and ancestor-charge coverage** - `0f1612e7` (test)

## Files Created/Modified

- `modules/mb-text/text/tags.mbt` - Copies validated four-byte script/language tags into private storage.
- `modules/mb-text/text/run.mbt` - Publishes copied opaque records and checked indexed immutable access.
- `modules/mb-text/text/shape.mbt` - Snapshots scalars and privately projects generated logical facts through the real transaction.
- `modules/mb-text/text/contract_test.mbt` - Freezes public Unicode scalar, tag, option, limit, empty, and fail-closed behavior.
- `modules/mb-text/text/contract_wbtest.mbt` - Generated table-free adjacency, cluster, direction, overflow, precedence, mutation, limit, and charge evidence.

`options.mbt` and `limits.mbt` already matched the exact locked Plan 108-04 surface from the Plan 108-01 tracer, so execution verified them without unnecessary source churn.

## Decisions Made

- Kept generated projection facts package-private and format-neutral; they hold only glyph identity, consumed scalar indices, signed positioning facts, charge facts, faults, and test probes.
- Computed every base advance plus adjustment before direction projection, negated only RTL advances, reversed only completed RTL records, and summed the published advances with shared checked arithmetic.
- Preserved ShapeLimits exactly as `new(max_input_scalars~, max_output_glyphs~)`, `max_input_scalars()`, and `max_output_glyphs()` with no defaults or layout/resource-limit expansion.

## Deviations from Plan

None - plan scope and architecture were executed as specified.

## Issues Encountered

- The planned fail-fast `mb-text check --deny-warn` gate stops at the first target on the pre-existing `mb-font` CFF unused-code/deprecation warning backlog already recorded in `.planning/WINDOWS.md` entry 61. Warning-tolerant `mb-text` checks pass on every target, all 17 focused tests pass per target, and the four-target workspace matrix passes 1321/1321 per target.
- The first interface audit looked under a module-local `target/` directory; this toolchain writes the generated interface to `modules/mb-text/text/pkg.generated.mbti`. The corrected audit passed and exposed no generated facts, probes, arrays/views, defaults, layout limits, or commit authority beyond the required public scalar-array input.

## Deferred Issues

- Clear the inherited `mb-font` CFF warning backlog before promoting dependency-wide `mb-text --deny-warn` to a clean gate.

## Known Stubs

None. Empty arrays are local builders, required empty-input records, or explicit empty fault fixtures; the public nonempty route intentionally returns CapabilityUnavailable at the Phase 108 boundary.

## Threat Flags

None. Caller-array tampering, run-storage aliasing, signed overflow, limit exhaustion, stage precedence, source mutation, and budget hierarchy behavior are all declared in the plan threat model and covered by executable tests.

## TDD Gate Compliance

- Task 1 RED `ed0816fa` failed only because the required snapshot probe was absent; GREEN `b324348e` follows and passes.
- Task 2 RED `cd98518b` failed only because the generated logical/run contract symbols were absent; GREEN `199cf4c6` follows and passes.
- Supplemental test-only commit `0f1612e7` closes exact signed-offset and hierarchy-charge evidence without changing production behavior.

## User Setup Required

None - no external services, credentials, packages, or manual configuration are required.

## Next Phase Readiness

- Phase 109 can add bounded selected-layout admission behind the unchanged public scalar/options/limits/run contract.
- Phases 110-111 can consume stable logical-order, scalar-cluster, direction-projection, and signed-arithmetic semantics without reopening Phase 108.
- Public nonempty shaping remains correctly unavailable until selected layout authority is admitted.

## Self-Check: PASSED

All seven plan-owned source/test files, this summary artifact, and commits
`ed0816fa`, `b324348e`, `cd98518b`, `199cf4c6`, and `0f1612e7` were found.
The worktree remains on `codex/v0.34-cff-outlines`, and the pre-existing
`.planning/config.json` change remains unstaged and unmodified by this plan.

---
*Phase: 108-public-contract-and-transaction-skeleton*
*Completed: 2026-07-30*
