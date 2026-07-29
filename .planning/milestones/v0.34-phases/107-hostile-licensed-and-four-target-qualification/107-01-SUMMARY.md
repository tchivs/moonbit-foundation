---
phase: 107-hostile-licensed-and-four-target-qualification
plan: 01
subsystem: testing
tags: [cff1, fonttools, afdko, ots, hostile-fixtures, provenance]

requires:
  - phase: 104-cff1-profile-and-bounded-data-model
    provides: Bounded CFF1 structural admission and name/CID keying contracts
  - phase: 105-bounded-type-2-validation-and-retained-metrics
    provides: Deterministic Type 2 VM, limits, B8 atomicity, and retained bounds
  - phase: 106-cubic-path-and-public-ttc-integration
    provides: Public CFF outline and selected-collection routing contracts
provides:
  - Locked Windows host toolchain with isolated fontTools, AFDKO, and OTS readers
  - Canonical generated, licensed-intake, target, workload, and compatibility contracts
  - Source-traced hostile outcome matrix with literal B8 snapshots and precedence
affects: [107-02, 107-03, 107-04, 107-05, 107-06, CFF-06]

tech-stack:
  added: [fontTools-4.63.0, AFDKO-5.0.1, OTS-3b26b2e]
  patterns: [caller-authorized host manifest, isolated exact-digest provisioning, closed ordered JSON contracts, source-traced hostile outcomes]

key-files:
  created:
    - fixtures/font/cff/host-toolchain.lock.json
    - fixtures/font/cff-oracle-tools.json
    - fixtures/font/cff-qualification-cases.json
    - scripts/fixtures/Provision-CffQualificationTools.ps1
    - scripts/fixtures/oracles/fonttools_cff_oracle.py
    - scripts/fixtures/oracles/Invoke-AfdkoCffOracle.ps1
  modified:
    - scripts/fixtures/Generate-FontQualification.ps1

key-decisions:
  - "The committed oracle contract records digest identities but excludes machine-local executable paths; the ignored validated handoff remains the sole path authority."
  - "OTS is structural-only; fontTools and AFDKO remain independent semantic readers with alias/import checks."
  - "Hostile outcomes store literal error, GID, publication, and four B8 snapshots; consumers may not derive or complete expected facts."

patterns-established:
  - "Every canonical JSON document is ordered, LF UTF-8 without BOM, and rejected on key/order/cardinality drift."
  - "Every adjustable ceiling uses adjacent exact/one-short rows; malformed framing records an explicit non-applicable Data reason."

requirements-completed: [CFF-06]

coverage:
  - id: D1
    description: Exact locked host chain provisions two independent semantic readers and one structural-only reader without fallback.
    requirement: CFF-06
    verification:
      - kind: integration
        ref: "scripts/fixtures/Test-CffQualificationTools.ps1 plus fresh-stage tracer feedback gate"
        status: pass
    human_judgment: false
  - id: D2
    description: Canonical generated, licensed-intake, public, compatibility, target, and workload contracts are closed and read-only.
    requirement: CFF-06
    verification:
      - kind: unit
        ref: "Generate-FontQualification.ps1 -CheckContracts/-CheckGeneratedRecipes/-CheckOracleAdapters/-CheckSchemaNegatives"
        status: pass
    human_judgment: false
  - id: D3
    description: Structural, Type 2, resource, mutation, and precedence outcomes carry literal source traces and complete B8 snapshots.
    requirement: CFF-06
    verification:
      - kind: unit
        ref: "Generate-FontQualification.ps1 -CheckHostileInventory/-CheckOutcomeTrace/-CheckBoundaryApplicability"
        status: pass
    human_judgment: false

duration: 58min
completed: 2026-07-29
status: complete
---

# Phase 107 Plan 01: Locked CFF Qualification Producers Summary

**Exact-digest fontTools/AFDKO/OTS provisioning plus a byte-canonical generated/licensed/hostile CFF corpus with literal B8 and precedence facts**

## Performance

- **Duration:** 58 min
- **Started:** 2026-07-29T01:48:15Z
- **Completed:** 2026-07-29T02:46:17Z
- **Tasks:** 3 implementation tasks plus 1 approved blocking preflight checkpoint
- **Files modified:** 9

## Accomplishments

- Locked the caller-authorized 28-role host manifest, exact wheels and OTS source, isolated build/test commands, invoked identities, and two independent semantic adapters.
- Froze deterministic name-keyed, two-FD CID, shared-CFF collection, Source Sans, Source Han, public workflow, compatibility, four-target, and four correctness-workload producer facts.
- Froze six hostile groups with exact assertion locators, literal error/GID/publication facts, four ordered B8 snapshots per row, adjustable-boundary applicability, and State → Resource → Capability → Data precedence.

## Task Commits

Each TDD task was committed atomically as RED then GREEN:

1. **Task 1: Locked host-chain tracer** — `3124ec6b` (RED), `0c0e6fdb` (GREEN)
2. **Task 2: Canonical non-hostile contracts** — `e63c9db8` (RED), `d99b5547` (GREEN)
3. **Task 3: Hostile outcomes and precedence** — `ce00f658` (RED), `c8205cf6` (GREEN)

## Files Created/Modified

- `fixtures/font/cff/host-toolchain.lock.json` — approved caller manifest, roles, exact readers, source, and process policy.
- `fixtures/font/cff-oracle-tools.json` — closed package/source/invoked/adapter digest contract without local paths.
- `fixtures/font/cff-qualification-cases.json` — ordered generated, licensed-intake, workflow, target, workload, hostile, B8, and precedence corpus.
- `scripts/fixtures/Provision-CffQualificationTools.ps1` — fail-closed manifest validation, isolated acquisition/build/test, negative probes, and atomic handoff update.
- `scripts/fixtures/Generate-FontQualification.ps1` — generated tracer plus closed contract, oracle, schema, hostile, trace, and boundary validators.
- `scripts/fixtures/oracles/fonttools_cff_oracle.py` — fontTools-only semantic projection.
- `scripts/fixtures/oracles/Invoke-AfdkoCffOracle.ps1` — AFDKO `tx`-only semantic projection.
- `scripts/fixtures/Test-CffQualificationTools.ps1` — host-chain contract test.
- `scripts/fixtures/Test-CffQualificationContracts.ps1` — read-only canonical contract and hostile matrix test.

## Execution handoff

- **Path:** `artifacts/release-qualification/phase-107/107-01-host-toolchain-handoff.json`
- **SHA-256:** `08731c546b88f29f175d8c1d513d9741ccf1e69b1027241cf6e7e83449fb3bdf`
- **Schema:** `mnf-phase107-host-toolchain-handoff/1.0.0`
- **Caller manifest SHA-256:** `6ff664ca0e03ae75388947a6dd4a80626d11cf61198ef2934d5808ef908ceaa9`
- **Lock SHA-256:** `670a357041d61e8315f930e08951de878aca49d92f384824e8f759eeea221bc5`
- **SDK inventory SHA-256:** `d4dcf1d9d1fae39bcd4f6e1daea4cea5e49d4a4da26b8d6fa1c0c6bef7f20e50`
- **Invoked identities SHA-256:** `2a32df8fc925871c81776d0a21c19ad8a7d6352eacb2d8a8053ac8dcaf22307d`
- **Provisioned tools root:** `D:\AI-Data\temp\Admin\mnf-cff-host-feedback-f8a889ccef664ab586c39652e6bdb228`
- **provisioning_validated:** `true`

Plan 107-02 must consume this exact ignored handoff and may not rediscover tools through ambient environment state.

## Decisions Made

- Kept all machine-local paths out of committed oracle JSON while freezing every equality-bearing digest and role.
- Stored generated expected geometry as ordered commands and coordinates, not debug strings or a production-derived projection.
- Classified only independently adjustable ceilings as Resource exact/one-short pairs; malformed/cardinality/framing rows remain Data and explain why no pair applies.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Performance bug] Avoided repeated full SDK inventories inside every negative mutation**
- **Found during:** Task 1
- **Issue:** Each one-field negative repeated the multi-minute complete inventory walk even though the positive entry check had already validated it.
- **Fix:** Negative manifest mutations skip redundant inventories while the authoritative positive invocation still verifies the full runtime and SDK inventories once.
- **Files modified:** `scripts/fixtures/Provision-CffQualificationTools.ps1`
- **Verification:** Fresh isolated provision, provisioner `-Check`, and tracer feedback gate passed.
- **Committed in:** `0c0e6fdb`

**2. [Rule 1 - Test bug] Dynamic PowerShell splatting did not pass named validation switches**
- **Found during:** Task 2
- **Issue:** The first harness form treated the inline hashtable as an ordinary argument, exercising the legacy generator path instead of each new read-only mode.
- **Fix:** Built a named argument hashtable variable before splatting and reran every switch independently.
- **Files modified:** `scripts/fixtures/Test-CffQualificationContracts.ps1`
- **Verification:** All seven independent validation modes and the aggregate harness passed.
- **Committed in:** `d99b5547`

**3. [Rule 1 - State attribution bug] GSD decision handler emitted `Phase ?` labels**
- **Found during:** Final state update
- **Issue:** The three recorded decisions were added with unknown phase attribution despite `current_phase: 107`.
- **Fix:** Normalized only the three newly added labels to `Phase 107` after the required SDK calls completed.
- **Files modified:** `.planning/STATE.md`
- **Verification:** State position remains Plan 2 of 6 and all three decisions now carry the literal phase.
- **Committed in:** final documentation commit

---

**Total deviations:** 3 auto-fixed Rule 1 issues.
**Impact on plan:** Both fixes strengthened verification correctness and reduced redundant work; no feature scope changed.

## Issues Encountered

- The first absolute patch operation resolved against the main checkout rather than the linked execution worktree. The four newly created, still-untracked task files were immediately verified, moved into the authorized worktree, and the task-created empty directories removed. The main checkout was rechecked with no task-path changes before testing or committing.

## Known Stubs

None. Empty arrays and nulls in the corpus are closed semantic values for no-FD name-keyed fonts, full-admission workloads, absent optional GIDs, and `Close` commands; no value is a placeholder or unwired data source.

## Authentication Gates

None.

## Threat Flags

No unplanned threat surface was introduced. The network acquisition, subprocess execution, filesystem staging, and caller-authority boundaries are all declared in the plan threat model and covered by exact-digest, containment, alias, and negative checks.

## User Setup Required

None. The approved caller-manifest checkpoint is complete and the validated ignored handoff names the exact provisioned root.

## Next Phase Readiness

- Plan 107-02 has exact Source Sans/Source Han archive/member/license/profile facts and a validated reader/tool handoff.
- No downstream phase must discover a tool, select a target/workload, derive an expected geometry, or invent a hostile outcome.

## Self-Check: PASSED

All nine task files, all six RED/GREEN commits, the ignored execution handoff, and its recorded SHA-256 were verified after summary creation.

---
*Phase: 107-hostile-licensed-and-four-target-qualification*
*Completed: 2026-07-29*
