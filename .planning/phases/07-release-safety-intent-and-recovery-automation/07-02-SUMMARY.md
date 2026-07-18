---
phase: 07-release-safety-intent-and-recovery-automation
plan: "02"
subsystem: release-publisher
tags: [powershell, state-machine, hash-chain, recovery, rehearsal]

requires:
  - phase: 07-release-safety-intent-and-recovery-automation
    plan: "01"
    provides: Immutable initial/root intent and forward-correction contracts
provides:
  - Closed content-addressed publisher journal record and state vocabularies
  - Pure monotonic transition reducer with immutable-root serialization identity
  - Credential-free adapter controller and adversarial recovery rehearsal matrix
affects: [07-03-hosted-release-control, phase-08-live-publication]

tech-stack:
  added: []
  patterns: [pure reducer, append-only hash chain, observe-decide-mutate-observe, immutable-root lock, forward-only correction]

key-files:
  created:
    - release/journal/record-schema.json
    - release/journal/state-schema.json
    - scripts/quality/ReleasePublisher.Common.ps1
    - scripts/quality/Invoke-ReleasePublisher.ps1
    - scripts/quality/Test-ReleasePublisherNegative.ps1
  modified: []

key-decisions:
  - "Serialization identity is repository plus immutable canonical-initial root_intent_sha256, so competing corrections cannot acquire separate locks."
  - "Every ambiguous adapter outcome requires a sanitized read-only re-observation classification before any later authorization can proceed."
  - "LiveOneStep is unreachable without both explicit live authorization and an injected one-step adapter; rehearsal persists no raw output."

patterns-established:
  - "Publisher journal: closed records, contiguous sequence, exact prior digest, immutable root/current binding, and SHA-256 over the record projection excluding its own digest."
  - "Recovery: exact match checkpoints without republish; absent requires fresh authorization; mismatch opens an incident; unknown stops; destructive recovery is absent."

requirements-completed: [REL-01, REL-02, REL-03, REL-04, REL-05]

coverage:
  - id: D10-D14
    description: "Immutable-root lock, monotonic state order, hash-chained journal, resume identity, and idempotent replay"
    requirement: REL-03
    verification:
      - kind: unit
        ref: "pwsh -NoProfile -File scripts/quality/Test-ReleasePublisherNegative.ps1 -ReducerOnly"
        status: pass
    human_judgment: false
  - id: D15-D18
    description: "Ambiguity, authentication/evidence failure, checkpoint resume, terminal mismatch, and single-successor forward correction"
    requirement: REL-04, REL-05
    verification:
      - kind: integration
        ref: "pwsh -NoProfile -File scripts/quality/Test-ReleasePublisherNegative.ps1"
        status: pass
    human_judgment: false

duration: 13min
completed: 2026-07-18
status: complete
---

# Phase 7 Plan 2: Monotonic Publisher and Recovery Rehearsal Summary

**The isolated publisher now has a closed append-only state machine and proves every replay, ambiguity, interruption, mismatch, and correction branch without credentials, network access, or registry mutation.**

## Performance

- **Duration:** 13 min
- **Completed:** 2026-07-18T04:09:43Z
- **Tasks:** 2 TDD tasks
- **Files modified:** 5

## Accomplishments

- Defined closed JSON schemas for exact publisher states, sanitized observations, run/artifact identity, and content-addressed journal records.
- Implemented a pure reducer that rejects sequence gaps, prior-digest tampering, root/current substitution, skipped dependency order, backward movement, replay mutation, and terminal-intent resume.
- Implemented credential-free controller rehearsals for timeout, nonzero, partial success, exact replay, mismatch, unknown result, invalid authentication, invalid evidence, interruption, and correction races.
- Proved that correction competitors share one repository-plus-root lock, only one sequence+1 successor is accepted, stale forks never mutate, and a sequence+2 successor must name the accepted sequence+1 intent.

## Task Commits

1. **Task 1 RED: Failing reducer scenarios** - `b091199`
2. **Task 1 GREEN: Closed schemas and monotonic reducer** - `356454e`
3. **Task 2 RED: Failing recovery rehearsals** - `552b6eb`
4. **Task 2 GREEN: Credential-free controller and recovery matrix** - `092043c`
5. **Coverage closure: Terminal and sequence+2 recovery edges** - `9d89827`

## Files Created/Modified

- `release/journal/record-schema.json` - Closed append-only record, sanitized observation, and run/artifact identity contract.
- `release/journal/state-schema.json` - Exact monotonic states and outcome vocabulary.
- `scripts/quality/ReleasePublisher.Common.ps1` - Closed-property checks, sanitizer, canonical record hash, chain verification, lock identity, reducer, and record factory.
- `scripts/quality/Invoke-ReleasePublisher.ps1` - Rehearsal, preflight, guarded one-step live seam, correction validation, and race simulation.
- `scripts/quality/Test-ReleasePublisherNegative.ps1` - Reducer-only and full adversarial failure/recovery matrix.

## Decisions Made

- Kept the reducer independent of filesystem state, credentials, commands, and network access; the controller must inject any eventual side-effect adapter.
- Modeled registry observation as a small allowlisted projection, never raw CLI output or exception text.
- Classified mismatch as terminal for the current intent and allowed only a newly authorized, policy-qualified, unpublished forward correction from fresh genesis.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added the reducer selector before its later task-owned test file existed**
- **Found during:** Task 1 TDD setup
- **Issue:** Task 1 verification required `Test-ReleasePublisherNegative.ps1 -ReducerOnly`, while the plan listed that script under Task 2.
- **Fix:** Created the minimal reducer selector for Task 1 RED, then expanded the same planned file during Task 2 RED/GREEN.
- **Verification:** RED failed only for the missing reducer; GREEN passed the reducer selector.
- **Committed in:** `b091199`

---

**Total deviations:** 1 auto-fixed blocking issue. No scope change.

## Issues Encountered

- PowerShell's correction-race parameter naming and expression precedence initially obscured the intended stale-fork classification. Parameters and validation order were made explicit so predecessor mismatch owns the exact diagnostic before sequence checks.

## User Setup Required

None. This plan is deliberately credential-free and performs no registry or network mutation.

## Next Phase Readiness

- Plan 07-03 can place the verified one-step controller behind the manual trusted-ref workflow, full-SHA action pins, read-only defaults, environment isolation, and immutable-root concurrency group.
- Actual Mooncakes publication remains deferred to the explicit Phase 8 live checkpoint.

## Known Stubs

None.

## Self-Check: PASSED

- All five plan-owned implementation files exist and parse.
- Reducer-only, full recovery matrix, journal schema parsing, and release qualification StaticOnly checks pass.
- Static scans find no publish command, web request, secret header, credential path, destructive recovery, or deletion command in the publisher files.
- Only the five plan-owned files changed from the Wave 1 baseline; pre-existing user changes and cache directories remain unstaged.

---
*Phase: 07-release-safety-intent-and-recovery-automation*
*Completed: 2026-07-18*
