---
phase: 97-font-admission-and-metrics
plan: 01
subsystem: font
tags: [moonbit, truetype, sfnt, byteview, checked-parsing, budget]
requires:
  - phase: v0.1-foundation
    provides: retained byte views, checked arithmetic, deterministic budgets, and structured errors
provides:
  - portable mb-font module with opaque Font and explicit FontLimits contracts
  - atomic standalone TrueType admission tracer with units-per-em access
  - deterministic generated-font fixtures and fail-closed conformance tests
affects:
  - 97-02
  - 97-03
  - 98-unicode-mapping-and-kerning
  - 99-outlines
  - 100-qualification
tech-stack:
  added: []
  patterns:
    - retained ByteView ownership with revision gates
    - checked table-local parsing and single-transaction admission charging
    - capability failures for unsupported profiles and data failures for malformed supported input
key-files:
  created:
    - modules/mb-font/moon.mod.json
    - modules/mb-font/font/moon.pkg
    - modules/mb-font/font/limits.mbt
    - modules/mb-font/font/font.mbt
    - modules/mb-font/font/cursor.mbt
    - modules/mb-font/font/directory.mbt
    - modules/mb-font/font/tables.mbt
    - modules/mb-font/font/generated_fonts.mbt
    - modules/mb-font/font/font_test.mbt
    - modules/mb-font/font/font_wbtest.mbt
  modified:
    - moon.work
key-decisions:
  - "Font retains the caller's ByteView and gates every query on the opening revision."
  - "Admission normalizes records to table-local ByteViews and charges bytes plus work atomically before checksum scans."
  - "Unsupported containers and deferred profiles return capability errors; malformed supported TrueType data returns data errors."
requirements-completed: [FONT-01]
coverage:
  - id: D1
    description: "`tchivs/mb-font` is a portable, independently consumable module with an opaque Font, explicit FontLimits, checked standalone TrueType admission, and units-per-em access."
    requirement: FONT-01
    verification:
      - kind: integration
        ref: "moon -C modules/mb-font test --target all --frozen"
        status: pass
      - kind: integration
        ref: "moon -C modules/mb-font info --target all --frozen"
        status: pass
    human_judgment: false
  - id: D2
    description: "A generated checksum-correct standalone TrueType font opens successfully and reports its exact units-per-em value."
    requirement: FONT-01
    verification:
      - kind: unit
        ref: "modules/mb-font/font/font_test.mbt#generated standalone TrueType opens and returns exact units per em"
        status: pass
      - kind: integration
        ref: "moon -C modules/mb-font test --target all --frozen"
        status: pass
    human_judgment: false
  - id: D3
    description: "Malformed, unsupported, over-limit, over-budget, and retained-source-mutated inputs fail closed deterministically without partial budget mutation."
    requirement: FONT-01
    verification:
      - kind: unit
        ref: "modules/mb-font/font/font_test.mbt and modules/mb-font/font/font_wbtest.mbt boundary suites"
        status: pass
      - kind: integration
        ref: "moon -C modules/mb-font test --target all --frozen"
        status: pass
    human_judgment: false
duration: 39min
completed: 2026-07-26
status: complete
---

# Phase 97 Plan 01: Font Admission Tracer Summary

Portable `mb-font` now admits a narrow standalone TrueType profile through checked, budgeted, retained-view parsing and exposes only an opaque `Font`, explicit `FontLimits`, and `units_per_em`.

## Performance

- **Started:** 2026-07-26T08:29:33Z
- **Completed:** 2026-07-26T09:07:35Z
- **Duration:** 39 minutes
- **Tasks:** 3
- **Files changed:** 11

## Accomplishments

- Added an independently publishable, four-target `mb-font` module whose only dependency is `mb-core`.
- Defined validated non-zero admission ceilings and an opaque font handle that retains its source view without copying.
- Implemented strict SFNT directory admission: canonical search fields, sorted unique tags, checked ranges, alignment, overlap rejection, required tables, table checksums, and the whole-font checksum.
- Added the first table tracer for `head`, including TrueType version and magic validation, units-per-em extraction, and short/long `loca` profile admission.
- Charged source bytes and deterministic work in one budget transaction before checksum traversal, with no partial budget mutation on rejection.
- Added generated in-language fixtures plus black-box and white-box coverage for success, unsupported profiles, truncation, malformed directories, limits, budgets, and retained-view mutation.

## Task Commits

Each task followed RED, GREEN, and—where useful—REFACTOR:

1. **Task 1: Establish the portable font module and public contracts**
   - `c49b638` — `test(97-01): add failing font contract tests`
   - `8c40d4f` — `feat(97-01): define portable font contracts`
2. **Task 2: Implement the leading standalone TrueType tracer**
   - `a8a944f` — `test(97-01): add failing TrueType tracer tests`
   - `d3c04a4` — `feat(97-01): admit generated TrueType font`
3. **Task 3: Lock ownership, classification, and rollback semantics**
   - `a4a2471` — `test(97-01): add failing ownership boundary tests`
   - `15eca65` — `feat(97-01): lock fail-closed font semantics`
   - `2473000` — `refactor(97-01): reuse checked byte reader`

## Files Created/Modified

- `moon.work` — registers the new workspace module.
- `modules/mb-font/moon.mod.json` — declares the portable module and `mb-core` dependency.
- `modules/mb-font/font/moon.pkg` — imports only the required core packages.
- `modules/mb-font/font/limits.mbt` — defines validated explicit admission ceilings.
- `modules/mb-font/font/font.mbt` — owns the opaque handle, admission transaction, and query revision gate.
- `modules/mb-font/font/cursor.mbt` — provides exact-fit checked big-endian reads.
- `modules/mb-font/font/directory.mbt` — validates and normalizes the SFNT directory.
- `modules/mb-font/font/tables.mbt` — validates the admitted `head` table contract.
- `modules/mb-font/font/generated_fonts.mbt` — builds deterministic checksum-correct test fonts.
- `modules/mb-font/font/font_test.mbt` — exercises the public contract as a consumer.
- `modules/mb-font/font/font_wbtest.mbt` — exercises parser invariants and error classification.

## Decisions Made

- Retain the caller-owned `ByteView` and opening revision instead of copying font bytes. This preserves zero-copy composition while making later caller mutation observable and fail-closed.
- Normalize every table record into a contained table-local view before any table parser runs. Offset arithmetic and ownership stay centralized at the admission boundary.
- Compute required work as twice the source byte length plus the table count and charge it with source bytes atomically. Rejected requests therefore leave caller budget state unchanged.
- Admit only standalone version `0x00010000` TrueType with required core tables. TTC, CFF/CFF2, variable, color, bitmap, and other deferred profiles remain explicit capability failures.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- An initial token-based interface check matched the permitted `max_cmap_records` accessor as though it were a future cmap API. Replacing it with an exact public-signature allowlist confirmed that no parser, fixture, backend, or deferred-feature surface leaked.
- `moon info --target all --frozen` reports pre-existing warnings in unrelated modules; the new `mb-font` sources introduce no warnings or errors.

## Verification

- `moon -C modules/mb-font test --target all --frozen`
  - wasm: 1020 passed, 0 failed
  - wasm-gc: 1020 passed, 0 failed
  - JavaScript: 1020 passed, 0 failed
  - native: 1020 passed, 0 failed
- `moon -C modules/mb-font info --target all --frozen` completed with zero errors.
- Generated public interface contains only `Font`, `Font::open`, `Font::units_per_em`, `FontLimits`, its eight accessors, and `FontLimits::new`.
- Stub scan found no `TODO`, `FIXME`, placeholder, coming-soon, or unwired runtime surface in the changed files.

## Next Phase Readiness

Plan 97-02 can expand admission coverage on top of the stable table-local view, limit, budget, and error-classification boundaries. No blockers remain.

## Self-Check: PASSED

- All 11 planned files exist.
- All seven RED/GREEN/REFACTOR commits are present.
- Four-target tests and interface generation pass after the final refactor.
- No known stubs, skipped tests, unrun verification commands, or undocumented threat surfaces remain.
