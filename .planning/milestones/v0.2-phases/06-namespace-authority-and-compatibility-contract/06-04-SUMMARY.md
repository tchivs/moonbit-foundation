---
phase: 06-namespace-authority-and-compatibility-contract
plan: "04"
subsystem: publication-documentation
tags: [documentation, compatibility, mooncakes, fail-closed, policy]
requires:
  - phase: 06-namespace-authority-and-compatibility-contract
    provides: policy-owned compatibility classes and evidence consequences from plan 06-03
provides:
  - Stable public support and security-reporting routes for all three candidate modules
  - Strict module-isolated source-document validator with default all selector
  - Policy-derived install, import, target, toolchain, class, dependency-floor, migration, and RFC contract
  - Explicit unknown Mooncakes-render state reserved for PROV-05 in Phase 8
affects: [06-05, 06-06, candidate-documentation, release-qualification]
tech-stack:
  added: []
  patterns: [ordinal-source-records, isolated-copy-negatives, policy-derived-documentation, expected-red-contract]
key-files:
  created:
    - docs/support.md
    - SECURITY.md
  modified:
    - scripts/quality/Test-CandidateDocumentation.ps1
key-decisions:
  - "Use one exact 15-record publication-source block per module so count, ordinal, identity, emptiness, duplication, and ordering are independently rejectable."
  - "Keep normal validation RED until Plan 06-05 adds module records, while ContractSelfTest proves the validator and all negative rules against isolated valid fixtures."
  - "Treat registry source metadata as intent only; actual Mooncakes rendering remains unknown and can be proven only by PROV-05 in Phase 8."
patterns-established:
  - "-Module defaults to all and a named selector reads, validates, and runs literate checks only for that module."
  - "Manifest closure and compatibility consequences are derived from release-qualification.json and compatibility.json rather than duplicated in prose."
requirements-completed: []
coverage:
  - id: D1
    description: Stable sole-maintainer-compatible shared support and security routes
    requirement: null
    verification:
      - kind: static
        ref: docs/support.md and SECURITY.md non-empty route check
        status: pass
    human_judgment: false
  - id: D2
    description: Bounded policy-owned source-document validation seam
    requirement: null
    verification:
      - kind: integration
        ref: scripts/quality/Test-CandidateDocumentation.ps1 -ContractSelfTest across all selectors
        status: pass
    human_judgment: false
  - id: D3
    description: Registry rendering remains unknown and reserved for PROV-05 Phase 8
    requirement: null
    verification:
      - kind: negative
        ref: PROV03-FABRICATED-RENDER isolated negative
        status: pass
    human_judgment: false
duration: 36m
completed: 2026-07-17
status: complete
---

# Phase 6 Plan 04: Publication Source Contract Summary

**Three candidate modules now share stable public routes and one policy-owned, module-isolated validation contract without claiming that Mooncakes has rendered unpublished metadata.**

## Performance

- **Duration:** 36m
- **Tasks:** 2
- **Files created:** 2
- **Files modified:** 1

## Accomplishments

- Established public support and private-first security-reporting routes with explicit candidate scope, sole-maintainer response boundaries, secret-handling boundaries, and no registry mutation or stability promise.
- Extended the existing collective validator with strict `-Module` selection, exact manifest closure, ordered public-package imports, and a 15-record source contract covering install, candidate status, targets, pinned toolchain, class, shared routes, changelog, conditional migration/RFC evidence, and intended registry metadata.
- Derived targets, toolchain floors, dependency floors, class consequences, migration requirements, and RFC triggers from canonical policy files.
- Proved missing and incorrect commands, route drift, class and dependency-floor disagreement, missing migration/RFC, unsupported manifest fields, empty ambiguity, duplicate/reordered records, and fabricated render claims reject under stable owning rules.

## Task Commits

1. **Task 1: Establish stable support and security routes** - `b1dd98f`
2. **Task 2: Extend the collective source-document validator** - `fbb0de4`

## Files Created/Modified

- `docs/support.md` - Stable public candidate support route and response boundary.
- `SECURITY.md` - Private-first security-reporting route with a safe public routing fallback.
- `scripts/quality/Test-CandidateDocumentation.ps1` - Policy-owned source-document validator, selector isolation, contract fixture builder, and exact negative matrix.

## Decisions Made

- The exact `publication-source` record order is part of the contract. Sorting is not accepted because it would hide reordered or duplicated evidence.
- A module selector does not validate other module documents or run collective public examples; default `all` retains the collective behavior.
- The validator accepts source intent only when `registry-render` is exactly `unknown;proof=PROV-05;phase=8`; a live-render pass statement is rejected.
- Plan 06-04 validates the contract itself with generated isolated fixtures. It intentionally does not add the records to module documentation owned by Plan 06-05.

## Deviations from Plan

### Auto-fixed Issues

**1. Strict-mode empty dependency enumeration**
- **Found during:** Task 2 contract self-test
- **Issue:** PowerShell strict mode rejects `.Name` member enumeration on the empty `mb-core` dependency property collection.
- **Fix:** Enumerate property objects explicitly and project each name, preserving a true empty array.
- **Files modified:** `scripts/quality/Test-CandidateDocumentation.ps1`
- **Verification:** `mb-core` and default-all contract self-tests pass.
- **Committed in:** `fbb0de4`

**2. Single-selector array unwrapping**
- **Found during:** Task 2 first isolated negative
- **Issue:** PowerShell unwrapped a one-element selector result, causing index access to return a property value instead of the module row.
- **Fix:** Type the selected row collection as an array and use PSCustomObject rows.
- **Files modified:** `scripts/quality/Test-CandidateDocumentation.ps1`
- **Verification:** All four selectors complete the positive fixture and negative matrix.
- **Committed in:** `fbb0de4`

---

**Total deviations:** 2 auto-fixed implementation issues.
**Impact on plan:** Both fixes preserve strict selector isolation and empty dependency semantics without expanding scope.

## Issues Encountered

- Normal module validation currently rejects with `PROV03-RECORD-ORDER` because Plan 06-05 has not yet added the 15 source records. This is the planned RED handoff, not a Plan 06-04 failure.

## User Setup Required

None - support and validation are credential-free and perform no publication or registry mutation.

## Verification

- Shared route non-empty check passed.
- PowerShell parser validation and `git diff --check` passed.
- `-ContractSelfTest` passed for `mb-core`, `mb-color`, `mb-image`, and default `all`.
- The isolated matrix proved all requested document and policy negatives, including fabricated Mooncakes rendering.
- Normal `-Module mb-core` was confirmed to fail only at the planned `PROV03-RECORD-ORDER` RED boundary.

## Next Phase Readiness

- Plan 06-05 can update each three-file module source set independently and use its matching selector as the acceptance gate.
- Actual registry rendering remains unclaimed and exclusively mapped to PROV-05 in Phase 8.
- The Plan 06-01 external namespace-authority checkpoint remains independent and unresolved.

---
*Phase: 06-namespace-authority-and-compatibility-contract*
*Completed: 2026-07-17*
