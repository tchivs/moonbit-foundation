---
phase: 68-rgba16-decode-qualification
plan: 01
subsystem: testing
tags: [moonbit, png, rgba16, adam7, streaming, qualification]
requires:
  - phase: 66-explicit-rgba16-png-preservation
    provides: Explicit eager Type-6/16 preservation and profile admission.
  - phase: 67-resumable-rgba16-png-preservation
    provides: Caller-owned RGBA16 chunk lifecycle and terminal semantics.
provides:
  - Independent Type-6/16 all-filter and all-pass Adam7 qualification vectors.
  - Eager/chunk compatibility, hostile-terminal, and first-IDAT resource evidence.
  - Serial ordinary PNG package verification on every supported target.
affects: [png decoder, rgba16, decoder qualification]
tech-stack:
  added: []
  patterns: [Fixed hand-authored PNG wire literals with static component-byte oracles, first-IDAT boundary matrices]
key-files:
  created: [.planning/phases/68-rgba16-decode-qualification/68-01-SUMMARY.md]
  modified:
    - modules/mb-image/png/png_test.mbt
    - modules/mb-image/png/stream_decode_test.mbt
    - modules/mb-image/png/stream_decode_wbtest.mbt
key-decisions:
  - "Qualification uses fixed PNG literals and static storage-order byte oracles; PngEncoder is not an oracle."
  - "No decoder change was made because all independent lane, terminal, and resource regressions passed against the shared machine."
patterns-established:
  - "Separate authenticated-IHDR codec-limit checks from first-IDAT owned-resource lease checks in white-box qualification."
requirements-completed: [RGBA16DEC-04]
coverage:
  - id: D1
    description: Independent all-five-filter and all-seven-pass RGBA16 eager/chunk preservation with frozen generic high-byte views.
    requirement: RGBA16DEC-04
    verification:
      - kind: unit
        ref: "modules/mb-image/png/png_test.mbt#RGBA16 all-filter and Adam7 tests"
        status: pass
      - kind: integration
        ref: "modules/mb-image/png/stream_decode_test.mbt#RGBA16 chunk schedules and terminals"
        status: pass
    human_judgment: false
  - id: D2
    description: Exact and one-less normal/Adam7 Type-6/16 preflight resource and admission boundaries.
    requirement: RGBA16DEC-04
    verification:
      - kind: unit
        ref: "modules/mb-image/png/stream_decode_wbtest.mbt#RGBA16 first-IDAT qualification"
        status: pass
    human_judgment: false
  - id: D3
    description: Ordinary PNG package portability across wasm, wasm-gc, js, and native.
    requirement: RGBA16DEC-04
    verification:
      - kind: integration
        ref: "moon -C modules/mb-image test png --target wasm|wasm-gc|js|native --frozen"
        status: pass
    human_judgment: false
duration: 20min
completed: 2026-07-23
status: complete
---

# Phase 68 Plan 01: RGBA16 Decode Qualification Summary

**Independent Type-6/16 all-filter and all-pass Adam7 PNG vectors prove byte-exact explicit RGBA16 decoding while generic compatibility stays RGBA8 high-byte-only.**

## Performance

- **Duration:** 20 min
- **Started:** 2026-07-23T19:07:10+08:00
- **Completed:** 2026-07-23T19:27:03+08:00
- **Tasks:** 3/3
- **Files modified:** 3

## Accomplishments

- Added a CRC-valid 2x5 Type-6/16 fixture using filter tags 0 through 4, plus a static 80-byte packed-lane oracle and generic eager high-byte checks.
- Added a separate sRGB 5x5 Adam7 fixture with every pass nonempty, full static component-byte coverage, eager/chunk parity, hostile terminals, and generic chunk compatibility.
- Added exact/one-less normal and Adam7 profile boundary evidence; ran the ordinary unfiltered PNG suite serially on wasm, wasm-gc, js, and native (245/245 each).

## Task Commits

1. **Task 1: Prove an independent all-filter eager RGBA16 path**
   - `df5ff5c` RED: failing all-filter qualification
   - `85e8036` GREEN: fixed all-filter literal and eager/generic checks
2. **Task 2: Extend independent Adam7, chunk-schedule, and hostile-terminal evidence**
   - `9a4c32c` RED: failing all-pass Adam7 qualification
   - `922a962` GREEN: Adam7, chunk, generic, and terminal coverage
3. **Task 3: Qualify first-IDAT resource boundaries and serial portability**
   - `fcab20d` RED: failing preflight matrix
   - `59f5609` GREEN: normal/Adam7 resource matrix

## Files Modified

- `modules/mb-image/png/png_test.mbt` — independent literal fixtures and static explicit/generic eager assertions.
- `modules/mb-image/png/stream_decode_test.mbt` — caller-owned schedule parity, generic high-byte, and hostile eager/chunk terminals.
- `modules/mb-image/png/stream_decode_wbtest.mbt` — exact/one-less boundary matrix and fallible authenticated-IHDR test seam.

## Decisions Made

- Retained the shared decoder unchanged: both independent vectors passed, so no shared-store defect was demonstrated.
- Codec ceilings are asserted at authenticated IHDR, while caller-owned resource leases are asserted at first IDAT; the white-box matrix preserves that established distinction.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test-data bug] Corrected one escaped byte in the hand-authored Adam7 literal.**
- **Found during:** Task 2
- **Issue:** The literal omitted a `0x5c` data byte, invalidating its IDAT Adler checksum before it reached the decoder.
- **Fix:** Restored the byte and confirmed the fixture byte-for-byte against its fixed wire plan.
- **Files modified:** `modules/mb-image/png/png_test.mbt`
- **Verification:** Focused JS RGBA16 suite passed 9/9 after correction.
- **Commit:** `922a962`

**2. [Rule 1 - Test helper bug] Made the white-box chunk feeder propagate acceptance errors.**
- **Found during:** Task 3
- **Issue:** The helper unwrapped errors while authenticating IHDR, obscuring the planned exact/one-less boundary result.
- **Fix:** Propagated the typed error through the helper and added a qualification-only fallible IHDR seam.
- **Files modified:** `modules/mb-image/png/stream_decode_wbtest.mbt`
- **Verification:** Focused JS RGBA16 suite passed 10/10; all four ordinary target runs passed.
- **Commit:** `59f5609`

**Total deviations:** 2 Rule 1 test-correctness fixes. No decoder source, public API, encoder oracle, copied tree, FFI, or release automation was added.

## Issues Encountered

- The ordinary full-package commands are intentionally serial and completed in about four minutes; each target passed 245/245 tests.

## Known Stubs

None.

## Next Phase Readiness

RGBA16DEC-04 has focused independent coverage and portable package evidence. No qualification regression required a shared decoder repair.

## Self-Check: PASSED

- All three plan-listed test files exist and are committed in the task commits above.
- `df5ff5c`, `85e8036`, `9a4c32c`, `922a962`, `fcab20d`, and `59f5609` are present in git history.

---
*Phase: 68-rgba16-decode-qualification*
*Completed: 2026-07-23*
