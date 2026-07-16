---
phase: 02-bounded-core-primitives
plan: "01"
subsystem: core-errors
tags: [moonbit, diagnostics, deterministic-rendering, package-policy]

requires:
  - phase: 01-foundation-charter-and-reproducible-workspace
    provides: reproducible four-target quality lane and fail-closed policy source
provides:
  - stable ErrorCategory and ErrorCode machine vocabulary
  - opaque CoreError with typed bounded context and canonical rendering
  - encounter-ordered structured diagnostics
  - policy-driven exact package, interface, import, and publication classifiers
affects: [02-checked, 02-budget, 02-bytes, 02-io, 02-host]

tech-stack:
  added: []
  patterns: [typed portable errors, fixed-order canonical rendering, policy-owned package topology]

key-files:
  created:
    - modules/mb-core/error/moon.pkg
    - modules/mb-core/error/core_error.mbt
    - modules/mb-core/error/diagnostics.mbt
    - modules/mb-core/error/error_test.mbt
    - modules/mb-core/error/error_wbtest.mbt
  modified:
    - policy/foundation.json
    - scripts/quality/Assert-Policy.ps1
    - scripts/quality/Invoke-MoonQuality.ps1

key-decisions:
  - "Treat policy semantic-interface lines and publication contents as exact ordered/closed allowlists."
  - "Map host failures by discarding foreign detail and retaining only a bounded portable operation token."

patterns-established:
  - "Portable failure pattern: stable category/code plus typed optional context, never prose parsing."
  - "Topology increment pattern: update policy and classifiers in the same green plan exit."

requirements-completed: [CORE-06]

coverage:
  - id: D1
    description: "Exact policy-owned root-plus-error package topology and classifiers"
    requirement: CORE-06
    verification:
      - kind: integration
        ref: "pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required"
        status: pass
    human_judgment: false
  - id: D2
    description: "Stable typed errors and deterministic ordered diagnostics on all portable targets"
    requirement: CORE-06
    verification:
      - kind: unit
        ref: "moon -C modules/mb-core test error --target all --frozen"
        status: pass
    human_judgment: false
  - id: D3
    description: "Bounded host context, fixed escaping, and exact interface/publication invariants"
    requirement: CORE-06
    verification:
      - kind: integration
        ref: "pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required"
        status: pass
    human_judgment: false

duration: 10min
completed: 2026-07-16
status: complete
---

# Phase 02 Plan 01: Stable Errors and Deterministic Diagnostics Summary

**Opaque typed portable errors, canonical bounded rendering, ordered diagnostics, and exact policy-driven multi-package qualification**

## Performance

- **Duration:** 10 min
- **Started:** 2026-07-16T14:16:49Z
- **Completed:** 2026-07-16T14:26:38Z
- **Tasks:** 3
- **Files modified:** 8

## Accomplishments

- Generalized the root quality machinery from one hard-coded package per module to exact policy-owned package, target, import, semantic-interface, and publication inventories.
- Added a public portable error vocabulary with stable category/code equality, typed optional context, bounded host mapping, and fixed-order escaped rendering.
- Added encounter-ordered diagnostics plus black-box and white-box evidence across js, wasm, wasm-gc, and native.

## Task Commits

1. **Task 1: Generalize exact policy and Required classifiers** - `25393d5` (chore)
2. **Task 2 RED: Specify deterministic error contracts** - `9afd7b9` (test)
3. **Task 2 GREEN: Implement structured portable diagnostics** - `d763766` (feat)
4. **Task 3: Register error invariants and prove the atomic green exit** - `af08e4a` (test)

## Files Created/Modified

- `modules/mb-core/error/core_error.mbt` - Stable categories, codes, opaque typed context, host mapping, and canonical renderer.
- `modules/mb-core/error/diagnostics.mbt` - Structured severity, diagnostic values, and encounter-ordered collection.
- `modules/mb-core/error/error_test.mbt` - Public black-box machine semantics and deterministic rendering tests.
- `modules/mb-core/error/error_wbtest.mbt` - Internal bounded-context, escaping, and range invariants.
- `modules/mb-core/error/moon.pkg` - Exact four-target portable package declaration.
- `policy/foundation.json` - Root-plus-error package, interface, import, and publication allowlists.
- `scripts/quality/Assert-Policy.ps1` - Multi-package identity, target, and import validation.
- `scripts/quality/Invoke-MoonQuality.ps1` - Multi-package interface and publication classification.

## Decisions Made

- Semantic interface lines are compared exactly and in generated order; comments and blanks are excluded from the stable classifier input.
- Host adapters intentionally discard raw foreign details so paths, exception names, platform codes, and clocks cannot enter portable semantics.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Normalized package-list separators before exact comparison**
- **Found during:** Task 3 root Required verification
- **Issue:** The pinned Windows toolchain emits nested publication paths with backslashes while policy owns canonical slash-separated paths.
- **Fix:** Normalize only the observed path separator before exact allowlist comparison; undeclared entries still fail closed.
- **Files modified:** `scripts/quality/Invoke-MoonQuality.ps1`
- **Verification:** Full root Required lane passed after the change.
- **Committed in:** `af08e4a`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** The portability fix preserves exact classification and adds no accepted files.

## Issues Encountered

- The first Task 1 verification exposed PowerShell's explicit-null array binding for an empty import result; materializing the result with `@(...)` corrected the classifier before Task 1 was committed.
- The formatter and deny-warning check identified pinned-toolchain syntax updates (`StringView::to_owned`); source was formatted and reverified before Task 3 completion.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None. The only placeholder-related match is the pre-existing governance evidence validator rejecting placeholder tokens.

## Next Phase Readiness

- The shared `error` package is ready for the checked-arithmetic package in Plan 02-02.
- Root-plus-error topology, all four targets, exact interfaces, package contents, and tracked read-only proof are green.

## Self-Check: PASSED

- All five created error-package files exist.
- Task commits `25393d5`, `9afd7b9`, `d763766`, and `af08e4a` exist.
- `moon -C modules/mb-core test error --target all --frozen` passed 8/8 per target.
- `pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required` passed with exact root-plus-error topology.

---
*Phase: 02-bounded-core-primitives*
*Completed: 2026-07-16*
