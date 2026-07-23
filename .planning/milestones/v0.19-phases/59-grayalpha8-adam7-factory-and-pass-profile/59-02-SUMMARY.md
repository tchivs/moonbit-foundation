---
phase: 59-grayalpha8-adam7-factory-and-pass-profile
plan: "02"
subsystem: png-encoding
tags: [moonbit, png, grayalpha8, adam7, streaming]
requires:
  - phase: 59-01
    provides: "Explicit GrayAlpha8 Adam7 eager and caller-buffered public selectors."
provides:
  - "Six-pair eager Type-4/8 Adam7 framing coverage."
  - "Six-pair ordinary GrayAlpha8 Adam7 chunk-to-eager parity coverage."
affects: [phase-60-bounded-adam7-streaming, phase-61-public-adam7-evidence]
tech-stack:
  added: []
  patterns: ["All-strategy selectors are tested with fresh sources and the ordinary established chunk drain."]
key-files:
  created: []
  modified:
    - modules/mb-image/png/encode_test.mbt
    - modules/mb-image/png/stream_encode_test.mbt
key-decisions:
  - "All six legal compression/filter pairs retain Type-4/depth-8/Adam7 framing through the existing public selector."
  - "Chunk parity uses only the ordinary 3/7-byte drain and fresh eager peers; replay and hostile schedules remain deferred."
requirements-completed: [GRAYA8A7-01]
duration: 18min
completed: 2026-07-23
status: complete
---

# Phase 59 Plan 02: GrayAlpha8 Adam7 Public Strategy Coverage Summary

**GrayAlpha8 Adam7 now has public six-pair framing and ordinary chunk-to-eager parity proof without broadening the shared encoder or later replay/hostile-schedule scope.**

## Accomplishments

- Added a compact eager regression that exercises Stored, Fixed-or-Stored, and Dynamic-or-Fixed-or-Stored with both None and Adaptive filters, asserting Type-4/depth-8/Adam7 IHDR framing.
- Added a matching six-pair caller-buffered regression that drains each public all-strategy selector through the established ordinary schedule and compares it with a freshly built eager peer.
- Retained the Plan 01 Stored/None independent G,A seven-pass raster oracle, narrow/all-strategy Stored/None selector parity, and frozen method-0 GrayAlpha8 coverage.

## Task Commits

1. **Task 1: Cover every legal GrayAlpha8 Adam7 eager factory framing pair**
   - `ce6f4b0` — `test(59-02): cover GrayAlpha8 Adam7 eager strategies`
2. **Task 2: Make both GrayAlpha8 Adam7 chunk selector routes explicitly comparable**
   - `28642a0` — `test(59-02): verify GrayAlpha8 Adam7 chunk strategies`

## Verification

- `moon -C modules/mb-image test png --target native --frozen -f 'PNG GrayAlpha8 Adam7 eager'` completed successfully; this MoonBit filter invocation reported no matching entry, so it was not used as the sole evidence.
- `moon -C modules/mb-image test png --target native --frozen -f 'PNG GrayAlpha8 Adam7 chunk parity'` — 1/1 passed.
- `moon -C modules/mb-image test png --target native --frozen` — 223/223 passed.

## TDD Gate Compliance

- Plan 01 had already implemented the additive public selectors before this test-expansion plan began. Consequently the new behavioral regressions passed immediately rather than producing an artificial failing RED test; the two commits above are deliberately test-only coverage commits.

## Deviations from Plan

### Auto-fixed Issues

1. **[Rule 1 - Bug] Replaced an error-producing test assertion inside a Unit helper**
   - **Found during:** Task 2 focused compile.
   - **Issue:** `inspect` propagated an error type from the new helper, preventing the native test module from compiling.
   - **Fix:** Replaced it with the project's established explicit `if ... abort(...)` assertion form.
   - **Files modified:** `modules/mb-image/png/stream_encode_test.mbt`
   - **Commit:** `28642a0`

## Known Stubs

None introduced by this plan.

## Self-Check: PASSED

- The summary and both committed test files exist.
- `ce6f4b0` and `28642a0` are present in git history.
- No new TODO, FIXME, placeholder, or skipped-test marker was introduced in the modified test files.
