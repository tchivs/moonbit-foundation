---
phase: 48-bounded-gray16-encoder-path
review_depth: standard
base: bc8f9ea
status: issues_found
files_reviewed: 5
findings:
  critical: 0
  warning: 1
  info: 1
  total: 2
tests:
  - command: moon -C modules/mb-image test png --target native --frozen
    result: pass (187 passed, 0 failed)
---

# Phase 48 Code Review

Reviewed the explicit Gray16 strategy factories, profile-aware wire-byte producer, filtering/match/planning/replay propagation, and native regressions in the five requested PNG files against `bc8f9ea..HEAD`.

## Findings

### WR-01 — Gray16 Fixed/Dynamic sticky replay has no regression coverage

- **Severity:** Warning
- **File:** `modules/mb-image/png/stream_encode_test.mbt:535`, `modules/mb-image/png/stream_encode_test.mbt:1921`
- **Evidence:** The new Gray16 tests cover normal eager/chunk identity and atomic construction across all six pairs, but the only fixed replay-mutation test remains the pre-existing Gray8 case at line 1990. There is no Gray16 test that mutates a U16 component after accepted framing/DEFLATE bytes for `FixedOrStored` or `DynamicOrFixedOrStored` and then asserts zero-byte failure, unchanged `total_written()`, identical terminal error, and untouched later lease.
- **Impact:** A regression in the Gray16-specific `PngFilteredMatchCursor` profile propagation or Fixed/Dynamic replay path can preserve normal eager/chunk identity while violating the acknowledgement-safe sticky replay contract required by D-04.
- **Recommendation:** Add dedicated Gray16 FixedOrStored and DynamicOrFixedOrStored replay-drift tests. Use `set_component_byte` after a one-byte pull prefix, force the selected route with an appropriate corpus, then assert accepted-progress-only accounting, `written()==0UL` on failure, error equality on a later pull, and unchanged sentinel leases.

### IN-01 — Gray8 replay test now reports a misleading Gray16 failure label

- **Severity:** Info
- **File:** `modules/mb-image/png/stream_encode_test.mbt:2036`
- **Evidence:** The test named `PNG Gray8 fixed replay mismatch is sticky` now aborts with `png gray16 replay was not sticky`.
- **Impact:** This does not affect runtime behavior, but a failure would misidentify the profile under test and slow diagnosis.
- **Recommendation:** Restore the abort text to `png gray8 replay was not sticky`, or replace the test with the missing Gray16-specific replay test described above.

## Verified Areas

- `PngEncoder` and `PngChunkEncoder` now expose compression-only, filter-only, and combined Gray16 factories while keeping Gray16 non-interlaced.
- `_png_wire_byte` maps U16 storage-order bytes to PNG big-endian bytes, and the reviewed stored, filter, match, Fixed, Dynamic, checksum, and replay call sites pass the profile through.
- Gray16 carries `2UL` as the byte stride from profile admission into filter/match traversal; no image-sized staging or new retained row buffer was introduced.
- The shared preflight still rejects `gray16-noninterlaced-required`, and Gray16 all-pair capability/geometry/output/work/budget admissions remain atomic in the reviewed tests.
- `moon -C modules/mb-image test png --target native --frozen` passed: 187 passed, 0 failed.

## Scope

- `modules/mb-image/png/png.mbt`
- `modules/mb-image/png/encode.mbt`
- `modules/mb-image/png/stream_encode.mbt`
- `modules/mb-image/png/encode_test.mbt`
- `modules/mb-image/png/stream_encode_test.mbt`
