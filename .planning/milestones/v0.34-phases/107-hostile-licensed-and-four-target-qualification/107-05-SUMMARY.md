---
phase: 107-hostile-licensed-and-four-target-qualification
plan: "05"
subsystem: qualification
tags: [moonbit, cff1, font, four-target, evidence-v3, policy, ci]

requires:
  - phase: 107-04
    provides: Closed public/private CFF observations, hostile outcomes, mutation facts, and static-glyf compatibility
provides:
  - Fresh link-safe v3 qualification ownership with exactly four ordered target records
  - Explicit target/runner-only semantic normalization and closed comparison evidence
  - Exact pre-benchmark policy inventories, single retained 20-minute CI lane, and qualified static-CFF1 documentation
affects: [107-06, cff-native-baseline, final-v3-seal, release-evidence]

tech-stack:
  added: []
  patterns:
    - Literal five-product ownership under a byte-preserved v3 marker
    - Explicit equality projection that removes only top-level target and runner
    - Policy-owned file facts with executable one-field substitution negatives

key-files:
  created: []
  modified:
    - scripts/quality/Invoke-FontQualification.ps1
    - scripts/quality/Test-FontQualificationEvidenceBoundary.ps1
    - scripts/quality/Assert-Policy.ps1
    - policy/foundation.json
    - .github/workflows/quality.yml
    - modules/mb-font/moon.mod.json
    - modules/mb-font/README.mbt.md
    - modules/mb-font/CHANGELOG.md
    - docs/policies/licensing-and-fixtures.md

key-decisions:
  - "Qualification v3 owns exactly js.json, wasm.json, wasm-gc.json, native.json, and comparison.json beneath a link-free managed root."
  - "Cross-target equality removes only top-level target and runner; every other closed field remains equality-bearing."
  - "Wave 6 owns the observation-only native baseline and final benchmark/workspace identity refresh; Wave 5 makes no threshold, comparison, verdict, release, or stability claim."

patterns-established:
  - "Fresh evidence authority: earlier markers fail before cleanup, while unrelated files never become cleanup authority."
  - "Pre-benchmark seal: live runtime, test, evidence, fixture, oracle, and qualification-tool identities are exact, with a named Wave 6 refresh seam."

requirements-completed: [CFF-06]

coverage:
  - id: D1
    description: Exactly four isolated v3 records pass in js, wasm, wasm-gc, native order and compare equal after target/runner-only normalization.
    requirement: CFF-06
    verification:
      - kind: integration
        ref: "quality.ps1 -Lane FontQualification -EvidenceDirectory artifacts/release-qualification/font-v3"
        status: pass
    human_judgment: false
  - id: D2
    description: Ownership, containment, marker, cleanup, schema, local resolution, source, toolchain, and semantic divergence negatives fail closed.
    requirement: CFF-06
    verification:
      - kind: integration
        ref: "Test-FontQualificationEvidenceBoundary.ps1 and Invoke-FontQualification.ps1 -ContractOnly"
        status: pass
    human_judgment: false
  - id: D3
    description: Policy and documentation preserve the 85-line API, sole dependency, five imports, static-CFF1 evidence ownership, and Wave 6 claim boundary.
    requirement: CFF-06
    verification:
      - kind: policy
        ref: "Assert-FontFoundationPolicy and four-target mb-font document tests"
        status: pass
    human_judgment: false

duration: 67min
completed: 2026-07-29
status: complete
---

# Phase 107 Plan 05: Four-Target Font Qualification v3 Summary

**Fresh v3 ownership now emits four equal closed font records while exact policy, CI, and documentation preserve the qualified static-CFF1 boundary for Wave 6.**

## Performance

- **Duration:** 67 min
- **Started:** 2026-07-29T05:39:17Z
- **Completed:** 2026-07-29T06:46:00Z
- **Tasks:** 3
- **Files modified:** 9

## Accomplishments

- Advanced the font qualification runner to schema `3.0.0`, workflow `font-complete-public-v3`, marker `mnf-font-qualification-evidence/v3`, and literal `js,wasm,wasm-gc,native` order.
- Closed managed-root authority, link/reparse containment, marker preservation, exact five-product cleanup, record schemas, local workspace resolution, and one-field semantic divergence negatives.
- Locked current production, test, evidence, fixture, licensed specimen, oracle, generator, runner, and boundary identities while preserving the 85-line public interface, sole `tchivs/mb-core@0.1.0` dependency, five imports, and four portable targets.
- Retained the single success-only 20-minute FontQualification CI job at `ci-font-v3`.
- Documented opaque standalone/selected-collection static CFF1, exact Source Sans and Source Han evidence, two-reader agreement, structural-only OTS, non-published package-private evidence, and the observation-only Wave 6 baseline boundary.
- Produced four equal v3 records with semantic SHA-256 `1601eb7a700966c508f09cead421dbc6c786a0105702f104d3e8bdd6fc6b2e0b`.

## Task Commits

1. **Task 1 RED: failing v3 evidence boundary contract** - `ef1b3c4c`
2. **Task 1 GREEN: v3 font qualification runner** - `5cd4b8e4`
3. **Task 2 RED: failing v3 policy and CI contract** - `f5ad0577`
4. **Task 2 GREEN: exact pre-benchmark policy and retained CI lane** - `ba1bcfad`
5. **Task 3: qualified static-CFF1 documentation** - `b84922fe`
6. **Policy synchronization fix** - `798b18ea`

## Files Created/Modified

- `scripts/quality/Invoke-FontQualification.ps1` - Fresh v3 ownership, isolated target execution, closed records, explicit normalization, and comparison.
- `scripts/quality/Test-FontQualificationEvidenceBoundary.ps1` - Destructive-boundary, schema, record, and semantic one-field negatives.
- `scripts/quality/Assert-Policy.ps1` - Exact v3 inventories, runtime/API/dependency/import boundaries, CI contract, and documentation claims.
- `policy/foundation.json` - Live CFF1 production/test/evidence/fixture/oracle/tool identities and Wave 6 refresh seam.
- `.github/workflows/quality.yml` - Existing single 20-minute v3 job and success-only five-product upload.
- `modules/mb-font/moon.mod.json` - Static TrueType/CFF1 standalone and selected-collection candidate description.
- `modules/mb-font/README.mbt.md` - Qualified CFF1 behavior, licensed evidence, v3 records, and deliberate exclusions.
- `modules/mb-font/CHANGELOG.md` - Current candidate static-CFF1 and v3 evidence entry.
- `docs/policies/licensing-and-fixtures.md` - Exact upstream specimen, reader, carrier, and production-payload ownership policy.

## Decisions Made

- A qualification directory is authoritative only after exact marker validation; cleanup remains a literal five-file operation and never enumerates ownership.
- Target records are constructed and validated independently; equality uses an explicit top-level projection rather than recursive normalization.
- Static CFF1 is production behavior, but licensed CFF bytes and generated evidence remain outside the production package and public API.
- Native timing remains an observation-only Wave 6 artifact and cannot become a threshold, ranking, superiority, release, or stability claim.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected PowerShell array composition in focused assertions**
- **Found during:** Task 1 GREEN
- **Issue:** Parenthesized `@($PublicEvidenceAssertions[0] + $PrivateFocusedAssertions)` coerced the left operand incorrectly and broke the intended assertion list.
- **Fix:** Composed `@($PublicEvidenceAssertions[0]) + @($PrivateFocusedAssertions)` at both runner call sites.
- **Files modified:** `scripts/quality/Invoke-FontQualification.ps1`
- **Verification:** Native tracer and the final four-target lane pass.
- **Committed in:** `5cd4b8e4`

**2. [Rule 3 - Blocking] Refreshed the live Phase 103 collection corpus semantic lock**
- **Found during:** Task 2 GREEN policy verification
- **Issue:** The hard-coded semantic digest predated the already-landed canonical corpus, preventing policy verification from reaching the new v3 contract.
- **Fix:** Recomputed the exact compressed semantic digest for the tracked corpus.
- **Files modified:** `scripts/quality/Assert-Policy.ps1`
- **Verification:** `Assert-FontFoundationPolicy` passes.
- **Committed in:** `ba1bcfad`

**3. [Rule 1 - Bug] Removed a false-positive CFF2 flow heuristic**
- **Found during:** Task 2 GREEN production-boundary verification
- **Issue:** A file-wide CFF2-tag plus generic Type 2 call heuristic rejected valid CFF1 code that explicitly detects and refuses CFF2.
- **Fix:** Retained direct CFF2 execution negatives while removing the coarse cross-region flow pairing.
- **Files modified:** `scripts/quality/Assert-Policy.ps1`
- **Verification:** Static CFF1 sources pass; direct and interpolated CFF2 execution probes still fail closed.
- **Committed in:** `ba1bcfad`

**4. [Rule 3 - Blocking] Synchronized documentation changes with exact policy file identities**
- **Found during:** Plan-level verification after Task 3
- **Issue:** Task 2 intentionally locked `moon.mod.json` and the policy validator itself, so the planned Task 3 description and claim updates made those exact identities stale.
- **Fix:** Refreshed the manifest/tool file facts and made the v3 README, CHANGELOG, and licensing statements executable policy assertions.
- **Files modified:** `policy/foundation.json`, `scripts/quality/Assert-Policy.ps1`
- **Verification:** Final policy and four-target qualification pass.
- **Committed in:** `798b18ea`

**5. [Rule 1 - Bug] Normalized stale SDK-generated execution metadata**
- **Found during:** Plan finalization
- **Issue:** State handlers advanced counters but emitted `Phase ?` decision labels and retained Plan 04 activity, Plan 05 next-step, and sixteen-plan prose.
- **Fix:** Attributed decisions to Phase 107 and synchronized activity, next step, plan count, and ROADMAP formatting with completed Plan 05.
- **Files modified:** `.planning/STATE.md`, `.planning/ROADMAP.md`
- **Verification:** State reports Plan 6 of 6, 17/18 completed plans, 94% progress, and ROADMAP reports 5/6.
- **Committed in:** Plan metadata commit

---

**Total deviations:** 5 auto-fixed (3 Rule 1 bugs, 2 Rule 3 blocking issues).
**Impact on plan:** Each fix was required for the planned v3 runner or exact fail-closed policy to operate; no public API, dependency, target, runtime I/O, licensed-payload, or release surface was added.

## Issues Encountered

- The combined four-target documentation command exceeded one tool-call timeout after `js` passed 1286/1286. The remaining targets were resumed individually and all passed 1286/1286; no verification was skipped.
- Existing compiler/deprecation warnings remain outside this plan's scope.

## Known Stubs

None.

## Threat Flags

None. All new policy and evidence schemas were planned, and no endpoint, authentication path, runtime file access, FFI seam, production dependency, or public fixture surface was introduced.

## TDD Gate Compliance

- Task 1 RED `ef1b3c4c` precedes GREEN `5cd4b8e4`.
- Task 2 RED `f5ad0577` precedes GREEN `ba1bcfad`.
- Both RED gates failed for the intended missing v3 contract before implementation; Task 3 was not designated TDD.

## User Setup Required

None.

## Next Phase Readiness

- Wave 6 can add the observation-only native baseline and refresh the named benchmark/workspace/script/test/baseline identities before the final v3 seal.
- No blocker, stub, skipped test, unrun verification, threshold, or broader release claim remains.

## Self-Check: PASSED

All nine key files and all six implementation/test/documentation commits were verified on disk and in Git history.

---
*Phase: 107-hostile-licensed-and-four-target-qualification*
*Completed: 2026-07-29*
