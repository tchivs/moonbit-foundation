---
phase: 98-unicode-mapping-and-kerning
plan: 01
subsystem: font
tags: [moonbit, opentype, cmap, unicode, format-4, format-12]

requires:
  - phase: 97-font-admission-and-metrics
    provides: atomic TrueType admission, retained table-local views, opaque GlyphId, and revision-guarded queries
provides:
  - deterministic canonical Unicode cmap selection across the four frozen ranks
  - guarded Font::glyph_for_scalar for BMP and supplementary scalar lookup
  - admitted allocation-free format-4 and format-12 binary searches
affects: [98-02-kern, font-api, text-foundation, generated-font-fixtures]

tech-stack:
  added: []
  patterns:
    - retain compact table-local lookup facts during the existing atomic admission transaction
    - derive binary-search bounds from admitted counts and guard retained-source reads before and after lookup

key-files:
  created:
    - modules/mb-font/font/cmap.mbt
  modified:
    - modules/mb-font/font/tables.mbt
    - modules/mb-font/font/font.mbt
    - modules/mb-font/font/font_test.mbt
    - modules/mb-font/font/font_wbtest.mbt

key-decisions:
  - "Canonical cmap priority is encoded literally as 0/4/12, 3/10/12, 0/3/4, then 3/1/4."
  - "Supported noncanonical format-4/12 records are structurally validated but never selected or used as per-scalar fallback."
  - "Duplicate canonical record keys fail admission, while different encoding records may alias one checked subtable."

patterns-established:
  - "Selected cmap descriptor: publish one private format-tagged lookup fact, never raw offsets or record arrays."
  - "Unicode query guard: revision check, signed scalar validation, one admitted lookup, revision check, opaque GlyphId publication."

requirements-completed: [FONT-02]

coverage:
  - id: D1
    description: One signed scalar query maps BMP and supplementary Unicode values to an opaque GlyphId, with glyph zero for valid misses and structured errors for invalid scalars.
    requirement: FONT-02
    verification:
      - kind: unit
        ref: "moon -C modules/mb-font test font --target native --frozen --target-dir <isolated> --no-parallelize (47/47)"
        status: pass
    human_judgment: false
  - id: D2
    description: Font opening validates supported cmap records and selects exactly one canonical format-12-or-format-4 mapping independent of record order.
    requirement: FONT-02
    verification:
      - kind: unit
        ref: "font/font_test.mbt#canonical cmap rank is record-order independent and never falls back"
        status: pass
      - kind: unit
        ref: "font/font_wbtest.mbt#cmap rank and format-12 lower bound preserve canonical boundaries"
        status: pass
    human_judgment: false
  - id: D3
    description: Format-4 direct delta, glyph-array, raw-zero, hole, and supplementary miss behavior uses admitted allocation-free binary search.
    requirement: FONT-02
    verification:
      - kind: unit
        ref: "font/font_test.mbt#format 4 lookup preserves direct indexed raw-zero and supplementary misses"
        status: pass
      - kind: unit
        ref: "font/font_wbtest.mbt#format-4 admitted bases and binary search cover direct and indexed edges"
        status: pass
    human_judgment: false

duration: 42min
completed: 2026-07-27
status: complete
---

# Phase 98 Plan 01: Unicode Mapping and Kerning Summary

**Deterministic OpenType format-12/format-4 Unicode mapping with one guarded signed-scalar query and allocation-free admitted lookups.**

## Performance

- **Duration:** 42 min
- **Started:** 2026-07-27T05:32:00Z
- **Completed:** 2026-07-27T06:14:00Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added `Font::glyph_for_scalar(Int)` with exact invalid-scalar, valid-miss, opaque-glyph, and retained-source mutation semantics.
- Implemented the frozen four-rank cmap selector, record-order independence, same-offset aliases, duplicate canonical-key rejection, and no lower-rank fallback.
- Added checked, allocation-free binary searches for format 12 groups and format 4 segments, including direct delta, glyph-array, and raw-zero behavior.
- Expanded public and private generated-font evidence to 47 passing native tests.

## Task Commits

Each task was committed atomically with TDD gates:

1. **Task 1 RED: Trace one admitted format-12 map through the public scalar query** - `cccf9e42` (test)
2. **Task 1 GREEN: Implement the production format-12 scalar tracer** - `b5aed0e2` (feat)
3. **Task 2 RED: Lock canonical selection and hostile cmap boundaries** - `41356b67` (test)
4. **Task 2 GREEN: Complete canonical format-12/format-4 lookup** - `abafeb05` (feat)

## Files Created/Modified

- `modules/mb-font/font/cmap.mbt` - Private canonical selector, retained format facts, and format-specific binary searches.
- `modules/mb-font/font/tables.mbt` - Carries the selected descriptor through the existing required-table admission transaction.
- `modules/mb-font/font/font.mbt` - Exposes the guarded signed-scalar query returning opaque `GlyphId`.
- `modules/mb-font/font/font_test.mbt` - Public selection, lookup, error, resource, and mutation evidence.
- `modules/mb-font/font/font_wbtest.mbt` - Private rank, array-base, and binary-search boundary evidence.

## Decisions Made

- The rank is a closed four-value function; all other platform/encoding/format tuples are noncanonical.
- Every supported format-4/12 record remains structurally and cardinality validated even when it cannot win selection.
- Admission retains exactly one descriptor. Query misses return glyph zero without consulting another record.
- Format-4 array zero is returned before applying `idDelta`; nonzero values use modulo-65536 delta semantics.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Repaired legacy Phase 98 state position metadata**
- **Found during:** Final state update
- **Issue:** `state.advance-plan` could not parse the pre-existing `Plan: Not started` body because `Current Plan` and `Total Plans in Phase` were absent.
- **Fix:** Added the canonical frontmatter counters and advanced the Current Position body to Plan 2 of 3 after all other SDK state handlers completed.
- **Files modified:** `.planning/STATE.md`
- **Verification:** `state.load` exposes Phase 98 Plan 2 with three total plans.

---

**Total deviations:** 1 auto-fixed (Rule 3)
**Impact on plan:** Planning metadata only; implementation scope and runtime behavior are unchanged.

## Issues Encountered

The unscoped module test driver stalled under Windows even with a unique target directory. Bounded diagnosis showed `modules/mb-font` contains one production package; the explicit `font` package selector completed all black-box, white-box, and generated-fixture tests (47/47), and `moon info --target native --frozen` completed successfully. Test target directories were isolated per run to avoid stale-process contention.

Compiler output included two warnings originating from MoonBit core `builtin/result.mbt`; no project source warnings remained.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 98-02 can build legacy horizontal kerning on the admitted opaque glyph identities and the same pre/post revision-guard pattern. No blockers remain.

## Self-Check: PASSED

All five implementation/test files, the summary, and all four TDD task commits were verified on disk.
