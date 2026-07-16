---
phase: 03-reference-color-semantics
plan: "01"
subsystem: color-model
tags: [moonbit, srgb, opaque-types, validation, package-policy]

requires:
  - phase: 02-bounded-core-primitives
    provides: opaque structured CoreError and exact package/interface policy classification
provides:
  - explicit sRGB space, transfer, representation, and alpha identity vocabulary
  - distinct opaque validated normalized and encoded-eight component domains
  - exact transitional root-scaffold-plus-model mb-color package policy
affects: [03-transfer, 03-quantize, 03-alpha, 03-profile, 04-image-contract]

tech-stack:
  added: []
  patterns: [identity-bearing scalar types, reject-before-narrow validation, exact policy topology]

key-files:
  created:
    - modules/mb-color/model/moon.pkg
    - modules/mb-color/model/components.mbt
    - modules/mb-color/model/identities.mbt
    - modules/mb-color/model/model_test.mbt
    - modules/mb-color/model/model_wbtest.mbt
  modified:
    - policy/foundation.json

key-decisions:
  - "Represent encoded-sRGB, linear-sRGB, normalized alpha, encoded color, and encoded alpha as distinct opaque scalar types rather than aliases or a universal color record."
  - "Reject non-finite and out-of-range normalized inputs before range acceptance, and reject full-width encoded values above 255 before Byte narrowing."
  - "Keep the Phase 1 root package private and non-reexporting while registering model as the first real public mb-color package."

patterns-established:
  - "Identity-bearing model: component types return fixed space, transfer, and representation identities; alpha types expose no color transfer."
  - "Color validation: InvalidInput/InvalidRange with a stable bounded context token, never clamping, wrapping, or ambient defaults."

requirements-completed: [COLR-01]

coverage:
  - id: D1
    description: "Explicit closed identity vocabulary for sRGB space, encoded/linear transfer, normalized/encoded representation, and straight/premultiplied alpha"
    requirement: COLR-01
    verification:
      - kind: unit
        ref: "modules/mb-color/model/model_test.mbt#closed identity vocabulary names every supported state"
        status: pass
    human_judgment: false
  - id: D2
    description: "Opaque normalized and encoded component types reject non-finite, out-of-range, and pre-narrowing overflow inputs"
    requirement: COLR-01
    verification:
      - kind: unit
        ref: "moon -C modules/mb-color test model --target all --frozen"
        status: pass
    human_judgment: false
  - id: D3
    description: "Exact candidate model interface, imports, targets, publication files, and transitional root topology"
    requirement: COLR-01
    verification:
      - kind: integration
        ref: "pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required"
        status: pass
    human_judgment: false

duration: 11min
completed: 2026-07-17
status: complete
---

# Phase 03 Plan 01: Explicit Validated Color Vocabulary Summary

**Identity-bearing opaque sRGB and alpha scalar types with reject-before-narrow validation and exact four-target package policy**

## Performance

- **Duration:** 11 min
- **Started:** 2026-07-16T17:35:47Z
- **Completed:** 2026-07-16T17:46:48Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added explicit equatable identities for sRGB space, encoded/linear transfer, normalized/encoded representation, and straight/premultiplied alpha mode.
- Added five distinct opaque validated scalar types with exact round-trip accessors and deterministic structured rejection of NaN, infinities, range violations, and full-width encoded overflow.
- Registered the first public `mb-color/model` package while retaining the Phase 1 root only as a temporary private, import-free scaffold.

## Task Commits

1. **Task 1 RED: Specify opaque component validation and explicit identities** - `bc0dc5d` (test)
2. **Task 1 GREEN: Implement explicit validated color vocabulary** - `c41749b` (feat)
3. **Task 2: Register the first exact mb-color package contract** - `0a5159d` (chore)

## Files Created/Modified

- `modules/mb-color/model/moon.pkg` - Four-target package with the sole inward `mb-core/error` dependency.
- `modules/mb-color/model/components.mbt` - Opaque normalized and encoded component/alpha values with deterministic validation.
- `modules/mb-color/model/identities.mbt` - Closed explicit semantic identity vocabulary.
- `modules/mb-color/model/model_test.mbt` - Public constructor, identity, boundary, and rejection evidence.
- `modules/mb-color/model/model_wbtest.mbt` - Internal validation-order and structured-error invariants.
- `policy/foundation.json` - Exact transitional package topology, interface, import, target, and publication allowlists.

## Decisions Made

- Color components encode their semantic identity in their type and fixed accessors; encoded and linear values cannot be substituted through a generic alias.
- Normalized alpha and encoded alpha deliberately expose only coverage values and never claim a color-space or transfer identity.
- Full-width `UInt64` encoded input is compared with 255 before `to_byte`, making target-specific wrapping impossible.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The pinned `moon fmt` command attempted its known automatic `moon.mod.json` to `moon.mod` migration. The generated files were removed and all tracked manifests were restored before the Task 1 commit; no manifest change entered history.

## User Setup Required

None - no external services or configuration are required.

## Known Stubs

None.

## Threat Flags

None. This plan adds no network, host, file, authentication, or external schema boundary; all introduced inputs are covered by T-03-01 through T-03-03.

## Next Phase Readiness

- `mb-color/model` now supplies the explicit validated inputs required by transfer conversion, quantization, alpha, and profile plans.
- The Required lane is green with exact model interface and package contents on all four production targets.

## Self-Check: PASSED

- All five created model-package files exist.
- Task commits `bc0dc5d`, `c41749b`, and `0a5159d` exist.
- `moon -C modules/mb-color test model --target all --frozen` passed 9/9 on js, wasm, wasm-gc, and native.
- `pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required` passed with exact root-plus-model topology.

---
*Phase: 03-reference-color-semantics*
*Completed: 2026-07-17*
