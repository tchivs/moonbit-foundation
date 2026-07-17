---
phase: 02-bounded-core-primitives
plan: "06"
subsystem: explicit-host-capabilities
tags: [moonbit, capabilities, dependency-injection, deterministic-fakes, portability]

requires:
  - phase: 02-bounded-core-primitives
    plan: "01"
    provides: stable structured host and capability errors with bounded context
  - phase: 02-bounded-core-primitives
    plan: "02"
    provides: checked UInt64 arithmetic for deterministic logical-clock advancement
provides:
  - five granular independently optional host capability traits
  - deterministic instance-local portable doubles for every capability
  - bounded adapter-failure mapping with no ambient or native fallback
affects: [04-image, 05-codec, native-adapters, application-composition]

tech-stack:
  added: []
  patterns: [capability-specific-injection, instance-local-portable-doubles, adapter-boundary-error-mapping]

key-files:
  created:
    - modules/mb-core/host/moon.pkg
    - modules/mb-core/host/capabilities.mbt
    - modules/mb-core/host/fakes.mbt
    - modules/mb-core/host/host_test.mbt
    - modules/mb-core/host/host_wbtest.mbt
  modified:
    - policy/foundation.json

key-decisions:
  - "Keep file access and logical resource resolution as separate traits returning portable immutable Bytes; neither contract prescribes a filesystem or network adapter."
  - "Expose one deterministic fake per capability instead of a Host aggregate, and keep all mutable fake state instance-local."
  - "Map rejecting adapter doubles through map_host_failure and use checked arithmetic for logical-clock advancement."

patterns-established:
  - "Explicit effects: algorithms accept only the individual capability traits they require; absence has no fallback path."
  - "Portable doubles: deterministic state belongs to the supplied fake instance and interleaved instances remain independent."

requirements-completed: [CORE-08]

coverage:
  - id: D1
    description: "File, diagnostics, clock, cancellation, and resource resolution are separate open traits with no mandatory aggregate or ambient fallback"
    requirement: CORE-08
    verification:
      - kind: unit
        ref: "modules/mb-core/host/host_test.mbt#file and resource capabilities are independently injectable"
        status: pass
      - kind: integration
        ref: "pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required"
        status: pass
    human_judgment: false
  - id: D2
    description: "Portable doubles are deterministic, independently composable, instance-local, and discard foreign adapter detail"
    requirement: CORE-08
    verification:
      - kind: unit
        ref: "modules/mb-core/host/host_test.mbt#portable doubles keep interleaved state instance local"
        status: pass
      - kind: unit
        ref: "moon -C modules/mb-core test host --target all --frozen"
        status: pass
    human_judgment: false
  - id: D3
    description: "The host package has an exact two-import, 48-line semantic-interface, four-target, and publication allowlist policy contract"
    requirement: CORE-08
    verification:
      - kind: integration
        ref: "pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required"
        status: pass
    human_judgment: false

duration: 18min
completed: 2026-07-16
status: complete
---

# Phase 02 Plan 06: Explicit Host Capabilities Summary

**Five granular injected effect traits with deterministic portable doubles, bounded failure mapping, and no ambient or native fallback across all four targets**

## Performance

- **Duration:** 18 min
- **Started:** 2026-07-16T15:46:00Z
- **Completed:** 2026-07-16T16:04:00Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added independent `FileCapability`, `DiagnosticSink`, `Clock`, `Cancellation`, and `ResourceResolver` open traits without a service-locator aggregate or automatic fallback.
- Added one portable deterministic double per capability, including encounter-ordered diagnostics, checked logical-clock progression, instance-local cancellation, and bounded adapter-failure mapping.
- Qualified 5/5 host tests on js, wasm, wasm-gc, and native, then passed the full Required lane with 63/63 tests per target and an exact 48-line host interface.

## Task Commits

1. **Task 1 RED: Specify explicit host capability contracts** - `facfafc` (test)
2. **Task 1 GREEN: Implement explicit portable host capabilities** - `6be6b81` (feat)
3. **Task 1 REFACTOR: Apply pinned formatting to host tests** - `e1f3d46` (refactor)
4. **Task 2: Register and qualify the exact host package contract** - `a563097` (chore)

## Files Created/Modified

- `modules/mb-core/host/moon.pkg` - Portable package declaration importing only checked arithmetic and structured errors.
- `modules/mb-core/host/capabilities.mbt` - Five granular open traits and bounded capability-absence mapping.
- `modules/mb-core/host/fakes.mbt` - Deterministic instance-local implementations and adapter-failure doubles.
- `modules/mb-core/host/host_test.mbt` - Public injection, composition, interleaving, and failure-mapping contracts.
- `modules/mb-core/host/host_wbtest.mbt` - Internal bounded-context invariant.
- `policy/foundation.json` - Exact host imports, semantic interface, targets, and publication contents.

## Decisions Made

- File and logical-resource capabilities return immutable built-in `Bytes`. This keeps the portable effect boundary allocation-policy-neutral while preventing the host package from depending on bounded I/O or prescribing a concrete adapter.
- Failure doubles discard their supplied foreign details immediately and emit only fixed operation tokens through the existing portable host mapper.
- The clock double uses checked addition and keeps state per instance; the tests prove deterministic interleaving without claiming cross-thread synchronization.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The first Required run identified formatter drift in the two new test files. The pinned formatter was applied only to the explicit MoonBit source paths, preserving the repository's `moon.mod.json` policy, and the full gate then passed.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None.

## Threat Flags

None. The new host effect boundary is the planned T-02-10 surface; granular traits, instance-local fakes, and bounded error mapping are its explicit mitigations.

## Next Phase Readiness

- Plan 02-07 can document and qualify the complete six-package core spine.
- Later composition roots can supply concrete leaf adapters without changing portable algorithms or introducing ambient state.

## Self-Check: PASSED

- All five host package files and the exact policy entry exist.
- Task commits `facfafc`, `6be6b81`, `e1f3d46`, and `a563097` exist in order.
- `moon -C modules/mb-core test host --target all --frozen` passed 5/5 on every required target.
- `pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required` passed with 63/63 tests per target, exact 48-line host interface classification, exact package contents, and read-only tracked proof.

---
*Phase: 02-bounded-core-primitives*
*Completed: 2026-07-16*
