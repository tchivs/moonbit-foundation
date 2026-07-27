---
phase: 100-portable-font-qualification
plan: "05"
subsystem: quality
tags: [moonbit, powershell, github-actions, font-qualification, process-timeout, release-evidence]

requires:
  - phase: 100-portable-font-qualification
    provides: Plans 01-04 immutable fixtures, independent oracles, hostile workflows, four-target evidence, and the focused selector
provides:
  - Public compact and licensed DejaVu Sans 2.37 qualification contract with exact reproducible facts
  - Bounded Required execution with captured streams, deterministic failure metadata, and full-tree timeout termination
  - Separate CI boundaries for success-only focused evidence and always-available Required diagnostics
affects: [phase-100-verification, release-qualification, required-quality, ci-artifacts]

tech-stack:
  added: []
  patterns:
    - System.Diagnostics.Process child execution with asynchronous stream capture and Kill(true) timeout enforcement
    - Structurally scoped CI artifact validation that selects the exact with.name mapping

key-files:
  created:
    - scripts/quality/Invoke-RequiredBounded.ps1
  modified:
    - modules/mb-font/README.mbt.md
    - modules/mb-font/CHANGELOG.md
    - README.md
    - .github/workflows/quality.yml

key-decisions:
  - "Label only successfully validated focused records as font-qualification-evidence; upload Required output separately as required-diagnostic."
  - "Require a Required-named evidence path and record timeout, exit, streams, and process-tree termination without touching focused evidence."
  - "Preserve the workspace Required timeout as a real failure while treating the independently passing focused font evidence as a separate boundary."

patterns-established:
  - "Bounded lane wrapper: capture child streams, wait a finite duration, Kill(true) on timeout, wait for termination, then persist a deterministic result."
  - "Artifact semantics: success-only passing evidence and always-uploaded diagnostics must have distinct step names, artifact names, and paths."

requirements-completed: [FONT-05]

coverage:
  - id: D1
    description: Public documentation distinguishes the compact complete-feature oracle from licensed DejaVu interoperability evidence and freezes exact provenance, public facts, hostile semantics, and reproduction commands.
    requirement: FONT-05
    verification:
      - kind: integration
        ref: "moon -C modules/mb-font check README.mbt.md on js, wasm, wasm-gc, and native plus Assert-FontFoundationPolicy"
        status: pass
    human_judgment: false
  - id: D2
    description: Focused font qualification remains an isolated four-target passing evidence boundary with byte-identical normalized semantics.
    requirement: FONT-05
    verification:
      - kind: e2e
        ref: "./scripts/quality.ps1 -Lane FontQualification -EvidenceDirectory artifacts/release-qualification/font-final"
        status: pass
    human_judgment: false
  - id: D3
    description: Required execution is finite, captures both streams, terminates the full child tree on timeout, records failure, and leaves focused evidence unchanged.
    requirement: FONT-05
    verification:
      - kind: integration
        ref: "Invoke-RequiredBounded.ps1 1-second timeout probe and 900-second required-phase100 invocation"
        status: pass
    human_judgment: false
  - id: D4
    description: CI exposes one exact success-only focused artifact and an independently named/path-scoped always-uploaded Required diagnostic artifact.
    requirement: FONT-05
    verification:
      - kind: integration
        ref: "Indentation-aware .github/workflows/quality.yml step-mapping parser"
        status: pass
    human_judgment: false

duration: 25min
completed: 2026-07-27
status: complete
---

# Phase 100 Plan 05: Documentation, Bounded Required, and CI Closure Summary

**Exact compact/DejaVu qualification documentation and success-isolated CI evidence now coexist with a 900-second, full-tree-terminating Required wrapper that preserves failures truthfully.**

## Performance

- **Duration:** 25 minutes
- **Started:** 2026-07-27T15:02:48Z
- **Completed:** 2026-07-27T15:27:55Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Published the `font-complete-public` compact command oracle and DejaVu Sans 2.37 interoperability oracle with exact hashes, license expression, independent-oracle role, public mappings/metrics/paths/kerning, hostile outcomes, and four-target commands.
- Added `Invoke-RequiredBounded.ps1`, which restricts output to a Required-scoped directory, redirects both streams, enforces a finite timeout, calls `Kill(true)`, waits for termination, and writes `required-invocation.json`.
- Split CI into a required focused font job with success-only `font-qualification-evidence` and the bounded workspace Required job with a distinct always-uploaded `required-diagnostic` artifact.
- Reproduced the known broad workspace stall honestly: the 900-second Required run returned failure after terminating its full process tree while all five focused evidence hashes remained unchanged.

## Task Commits

Each task was committed atomically:

1. **Task 1: Publish the compact and DejaVu qualification contract** - `5c045473` (`docs`)
2. **Task 2: Bound Required execution and close CI artifact semantics** - `7708d620` (`feat`)

## Files Created/Modified

- `modules/mb-font/README.mbt.md` - Exact public workflow oracles, provenance, evidence schema, commands, and deliberate exclusions.
- `modules/mb-font/CHANGELOG.md` - FONT-05 evidence closure and narrow non-selectable/non-queryable format-6 coexistence repair.
- `README.md` - Consistent English and Chinese Phase 100 status plus focused and bounded reproduction commands.
- `scripts/quality/Invoke-RequiredBounded.ps1` - Required-scoped bounded child runner, stream capture, full-tree timeout termination, and deterministic result record.
- `.github/workflows/quality.yml` - Separate focused and Required jobs with unambiguous passing versus diagnostic artifacts.

## Decisions Made

- Passing evidence is emitted only by the focused job under `font-qualification-evidence` and only under `success()`; no always-running step can reuse that name or path.
- Required output is isolated under a path containing `required`, and the wrapper refuses an evidence path without that scope marker to prevent accidental focused-directory reuse.
- A timeout is represented by `timed_out=true`, `exit_code=null`, `process_tree_terminated=true`, `termination_status=killed`, and `status=failure`; focused qualification success does not rewrite that outcome.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Selected one concrete PowerShell executable**

- **Found during:** Task 2 (first bounded Required launch)
- **Issue:** `Get-Command pwsh` returned two application entries on Windows, and assigning both `.Source` values produced one invalid concatenated executable path.
- **Fix:** Materialized the application results and selected the first concrete command before setting `ProcessStartInfo.FileName`.
- **Files modified:** `scripts/quality/Invoke-RequiredBounded.ps1`
- **Verification:** The corrected wrapper launched the real Required child and its descendants under the configured working directory.
- **Committed in:** `7708d620`

**2. [Rule 1 - Bug] Replaced unsupported C# checked-cast syntax**

- **Found during:** Task 2 (second bounded Required launch)
- **Issue:** PowerShell treated `[checked]` as an unknown type before starting the child.
- **Fix:** Used ordinary integer multiplication; the validated maximum of 86,400 seconds keeps milliseconds safely inside `Int32`.
- **Files modified:** `scripts/quality/Invoke-RequiredBounded.ps1`
- **Verification:** The authoritative run stayed active for 900 seconds, then terminated the full tree and persisted the expected timeout failure record.
- **Committed in:** `7708d620`

**3. [Rule 3 - Blocking] Normalized final GSD verification state**

- **Found during:** Plan metadata finalization
- **Issue:** The state SDK correctly selected `verifying` but left stale Plan 04 activity text, an `EXECUTING` prose label, `Phase ?` decision attribution, Plan 05 operator guidance, and pre-Phase-100 aggregate metrics.
- **Fix:** Aligned machine-readable and prose state with completed Plan 05 execution, attributed decisions to Phase 100, recorded the bounded Required concern, and refreshed roadmap activity metadata.
- **Files modified:** `.planning/STATE.md`, `.planning/ROADMAP.md`
- **Verification:** STATE now reports 15/15 plans, Phase 100 `VERIFYING`, Plan 5 of 5, and no unattributed decisions; ROADMAP reports 5/5 Phase 100 plans.
- **Committed in:** Final plan metadata commit

---

**Total deviations:** 3 auto-fixed (2 Rule 1 bugs, 1 Rule 3 blocking metadata repair)
**Impact on plan:** The runtime fixes were limited to wrapper startup correctness and the final repair affected planning metadata only. No focused evidence, runtime font code, public API, dependency, or format boundary changed.

## Issues Encountered

- The authoritative workspace Required invocation reproduced the known unscoped Windows stall. Process inspection showed a broad module test spawning the generated `tchivs/mb-image/png` black-box runner; after 900 seconds the wrapper killed the full tree and returned nonzero.
- `artifacts/release-qualification/required-phase100/required-invocation.json` records the result as a timeout failure. Captured stdout is 20,757 bytes and stderr is 1,529 bytes; the records are diagnostic evidence, not passing font evidence.
- The Required timeout remains a cross-workspace quality concern, but it does not invalidate the focused FONT-05 result: `js`, `wasm`, `wasm-gc`, and `native` each passed 102/102 tests, normalized semantic SHA-256 remained `c152549e7077ed1a79397b6f38818bdf523c596a72dd4188dc7cc21159cdcefc`, and focused file hashes were byte-identical before and after Required.

## Verification

- Final focused selector passed fixture generation, provenance/schema/policy/interface/dependency gates, four README checks, and 102/102 tests independently on all four production targets.
- The 900-second Required invocation and independent one-second probe both returned failure with `process_tree_terminated=true` and `termination_status=killed`; no inspected descendant remained.
- Required stdout/stderr and `required-invocation.json` exist under the Required-only directory, while the exact focused evidence hashes match their pre-Required values.
- The indentation-aware CI parser found exactly one `font-qualification-evidence` step, required its pinned upload action, exact focused path, and `success()` condition, and independently accepted only the distinct `required-diagnostic` always-running step.
- `git diff --check` and stub-marker scans passed for all plan-owned files.

## Known Stubs

None.

## User Setup Required

None - qualification uses committed immutable fixtures and the repository-pinned local toolchain.

## Next Phase Readiness

- Phase 100 is ready for goal verification with complete focused FONT-05 evidence and explicit CI artifact semantics.
- The separate workspace Required timeout remains visible as a real failure and should be handled as the existing cross-workspace PNG/driver concern; it was neither suppressed nor converted into font success.

## Self-Check: PASSED

- All five plan-owned implementation/documentation artifacts, the Required invocation record, and this summary exist.
- Task commits `5c045473` and `7708d620` resolve in repository history.
- Final focused, timeout, stream, process-tree, focused-hash, CI-structure, diff, and stub checks were revalidated before state advancement.

---
*Phase: 100-portable-font-qualification*
*Completed: 2026-07-27*
