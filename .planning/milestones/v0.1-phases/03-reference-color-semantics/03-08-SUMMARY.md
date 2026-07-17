---
phase: 03-reference-color-semantics
plan: "08"
subsystem: color-evidence
tags: [moonbit, generated-vectors, profile-budgets, provenance, four-target]

requires:
  - phase: 03-reference-color-semantics
    provides: bounded opaque profile API, canonical profile payload cases, and root color qualification
provides:
  - complete canonical profile payload and derived budget evidence in package-local MoonBit
  - behavioral four-target proof of exact bytes, caller limits, and atomic budget rejection
  - provenance-accurate public wording for formula-derived numeric points
affects: [04-image-contract, 05-release-qualification, color-verification]

tech-stack:
  added: []
  patterns: [canonical-data-to-package-test generation, applicable-dimension budget case derivation, formatter-clean byte-stable MoonBit output]

key-files:
  created: []
  modified:
    - scripts/fixtures/Generate-ColorVectors.ps1
    - modules/mb-color/profile/reference_vectors_wbtest.mbt
    - modules/mb-color/profile/profile_wbtest.mbt
    - modules/mb-color/README.mbt.md

key-decisions:
  - "Derive allocation rejection for every successful canonical payload, and bytes plus allocation-size rejection only when a nonempty payload can be underfunded."
  - "Preserve canonical payload order and use compact generated local bindings so renderer output remains MoonBit-formatter-clean and byte-stable."

patterns-established:
  - "Generated evidence completeness: canonical identifiers are counted exactly once and every generated case is consumed behaviorally."
  - "Budget evidence: each independently underfunded dimension must reject with its exact context and leave every observable counter unchanged."

requirements-completed: [COLR-04]

coverage:
  - id: D1
    description: "Every canonical profile payload and applicable independent budget rejection is generated and behaviorally consumed"
    requirement: COLR-04
    verification:
      - kind: integration
        ref: "modules/mb-color/profile/profile_wbtest.mbt#generated profile payload and budget evidence is complete"
        status: pass
      - kind: integration
        ref: "moon -C modules/mb-color test profile --target all --frozen"
        status: pass
      - kind: other
        ref: "pwsh -NoProfile -File scripts/fixtures/Generate-ColorVectors.ps1 -Artifacts all -Check"
        status: pass
    human_judgment: false
  - id: D2
    description: "Public evidence wording distinguishes published formulas from project-selected formula-derived points"
    requirement: COLR-04
    verification:
      - kind: integration
        ref: "moon -C modules/mb-color check README.mbt.md --target {js,wasm,wasm-gc,native} --frozen"
        status: pass
      - kind: integration
        ref: "pwsh -NoProfile -File scripts/quality.ps1 -Lane Required#COLR source and documentation prohibitions"
        status: pass
    human_judgment: false
  - id: D3
    description: "Full positive, negative, package, interface, target, fixture, and tracked-read-only qualification remains green"
    requirement: COLR-04
    verification:
      - kind: integration
        ref: "pwsh -NoProfile -File scripts/quality.ps1 -Lane Required"
        status: pass
    human_judgment: false

duration: 7min
completed: 2026-07-17
status: complete
---

# Phase 03 Plan 08: Profile Evidence Gap Closure Summary

**Canonical opaque-profile payloads now drive formatter-clean generated MoonBit and exhaustive four-target limit, byte-preservation, and atomic-budget evidence with accurate public provenance wording**

## Performance

- **Duration:** 7 min
- **Started:** 2026-07-16T19:39:44Z
- **Completed:** 2026-07-16T19:45:52Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Connected all four canonical `profile.payload_cases` through `Render-ProfileMoon` into a package-local payload table, with exact identifier completeness and byte preservation.
- Derived seven applicable budget-rejection cases and proved exact dimension context plus unchanged bytes, allocations, and allocation-size state on all four targets.
- Corrected the README to identify W3C/ICC formulas as primary sources while describing the numeric points as project-selected formula-derived evidence.
- Passed generator byte identity, fixture-policy negatives, profile and README checks on all targets, and the full Required lane with 111/111 tests per target and tracked-read-only proof.

## Task Commits

1. **Task 1 RED: expose missing generated profile evidence** - `82cd751` (test)
2. **Task 1 GREEN: generate complete profile payload evidence** - `54ebe79` (feat)
3. **Task 2: correct color evidence provenance** - `7caac1e` (docs)

## Files Created/Modified

- `scripts/fixtures/Generate-ColorVectors.ps1` - Serializes every canonical payload and derives only applicable independent budget failures.
- `modules/mb-color/profile/reference_vectors_wbtest.mbt` - Generated private payload and budget-rejection tables.
- `modules/mb-color/profile/profile_wbtest.mbt` - Completeness, exact-byte, caller-limit, error-context, and atomic-counter behavior.
- `modules/mb-color/README.mbt.md` - Provenance-accurate formula and sampled-point wording.

## Decisions Made

- Empty payloads receive only an allocation-count rejection case because neither zero bytes nor zero allocation size can be independently underfunded.
- Nonempty successful payloads receive bytes, allocation-count, and allocation-size rejection cases in canonical payload order.
- Generated budget identifiers retain the canonical payload identifier plus a compact stable dimension suffix; package tests enumerate each identifier exactly once.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The first combined PowerShell verification wrapper treated an unset `$LASTEXITCODE` after a successful script as nonzero and exited after generator checking. Each remaining gate was rerun directly with explicit process exit checks; all passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Both deterministic gaps from `03-VERIFICATION.md` are closed without public API, policy, fixture, or DAG expansion.
- Phase 3 is ready for independent re-verification and transition to the image contract.

## Self-Check: PASSED

- All four modified implementation/evidence files and this summary exist.
- RED, GREEN, and provenance task commits are present.
- No task-blocking stubs or placeholders remain in the modified surface.

---
*Phase: 03-reference-color-semantics*
*Completed: 2026-07-17*
