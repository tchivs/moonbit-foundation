---
phase: 01-foundation-charter-and-reproducible-workspace
plan: "01"
subsystem: governance
tags: [rfc, architecture, governance, lifecycle]

requires: []
provides:
  - Canonical Proposed foundation charter for v0.1
  - Normative RFC lifecycle, authority, evidence, and boundary-change policy
  - Discoverable RFC index with truthful status
affects: [phase-01-policy, workspace-scaffold, quality-validation, future-rfcs]

tech-stack:
  added: []
  patterns:
    - Fail-closed governance evidence
    - Owns/does-not-own/depends-on module boundaries
    - Bidirectional charter/process/index links

key-files:
  created:
    - docs/rfcs/README.md
    - docs/governance/rfc-process.md
  modified:
    - docs/rfcs/0001-moonbit-native-foundation.md

key-decisions:
  - "RFC 0001 remains Proposed until an authorized acceptance route has authentic evidence."
  - "Public dependencies point inward and downward: mb-color depends on mb-core, while mb-image may depend on both."
  - "New modules, public dependency-direction changes, and breaking architectural boundaries require an accepted RFC."

patterns-established:
  - "Governance transitions fail closed: missing or disputed evidence retains the less advanced truthful state."
  - "RFC boundaries state what each module owns, does not own, and depends on."

requirements-completed: [GOV-01, GOV-02]

coverage:
  - id: D1
    description: "RFC 0001 is the canonical Proposed v0.1 architectural charter with explicit layers, boundaries, dependency direction, portability, scope, and governance triggers."
    requirement: GOV-01
    verification:
      - kind: other
        ref: "pwsh content validation for RFC lifecycle and mb-core/mb-color/mb-image terms"
        status: pass
    human_judgment: true
    rationale: "The two unclassified architectural and authority edge cases remain explicit manual review obligations before acceptance."
  - id: D2
    description: "The normative RFC process defines all lifecycle states, both authority routes, blocking-objection handling, evidence requirements, and RFC-required changes."
    requirement: GOV-02
    verification:
      - kind: other
        ref: "pwsh content validation for lifecycle, seven-day route, objection handling, evidence prohibition, and boundary triggers"
        status: pass
    human_judgment: false
  - id: D3
    description: "The RFC index reports RFC 0001 as Proposed and links the charter and normative process."
    requirement: GOV-02
    verification:
      - kind: other
        ref: "Select-String docs/rfcs/README.md -Pattern 0001-moonbit-native-foundation[.]md"
        status: pass
    human_judgment: false

duration: 4min
completed: 2026-07-16
status: complete
---

# Phase 01 Plan 01: Foundation Charter and Auditable RFC Lifecycle Summary

**A truthful Proposed charter now fixes the v0.1 architecture while an evidence-gated RFC process controls acceptance and future boundary changes.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-07-16T07:09:12Z
- **Completed:** 2026-07-16T07:13:11Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Converted RFC 0001 into the sole v0.1 charter with explicit terminology, layer direction, module boundaries, portability policy, scope, and RFC-required changes.
- Published a fail-closed lifecycle with two-maintainer and seven-day bootstrap authority routes, blocking-objection handling, and authentic-evidence requirements.
- Added a discoverable RFC index and bidirectional links among the charter, process, and status list while preserving Proposed truthfully.

## Task Commits

Each task was committed atomically:

1. **Task 1: Convert RFC 0001 into the canonical proposed charter** - `f6b01e3` (docs)
2. **Task 2: Publish the RFC lifecycle and index** - `7f7ae74` (docs)
3. **Task 2 verification fix: Preserve governance edge review gates** - `257c441` (fix)

## Files Created/Modified

- `docs/rfcs/0001-moonbit-native-foundation.md` - Canonical Proposed architecture and transition ledger.
- `docs/rfcs/README.md` - RFC status, scope, lifecycle summary, and index.
- `docs/governance/rfc-process.md` - Normative transition, authority, objection, evidence, and boundary-change rules.

## Decisions Made

- Kept RFC 0001 Proposed because no authentic maintainer approvals, public-review interval, or objection-disposition evidence exists.
- Made the three v0.1 module edges explicit and prohibited reverse, cyclic, self, and undeclared public dependencies.
- Required accepted RFCs before new modules, public dependency-direction changes, or breaking architectural boundary changes may merge.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Preserved the stable governance edge-review identifiers**

- **Found during:** Overall plan verification after Task 2
- **Issue:** The evidence prohibition was normative, but the two unclassified manual-review assumptions and stable prohibition ID were not yet explicit in a shipped artifact.
- **Fix:** Added `EDGE-GOV-01-UNCLASSIFIED`, `EDGE-GOV-02-UNCLASSIFIED`, and `PROH-GOV-02-EVIDENCE` to the normative RFC process as open acceptance obligations.
- **Files modified:** `docs/governance/rfc-process.md`
- **Verification:** PowerShell content checks found all three identifiers and the plan-wide verification passed.
- **Committed in:** `257c441`

---

**Total deviations:** 1 auto-fixed (1 missing critical functionality).
**Impact on plan:** The fix preserves required review traceability without changing the charter architecture or widening scope.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Governance inputs are ready for 01-02 policy single-sourcing and 01-03 workspace manifests.
- RFC 0001 must remain Proposed until Plan 01-08 records authentic acceptance evidence.

## Self-Check: PASSED

- All three key artifacts exist.
- All task verification commands and plan-level D-01 through D-04 checks passed.
- The RFC remains Proposed and records no invented acceptance evidence.
- All 01-01 task and verification-fix commits are present.

---
*Phase: 01-foundation-charter-and-reproducible-workspace*
*Completed: 2026-07-16*
