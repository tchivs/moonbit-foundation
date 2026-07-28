---
phase: 103-hostile-licensed-and-four-target-qualification
plan: 03
subsystem: font-release-qualification
tags: [moonbit, ttc, opentype, evidence, policy, ci, provenance, tdd]

requires:
  - phase: 103-hostile-licensed-and-four-target-qualification
    plan: 01
    provides: Frozen collection corpus, licensed derivative, independent oracle, and exact 14-record manifest
  - phase: 103-hostile-licensed-and-four-target-qualification
    plan: 02
    provides: Exact standalone, collection, hostile, resource, and mutation focused assertion identities
provides:
  - Fresh managed font qualification evidence schema v2 with four ordered target records
  - Closed semantic projection and target/runner-only normalization with SHA-256 comparison
  - Independent corpus, oracle, source, interface, dependency, CI, and documentation policy gates
  - Executable collection documentation and retained licensing/runtime/release boundaries
affects: [font-verification, milestone-audit, release-qualification]

tech-stack:
  added: []
  patterns:
    - Build canonical evidence only after every target gate passes, then read back and validate before comparison
    - Derive focused and package totals from executed commands rather than source constants
    - Keep managed evidence versions in fresh ownership directories with exact markers

key-files:
  created:
    - .planning/phases/103-hostile-licensed-and-four-target-qualification/103-03-SUMMARY.md
  modified:
    - scripts/quality/Invoke-FontQualification.ps1
    - scripts/quality/Test-FontQualificationEvidenceBoundary.ps1
    - scripts/quality/Assert-Policy.ps1
    - policy/foundation.json
    - modules/mb-font/moon.mod.json
    - .github/workflows/quality.yml
    - docs/policies/licensing-and-fixtures.md
    - modules/mb-font/README.mbt.md
    - modules/mb-font/CHANGELOG.md

key-decisions:
  - "Evidence v2 normalizes exactly top-level target and runner; every other semantic field participates in canonical equality."
  - "The 14 focused identities and 152 full-package passes are discovered per target, with no aggregate source constant."
  - "The measured 45.485-second complete lane leaves the existing 20-minute CI timeout unchanged."
  - "Collection inspection and selected static-glyf admission are documented without changing publication, stability, or release policy."

patterns-established:
  - "Managed evidence ownership: a v1 marker never authorizes v2 cleanup, and only known v2 evidence files may be removed."
  - "Closed qualification record: exact ordered top-level and nested schemas are validated before write, after read-back, and during comparison."

requirements-completed:
  - TTC-04
  - TTC-05

coverage:
  - id: D1
    description: "Four independent targets execute the exact standalone, generated, licensed, hostile, resource, and mutation assertions plus the complete font package."
    requirement: TTC-05
    verification:
      - kind: integration
        ref: "./scripts/quality.ps1 -Lane FontQualification -EvidenceDirectory artifacts/release-qualification/font-v2"
        status: pass
      - kind: other
        ref: "14 focused gates and 152/152 discovered package passes on js, wasm, wasm-gc, and native"
        status: pass
    human_judgment: false
  - id: D2
    description: "Canonical v2 records preserve exact hostile, budget, mutation, derivative, API, source, and dependency facts with target/runner-only normalization."
    requirement: TTC-04
    verification:
      - kind: integration
        ref: "scripts/quality/Test-FontQualificationEvidenceBoundary.ps1"
        status: pass
      - kind: other
        ref: "4 ordered records, 18 negative probes, comparison equal, semantic SHA-256 237117eae54ef9e81f2f8be778597a24b940846eb195772d0d1f7562ef7968a3"
        status: pass
    human_judgment: false
  - id: D3
    description: "Policy and documentation preserve the 85-line API, 13 production sources, sole mb-core edge, five imports, four targets, exact licensed lineage, and deferred runtime/release boundaries."
    requirement: TTC-05
    verification:
      - kind: integration
        ref: "Assert-FontFoundationPolicy -PolicyPath ./policy/foundation.json"
        status: pass
      - kind: integration
        ref: "./scripts/quality/Test-FixturePolicy.ps1"
        status: pass
      - kind: other
        ref: "moon -C modules/mb-font check --target all --frozen"
        status: pass
    human_judgment: false

duration: 15min
completed: 2026-07-28
status: complete
---

# Phase 103 Plan 03: Managed Four-Target Evidence and Policy Summary

**Managed evidence v2 now proves identical standalone, collection, hostile, resource, and mutation semantics across all four MoonBit targets while policy and documentation keep deferred runtime and release boundaries closed.**

## Performance

- **Duration:** 15 min
- **Started:** 2026-07-28T05:37:49Z
- **Completed:** 2026-07-28T05:52:55Z
- **Tasks:** 2
- **Files modified:** 10
- **Measured complete lane:** 45.485 seconds (0.758 minutes)

## Accomplishments

- Advanced the existing runner to marker `mnf-font-qualification-evidence/v2`, workflow `font-complete-public-v2`, and fresh local/CI directories without reusing or cleaning v1 evidence.
- Emitted exactly `js`, `wasm`, `wasm-gc`, and `native` records with the frozen 15-key schema, exact Plan 103 focused identities, read-back validation, 18 negative probes, and one canonical comparison.
- Proved 14 focused gates and 152 discovered complete-package passes independently on every target; normalized semantics are equal with SHA-256 `237117eae54ef9e81f2f8be778597a24b940846eb195772d0d1f7562ef7968a3`.
- Extended independent policy classification for the collection corpus/oracle, licensed derivative lineage, WOFF/CFF/variable/FFI/I/O boundaries, exact 85-line interface, 13-source inventory, five imports, sole mb-core edge, and four targets.
- Added executable public collection documentation, precise DejaVu derivative provenance, v2 report semantics, and retained exclusions without publication, stability, or release-policy changes.
- Measured the complete lane at 45.485 seconds and retained the existing 20-minute CI timeout.

## Task Commits

TDD gates and task outcomes were committed atomically:

1. **Task 1 RED: v2 ownership and schema gates** — `e38897bf`
2. **Task 1 GREEN: managed four-target evidence v2** — `b5f42a5c`
3. **Task 2 RED: collection policy and CI gates** — `4dbcbe6c`
4. **Rule 1 fixes: complete-lane runtime validation** — `d8b5aeb8`
5. **Task 2 GREEN: policy, CI, licensing, README, and changelog** — `2589c971`

## Files Created/Modified

- `scripts/quality/Invoke-FontQualification.ps1` — closed v2 runner, 14 per-target focused gates, discovered package totals, read-back validation, negative probes, and semantic comparison.
- `scripts/quality/Test-FontQualificationEvidenceBoundary.ps1` — fresh-v2 identity, v1-marker rejection, strict child/link/reparse, known-file cleanup, and unrelated-file preservation.
- `scripts/quality/Assert-Policy.ps1` — independent collection corpus/oracle, source capability, runner, CI, interface, dependency, fixture, and documentation classifiers.
- `policy/foundation.json` — synchronized collection-aware mb-font description; all other module/publication identities retained.
- `modules/mb-font/moon.mod.json` — synchronized description with version, dependency, targets, repository, readme, and release identity unchanged.
- `.github/workflows/quality.yml` — existing FontQualification job moved to success-only `ci-font-v2` evidence; timeout remains 20 minutes.
- `docs/policies/licensing-and-fixtures.md` — explicit external-derivative parent, generator, notice, digest, and redistribution rule.
- `modules/mb-font/README.mbt.md` — executable caller-owned collection workflow, selected static-glyf observations, licensed lineage, v2 command/report, and retained exclusions.
- `modules/mb-font/CHANGELOG.md` — unpublished candidate history for collection inspection, admission, hostile/mutation qualification, derivative, and evidence v2.

## Decisions Made

- Kept comparison normalization deliberately narrow: only top-level `target` and `runner` are removed.
- Treated toolchain, fixtures, all semantic facts, dependencies, focused assertion identities, and pass state as equality-bearing evidence.
- Used the closed assertion array and parsed Moon test summaries for counts instead of freezing a package total in source.
- Kept the existing CI job and 20-minute timeout because the measured full lane completes in under one minute.
- Preserved the Wave 1 exact 14-record manifest gate and the Wave 2 focused names verbatim.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected PowerShell child-script success detection**

- **Found during:** Task 2 complete-lane measurement
- **Issue:** The runner read `$LASTEXITCODE` after invoking a PowerShell script, where the variable is not guaranteed to exist.
- **Fix:** Used PowerShell success state for the generator child script while retaining native exit-code checks for `moon`.
- **Files modified:** `scripts/quality/Invoke-FontQualification.ps1`
- **Verification:** Complete FontQualification lane passed.
- **Committed in:** `d8b5aeb8`

**2. [Rule 1 - Bug] Closed validation over the actual corpus enums**

- **Found during:** Task 2 complete-lane measurement
- **Issue:** The initial validator admitted only success/failure and new-object publication values, omitting the frozen exact/one-short and existing-object states.
- **Fix:** Added only the exact Wave 1 boundary and publication enum values.
- **Files modified:** `scripts/quality/Invoke-FontQualification.ps1`
- **Verification:** All four records passed write/read-back validation.
- **Committed in:** `d8b5aeb8`

**3. [Rule 1 - Bug] Excluded the managed marker from target-record counting**

- **Found during:** Task 2 final evidence gate
- **Issue:** The `.json` marker was included by the target-record glob and appeared as a fifth record.
- **Fix:** Excluded both `comparison.json` and the exact managed marker name.
- **Files modified:** `scripts/quality/Invoke-FontQualification.ps1`
- **Verification:** Final report emitted `targets=4, records=4`.
- **Committed in:** `d8b5aeb8`

---

**Total deviations:** 3 auto-fixed bugs.
**Impact on plan:** All fixes were necessary for correct execution of the planned v2 lane; no scope or architectural boundary changed.

## Issues Encountered

- The first two attempted measurements intentionally stopped at newly exercised validation boundaries. After the three inline fixes, the complete lane passed in 45.485 seconds.
- Native focused tests emitted two inherited unused-result compiler warnings from the MoonBit core library; all tests passed and no project source warning was introduced.

## User Setup Required

None - qualification is deterministic, offline, and uses only pinned repository fixtures and toolchain inputs.

## Known Stubs

None.

## Threat Flags

None. This plan added no network endpoint, authentication path, ambient file access, FFI, schema trust boundary, or publication surface.

## Next Phase Readiness

- TTC-04 and TTC-05 now have canonical four-target release evidence and independent policy enforcement.
- The v2 evidence directory contains four ordered records plus `comparison.json`, with equal normalized semantics.
- Milestone verification can consume the exact focused identities, discovered pass totals, hashes, and retained boundary facts.
- No blockers remain.

## Self-Check: PASSED

All ten owned artifacts exist, all five implementation/TDD/deviation commits resolve, the final evidence has four ordered target records with equality true, and the worktree contains no uncommitted implementation changes.

---
*Phase: 103-hostile-licensed-and-four-target-qualification*
*Completed: 2026-07-28*
