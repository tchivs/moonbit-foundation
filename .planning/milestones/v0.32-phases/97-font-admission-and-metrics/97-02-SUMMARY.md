---
phase: 97-font-admission-and-metrics
plan: 02
subsystem: font
tags: [moonbit, truetype, sfnt, checksums, table-admission, metrics]
requires:
  - phase: 97-font-admission-and-metrics
    plan: 01
    provides: opaque Font ownership, FontLimits, retained ByteView revision gates, checked cursors, and generated micro-font infrastructure
provides:
  - strict normalized standalone TrueType directory and checksum admission
  - bounded structural admission for all ten required tables and hmtx/loca cardinalities
  - opaque FontBounds and separately named hhea and OS/2 FontLineMetrics queries
affects:
  - 97-03
  - 98-unicode-mapping-and-kerning
  - 99-outlines
  - 100-qualification
tech-stack:
  added: []
  patterns:
    - checked table-local windows before payload decoding
    - one opaque Font construction after aggregate admission and revision checks
    - separate source-named integer metric values without selection policy
key-files:
  created:
    - modules/mb-font/font/metrics.mbt
  modified:
    - modules/mb-font/font/directory.mbt
    - modules/mb-font/font/tables.mbt
    - modules/mb-font/font/font.mbt
    - modules/mb-font/font/generated_fonts.mbt
    - modules/mb-font/font/font_test.mbt
    - modules/mb-font/font/font_wbtest.mbt
key-decisions:
  - "Font stores the admitted private directory, required-table facts, and metric index while exposing no raw tags, windows, offsets, or checksums."
  - "Required-table presence is checked without decoding before checksum traversal so missing-table errors retain the established font-required-table contract."
  - "head bounds, hhea line metrics, and OS/2 typographic metrics remain separate signed integer values with no implicit selector."
patterns-established:
  - "Admission coordinator: directory, profile, presence, checksum, table envelopes, cross-cardinality index, final revision check, then exactly one Font construction."
  - "Generated SFNT fixtures repair table and whole-font checksums after deterministic hostile mutations."
requirements-completed: [FONT-01]
coverage:
  - id: D1
    description: "Standalone TrueType directories are normalized to checked table-local windows and rejected on malformed ordering, ranges, overlap, profiles, table checksums, or whole-font adjustment."
    requirement: FONT-01
    verification:
      - kind: integration
        ref: "moon -C modules/mb-font test --target all --frozen"
        status: pass
    human_judgment: false
  - id: D2
    description: "All ten required tables, structural envelopes, hmtx length, and short/long loca offsets are admitted under explicit limits and cross-table cardinalities."
    requirement: FONT-01
    verification:
      - kind: unit
        ref: "modules/mb-font/font/font_wbtest.mbt#font required table matrix enforces structural cardinalities"
        status: pass
      - kind: integration
        ref: "moon -C modules/mb-font test --target all --frozen"
        status: pass
    human_judgment: false
  - id: D3
    description: "Opaque Font queries publish exact units-per-em, global bounds, hhea line metrics, and OS/2 typographic metrics while uniformly rejecting retained-source revision drift."
    requirement: FONT-01
    verification:
      - kind: unit
        ref: "modules/mb-font/font/font_test.mbt#font publishes separate exact global metric sources"
        status: pass
      - kind: integration
        ref: "moon -C modules/mb-font info --target all --frozen"
        status: pass
    human_judgment: false
duration: 40min
completed: 2026-07-26
status: complete
---

# Phase 97 Plan 02: Strict Font Admission and Global Metrics Summary

Strict table-local SFNT admission now validates required TrueType structure and cross-cardinalities before publishing an opaque `Font` with exact, separately named head, hhea, and OS/2 integer metrics.

## Performance

- **Started:** 2026-07-26T09:17:01Z
- **Completed:** 2026-07-26T09:56:35Z
- **Duration:** 40 minutes
- **Tasks:** 3
- **Files changed:** 7

## Accomplishments

- Replaced raw directory navigation with normalized checked `TableWindow` facts, canonical search-helper validation, overlap/alignment rejection, per-table checksums, and the standalone whole-font checksum invariant.
- Added bounded private decoders for `head`, `maxp`, `hhea`, `OS/2`, `cmap`, `name`, and `post`, plus exact `hmtx` and short/long `loca` cardinality admission against `glyf`.
- Refactored `Font::open` into the sole aggregate coordinator and sole construction point after every profile, structure, budget, checksum, cross-table, and final revision gate succeeds.
- Published opaque `FontBounds` and `FontLineMetrics` values with four revision-guarded queries and no platform-dependent metric-source selection.
- Expanded deterministic generated fonts and hostile matrices while keeping every parser, table window, offset, checksum, and metric index private.

## Task Commits

Each task was committed atomically with TDD RED and GREEN gates:

1. **Task 1: Normalize and checksum the standalone TrueType directory**
   - `712df97` — `test(97-02): add failing SFNT directory matrix`
   - `2d703e7` — `feat(97-02): normalize and checksum SFNT directories`
2. **Task 2: Admit required table structures and cross-table cardinalities**
   - `09b8bfd` — `test(97-02): add failing required table matrix`
   - `8021c99` — `feat(97-02): admit required tables and metric index`
3. **Task 3: Publish the admitted Font with separately named global metrics**
   - `c07e62b` — `test(97-02): add failing global metric API coverage`
   - `ed01bbd` — `feat(97-02): publish admitted global font metrics`
   - `8e04e7f` — `fix(97-02): stabilize generated global metric fixture`

## Files Created/Modified

- `modules/mb-font/font/directory.mbt` — normalizes checked table windows and validates strict directory/checksum invariants.
- `modules/mb-font/font/tables.mbt` — admits required fixed table facts and stable structured errors.
- `modules/mb-font/font/metrics.mbt` — validates exact hmtx/loca cardinalities and caches normalized glyph offsets.
- `modules/mb-font/font/font.mbt` — coordinates atomic admission and publishes opaque global metric values.
- `modules/mb-font/font/generated_fonts.mbt` — builds checksum-correct deterministic fonts and hostile mutations.
- `modules/mb-font/font/font_test.mbt` — verifies the public global metric and revision-drift contract.
- `modules/mb-font/font/font_wbtest.mbt` — verifies directory, table envelope, profile, checksum, and cross-cardinality matrices.

## Decisions Made

- Preserve the private directory, required-table fact set, and metric index inside `Font` for Plan 97-03 while keeping the generated public interface limited to semantic values.
- Run a non-decoding required-table presence preflight before checksums. This preserves the established `font-required-table` result when a required tag is absent without trusting or decoding unverified payload bytes.
- Keep hhea and OS/2 line metrics as separate `FontLineMetrics` instances. Callers receive exact signed integers and must choose policy explicitly.
- Continue to guard cached values against source revision drift; caching never weakens retained-source ownership semantics.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Preserved and repaired an in-scope Task 3 draft with unknown provenance**
- **Found during:** Task 3 RED verification
- **Issue:** `font.mbt` and `generated_fonts.mbt` acquired an uncommitted in-scope draft while execution was active. The draft contained an invalid private-method declaration, unbound generated-font writers, and later a duplicated helper definition.
- **Fix:** Preserved the intended coordinator and distinct-metric work, reviewed it against the plan, converted the revision guard to a valid private `Font` method, implemented one signed 16-bit writer, removed the duplicate, and serialized subsequent edits and tests.
- **Files modified:** `modules/mb-font/font/font.mbt`, `modules/mb-font/font/generated_fonts.mbt`
- **Verification:** native 1026/1026 tests and four-target interface generation
- **Committed in:** `ed01bbd`

**2. [Rule 1 - Bug] Restored stable missing-table and head error contracts**
- **Found during:** Task 3 GREEN verification
- **Issue:** The expanded coordinator checked checksums before noticing a missing required tag, and the new head decoder collapsed established length, version, magic, units, and loca-format tokens into a generic `font-head` error.
- **Fix:** Added a non-decoding required-table presence gate and retained the established detailed head tokens with checked source offsets while keeping bounds-order failures under `font-head`.
- **Files modified:** `modules/mb-font/font/font.mbt`, `modules/mb-font/font/tables.mbt`
- **Verification:** native 1026/1026 tests, including the Plan 97-01 compatibility cases
- **Committed in:** `ed01bbd`

**3. [Rule 1 - Bug] Stabilized a late generated OS/2 metric update across all targets**
- **Found during:** plan-wide four-target verification
- **Issue:** A second in-scope draft mutation added distinct OS/2 metrics after the Task 3 GREEN commit. The first all-target run used mixed source snapshots: wasm passed the prior fixture while wasm-gc, JavaScript, and native observed ascent `750` against the old `0` assertion.
- **Fix:** Preserved the useful distinct typographic fixture, expanded white-box assertions to exact head, hhea, and OS/2 triplets, committed the synchronized fixture/test pair, and reran all targets from a clean tracked state.
- **Files modified:** `modules/mb-font/font/generated_fonts.mbt`, `modules/mb-font/font/font_wbtest.mbt`
- **Verification:** wasm, wasm-gc, JavaScript, and native each passed 1026/1026
- **Committed in:** `8e04e7f`

---

**Total deviations:** 3 auto-fixed (2 Rule 1 bugs, 1 Rule 3 blocker)
**Impact on plan:** All changes stayed inside Plan 97-02 files and strengthened correctness, compatibility, and deterministic generated evidence; no public capability or dependency scope expanded.

## Issues Encountered

- The initial four-target run exposed that different backends had compiled different snapshots during an unexplained repeated in-scope write. Serializing the fixture repair, committing it, and rerunning from a tracked-clean source state produced identical passing results.
- `moon info --target all --frozen` reports existing workspace warnings plus intentionally private facts reserved for Plan 97-03; it completed with zero errors.

## Verification

- `moon -C modules/mb-font test --target all --frozen`
  - wasm: 1026 passed, 0 failed
  - wasm-gc: 1026 passed, 0 failed
  - JavaScript: 1026 passed, 0 failed
  - native: 1026 passed, 0 failed
- `moon -C modules/mb-font info --target all --frozen` completed with zero errors.
- The generated `font.mbti` SHA-256 is identical on all four targets: `E010D6282F293C018F15773EAA004DFD74B7A17349501CAA3D7FA61A4B3CF585`.
- Interface scans found no `DirectoryFacts`, `TableWindow`, `RequiredTableFacts`, `MetricIndexFacts`, or private parser/admission symbols.
- Stub/skip scan found no `TODO`, `FIXME`, placeholder, coming-soon, skipped test, or unwired runtime surface in the seven changed files.
- Threat-surface review found no network, filesystem, authentication, schema, or other trust boundary beyond the plan's hostile caller-byte admission model.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 97-03 can consume the retained private metric index to publish checked `GlyphId` and per-glyph horizontal metrics. No blockers remain.

## Self-Check: PASSED

- All seven planned source/test files exist.
- All seven RED/GREEN/fix commits exist.
- Four-target tests and interface generation pass after the final committed fixture repair.
- No known stubs, skipped tests, unrun verification commands, or undocumented threat surfaces remain.

---
*Phase: 97-font-admission-and-metrics*
*Completed: 2026-07-26*
