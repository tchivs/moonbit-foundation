---
phase: 21-bounded-png-decode-and-deflate
reviewed: 2026-07-20T17:10:34Z
depth: deep
files_reviewed: 19
files_reviewed_list:
  - fixtures/manifest.json
  - fixtures/png/decode-cases.json
  - modules/mb-image/png/deflate_bits.mbt
  - modules/mb-image/png/deflate_huffman.mbt
  - modules/mb-image/png/deflate_inflate.mbt
  - modules/mb-image/png/deflate_wbtest.mbt
  - modules/mb-image/png/generated_vectors.mbt
  - modules/mb-image/png/generated_vectors_test.mbt
  - modules/mb-image/png/moon.pkg
  - modules/mb-image/png/png.mbt
  - modules/mb-image/png/png_test.mbt
  - modules/mb-image/png/raster_decode.mbt
  - modules/mb-image/png/raster_decode_wbtest.mbt
  - modules/mb-image/png/structural.mbt
  - policy/foundation.json
  - scripts/fixtures/Generate-PngDecodeVectors.ps1
  - scripts/quality/Assert-Policy.ps1
  - scripts/quality/Invoke-MoonQuality.ps1
findings:
  critical: 3
  warning: 1
  info: 0
  total: 4
status: issues_found
---

# Phase 21: Code Review Report

**Reviewed:** 2026-07-20T17:10:34Z
**Depth:** deep
**Files Reviewed:** 19
**Status:** issues_found

## Summary

The changed eager decoder reaches `DecodeResult` only after the transport has
seen IEND/EOF and the later zlib/raster steps return successfully, so the
result object is not exposed early.  It does not, however, implement the
required bounded forward pipeline: it stages both the complete compressed IDAT
stream and the complete decompressed filtered stream in arrays outside the
caller budget.  The dynamic-Huffman validator also accepts malformed
incomplete trees.  Finally, the new decode corpus is declarative only; its
claimed fixed/dynamic and split coverage is not executed.

`moon -C modules/mb-image test png --target all --frozen` passes 15 tests on
wasm, wasm-gc, js, and native, but those tests do not exercise a valid fixed or
dynamic zlib stream through `PngDecoder`.

## Critical Issues

### CR-01: Whole-IDAT and whole-filtered staging bypass the bounded, forward-only budget contract

**File:** `modules/mb-image/png/structural.mbt:522-584`; `modules/mb-image/png/deflate_inflate.mbt:102-114`; `modules/mb-image/png/png.mbt:53-60`

**Issue:** `_png_read_transport` collects every IDAT byte in an ordinary
`Array[Byte]`: each IDAT is first copied into `payload`, then copied again into
`idat`, and finally converted to `Bytes`.  These allocations are neither
charged to nor preflighted against the caller's `Budget`; `max_input_bytes`
only caps their eventual size.  The inflater then accumulates the full
filtered output in another uncharged image-sized `Array` before the raster
writer runs.  Consequently, a legal large compressed stream with little
output can consume up to the input limit (with per-chunk duplication), and a
normal image needs unaccounted compressed plus filtered backing in addition to
the charged `OwnedImage`.  This is precisely the whole-IDAT/whole-filtered
staging prohibited by the phase design and defeats its bounded forward-reader
resource semantics.

**Fix:** Replace `PngTransport.idat` with a stateful private `PngIdatSource`
that yields a byte at a time from consecutive IDAT chunks, verifies each
chunk's CRC as its payload is exhausted, and preserves the chunk-state/input
limit checks.  Make DEFLATE sink-driven and feed each emitted byte directly to
a row-level raster sink over the locally allocated `OwnedImage`.  Retain only
the fixed 32 KiB history plus bounded scanline state; after zlib completion,
advance the source through post-IDAT chunks, IEND, and strict EOF before
constructing `DecodeResult`.

### CR-02: Dynamic DEFLATE accepts malformed incomplete Huffman trees

**File:** `modules/mb-image/png/deflate_huffman.mbt:19-43`

**Issue:** `_png_huffman_new` rejects oversubscribed trees but never rejects a
code space that remains incomplete.  It therefore accepts dynamic literal,
distance, and code-length alphabets whose final occupancy is below the full
code space, including a literal tree with EOB that can decode and finish.  RFC
1951 permits only the narrow one-symbol distance-tree exception; the phase
requires invalid/incomplete trees to be deterministic typed errors.  The
existing `require_eob` check does not establish occupancy.

**Fix:** After counting code lengths, calculate final occupancy at the maximum
bit width and reject a residual code space.  Thread a tree-kind/exception flag
through the builder so only the RFC-permitted single one-bit distance tree is
accepted as incomplete; apply the stricter rule to the code-length and
literal/length alphabets.  Add hostile vectors for each incomplete case.

### CR-03: Claimed fixed/dynamic, split, hostile, and RGBA coverage is not executable evidence

**File:** `fixtures/png/decode-cases.json:5-10`; `scripts/fixtures/Generate-PngDecodeVectors.ps1:7-18`; `modules/mb-image/png/deflate_wbtest.mbt:2-27`; `modules/mb-image/png/png_test.mbt:84-116`

**Issue:** The corpus records labels such as `fixed-filter-suite`,
`dynamic-rgba`, and `idat_splits`, but contains no compressed bytes, PNG
framing, limits/budgets, expected raster data, or typed hostile vectors for
those rows.  The generator only verifies the six identifiers and independently
decompresses the one hard-coded stored stream.  The white-box inflater test
and public decoder test also use only that stored stream.  Thus a regression
that breaks fixed Huffman, dynamic Huffman, IDAT-boundary handling, RGBA, or
the listed hostile forms continues to pass the declared PNG evidence lane,
despite PNG-04/PNG-05 requiring those cases.

**Fix:** Commit literal independently derived zlib/PNG byte vectors and
expected filtered/pixel bytes for stored, fixed, and dynamic streams; execute
each through the public decoder over every-byte and semantic IDAT splits.  Add
RGB and RGBA examples for filters 0-4, plus the declared malformed header,
tree, distance, checksum, truncation, expansion, filter, reader, budget, and
no-result cases.  Have the generator derive only framing/CRC and verify each
accepted zlib payload with a non-production oracle, then generate the MoonBit
test rows consumed by the package tests.

## Warnings

### WR-01: Generated public cases intentionally accept and discard an unexpected error contract

**File:** `modules/mb-image/png/png_test.mbt:274-281`

**Issue:** For every legacy row labeled `capability-unavailable`, the test now
accepts either `InvalidEncoding` or `CapabilityUnavailable` and explicitly
skips its expected context.  This masks unrelated decoding failures (for
example a bad header, tree, or filter error) as a pass, so these rows no longer
reliably detect behavioral regressions.

**Fix:** Replace Phase-20 capability rows with explicit Phase-21 outcomes and
assert the exact category, code, and context for each.  If a legacy structural
case is intentionally no longer valid after decoding begins, give it the
specific new zlib/PNG error rather than a two-code fallback.

---

_Reviewed: 2026-07-20T17:10:34Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: deep_
