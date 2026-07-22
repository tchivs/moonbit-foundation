---
phase: 54-bounded-type-4-16-encoder
plan: "01"
subsystem: png-encoding
tags: [moonbit, png, grayalpha16, u16, bounded-encoding, streaming]
requires:
  - phase: 53-grayalpha16-model-and-checked-storage
    provides: packed little-endian U16 GrayAlpha images with straight-alpha metadata and checked component-byte storage
provides:
  - Explicit eager and caller-buffered GrayAlpha16 PNG factory families
  - Private non-interlaced type-4/depth-16 profile on the shared bounded machine
  - Four-byte Ghi/Glo/Ahi/Alo wire traversal across filtering, compression planning, and replay
affects: [55-grayalpha16-portable-public-evidence, png-encoding]
tech-stack:
  added: []
  patterns: [private profile composition, checked component-byte wire mapping, eager-chunk parity]
key-files:
  created: []
  modified:
    - modules/mb-image/png/png.mbt
    - modules/mb-image/png/encode.mbt
    - modules/mb-image/png/stream_encode.mbt
    - modules/mb-image/png/encode_test.mbt
    - modules/mb-image/png/stream_encode_test.mbt
key-decisions:
  - "GrayAlpha16 uses the existing bounded preflight, filter, compression planner, and replay machine without staging."
  - "Phase 53's little-endian-only GrayAlpha16 descriptor contract remains locked; Big-endian construction is rejected before PNG admission."
patterns-established:
  - "U16 PNG profiles select the shared component-aware wire reader and replay cursor through one private profile predicate."
requirements-completed: [GRAYA16-02, GRAYA16-03]
coverage:
  - id: D1
    description: Explicit eager and caller-buffered GrayAlpha16 factories emit non-interlaced type-4/depth-16 output in Ghi/Glo/Ahi/Alo order.
    requirement: GRAYA16-02
    verification:
      - kind: unit
        ref: modules/mb-image/png/encode_test.mbt#PNG GrayAlpha16 eager Stored output uses type 4 four-byte wire pixels
        status: pass
      - kind: unit
        ref: modules/mb-image/png/stream_encode_test.mbt#PNG GrayAlpha16 chunk Stored output matches eager
        status: pass
    human_judgment: false
  - id: D2
    description: All legal GrayAlpha16 compression/filter factory selections use the shared bounded eager and caller-buffered route with a four-byte Adaptive stride.
    requirement: GRAYA16-03
    verification:
      - kind: unit
        ref: modules/mb-image/png/encode_test.mbt#PNG GrayAlpha16 eager factories preserve four-byte wire and strategy parity
        status: pass
      - kind: unit
        ref: modules/mb-image/png/stream_encode_test.mbt#PNG GrayAlpha16 chunk factory strategies match eager
        status: pass
    human_judgment: false
duration: 14min
completed: 2026-07-22
status: complete
---

# Phase 54 Plan 01: Bounded Type-4/16 Encoder Summary

**Packed U16 straight-alpha GrayAlpha images now encode through explicit bounded eager and caller-buffered Type-4/16 PNG APIs with Ghi/Glo/Ahi/Alo wire fidelity.**

## Performance

- **Duration:** 14 min
- **Started:** 2026-07-22T20:58:18Z
- **Completed:** 2026-07-22T21:12:15Z
- **Tasks:** 2/2
- **Files modified:** 5

## Accomplishments

- Added all default, compression-only, filter-only, and combined `graya16` factory forms for `PngEncoder` and `PngChunkEncoder`.
- Added strict packed U16 GrayAlpha straight-alpha admission, a non-interlaced type-4/depth-16 IHDR profile, and per-component big-endian Ghi/Glo/Ahi/Alo wire mapping.
- Routed Stored, FixedOrStored, and DynamicOrFixedOrStored with None and Adaptive filters through the existing preflight, cursor, planner, and acknowledgement-safe replay machine.
- Added native focused coverage for framing, stored wire bytes, strict Big-endian descriptor rejection, four-byte Adaptive Sub stride, and ordinary eager/chunk parity across all six strategy pairs.

## Verification

| Command | Result |
| --- | --- |
| `moon -C modules/mb-image test png --target native --frozen --filter '*GrayAlpha16*'` | PASS — 5 passed, 0 failed |
| `moon -C modules/mb-image test png --target native --frozen` | PASS — 201 passed, 0 failed |
| `git diff --check` | PASS |

## Task Commits

1. **Task 1: Deliver one end-to-end GrayAlpha16 eager and chunk PNG path**
   - `0c92b6f` — RED tracer tests.
   - `30ce7b1` — profile, strict admission, factory families, four-byte wire path, and replay integration.
2. **Task 2: Expand the shared GrayAlpha16 path across every supported strategy pair**
   - `43cc3ae` — full legal strategy, Adaptive-stride, strict descriptor, and eager/chunk parity coverage.

## Files Created/Modified

- `modules/mb-image/png/png.mbt` — private GrayAlpha16 profile and eager factory family.
- `modules/mb-image/png/encode.mbt` — closed source admission, four-byte U16 component wire mapping, and non-interlace guard.
- `modules/mb-image/png/stream_encode.mbt` — caller-buffered factory family, U16 replay cursors, and Type-4/16 IHDR emission.
- `modules/mb-image/png/encode_test.mbt` — eager framing, exact wire lanes, descriptor rejection, strategy, and Adaptive tests.
- `modules/mb-image/png/stream_encode_test.mbt` — caller-buffered default and six-pair parity tests.

## Decisions Made

- Kept GrayAlpha16 on the one bounded encoder transaction; no conversion buffer, alternative machine, target branch, or source copy was introduced.
- Retained Phase 53's little-endian GrayAlpha16 model identity. The shared U16 wire mapper remains component-aware, but Big-endian GrayAlpha descriptors are rejected before an image source can exist.

## Deviations from Plan

### Plan-contradiction correction

**1. [Rule 4 - Architectural boundary] Removed impossible Big-endian GrayAlpha16 PNG parity evidence.**

- **Found during:** Task 2
- **Issue:** Task 2 requested legal little-/big-endian GrayAlpha16 sources, while Phase 53's locked `validate_gray_alpha_identity` explicitly rejects Big-endian GrayAlpha descriptors.
- **Resolution:** Preserved the Phase 53 contract and its strict admission boundary; replaced Big-endian parity with focused rejection evidence and limited the encoder matrix to legal little-endian sources.
- **Files modified:** `modules/mb-image/png/encode_test.mbt`
- **Verification:** Focused GrayAlpha16 suite passed 5/5; the native PNG suite passed 201/201.
- **Committed in:** `43cc3ae`

**Impact on plan:** The locked source-model boundary is preserved without architectural expansion. Legal GrayAlpha16 PNG behavior is fully covered; widening the model remains out of scope.

## Known Stubs

None. The stub scan found only pre-existing explanatory comments containing “not available”; no placeholder behavior was introduced.

## Next Phase Readiness

- Phase 55 can add public hostile schedules, frozen vectors, and independent four-target qualification over the explicit `graya16` factory families.
- Big-endian GrayAlpha16 remains a model-contract decision, not an encoder extension.

## Self-Check: PASSED

- All five modified PNG source/test files and this summary exist.
- Task commits `0c92b6f`, `30ce7b1`, and `43cc3ae` exist in repository history.

---
*Phase: 54-bounded-type-4-16-encoder*
*Plan: 01*
*Completed: 2026-07-22*
