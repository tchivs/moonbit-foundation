---
phase: 06-namespace-authority-and-compatibility-contract
plan: "03"
subsystem: compatibility
tags: [moonbit, mbti, semver, fail-closed, policy]
requires:
  - phase: 06-namespace-authority-and-compatibility-contract
    provides: exact 17-package and 68-record public-interface baseline from plan 06-02
provides:
  - Closed exact, additive, incompatible, or unknown comparison result
  - Policy-owned pre-1.0 version, changelog, migration, and conditional RFC consequences
  - Lossless declaration, target, toolchain, and dependency-floor comparator
  - Focused positive and fail-closed negative compatibility matrix
affects: [06-04, 06-05, 06-06, release-qualification, compatibility-policy]
tech-stack:
  added: []
  patterns: [unknown-first-classification, closed-json-contracts, stable-rule-ids, arbitrary-precision-semver]
key-files:
  created:
    - policy/compatibility.json
    - compatibility/schema/comparison-schema.json
    - scripts/quality/Compare-PublicInterfaceBaseline.ps1
    - scripts/quality/Test-PublicCompatibility.ps1
  modified: []
key-decisions:
  - "Treat unknown syntax, adjacent overload ambiguity, partial inventories, per-target divergence, and unapproved generation-toolchain drift as unknown before considering incompatible evidence."
  - "Keep all version and evidence consequences in policy/compatibility.json; the comparator reads those rules and never rewrites a candidate version."
  - "Require an accepted RFC only for declared boundary, architecture, or governance impact; an ordinary incompatible pre-1.0 API delta requires a minor version, changelog, and migration note without an automatic RFC requirement."
patterns-established:
  - "Every blocked result carries stable COMP02, COMP03, or COMP04 rule IDs through the same executable authorization gate."
  - "Compatibility claims are bounded to public-interface text and declared release facts; behavioral and semantic claims remain outside this comparator."
requirements-completed: [COMP-02, COMP-03, COMP-04]
coverage:
  - id: D1
    description: Deterministic closed four-class comparison with unknown-first precedence
    requirement: COMP-02
    verification:
      - kind: integration
        ref: scripts/quality/Test-PublicCompatibility.ps1#four classes, ambiguity, divergence, partial input, and precedence matrix
        status: pass
    human_judgment: false
  - id: D2
    description: Policy-owned pre-1.0 version consequences across API, targets, toolchain, and dependency floors
    requirement: COMP-03
    verification:
      - kind: integration
        ref: scripts/quality/Test-PublicCompatibility.ps1#version boundary and controlled-fact matrix
        status: pass
    human_judgment: false
  - id: D3
    description: Fail-closed changelog, added-surface, migration, and conditional RFC evidence gate
    requirement: COMP-04
    verification:
      - kind: integration
        ref: scripts/quality/Test-PublicCompatibility.ps1#evidence consequence matrix
        status: pass
    human_judgment: false
duration: 48m
completed: 2026-07-17
status: complete
---

# Phase 6 Plan 03: Public Compatibility Policy Summary

**A closed unknown-first comparator now applies one policy to public API, supported targets, minimum toolchain, dependency floors, candidate versions, and release evidence.**

## Performance

- **Duration:** 48m
- **Tasks:** 2
- **Files created:** 4

## Accomplishments

- Defined the canonical four-class policy and closed comparison-result schema with an explicit non-semantic claim boundary.
- Implemented lossless normalized declaration/import comparison, target and generation-toolchain validation, supported-target/minimum-toolchain/dependency-floor classification, arbitrary-precision canonical SemVer checks, and policy-driven release authorization without version mutation.
- Proved exact, additive, incompatible, and unknown outcomes plus stable rejection rules for malformed, ambiguous, partial, divergent, incompatible, version-insufficient, and evidence-deficient candidates while keeping committed fixtures and tracked source immutable.

## Task Commits

1. **Task 1: Define and implement the four-class policy comparator** - `b404c64`
2. **Task 2: Prove version and evidence failures reject exactly** - `51a04f9`

## Files Created/Modified

- `policy/compatibility.json` - Single owner for precedence, controlled facts, baseline profile, version increments, evidence requirements, RFC conditions, and stable rule IDs.
- `compatibility/schema/comparison-schema.json` - Closed exact/additive/incompatible/unknown result contract.
- `scripts/quality/Compare-PublicInterfaceBaseline.ps1` - Read-only structural classifier and executable authorization gate.
- `scripts/quality/Test-PublicCompatibility.ps1` - Positive and fail-closed test matrix with immutable baseline and tracked-source checks.

## Decisions Made

- A new declaration that collides with an existing declaration identity is ambiguous, including adjacent overload additions; ambiguity is `unknown`, not optimistically additive.
- A fully represented supported-target removal is incompatible, while per-target text divergence or mismatch between generated and declared targets is unknown.
- Generation toolchain drift is unknown because its normalized evidence is unapproved; changing the declared minimum-toolchain floor is an explicit incompatible policy fact.
- Canonical version components use arbitrary-precision integers, so leading-zero forms reject and large valid components do not overflow.
- Policy JSON, not comparator branches or changelog prose, owns minimum increments and evidence consequences.

## Deviations from Plan

### Auto-fixed Issues

**1. Existing normalized grammar contains a plain private alias**
- **Found during:** Task 2 exact-class regression
- **Issue:** The v0.1 baseline contains `type BudgetWindow`; the first parser version recognized only declarations with explicit visibility and therefore failed a valid exact baseline closed.
- **Fix:** Preserve a plain top-level `type` as a known internal declaration and compare it losslessly.
- **Files modified:** `scripts/quality/Compare-PublicInterfaceBaseline.ps1`
- **Verification:** Exact comparison and the full matrix pass.
- **Committed in:** `51a04f9`

**2. Consequence checks initially mirrored policy values in code**
- **Found during:** Task 2 policy-ownership audit
- **Issue:** Version, migration, and added-surface checks had correct behavior but duplicated policy values in branches.
- **Fix:** Read `minimum_increment`, release allowance, and evidence requirements directly from the closed class policy; read RFC triggers from the closed RFC condition.
- **Files modified:** `scripts/quality/Compare-PublicInterfaceBaseline.ps1`, `scripts/quality/Test-PublicCompatibility.ps1`
- **Verification:** A temporary policy-controlled minimum-increment case proves the comparator follows policy data.
- **Committed in:** `51a04f9`

---

**Total deviations:** 2 auto-fixed correctness issues.
**Impact on plan:** Both fixes strengthen the intended closed, single-authority design without expanding scope.

## Edge and Prohibition Review

- **EDGE-COMP-02-ADJACENCY:** A new adjacent overload with the same declaration identity is explicitly ambiguous and returns `unknown`.
- **EDGE-COMP-02-EMPTY:** An empty or partial candidate inventory returns `unknown`; a missing baseline returns `unknown` under its own rule.
- **EDGE-COMP-02-ORDERING:** Unknown syntax wins when unknown and incompatible evidence coexist.
- **EDGE-COMP-03-BOUNDARY:** Additive and incompatible patch increments reject; sufficient minor increments pass.
- **EDGE-COMP-03-PRECISION:** Leading zeros reject and arbitrary-size canonical numeric components compare without overflow.
- **EDGE-COMP-03-CONCURRENCY:** An incomplete/interrupted candidate result rejects before authorization.
- **EDGE-COMP-04-UNCLASSIFIED:** Missing changelog, added-surface, migration, or triggered RFC evidence each rejects under its owning rule.
- **PROH-COMP-SEMANTICS:** Remains an explicit scope prohibition. The policy, schema, and result claim only interface text and declared release facts; no behavioral, resource-limit, representation-layout, performance, or full semantic compatibility is inferred.

## Issues Encountered

- PowerShell strict mode does not allow `.Name` member enumeration on an empty property collection. Dependency-floor name collection now enumerates property objects explicitly, including `mb-core`'s empty dependency set.

## User Setup Required

None - this plan is credential-free and performs no registry or publication mutation.

## Verification

- The plan's JSON policy/schema verification command passed.
- `pwsh -NoProfile -File scripts/quality/Test-PublicCompatibility.ps1` passed the complete matrix in 52.1 seconds.
- The suite proved baseline fixture digests and the tracked working-tree snapshot were unchanged.

## Next Phase Readiness

- Plan 06-04 can consume one closed comparison result and policy-owned evidence consequence set.
- The registry authority checkpoint from Plan 06-01 remains independent and unresolved; this plan neither reads credentials nor claims publication readiness.

---
*Phase: 06-namespace-authority-and-compatibility-contract*
*Completed: 2026-07-17*
