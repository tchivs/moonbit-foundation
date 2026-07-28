---
phase: 101-collection-contract-and-bounded-envelope
plan: 01
subsystem: font
tags: [moonbit, opentype, ttc, byteview, budget, policy]
requires:
  - phase: 97-font-admission-and-metrics
    provides: standalone Font contract, revision-guarded caller-byte ownership, and exact semantic-interface policy
provides:
  - opaque bounded FontCollection identity for root-relative TTC v1 bytes
  - eight-ceiling FontCollectionLimits and closed profile/DSIG inspection
  - revision-first collection queries and exact Phase 101 generated-interface gate
affects:
  - 101-02 bounded all-face expansion
  - 101-03 qualification
  - 102-root-relative-selected-face-admission
tech-stack:
  added: []
  patterns:
    - separate collection facade preserves standalone Font::open behavior
    - root ByteView revision guard precedes cached query/index publication
    - compiler output is ephemeral evidence checked against two tracked interface allowlists
key-files:
  created:
    - modules/mb-font/font/collection_limits.mbt
    - modules/mb-font/font/collection_parser.mbt
    - modules/mb-font/font/collection.mbt
    - modules/mb-font/font/collection_test.mbt
  modified:
    - policy/foundation.json
    - scripts/quality/Assert-Policy.ps1
key-decisions:
  - "Keep FontCollection separate and opaque while leaving Font::open standalone-only."
  - "Charge only compact retained collection facts (184 bytes, two allocations, 34 work for tracer), not caller-owned source bytes."
  - "Treat pkg.generated.mbti as ignored evidence and freeze the 84-line surface in both JSON and an independent classifier."
patterns-established:
  - "Collection admission: authority and structure -> compact preflight -> normalization -> final revision guard -> one budget charge -> publication."
  - "Collection query: revision guard -> UInt64 index validation -> checked narrowing -> semantic fact."
requirements-completed: [TTC-01]
coverage:
  - id: D1
    description: "A caller-owned one-face TTC v1 opens under exact limits and exposes count 1, StaticGlyf profile, and Absent DSIG without copying source bytes."
    requirement: TTC-01
    verification:
      - kind: unit
        ref: "modules/mb-font/font/collection_test.mbt#TTC-01 tracer opens one static glyf collection atomically"
        status: pass
      - kind: integration
        ref: "moon -C modules/mb-font test font --target native --frozen --target-dir target/phase101-plan01-regression --no-parallelize"
        status: pass
    human_judgment: false
  - id: D2
    description: "Malformed, over-authority, and revision-drifted inputs fail with distinct stable categories while preserving budget atomicity and revision-before-index precedence."
    requirement: TTC-01
    verification:
      - kind: unit
        ref: "modules/mb-font/font/collection_test.mbt#malformed, limit, and revision matrix"
        status: pass
    human_judgment: false
  - id: D3
    description: "The generated public interface is exactly 84 ordered lines and exposes no raw collection storage, range, revision, DSIG payload, or selected-face admission."
    requirement: TTC-01
    verification:
      - kind: integration
        ref: "Assert-FontFoundationPolicy -PolicyPath ./policy/foundation.json"
        status: pass
      - kind: integration
        ref: "moon -C modules/mb-font info --target all --frozen"
        status: pass
    human_judgment: false
duration: 13min
completed: 2026-07-27
status: complete
---

# Phase 101 Plan 01: Collection Contract Tracer and Interface Summary

Opaque, revision-guarded TTC v1 collection admission with exact resource accounting, closed semantic queries, and a frozen 84-line public interface.

## Performance

- **Started:** 2026-07-27T21:25:46Z
- **Completed:** 2026-07-27T21:38:49Z
- **Duration:** 13 min
- **Tasks:** 2
- **Files changed:** 6

## Accomplishments

- Added an opaque `FontCollection` tracer that validates root-relative TTC v1 bytes, retains caller ownership, and publishes only after a final revision guard and atomic budget charge.
- Added eight exact collection ceilings plus closed face-profile and DSIG-status queries with revision-before-index error precedence.
- Extended the qualification policy to freeze the exact 84-line generated interface while rejecting private collection facts and selected-face admission leaks.

## Task Commits

Each task was committed atomically through its required TDD gates:

1. **Task 1 RED: bounded collection tracer tests** - `1e1fee80`
2. **Task 1 GREEN: bounded collection tracer** - `761e5395`
3. **Task 2 RED: query and policy coverage** - `b8cb22c8`
4. **Task 2 GREEN: frozen query interface** - `6a3c13d2`

## Files Created/Modified

- `modules/mb-font/font/collection_limits.mbt` - Defines eight non-zero UInt64 collection ceilings and exact getters.
- `modules/mb-font/font/collection_parser.mbt` - Performs bounded TTC v1 preflight, normalization, profile classification, and exact charging.
- `modules/mb-font/font/collection.mbt` - Exposes the opaque collection facade and revision-first semantic queries.
- `modules/mb-font/font/collection_test.mbt` - Covers success, malformed input, limits, atomic budgets, mutation, index precedence, and owner isolation.
- `policy/foundation.json` - Tracks the expanded source/test inventories and exact Phase 101 semantic interface.
- `scripts/quality/Assert-Policy.ps1` - Independently classifies the allowed interface and rejects collection-private leaks.

## Decisions Made

- Kept collection admission independent from `Font::open`, preserving the standalone-font contract for existing callers.
- Charged compact retained facts only: the one-face tracer uses 184 retained bytes, two allocations of 48 bytes, and 34 work units.
- Treated `pkg.generated.mbti` as ignored compiler evidence and compared it against two tracked, exact allowlists rather than committing generated output.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Verification

- Focused tracer tests: 5/5 passed before expansion.
- Focused final collection tests: 8/8 passed.
- Full native font regression suite: 111/111 passed.
- `moon info` succeeded for all configured targets.
- Generated `pkg.generated.mbti` remained ignored.
- `Assert-FontFoundationPolicy` and qualification-fixture checks passed.

## Known Stubs

None.

## User Setup Required

None.

## Next Phase Readiness

- Plan 101-02 can expand the proven parser across all faces, aliases, and protected ranges without changing the public collection boundary.
- Plan 101-03 can add DSIG qualification on top of the retained collection facts.
- No blockers remain.

## Self-Check: PASSED

All created files and all four task commits were verified in the isolated worktree.
