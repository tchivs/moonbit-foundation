---
phase: 87
plan: 01
subsystem: png-indexed-compression
tags: [png, indexed, streaming, deflate, qualification]
requires:
  - phase: 86
    provides: ancillary-aware indexed preflight and shared acknowledged machine
provides:
  - hostile caller-lease lifecycle qualification for Indexed1/2/4/8
  - independent Type-3 framing, DEFLATE, raster, checksum, and decode oracle
  - sticky indexed replay-work drift and frozen Stored compatibility evidence
affects: [INDEXCOMP-04, INDEXCOMP-05, indexed-png-compression-profiles]
tech-stack:
  added: []
  patterns: [test-local fixed-huffman inflater, accepted-only lease accounting, sticky replay assertions]
key-files:
  created:
    - .planning/phases/87-hostile-indexed-streaming-and-independent-qualification/87-01-SUMMARY.md
  modified:
    - modules/mb-image/png/stream_encode_test.mbt
    - modules/mb-image/png/stream_encode_wbtest.mbt
key-decisions:
  - Keep the 512-pixel all-depth corpus local to the stream qualification and derive expected packed rows arithmetically.
  - Parse eager bytes and separately collected chunk-origin bytes before comparing them for parity.
  - Induce indexed replay failure by perturbing the admitted private work ledger because the immutable indexed source has no public mutation revision.
patterns-established:
  - Hostile schedules always retain a sentinel owner and append only acknowledged prefixes.
  - Fixed/Stored wire checks use a bounded test-local inflater and checksum arithmetic, never production planning helpers.
requirements-completed: [INDEXCOMP-04, INDEXCOMP-05]
coverage:
  - id: D1
    description: "Indexed1/2/4/8 Fixed-or-Stored and Stored streams survive zero, one-byte, and ragged leases with accepted-only totals and sticky terminals."
    requirement: INDEXCOMP-04
    verification:
      - kind: unit
        ref: "modules/mb-image/png/stream_encode_test.mbt#PNG indexed compression hostile matrix independent qualification"
        status: pass
      - kind: unit
        ref: "moon -C modules/mb-image test png --target native --frozen"
        status: pass
    human_judgment: false
  - id: D2
    description: "Eager and collected Type-3 bytes are independently checked for framing, canonical palette chunks, Fixed/Stored DEFLATE, packed rows, Adler-32, CRCs, and public decode."
    requirement: INDEXCOMP-05
    verification:
      - kind: unit
        ref: "modules/mb-image/png/stream_encode_test.mbt#PNG indexed compression hostile matrix independent qualification"
        status: pass
      - kind: unit
        ref: "modules/mb-image/png/stream_encode_test.mbt#PNG indexed compression narrow packed tails and public decode"
        status: pass
    human_judgment: false
  - id: D3
    description: "Legacy non-interlaced Indexed1/2/4/8 Stored bytes remain frozen and opaque RGB8 plus partial-alpha RGBA8 decode semantics are covered."
    requirement: INDEXCOMP-05
    verification:
      - kind: unit
        ref: "modules/mb-image/png/stream_encode_test.mbt#PNG indexed compression Stored compatibility remains byte frozen"
        status: pass
      - kind: unit
        ref: "modules/mb-image/png/stream_encode_test.mbt#PNG indexed compression narrow packed tails and public decode"
        status: pass
    human_judgment: false
  - id: D4
    description: "Indexed Fixed replay-work drift is typed, sticky, and zero-progress at the private machine seam."
    requirement: INDEXCOMP-04
    verification:
      - kind: unit
        ref: "modules/mb-image/png/stream_encode_wbtest.mbt#PNG indexed fixed replay work fingerprint drift is sticky"
        status: pass
    human_judgment: false
metrics:
  duration: 2h 45m
  completed: 2026-07-24
  tasks_completed: 2
  tests: 315 per declared target gate
status: complete
---

# Phase 87 Plan 01: Hostile Indexed Streaming and Independent Qualification Summary

Test-only qualification now proves acknowledged hostile leases, independent Type-3 wire/decode facts, frozen Stored compatibility, and indexed replay-failure stickiness across all declared targets.

## Performance

- **Duration:** 2h 45m
- **Started:** 2026-07-24T15:45:00+08:00
- **Completed:** 2026-07-24T18:31:42+08:00
- **Tasks:** 2
- **Files modified:** 2 planned test files

## Accomplishments

- Added a production-quality Fixed-winner hostile tracer with zero-capacity, one-byte, ragged, release-failure, and sticky Finished coverage.
- Added an all-depth 512-pixel Fixed/Stored matrix with an independent bounded parser/inflater, CRC/Adler checks, filter-None packed-row/tail checks, eager-vs-collected parity, and coordinate-level RGB/RGBA decode checks.
- Added odd-width partial-alpha and opaque fixtures, byte-frozen legacy Stored comparisons, and a mandatory indexed white-box replay-work drift test.
- Verified the ordinary PNG package gate for native, wasm, wasm-gc, js, and the aggregate `--target all` invocation: 315/315 tests passed for every target.

## Task Commits

1. **Task 1: TDD tracer for one Fixed-winner hostile indexed stream** — `eb646c5` (RED test), `50256bd` (GREEN implementation)
2. **Task 2: Expand independent qualification, compatibility, and targets** — `6b74daa`

## Files Created/Modified

- `modules/mb-image/png/stream_encode_test.mbt` — hostile lease matrix, local corpus, independent PNG/DEFLATE parser, decode checks, narrow fixtures, and compatibility vectors.
- `modules/mb-image/png/stream_encode_wbtest.mbt` — indexed replay-work/fingerprint drift and sticky terminal white-box assertion.

## Decisions Made

- Kept all qualification data and expected rows test-local; no production planner, matcher, packer, or frame-facts helper is used as an oracle.
- Used private work-ledger perturbation for indexed replay drift because `PngIndexedImage` is immutable and cannot expose a source-revision mutation without production changes.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Replaced an inaccessible white-box corpus helper with a local stream-test corpus.**
- **Found during:** Task 1 GREEN compilation
- **Issue:** `png_indexed_compression_matrix_source` is scoped to white-box tests and was unavailable to `stream_encode_test.mbt`.
- **Fix:** Added an equivalent literal 512-pixel source builder in the planned stream test file.
- **Files modified:** `modules/mb-image/png/stream_encode_test.mbt`
- **Verification:** Native focused tracer and all target gates pass.
- **Committed in:** `50256bd`

**2. [Rule 1 - Bug] Corrected packed-row expected length in the independent oracle.**
- **Found during:** Task 2 native matrix qualification
- **Issue:** Expected packed bytes were initially scaled by bit depth instead of the fixed 512 wire bits.
- **Fix:** Bound the expected packed row to 64 bytes for every indexed depth.
- **Files modified:** `modules/mb-image/png/stream_encode_test.mbt`
- **Verification:** Full all-depth matrix passes on native, wasm, wasm-gc, and js.
- **Committed in:** `6b74daa`

---

**Total deviations:** 2 auto-fixed (1 Rule 1, 1 Rule 3)
**Impact on plan:** Both fixes preserved the test-only scope and strengthened independent evidence; no production architecture changed.

## Issues Encountered

- The initial aggregate target invocation waited on the shared Moon build lock and timed out; it was rerun with a longer timeout and completed with 315/315 passing for native, wasm, wasm-gc, and js.
- No target was unavailable and no authentication or user setup was required.

## Known Stubs

None. All created qualification paths are wired to real eager/chunk output and public decode behavior.

## Self-Check: PASSED

- Both planned test files exist and are the only source files in the task commits.
- Commits `eb646c5`, `50256bd`, and `6b74daa` are present in git history.
- Summary artifact exists at the required phase path.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

INDEXCOMP-04 and INDEXCOMP-05 have test-only evidence on all declared targets. No production changes or deferred capability work are pending from this plan.

---
*Phase: 87-hostile-indexed-streaming-and-independent-qualification*
*Completed: 2026-07-24*
