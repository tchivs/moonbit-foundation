---
phase: 07-release-safety-intent-and-recovery-automation
plan: "01"
subsystem: release-control
tags: [powershell, canonical-json, sha256, release-intent, fail-closed]

requires:
  - phase: 06-namespace-authority-and-compatibility-contract
    provides: Credential-free qualification evidence, registry authority classifications, module order, archive contracts, and interface baselines
provides:
  - Closed initial and forward-correction release-intent policy/schema
  - Credential-free canonical JSON generator and independent adversarial validator
  - One-way release qualification binding from stable evidence to initial root/current intent digest
affects: [07-02-publisher-state-machine, 07-03-hosted-release-control, phase-08-live-publication]

tech-stack:
  added: []
  patterns: [schema-ordered canonical JSON, UTF-8 without BOM, content-addressed intent, immutable initial root, monotonic forward correction]

key-files:
  created:
    - policy/release-control.json
    - release/intent/schema.json
    - release/intent/README.md
    - scripts/quality/New-ReleaseIntent.ps1
    - scripts/quality/Test-ReleaseIntent.ps1
  modified:
    - scripts/quality/ReleaseQualification.Common.ps1
    - scripts/quality/Invoke-ReleaseQualification.ps1

key-decisions:
  - "The initial canonical object omits root_intent_sha256; its computed intent digest becomes both the external root and current dispatch binding."
  - "Corrections retain the immutable initial root, name one latest predecessor, advance sequence by one, use a fresh clean source, and permit only one authorized successor."
  - "Release qualification emits a separate one-way binding wrapper after tracked archive/report validation, preserving false credential and publication outcomes."

patterns-established:
  - "Canonical intent: closed schema-order objects, policy-order arrays, controlled ASCII, bounded integers, compact UTF-8 without BOM."
  - "Forward recovery: mismatched intents are terminal; only a fresh policy-qualified correction may begin from genesis under new authorization."

requirements-completed: [REL-01, REL-02, REL-03, REL-04, REL-05]

coverage:
  - id: D1
    description: "Closed machine-authoritative initial and forward-correction intent contracts"
    requirement: REL-01
    verification:
      - kind: unit
        ref: "pwsh -NoProfile -File scripts/quality/Test-ReleaseIntent.ps1 -ContractOnly"
        status: pass
    human_judgment: false
  - id: D2
    description: "Deterministic credential-free generator and adversarial validator for initial/correction intents"
    requirement: REL-01
    verification:
      - kind: unit
        ref: "pwsh -NoProfile -File scripts/quality/Test-ReleaseIntent.ps1 -Focused"
        status: pass
    human_judgment: false
  - id: D3
    description: "One-way release qualification binding to equal initial root/current digests without a hash cycle"
    requirement: REL-01
    verification:
      - kind: integration
        ref: "pwsh -NoProfile -File scripts/quality/Test-ReleaseIntent.ps1 -QualificationIntegration"
        status: pass
      - kind: integration
        ref: "pwsh -NoProfile -File scripts/quality/Invoke-ReleaseQualification.ps1 -Check -StaticOnly"
        status: pass
    human_judgment: false

duration: 13min
completed: 2026-07-18
status: complete
---

# Phase 7 Plan 1: Deterministic Release Intent Summary

**Closed canonical release intents now bind exact source, toolchain, module graph, archives, interfaces, and qualification evidence while preserving an immutable root across forward-only corrections.**

## Performance

- **Duration:** 13 min
- **Started:** 2026-07-18T03:43:56Z
- **Completed:** 2026-07-18T03:56:43Z
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments

- Froze a closed Draft 2020-12 intent schema and release-control policy for exact initial and monotonic forward-correction profiles.
- Added canonical JSON/SHA-256 helpers, atomic intent generation, clean-source/ref checks, and adversarial tests for every D-02 binding, encoding/order edges, terminal mismatch, root drift, sequence drift, and stale forks.
- Integrated the initial intent after tracked archive/report validation, with a separate one-way wrapper that binds `root_intent_sha256 == intent_sha256` without serializing a self-referential root.

## Task Commits

1. **Task 1: Freeze release-control and intent contracts** - `2fb63db` (feat)
2. **Task 2 RED: Add failing canonical intent scenarios** - `f180a8b` (test)
3. **Task 2 GREEN: Implement canonical intent generation and validation** - `71bb551` (feat)
4. **Task 3: Bind the intent one-way into release qualification** - `3a78b03` (feat)

## Files Created/Modified

- `policy/release-control.json` - Exact repository, actor, environment, initial/correction, canonicalization, authority, and terminal-recovery constants.
- `release/intent/schema.json` - Closed `oneOf` schema for initial and forward-correction intent forms.
- `release/intent/README.md` - Non-authoritative explanation of root, digest, canonical encoding, and authority semantics.
- `scripts/quality/ReleaseQualification.Common.ps1` - Canonical serializer, digest helpers, intent validation, authorization binding, and terminal mismatch checks.
- `scripts/quality/New-ReleaseIntent.ps1` - Atomic credential-free initial/correction intent generator over clean Git source evidence.
- `scripts/quality/Test-ReleaseIntent.ps1` - Contract, focused adversarial, deterministic-clean-copy, correction-fork, and qualification-integration selectors.
- `scripts/quality/Invoke-ReleaseQualification.ps1` - Stable qualification projection and one-way initial intent binding after tracked evidence validation.

## Decisions Made

- Kept the initial root outside the canonical initial object to avoid a self-hash cycle; the computed current digest is aliased externally as the immutable root.
- Required correction candidates to use a clean source distinct from their predecessor and kept authorization selection separate from content identity.
- Used a dedicated binding wrapper rather than weakening the existing closed release package report schema.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added the ContractOnly validator during Task 1**
- **Found during:** Task 1 verification
- **Issue:** The plan required `Test-ReleaseIntent.ps1 -ContractOnly` before Task 2, but the script did not yet exist and was listed under the later task.
- **Fix:** Added the minimal closed-contract selector with Task 1, then expanded the same planned file through Task 2 TDD.
- **Files modified:** `scripts/quality/Test-ReleaseIntent.ps1`
- **Verification:** ContractOnly passed before Task 1 commit; RED then failed specifically because the generator was absent.
- **Committed in:** `2fb63db`

---

**Total deviations:** 1 auto-fixed (1 blocking).
**Impact on plan:** The adjustment only made the plan's own Task 1 verification executable and preserved the intended TDD RED/GREEN sequence for generator behavior.

## Issues Encountered

- PowerShell unwrapped single-element dependency arrays during recursive canonicalization. The serializer now handles schema-declared arrays explicitly, preserving empty, singleton, and multi-item arrays identically.
- Semantic validation originally compared the authorized digest before reporting a more specific ref failure. Validation order was corrected so malformed bindings retain one exact owning diagnostic.

## User Setup Required

None - this plan creates only credential-free preparation and validation controls.

## Next Phase Readiness

- Plan 07-02 can consume the immutable current/root digest and closed correction semantics in the pure publisher reducer and hash-chained journal.
- No Mooncakes credential was read and no production mutation was attempted.

## Known Stubs

None.

## Self-Check: PASSED

- All seven plan-owned files exist.
- ContractOnly, Focused, QualificationIntegration, and release qualification StaticOnly checks pass.
- Task commits `2fb63db`, `f180a8b`, `71bb551`, and `3a78b03` exist in history.
- No tracked file deletion, credential read, publication command, placeholder, TODO, or FIXME was introduced.

---
*Phase: 07-release-safety-intent-and-recovery-automation*
*Completed: 2026-07-18*
