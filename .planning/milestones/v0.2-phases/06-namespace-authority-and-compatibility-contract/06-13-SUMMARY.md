---
phase: 06-namespace-authority-and-compatibility-contract
plan: "13"
subsystem: release-qualification
tags: [moonbit, namespace, package-consumers, native, negative-testing]
requires:
  - phase: 06-namespace-authority-and-compatibility-contract
    provides: canonical tchivs module graph and repaired qualification metadata from plans 06-09 and 06-25
provides:
  - Canonical isolated mb-core artifact consumer on tchivs/mb-core@0.1.0
  - Full packaged-copy qualification with four-target checks and real native linking/runtime proof
  - Exact fail-closed ownership for the release-qualification negative matrix
affects: [06-01, 06-06, release-qualification, publication-readiness]
tech-stack:
  added: []
  patterns: [policy-projected-consumer-identities, real-native-qualification, exact-negative-rule-ownership]
key-files:
  created:
    - .planning/phases/06-namespace-authority-and-compatibility-contract/06-13-SUMMARY.md
  modified:
    - qualification/consumers/mb-core/moon.mod.json
    - qualification/consumers/mb-core/main/moon.pkg
    - qualification/negative/higher-layer-dependency/mb-core.moon.pkg
    - qualification/negative/path-dependency/mb-color.moon.mod.json
    - scripts/quality/Invoke-ReleaseQualification.ps1
    - scripts/quality/Test-ReleaseQualification.ps1
    - scripts/quality/Test-ReleaseQualificationNegative.ps1
key-decisions:
  - "Use the canonical tchivs identities inside semantic negative fixtures so each failure is owned by its intended rule rather than by stale namespace drift."
  - "Count native qualification only after real compilation, linking, and runtime execution; no compile-only fallback was used."
patterns-established:
  - "Packaged-copy qualification derives registry probe identities from the closed release policy and rejects any non-tchivs 0.1.0 graph."
requirements-completed: [COMP-01, COMP-02, COMP-03, COMP-04, PROV-03]
coverage:
  - id: D1
    description: The isolated leaf artifact consumer resolves the exact tchivs/mb-core@0.1.0 identity without a path substitution
    requirement: COMP-01
    verification:
      - kind: integration
        ref: PowerShell exact consumer manifest and import assertion
        status: pass
    human_judgment: false
  - id: D2
    description: Positive release qualification packages two clean copies and exercises the canonical graph across js, wasm, wasm-gc, and native including native link/runtime
    requirement: COMP-04
    verification:
      - kind: integration
        ref: pwsh Invoke-ReleaseQualification.ps1 -Check -OutputDirectory artifacts/release-qualification/phase-06-plan-13-final
        status: pass
      - kind: integration
        ref: pwsh Test-ReleaseQualification.ps1
        status: pass
    human_judgment: false
  - id: D3
    description: Every release-qualification negative is rejected by one exact owning rule on the canonical identity graph
    requirement: PROV-03
    verification:
      - kind: integration
        ref: pwsh Test-ReleaseQualificationNegative.ps1
        status: pass
    human_judgment: false
duration: 39m
completed: 2026-07-17
status: complete
---

# Phase 6 Plan 13: Qualification Consumers and Exact Negatives Summary

**The isolated package consumer and release validator now prove the complete `tchivs/*@0.1.0` graph through deterministic archives, four portable targets, real native execution, and exact negative-rule ownership.**

## Performance

- **Duration:** 39m across the retained Task 1 and resumed Tasks 2-3
- **Started:** 2026-07-17T10:47:42Z
- **Completed:** 2026-07-17T11:26:45Z
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments

- Migrated the bounded mb-core artifact consumer to exact `tchivs/mb-core@0.1.0` imports while preserving its behavior source.
- Closed positive release qualification on the ordered `tchivs/mb-core` to `tchivs/mb-color` to `tchivs/mb-image` graph with byte-identical archives and real native linking/runtime execution.
- Kept path-substitution, higher-layer dependency, PPM, metadata, provenance, artifact, and tracked-source negatives under their exact fail-closed rules.

## Task Commits

1. **Task 1: Migrate the bounded positive package consumer** - `9f05754` (feat)
2. **Task 2: Reconcile positive release qualification** - `a0a587b` (test)
3. **Task 3: Preserve exact negative fixture ownership** - `93ef4a7` (test)

## Files Created/Modified

- `qualification/consumers/mb-core/moon.mod.json` and `main/moon.pkg` - Exact isolated `tchivs/mb-core@0.1.0` consumer contract.
- `scripts/quality/Invoke-ReleaseQualification.ps1` - Policy-derived canonical consumer and registry-probe identities.
- `scripts/quality/Test-ReleaseQualification.ps1` - Closed positive module order, identity, version, and dependency assertions.
- `qualification/negative/higher-layer-dependency/mb-core.moon.pkg` - Canonical higher-layer import rejected by REL04.
- `qualification/negative/path-dependency/mb-color.moon.mod.json` - Canonical identity with an intentional path substitution rejected by REL03.
- `scripts/quality/Test-ReleaseQualificationNegative.ps1` - Canonical PPM02 mutation and unchanged exact negative matrix.

## Decisions Made

- Semantic negative fixtures use canonical identities; their intentionally invalid property is limited to the behavior named by the owning rule.
- The real native result is qualification evidence only because Clang compiled, linked, and ran the MoonBit runtime. No compile-only mode or qualifying downgrade was used.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Supplied the installed LLVM-MinGW sysroot to the requested Clang binary**

- **Found during:** Task 2 full positive verification.
- **Issue:** `C:\Program Files\LLVM\bin\clang.exe` was executable but its installation contained only binaries, so its default MSVC target could not find `stddef.h`, a Windows SDK, or runtime libraries.
- **Fix:** Kept the requested Program Files Clang first on `PATH` and as `CC`, then explicitly selected the installed LLVM-MinGW UCRT target, sysroot, resource directory, compiler runtime, unwind library, and LLD linker for every verification process.
- **Files modified:** None; verification environment only.
- **Verification:** A standalone C executable compiled, linked, and ran, followed by two successful full release-qualification runs with native tests.
- **Committed in:** Not applicable; no repository file changed.

---

**Total deviations:** 1 auto-fixed blocking environment issue.
**Impact on plan:** The required real native proof was completed without broadening repository scope or weakening qualification semantics.

## Issues Encountered

- The first native attempt failed at the exact missing `stddef.h` compiler-resource boundary. The complete installed LLVM-MinGW sysroot resolved it; no test or release rule was bypassed.

## User Setup Required

None. The required Clang and LLVM-MinGW UCRT components are already installed; verification must continue to inject their paths explicitly in fresh processes.

## Verification

- The bounded consumer identity/import assertion passed.
- Full positive qualification passed twice with clean clones, deterministic ZIP hashes and bytes, archive/manifest checks, isolated consumers, four targets, real native linking/runtime, blocked unpublished registry probes, and no registry mutation.
- The positive identity graph and static v0.1 ledger assertions passed.
- All 19 named negative cases failed under their exact owning rules.
- `git diff --check` passed, and the three task commits changed exactly the seven declared source files.

## Known Stubs

None.

## Next Phase Readiness

- The credential-free release-qualification chain is ready for the remaining Phase 6 plans and the revised live authority checkpoint in 06-01.
- Live Mooncakes ownership and GitHub repository liveness remain intentionally unverified; this plan performed no authentication, push, publication, or registry mutation.

## Self-Check: PASSED

- All seven declared source files and this summary exist.
- Task commits `9f05754`, `a0a587b`, and `93ef4a7` are present in git history.
- Coverage metadata classifies all three deliverables with passing automated evidence.
- No stub pattern, new endpoint, credential read, or external mutation was introduced.

---
*Phase: 06-namespace-authority-and-compatibility-contract*
*Completed: 2026-07-17*
