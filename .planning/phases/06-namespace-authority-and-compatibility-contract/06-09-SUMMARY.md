---
phase: 06-namespace-authority-and-compatibility-contract
plan: "09"
subsystem: public-consumers-and-benchmarks
tags: [moonbit, examples, benchmarks, native, qualification]
requires:
  - phase: 06-namespace-authority-and-compatibility-contract
    provides: canonical 17-package tchivs source graph from plan 06-08
provides:
  - Canonical tchivs dependency/import graphs for two public examples and the bounded benchmark
  - Fail-closed native runtime verification with an explicit non-qualifying compile-only mode
  - Identity-aware benchmark qualification retaining all baseline and adversarial rules
affects: [06-10, 06-11, 06-13, release-qualification, public-examples]
tech-stack:
  added: []
  patterns: [explicit-native-verification-mode, non-qualifying-compile-evidence, canonical-consumer-allowlists]
key-files:
  created:
    - .planning/phases/06-namespace-authority-and-compatibility-contract/06-09-SUMMARY.md
  modified:
    - examples/ppm-portable/moon.mod.json
    - examples/ppm-portable/main/moon.pkg
    - examples/ppm-native-cli/moon.mod.json
    - examples/ppm-native-cli/main/moon.pkg
    - benchmarks/ppm/moon.mod.json
    - benchmarks/ppm/moon.pkg
    - scripts/quality/Test-PublicExamples.ps1
    - scripts/quality/Test-BenchmarkQualification.ps1
key-decisions:
  - "Keep native runtime verification as the default and require an explicit compile-only selection when a system C compiler is unavailable."
  - "Compile-only reports are never qualification-equivalent: they record qualification_eligible=false and explicitly mark linking and runtime output unverified."
patterns-established:
  - "Environment-limited native checks may prove compilation only through an explicit opt-in mode; runtime qualification remains fail-closed."
requirements-completed: [COMP-01, COMP-02, COMP-03, COMP-04, PROV-03]
coverage:
  - id: D1
    description: Public example consumers use only canonical tchivs imports and execute with exact output on every locally runnable portable target
    requirement: COMP-01
    verification:
      - kind: integration
        ref: pwsh Test-PublicExamples.ps1 -Example all -Mode workspace -Target all -NativeVerification compile-only
        status: pass
      - kind: integration
        ref: compile-only qualification report records native linking/runtime unverified
        status: pass
    human_judgment: true
    rationale: Native linking and runtime output still require a future environment with a system C compiler.
  - id: D2
    description: Default all-target verification refuses to downgrade native execution when no compiler exists
    requirement: COMP-04
    verification:
      - kind: integration
        ref: default Test-PublicExamples all-target invocation exits nonzero at exact native compiler gate
        status: pass
    human_judgment: false
  - id: D3
    description: Bounded benchmark consumes the canonical graph while all positive and negative qualification rules pass
    requirement: PROV-03
    verification:
      - kind: integration
        ref: pwsh -NoProfile -File scripts/quality/Test-BenchmarkQualification.ps1
        status: pass
    human_judgment: false
duration: 18m
completed: 2026-07-17
status: complete
---

# Phase 6 Plan 09: Canonical Public Consumers and Benchmark Summary

**Both public examples and the bounded benchmark now consume the canonical `tchivs/*` graph, with portable runtime evidence, explicit native compile-only evidence, and unchanged benchmark qualification semantics.**

## Performance

- **Duration:** 18m
- **Started:** 2026-07-17T10:25:00Z
- **Completed:** 2026-07-17T10:43:00Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Rebased the portable and native example manifests/imports to exact `tchivs/mb-core` and `tchivs/mb-image` identities.
- Kept JS, wasm, and wasm-gc as real execution/output checks while adding an explicit native compile-only mode that cannot qualify as runtime proof.
- Rebased the benchmark graph and retained its closed schema, workload order, environment, correctness digest, sample-count, and no-marketing negative gates.

## Task Commits

1. **Task 1: Migrate the four public-example configuration files** - `41f2804` (feat)
2. **Task 2: Migrate and qualify the bounded benchmark** - `f645e39` (test)

## Files Created/Modified

- `examples/ppm-portable/moon.mod.json` and `main/moon.pkg` - Canonical portable consumer graph.
- `examples/ppm-native-cli/moon.mod.json` and `main/moon.pkg` - Canonical native CLI consumer graph.
- `benchmarks/ppm/moon.mod.json` and `moon.pkg` - Canonical bounded benchmark graph.
- `scripts/quality/Test-PublicExamples.ps1` - Explicit runtime/compile-only native verification and honest evidence reporting.
- `scripts/quality/Test-BenchmarkQualification.ps1` - Exact benchmark identity checks with preserved adversarial qualification.

## Decisions Made

- No system compiler was installed. The normal/default mode still performs `moon run` and fails at the native compiler/linking gate on this machine.
- `-NativeVerification compile-only` is the only opt-in escape hatch. It runs frozen native `moon check`, never verifies linking/output, and emits a deliberately non-qualifying report.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added an explicit non-qualifying native compile-only verification mode**

- **Found during:** Task 1 verification after the human-action checkpoint.
- **Issue:** The machine has no `cl`, `cc`, `gcc`, or `clang`, so native linking/runtime proof could not run; the user explicitly declined a system compiler installation.
- **Fix:** Preserved fail-closed runtime verification as the default and added explicit `-NativeVerification compile-only`. Native packages run `moon check --target native --frozen`; the report records `qualification_eligible=false`, `linking_verified=false`, `runtime_output_verified=false`, and `incomplete_reason=native_linking_and_runtime_output_not_verified`.
- **Files modified:** `scripts/quality/Test-PublicExamples.ps1`.
- **Verification:** Explicit compile-only workspace and qualification runs passed; the unflagged all-target command failed at the exact native compiler gate; JS/wasm/wasm-gc still executed and matched real output.
- **Committed in:** `41f2804`.

---

**Total deviations:** 1 auto-fixed blocking environment issue.
**Impact on plan:** Canonical consumer identity and portable execution are closed. Native source compilation is proven, but native linking and runtime output remain a required future verification and are not represented as qualification success.

## Issues Encountered

- ANSI-formatted PowerShell error output required normalization in the local negative assertion; the underlying default native failure remained exact and unchanged.

## User Setup Required

None. A future native-runtime verification environment must provide a supported system C compiler, but this plan intentionally made no external installation or system change.

## Verification

- Workspace and isolated qualification modes passed with explicit compile-only native verification.
- JS, wasm, and wasm-gc executed and matched their exact semantic output.
- Both native example packages passed frozen native compilation; linking and runtime output were explicitly not verified.
- Default all-target mode failed at `no system C compiler found; tried cl, cc, gcc, clang` and did not silently downgrade.
- Benchmark positive qualification passed; BENCH01 through BENCH05 were rejected under their exact rules.
- Exactly the eight planned files changed relative to the completed 06-08 plan; `git diff --check` passed.

## Known Stubs

None.

## Next Phase Readiness

- Plans 06-10 and 06-11 can consume identity-correct example and benchmark boundaries.
- Before any release claims full native runtime qualification, rerun default `Test-PublicExamples.ps1 -Example all -Mode qualify -Target all` on a machine with a supported system C compiler and produce the schema-conforming runtime report.
- Live Mooncakes authority remains separately blocked and untouched.

## Self-Check: PASSED

- All eight planned files exist and are present across the two atomic task commits.
- Compile-only evidence is explicitly non-qualifying; default runtime verification remains fail-closed.
- All locally applicable task and plan verification commands passed.

---
*Phase: 06-namespace-authority-and-compatibility-contract*
*Completed: 2026-07-17*
