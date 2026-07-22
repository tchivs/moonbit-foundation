---
phase: quick-260716-pml-bootstrap-rfc-01-08-validate
plan: "01"
subsystem: governance
tags: [rfc, policy, powershell, sole-owner, validation]
requires:
  - phase: 01-foundation-charter-and-reproducible-workspace
    provides: Proposed RFC 0001, governance process, and deterministic Required quality lane
provides:
  - Auditable sole-project-owner-bootstrap acceptance route
  - Canonical maintainer roster and fail-closed route validator
  - Autonomous Plan 01-08 edge-review and acceptance flow
affects: [01-08, governance, required-quality]
tech-stack:
  added: []
  patterns: [canonical roster-derived authority, repository-contained evidence paths, route-specific validation]
key-files:
  created:
    - docs/governance/decisions/0001-sole-owner-bootstrap.md
    - policy/maintainers.json
    - scripts/quality/Test-RfcAcceptance.ps1
  modified:
    - docs/governance/rfc-process.md
    - policy/foundation.json
    - scripts/quality/Assert-Policy.ps1
    - scripts/quality.ps1
    - .planning/phases/01-foundation-charter-and-reproducible-workspace/01-08-PLAN.md
key-decisions:
  - "Treat the user's exact sole-developer instruction as conditional preauthorization for RFC 0001 only, consumed after both mandatory edge reviews pass."
  - "Derive sole-owner eligibility from unique canonical roster identities; never store an independent maintainer count."
  - "Keep RFC 0001 Proposed until autonomous Plan 01-08 completes and dispositions both edge reviews."
patterns-established:
  - "Route-specific RFC evidence: each acceptance route has required and forbidden fields."
  - "Evidence containment: reject rooted, traversing, symbolic-link, and reparse-point paths before normalized root-prefix and leaf checks."
requirements-completed: [GOV-02]
coverage:
  - id: D1
    description: Transparent sole-owner governance route preserving the exact user instruction without invented approval or elapsed time
    requirement: GOV-02
    verification:
      - kind: integration
        ref: "pwsh -NoProfile -File scripts/quality/Test-RfcAcceptance.ps1"
        status: pass
    human_judgment: false
  - id: D2
    description: Canonical roster and fail-closed policy validation across all three acceptance routes and evidence-path attacks
    requirement: GOV-02
    verification:
      - kind: integration
        ref: "Assert-FoundationPolicy and Assert-PhaseSourceAudit"
        status: pass
    human_judgment: false
  - id: D3
    description: Autonomous Plan 01-08 prerequisite and Required-controller integration ready for the later RFC acceptance transition; this quick task does not complete GOV-01
    verification:
      - kind: integration
        ref: "verify.plan-structure 01-08-PLAN.md and scripts/quality.ps1 -Lane Required"
        status: pass
    human_judgment: false
duration: 35min
completed: 2026-07-16
status: complete
---

# Quick Task 260716-pml: Sole-owner RFC Bootstrap Summary

**Auditable sole-owner preauthorization, canonical roster-derived authority, fail-closed acceptance matrix, and autonomous RFC 0001 finalization flow**

## Performance

- **Duration:** 35 min
- **Completed:** 2026-07-16
- **Tasks:** 3
- **Task commits:** 5

## Accomplishments

- Preserved `现在只有我一个人开发，跳过` as RFC 0001-only conditional preauthorization without inventing a second approval, public review, or later approval.
- Added canonical roster-derived route eligibility plus path-contained decision evidence and negative tests for duplicate/multiple identities, owner mismatch, traversal/rooted/reparse paths, missing anchors/reviews, route-field leakage, elapsed-time failure, and state divergence.
- Rewrote Plan 01-08 to complete both edge reviews before consuming the preauthorization, and made the Required controller execute the acceptance matrix.

## Task Commits

1. **Task 1: Amend the governance contract** — `699a1c4`
2. **Task 2 RED: Add failing acceptance matrix** — `456fa58`
3. **Task 2 GREEN: Enforce route-specific validation** — `fa17d30`
4. **Task 3: Rewire autonomous finalization** — `d9d66ee`
5. **Gap closure: Reject linked external evidence** — `c310a68`

## Verification

- `Test-RfcAcceptance.ps1`: all 25 positive and negative cases passed, including an exact canonical-path symlink to an external file.
- Direct foundation policy and exact source-audit validators passed.
- Plan 01-08 structure: valid, three autonomous tasks, zero warnings.
- Required lane: passed across `js`, `wasm`, `wasm-gc`, and `native`, including 3/3 tests per target and exact `1/9/16/29/17/5` source inventory.
- RFC 0001 remains truthfully `Proposed`; Plan 01-08 owns the actual review and Accepted transition.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed reliance on unset `$LASTEXITCODE` after a PowerShell script invocation**
- **Found during:** Task 3 Required-lane verification
- **Issue:** Strict mode throws when `$LASTEXITCODE` has not been set by a native process.
- **Fix:** Wrapped the acceptance matrix in terminating `try`/`catch` semantics.
- **Verification:** Full Required lane passed.
- **Committed in:** `d9d66ee`

**2. [Rule 2 - Missing Critical] Allowed completed edge-review evidence while the RFC is still Proposed**
- **Found during:** Task 3 autonomous 01-08 wiring
- **Issue:** The validator originally permitted only pending reviews before acceptance, making the required review-before-transition ordering impossible.
- **Fix:** Proposed state now permits only pending records or completed records with resolved dispositions, while acceptance evidence remains empty.
- **Verification:** Added and passed the `proposed with completed edge reviews` matrix case.
- **Committed in:** `d9d66ee`

**3. [Rule 2 - Missing Critical] Rejected symbolic-link and reparse-point evidence escapes**
- **Found during:** Independent quick-task verification
- **Issue:** Lexical path containment accepted the canonical decision filename when it was a symbolic link to external content.
- **Fix:** Evidence resolution now rejects any symbolic link or reparse point in the repository-relative evidence component chain; the regression matrix creates the exact canonical link to an external file and requires rejection.
- **Verification:** `canonical decision symlink escape` passed, followed by direct validators, plan structure, and full Required quality.
- **Committed in:** `c310a68`

**Total deviations:** 3 auto-fixed. **Impact:** All fixes are required for fail-closed execution; no governance prerequisite was weakened.

## Issues Encountered

The codebase-memory index refresh crashed on a repository file, so discovery fell back to targeted repository reads and searches as allowed by AGENTS.md. This did not affect implementation or verification.

## User Setup Required

None.

## Next Phase Readiness

Plan 01-08 is autonomously enabled to perform the two edge reviews, consume the existing preauthorization, synchronize Accepted state, and complete Phase 1 qualification. This quick task is a prerequisite and does not itself satisfy GOV-01: RFC 0001 remains Proposed until 01-08 completes.

## Self-Check: PASSED
