---
phase: 107-hostile-licensed-and-four-target-qualification
plan: "06"
subsystem: testing
tags: [moonbit, cff1, native-benchmark, reproducibility, qualification]

requires:
  - phase: 107-05
    provides: four-target CFF1 correctness qualification and final v3 evidence contract
provides:
  - Exact tracked-local native CFF1 benchmark workspace and four ordered workloads
  - Observation-only native release baseline with one warmup and seven retained captures
  - Read-only audit, closed policy identity, and complete four-target post-baseline qualification
affects: [release-qualification, mb-font, cff1, benchmark-policy]

tech-stack:
  added: []
  patterns:
    - Canonical LF UTF-8 benchmark evidence with embedded closed audit data
    - Locale-independent host identity and same-directory atomic replacement

key-files:
  created:
    - docs/benchmarks/mb-font-cff-native-release-baseline.md
  modified:
    - benchmarks/moon.work
    - benchmarks/font-cff/cff_bench.mbt
    - scripts/benchmarks/Invoke-CffNativeBenchmarkBaseline.ps1
    - scripts/quality/Test-BenchmarkQualification.ps1
    - scripts/quality/Assert-Policy.ps1
    - policy/foundation.json

key-decisions:
  - "Native timing remains observation-only and separate from portable four-target correctness evidence."
  - "The active power scheme is sealed by locale-independent GUID rather than localized display text."
  - "Existing baseline replacement uses same-directory File.Replace backup and guaranteed cleanup."

patterns-established:
  - "Benchmark capture: one excluded warmup followed by exactly seven complete retained captures."
  - "Audit identity: raw hashes, six descriptive statistics, exact sources/toolchain/host, and no timing threshold."

requirements-completed: [CFF-06]

coverage:
  - id: D1
    description: Exact tracked-local workspace and four fresh-budget native CFF1 workloads
    requirement: CFF-06
    verification:
      - kind: integration
        ref: scripts/quality/Test-BenchmarkQualification.ps1 -ContractOnly
        status: pass
      - kind: integration
        ref: scripts/benchmarks/Invoke-CffNativeBenchmarkBaseline.ps1 -CheckWorkspaceResolution
        status: pass
    human_judgment: false
  - id: D2
    description: Observation-only native baseline with one warmup, seven captures, raw hashes, and six statistics
    requirement: CFF-06
    verification:
      - kind: integration
        ref: scripts/benchmarks/Invoke-CffNativeBenchmarkBaseline.ps1 -Audit
        status: pass
    human_judgment: false
  - id: D3
    description: Final policy seal and complete four-target FontQualification after baseline commit
    requirement: CFF-06
    verification:
      - kind: e2e
        ref: scripts/quality.ps1 -Lane FontQualification -EvidenceDirectory artifacts/release-qualification/font-v3
        status: pass
      - kind: integration
        ref: scripts/quality/Assert-Policy.ps1
        status: pass
    human_judgment: false

duration: 3h 41m
completed: 2026-07-29
status: complete
---

# Phase 107 Plan 06: Native CFF1 Benchmark and Final Qualification Summary

**Tracked-local CFF1 native release evidence with four fresh-budget workloads, seven retained captures, closed observation-only policy identity, and a clean read-only audit**

## Performance

- **Duration:** 3h 41m
- **Started:** 2026-07-29T06:51:28Z
- **Completed:** 2026-07-29T10:32:30Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Added the exact local MoonBit benchmark workspace and four ordered Latin/CJK admission and outline workloads with a fresh budget for every public operation.
- Recorded a 63,370-byte observation-only native baseline (`ca5fb247dceaeb63e15fec7d49b54803ca9134d1f4c686a30e58e44b7b811ce5`) from one excluded warmup and seven retained captures.
- Sealed the baseline in policy, passed the clean read-only audit, and reran the complete four-target FontQualification lane successfully.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: failing benchmark evidence contract** - `8b03b020` (test)
2. **Task 1 GREEN: exact native CFF benchmark contract** - `99aeb4d3` (feat)
3. **Task 1/2 fixes: schema and post-processing qualification** - `defee5fe`, `9c35f085`, `3ea3f476`, `ddcab3ae` (fix)
4. **Task 2: native CFF observation baseline** - `b357ac81` (perf)
5. **Task 2 fixes: stable host identity and atomic replacement** - `bbb7efa7`, `efede01c`, `a00fae7f` (fix)

## Files Created/Modified

- `benchmarks/moon.work` - Adds exact ordered tracked-local mb-font and font-cff workspace members.
- `benchmarks/font-cff/cff_bench.mbt` - Implements four fixed public-operation benchmark workloads.
- `scripts/benchmarks/Invoke-CffNativeBenchmarkBaseline.ps1` - Captures, renders, validates, replaces, and audits closed benchmark evidence.
- `scripts/quality/Test-BenchmarkQualification.ps1` - Exercises positive contracts and 26 one-fact negative cases.
- `scripts/quality/Assert-Policy.ps1` - Validates the final benchmark source inventory and baseline schema.
- `policy/foundation.json` - Owns exact benchmark inputs and the recorded observation-only baseline identity.
- `docs/benchmarks/mb-font-cff-native-release-baseline.md` - Stores canonical visible facts, raw normalized outputs, hashes, and aggregates.

## Decisions Made

- Kept portable v3 evidence correctness-only; performance timing exists solely in the native release baseline.
- Represented the active power scheme by GUID so the same host audits identically across localized console encodings.
- Used same-directory `File.Replace` with a temporary backup for atomic updates on Windows PowerShell/.NET Framework.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Extended policy validation for the new baseline contract**
- **Found during:** Task 1
- **Issue:** Existing policy validation did not know the final benchmark inventory and closed baseline schema.
- **Fix:** Added exact inventory, status, claim, workload, sample, statistic, and audit-owner validation.
- **Files modified:** `scripts/quality/Assert-Policy.ps1`
- **Verification:** Policy assertion and full FontQualification passed.
- **Committed in:** `99aeb4d3`

**2. [Rule 1 - Bug] Preserved closed JSON root order through baseline round-trip**
- **Found during:** Task 2 record post-processing
- **Issue:** Reconstruction moved `runs` after `aggregates`, rejecting otherwise valid captured evidence.
- **Fix:** Rebuilt evidence without changing root property order and added round-trip coverage.
- **Files modified:** `scripts/benchmarks/Invoke-CffNativeBenchmarkBaseline.ps1`, `policy/foundation.json`
- **Verification:** ContractOnly closed-schema and synthetic round-trip gates passed.
- **Committed in:** `defee5fe`

**3. [Rule 1 - Bug] Removed dirty-state recursion from atomic temporary validation**
- **Found during:** Task 2 record post-processing
- **Issue:** The in-repository temporary document was classified as unexpected dirt by its own current-input verification.
- **Fix:** Split content validation from the pre-temp current-input check and added a complete synthetic post-processing gate.
- **Files modified:** `scripts/benchmarks/Invoke-CffNativeBenchmarkBaseline.ps1`, `policy/foundation.json`
- **Verification:** Synthetic create/round-trip/audit/policy/cleanup gate passed.
- **Committed in:** `9c35f085`

**4. [Rule 1 - Bug] Corrected synthetic canonical timing and policy staging fixtures**
- **Found during:** Task 2 synthetic post-processing gate
- **Issue:** Synthetic min/max values were not canonical and the staged policy path variable was unbound.
- **Fix:** Canonicalized timing facts and bound the exact staged baseline policy object.
- **Files modified:** `scripts/benchmarks/Invoke-CffNativeBenchmarkBaseline.ps1`, `policy/foundation.json`
- **Verification:** Both runner and wrapper ContractOnly gates passed.
- **Committed in:** `3ea3f476`, `ddcab3ae`

**5. [Rule 1 - Bug] Canonicalized localized power-scheme identity**
- **Found during:** First clean audit
- **Issue:** Background recording decoded localized `powercfg` display text differently from interactive audit.
- **Fix:** Store and validate only the locale-independent active power-scheme GUID.
- **Files modified:** `scripts/benchmarks/Invoke-CffNativeBenchmarkBaseline.ps1`, `policy/foundation.json`, `docs/benchmarks/mb-font-cff-native-release-baseline.md`
- **Verification:** Clean Windows PowerShell 5.1 audit passed.
- **Committed in:** `bbb7efa7`, `a00fae7f`

**6. [Rule 1 - Bug] Made existing-file baseline replacement atomic on .NET Framework**
- **Found during:** Canonical baseline re-render
- **Issue:** `File.Replace` rejected a null backup path when replacing an existing file under Windows PowerShell 5.1.
- **Fix:** Added a same-directory backup path with guaranteed cleanup and exercised both create and replacement paths in the synthetic gate.
- **Files modified:** `scripts/benchmarks/Invoke-CffNativeBenchmarkBaseline.ps1`, `policy/foundation.json`
- **Verification:** Windows Framework replacement primitive and repeated synthetic atomic writes passed.
- **Committed in:** `efede01c`

**7. [Rule 1 - Bug] Normalized final GSD state metadata**
- **Found during:** Plan metadata update
- **Issue:** SDK handlers left the activity on Plan 05 and attributed new decisions to `Phase ?`.
- **Fix:** Set the final Plan 06 activity, verifying position, and Phase 107 decision labels explicitly.
- **Files modified:** `.planning/STATE.md`
- **Verification:** State reports 18/18 plans, 100% progress, Plan 6 of 6, and ready for verification.
- **Committed in:** plan metadata commit

---

**Total deviations:** 7 auto-fixed (6 Rule 1 bugs, 1 Rule 3 blocker)
**Impact on plan:** All fixes protect evidence correctness and atomicity; no benchmark scope or observation-only claim changed.

## Issues Encountered

- The orchestrator intentionally kept `.planning/config.json` modified for auto-chain state. All clean-state checks allowed only that exact marker and rejected every other change.
- One early patch resolved relative to the main checkout. The task-created files were immediately moved into this worktree and the main checkout was restored to its exact prior unrelated status before implementation continued.
- Two rejected record attempts completed captures but failed closed post-processing. Their raw data was not reused; the successful baseline came from a fresh warmup plus seven retained captures after the complete synthetic post-processing gate passed.

## Known Stubs

None. The empty glyph array in the benchmark is populated deterministically before use; the placeholder text match in policy validation is an intentional rejection rule.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- CFF-06 is fully sealed with reproducible native evidence and final four-target qualification.
- No blockers remain; all observed MoonBit warnings were pre-existing unused/deprecation warnings and the lane completed with zero errors.

## Self-Check: PASSED

All seven implementation/evidence files and all ten task/deviation commits were found.

---
*Phase: 107-hostile-licensed-and-four-target-qualification*
*Completed: 2026-07-29*
