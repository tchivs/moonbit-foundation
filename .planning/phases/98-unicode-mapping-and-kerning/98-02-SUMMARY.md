---
phase: 98-unicode-mapping-and-kerning
plan: 02
subsystem: font
tags: [moonbit, opentype, kern, binary-search, resource-bounds]

requires:
  - phase: 98-unicode-mapping-and-kerning
    plan: 01
    provides: canonical cmap admission, opaque GlyphId, and revision-guarded scalar lookup
  - phase: 97-font-admission-and-metrics
    provides: atomic TrueType admission, normalized table windows, and guarded metric queries
provides:
  - guarded Font::kerning with exact signed format-0 adjustments
  - retained absent, supported, and unsupported legacy kern taxonomy
  - explicit kern subtable and pair ceilings with exact preflighted work accounting
affects: [98-03-integration, font-api, text-foundation, hostile-font-admission]

tech-stack:
  added: []
  patterns:
    - classify optional tables during atomic opening and retain compact private lookup facts
    - preflight attacker-controlled counts before iteration and charge each admitted scan exactly once
    - distinguish absent data, supported misses, unsupported capability, and malformed recognized bytes

key-files:
  created:
    - modules/mb-font/font/kern.mbt
  modified:
    - modules/mb-font/font/directory.mbt
    - modules/mb-font/font/tables.mbt
    - modules/mb-font/font/font.mbt
    - modules/mb-font/font/limits.mbt
    - modules/mb-font/font/font_test.mbt
    - modules/mb-font/font/font_wbtest.mbt
    - modules/mb-font/font/generated_fonts_wbtest.mbt
    - modules/mb-font/README.mbt.md

key-decisions:
  - "Only classic OpenType version 0 with exactly one version-0 coverage-0x0001 format-0 subtable is queryable; other structurally valid profiles remain Unsupported."
  - "Exact Apple 0x00010000 envelopes are validated without interpreting format bodies, while other complete unknown prefixes defer directly to Capability at query time."
  - "Font opening carries pre-admitted KernState through FontAdmissionPlan so the optional directory scan, subtable scan, and pair scan are each preflighted and charged once."
  - "Kerning lookup is allocation-free and budget-neutral, with receiving-font glyph validation and revision guards surrounding retained-source reads."

patterns-established:
  - "Optional-table taxonomy: absence is neutral, recognized malformed bytes fail opening, and structurally valid unsupported profiles fail only at their public query."
  - "Count-derived lookup: retain pair start/count and use binary search over strictly increasing admitted keys."

requirements-completed: [FONT-04]

coverage:
  - id: D1
    description: Font::kerning distinguishes absence and miss zero, signed hit, foreign glyph rejection, unsupported capability, malformed data, and retained-source mutation.
    requirement: FONT-04
    verification:
      - kind: unit
        ref: "moon -C modules/mb-font test font --target native --frozen --no-parallelize --target-dir <isolated> (56/56)"
        status: pass
      - kind: unit
        ref: "font/font_test.mbt#optional supported kern returns signed hits and neutral misses"
        status: pass
    human_judgment: false
  - id: D2
    description: Classic and Apple envelopes, exact format-0 lengths, canonical helpers, ordered unique in-range keys, and signed values are validated before publication.
    requirement: FONT-04
    verification:
      - kind: unit
        ref: "font/font_test.mbt#recognized classic and Apple kern envelope malformations fail opening"
        status: pass
      - kind: unit
        ref: "font/font_wbtest.mbt#kern admission rejects exact-length search order duplicate and range errors"
        status: pass
    human_judgment: false
  - id: D3
    description: Optional directory, classic/Apple subtable, and supported pair work is bounded by explicit ceilings, max_work, and the caller budget before iteration.
    requirement: FONT-04
    verification:
      - kind: unit
        ref: "font/font_test.mbt#kern semantic ceilings reject before subtable and pair scans"
        status: pass
      - kind: unit
        ref: "font/font_test.mbt#kern work admits exact fit and rejects one short atomically"
        status: pass
    human_judgment: false

duration: 36min
completed: 2026-07-27
status: complete
---

# Phase 98 Plan 02: Legacy Kerning Summary

**Strict legacy `kern` admission with signed allocation-free pair lookup, deferred unsupported capability, and exact hostile-count resource accounting.**

## Performance

- **Duration:** 36 min
- **Started:** 2026-07-27T06:19:03Z
- **Completed:** 2026-07-27T06:55:09Z
- **Tasks:** 3
- **Files modified:** 9

## Accomplishments

- Added `Font::kerning(left, right)` with exact positive and negative adjustments, neutral absence/miss behavior, receiving-font glyph validation, and pre/post revision guards.
- Implemented a closed absent/supported/unsupported kern classifier with full classic and Apple envelope validation and strict format-0 pair admission.
- Added explicit non-zero `max_kern_subtables` and `max_kern_pairs` limits across every MoonBit and literate constructor call site.
- Proved exact-fit and one-short behavior for optional directory discovery, classic/Apple subtable counts, pair counts, `max_work`, and caller budget without partial budget consumption.
- Expanded public and private evidence to 56 passing native tests and confirmed that generated interfaces contain no private kern facts.

## Task Commits

Each task was committed atomically with mandatory TDD RED/GREEN gates:

1. **Task 1 RED: Add failing kern query tracer** - `08cfd995` (test)
2. **Task 1 GREEN: Trace supported legacy kern lookup** - `d84d8872` (feat)
3. **Task 2 RED: Add failing kern limit contract** - `fe6d3daa` (test)
4. **Task 2 GREEN: Publish explicit kern ceilings** - `ea1a7128` (feat)
5. **Task 3 RED: Add failing hostile kern matrix** - `1d51f552` (test)
6. **Task 3 GREEN: Close hostile kern admission boundaries** - `35925edd` (feat)

## Files Created/Modified

- `modules/mb-font/font/kern.mbt` - Private tri-state classifier, classic/Apple envelope validators, strict format-0 admission, and binary search.
- `modules/mb-font/font/directory.mbt` - Optional normalized table-window discovery.
- `modules/mb-font/font/tables.mbt` - Pre-admission work plan, exact aggregate charging, and retained kern state.
- `modules/mb-font/font/font.mbt` - Public guarded kerning facade.
- `modules/mb-font/font/limits.mbt` - Explicit non-zero kern subtable and pair ceilings.
- `modules/mb-font/font/font_test.mbt` - Public taxonomy, mutation, foreign-ID, and resource-boundary evidence.
- `modules/mb-font/font/font_wbtest.mbt` - Private search-helper, signed-value, pair-order, and malformed-boundary evidence.
- `modules/mb-font/font/generated_fonts_wbtest.mbt` - Explicit limits at generated-fixture call sites.
- `modules/mb-font/README.mbt.md` - Literate constructor example with explicit kern limits.

## Decisions Made

- Classic tables are structurally exhausted before profile classification; multiple otherwise supported subtables are retained as unsupported rather than accumulated.
- Apple v1 is recognized only by the exact 32-bit `0x00010000` prefix and only its table/subtable envelopes are interpreted.
- Complete unknown top-level prefixes are retained as unsupported without attacker-controlled traversal.
- Successful format-0 admission requires exact length, canonical binary-search fields, strictly increasing unique pair keys, in-range glyph IDs, and valid signed adjustment reads.
- Opening performs the optional directory scan and kern count scans once, before one authoritative budget charge; queries consume no opening budget.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Repaired stale Phase 98 state fields after SDK advancement**
- **Found during:** Final state update
- **Issue:** The state SDK advanced the body to Plan 3 but left `current_plan`, progress prose, activity text, operator next steps, and decision phase labels stale.
- **Fix:** Synchronized the frontmatter and human-readable state fields to completed Plan 98-02 and ready Plan 98-03.
- **Files modified:** `.planning/STATE.md`
- **Verification:** `state.load` reports the Plan 3 body and the persisted state now consistently records 5/6 completed plans.

---

**Total deviations:** 1 auto-fixed (Rule 3)
**Impact on plan:** Planning metadata only; implementation scope and runtime behavior are unchanged.

## Issues Encountered

The exact unscoped module test command stalled under Windows for 90 seconds and its isolated process tree was terminated. As established in Plan 98-01, `modules/mb-font` has one production package; the bounded `font` selector exercised all black-box, white-box, and generated-fixture tests and passed 56/56 in isolated target directories. Native README checking and native interface generation also passed.

Compiler output included warnings originating from MoonBit core `builtin/result.mbt`; no project source warning remained.

## Known Stubs

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 98-03 can complete phase-level integration and documentation checks over the stable cmap and kern public surface. No blockers remain.

## Self-Check: PASSED

All nine implementation/test/documentation files, the summary, and all six TDD task commits were verified on disk.
