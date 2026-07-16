---
phase: 02-bounded-core-primitives
plan: "07"
subsystem: core-release-qualification
tags: [moonbit, literate-docs, package-topology, negative-fixtures, four-target]

requires:
  - phase: 02-bounded-core-primitives
    plans: ["01", "02", "03", "04", "05", "06"]
    provides: complete error, checked, budget, bytes, io, and host public contracts
provides:
  - executable public examples for every Phase 2 contract family
  - exact six-package mb-core topology with no root facade or private scaffold
  - four-target literate documentation and full fail-closed qualification
affects: [03-color, 04-image, 05-codec, release-qualification]

tech-stack:
  added: []
  patterns: [standalone-literate-imports, exact-ordered-package-spine, executable-negative-fixtures]

key-files:
  created:
    - .planning/phases/02-bounded-core-primitives/02-07-SUMMARY.md
  modified:
    - modules/mb-core/README.mbt.md
    - modules/mb-core/CHANGELOG.md
    - policy/foundation.json
    - scripts/quality/Assert-Policy.ps1
    - scripts/quality/Invoke-MoonQuality.ps1
  deleted:
    - modules/mb-core/moon.pkg
    - modules/mb-core/scaffold.mbt
    - modules/mb-core/scaffold_wbtest.mbt

key-decisions:
  - "Publish exactly six mb-core packages in error, checked, budget, bytes, io, host order; retain no root facade."
  - "Run standalone README.mbt.md compilation on js, wasm, wasm-gc, and native as an explicit Required stage."
  - "Exercise fail-closed negative fixtures for topology, surface, documentation, capabilities, mutable backing, narrowing, and physical-OOM prose on every Required run."

patterns-established:
  - "Literate module docs use moonbit frontmatter imports so checked examples remain independent of a root package."
  - "Portable prohibition checks share the same classifiers used by synthetic negative fixtures."

requirements-completed: [CORE-01, CORE-02, CORE-03, CORE-04, CORE-05, CORE-06, CORE-07, CORE-08]

coverage:
  - id: D1
    description: "Executable examples cover structured checked failures, diagnostics, budgets, bytes/views/leases, partial exact I/O, separate seeking, and explicit host injection"
    requirement: CORE-01
    verification:
      - kind: integration
        ref: "moon -C modules/mb-core check README.mbt.md --target {js,wasm,wasm-gc,native} --frozen"
        status: pass
    human_judgment: false
  - id: D2
    description: "Exactly six inward-only public packages replace the root scaffold and reject topology, surface, capability, backing, narrowing, and OOM negative fixtures"
    requirement: CORE-08
    verification:
      - kind: integration
        ref: "pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required#CORE fail-closed negative fixtures"
        status: pass
    human_judgment: false
  - id: D3
    description: "Required qualifies four targets, generated interfaces, documentation, publication contents, prohibitions, and read-only behavior"
    requirement: CORE-06
    verification:
      - kind: integration
        ref: "pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required"
        status: pass
    human_judgment: false

duration: 17min
completed: 2026-07-16
status: complete
---

# Phase 02 Plan 07: Complete mb-core Spine Qualification Summary

**Six portable public packages with standalone checked examples, exact closed topology, fail-closed negative fixtures, and green four-target qualification**

## Performance

- **Duration:** 17 min
- **Started:** 2026-07-16T15:54:00Z
- **Completed:** 2026-07-16T16:11:00Z
- **Tasks:** 3
- **Files modified:** 8

## Accomplishments

- Replaced the Phase 1 private root scaffold with standalone executable documentation covering all eight CORE requirements through public APIs only.
- Finalized the exact ordered `error -> checked -> budget -> bytes -> io -> host` policy and publication inventory, with no root facade or reverse dependency.
- Added explicit four-target README execution, portable source/prose prohibitions, and ten fail-closed negative fixtures to the root Required lane.
- Passed Required twice with 62/62 workspace tests per target, exact six-package interfaces and contents, generated docs, and an unchanged tracked checkout.

## Task Commits

1. **Task 1: Replace the private scaffold with checked public examples** - `772cb83` (docs)
2. **Task 2: Finalize exact six-package policy and literate-doc gate** - `b47b166` (chore)
3. **Task 3: Run final four-target qualification** - `1334d60` (test)

## Files Created/Modified

- `modules/mb-core/README.mbt.md` - Standalone imported public examples and exact candidate/target/capability/OOM boundaries.
- `modules/mb-core/CHANGELOG.md` - Unreleased six-package contract and scaffold-removal ledger.
- `policy/foundation.json` - Exact six-package policy and publication allowlist without root artifacts.
- `scripts/quality/Assert-Policy.ps1` - Ordered six-package spine and obsolete-root rejection.
- `scripts/quality/Invoke-MoonQuality.ps1` - Four-target README execution, portable prohibitions, and negative fixtures.
- `modules/mb-core/{moon.pkg,scaffold.mbt,scaffold_wbtest.mbt}` - Intentionally removed obsolete Phase 1 root package proof.

## Decisions Made

- A root facade would add no contract value and would violate the selected six-package spine, so it was removed rather than retained as a seventh package.
- The README is a standalone `.mbt.md` input with explicit frontmatter imports, preserving executable black-box examples after root package removal.
- Physical runtime OOM remains explicitly unrecoverable; only budget and injected allocator rejection are documented as portable structured outcomes.
- Negative fixtures execute inside Required without mutating tracked files, so the read-only proof remains meaningful.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The first direct prohibition check compared a required sentence before normalizing Markdown line wrapping. The classifier was corrected to normalize whitespace, then the exact check and full Required lane passed.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None. The only placeholder token match is the pre-existing governance validator that rejects placeholder approval evidence.

## Threat Flags

None. This plan closes the declared tampering, disclosure/elevation, and documentation-repudiation surfaces with exact classifiers and executable negative fixtures; it adds no network, filesystem, authentication, schema, FFI, or ambient-host surface.

## Next Phase Readiness

- Phase 2 is implementation-complete and ready for independent phase verification.
- Phase 3 can consume stable candidate checked arithmetic and deterministic error contracts from the qualified six-package spine.
- No execution blocker remains; namespace publication ownership remains the existing milestone-level pending decision.

## Self-Check: PASSED

- Task commits `772cb83`, `b47b166`, and `1334d60` exist in order.
- The three obsolete root files are absent and exactly six `mb-core` public packages remain.
- All four exact README checks passed.
- Full Required passed with every negative fixture rejected, 62/62 tests on each required target, exact interfaces/package contents, and read-only tracked proof.

---
*Phase: 02-bounded-core-primitives*
*Completed: 2026-07-16*
