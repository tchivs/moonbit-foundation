# v0.26 Research: Indexed8 Adam7 PNG Encode — Scope and Pitfalls

**Scope:** Add explicit Adam7 encoding for the existing unpacked `PngIndexedImage`
source at Type-3/8 only. This is **not** indexed low-bit Adam7.

**Researched:** 2026-07-24  
**Confidence:** HIGH for repository seams and acceptance anchors (current source and
tests inspected); MEDIUM for PNG wire compatibility facts (the project already
encodes the corresponding Type-3 and Adam7 contracts).

## Recommendation

Implement one additive Indexed8-only eager selector and one matching
caller-buffered selector. They must route through the current single pending-byte
machine, retaining the Indexed8 contract of Stored DEFLATE and filter None. The
existing `encode_indexed8` and `new_indexed8` APIs must remain explicit
non-interlaced compatibility wrappers whose bytes do not change.

The implementation cannot merely set `interlace_strategy: Adam7` in the indexed
machine. Its `scanline_byte` presently assumes non-interlaced rows, its indexed
preflight counts `(row_bytes + 1) * height`, and the reusable Adam7
`PngFilteredCursor` takes an `ImageView`, whereas the indexed path deliberately
owns a `PngIndexedImage`. Add a small indexed pass traversal (or a private
source-neutral traversal abstraction) that reads `PngIndexedImage::index_at`; do
not stage a converted raster or silently widen `ImageView` with palette semantics.

Suggested public shape, subject to API naming review:

```moonbit
PngEncoder::encode_indexed8_with_interlace_strategy(
  encoder, source, interlace_strategy, writer, limits, budget, diagnostics,
)
PngChunkEncoder::new_indexed8_with_interlace_strategy(
  source, interlace_strategy, limits, budget, diagnostics,
)
```

Both accept `None` and `Adam7`; the frozen wrappers delegate to `None`. Do not
add `Eight` to `PngIndexedBitDepth`: that enum documents the low-bit selected
surface, and extending it would muddle the compatibility boundary.

## Current seams and the traps they create

| Concern | Current code evidence | Failure mode | Required guardrail |
|---|---|---|---|
| Indexed ABI | `PngIndexedImage` is an immutable PNG-only source with an unpacked U8 raster, RGB triples, and one alpha byte per palette entry (`png.mbt`). `encode_indexed8` / `new_indexed8` use fixed Type-3/8 Stored/None output (`encode.mbt`, `stream_encode.mbt`). | Replacing old routes or adding a generic indexed `ImageEncoder` path changes ownership/API and risks frozen bytes. | Add explicit opt-in selectors only. Existing wrappers must still emit IHDR `08 03 00 00 00` and their literal regression bytes must remain identical. |
| Adam7 source mismatch | `PngFilteredCursor` and `_png_adam7_cursor_location` require `@storage.ImageView`; the indexed machine has `source: None` and `indexed_source: Some(source)` (`encode.mbt`, `stream_encode.mbt`). | A superficial reuse either cannot compile, falls back to normal-row indexing, or adds an image-sized copy. | Traverse `PngIndexedImage::index_at(x, y)` directly using the canonical `_png_adam7_passes(width, height, 1, 8)` geometry. Keep the cursor scalar/pending-byte based. |
| Pass geometry | `_png_adam7_passes` is the shared seven-pass authority (`structural.mbt`). The normal indexed preflight instead computes `scanlines = (row_bytes + 1) * height` (`encode.mbt`). | Wrong IDAT length, Adler input, CRC offsets, limits, budget work, or an omitted pass filter byte. | For Adam7 sum `height_pass * (row_bytes_pass + 1)` only for nonempty passes, with checked arithmetic. Use source channels `1`, bit depth `8`; no packed-row math applies. |
| Filtering/reset | Indexed8 is intentionally Stored/None. Other Adam7 profiles use a pass-local cursor and choose a filter tag at each local pass row (`encode.mbt`). | A global row loop may omit a filter byte between passes or inherit a previous pass's predictor state. | Keep filter None: emit exactly one `00` filter tag for every nonempty pass row, none for empty passes. Do not expose Adaptive or Fixed/Dynamic strategies in this milestone. If a generic cursor is touched, explicitly prove that its predictor/winner state resets at every pass boundary. |
| Palette and `tRNS` | `PngFrameFacts` frames `PLTE`, then canonical optional `tRNS`, then `IDAT`; indexed preflight writes `tRNS` through the last non-`FF` alpha (`encode.mbt`). | Interlace code may accidentally change ancillary order, use a 256-entry capacity rather than actual PLTE length, or alter the shortest legal alpha table. | Reuse the current frame/CRC emission. Interlace changes only IDAT scanlines and total frame facts; PLTE is `3 * actual_entries`, and `tRNS` ends at the highest non-opaque entry (or is omitted). |
| Atomic resources | Preflight currently applies every checked size/limit before the single `budget.charge`; chunk construction has no lease until the machine exists (`encode.mbt`, `stream_encode.mbt`). | Budget/work calculated from a noninterlaced raster lets a too-small limit pass, or failure occurs after a writer/lease becomes observable. | Recompute exact Adam7 Stored IDAT length and complete frame total before any charge/output. Test exact acceptance and one-less rejection for both `None` and `Adam7`; rejection returns no result, leaves writer position zero, exposes no chunk encoder/lease, and leaves the encode budget unchanged. |
| Caller-owned leases | `PngChunkEncoder::pull` validates before writes, advances totals only for accepted bytes, preserves pending previews, and has sticky Finished/Failed states (`stream_encode.mbt`). Existing indexed hostile tests already cover zero/one/ragged capacities and released leases. | A second stream or eager-buffer handoff can write past capacity, mutate sentinel tails, report produced rather than accepted bytes, or make completion non-sticky. | Extend the existing indexed hostile-drain/released-lease helpers for Adam7. Each schedule must equal a fresh eager peer byte-for-byte, retain untouched tails, and preserve sticky terminals. |

## Independent all-seven-pass oracle

Use a hand-authored 5×5 Indexed8 source with index `i = x + 5*y`; it makes every
pixel, pass coordinate, and emitted source byte distinguishable. Give all 25
palette entries distinct RGB triples. Include at least one non-opaque alpha and
end with an opaque entry so the test proves canonical shortened `tRNS`, rather
than merely that a table exists.

For that source the all-nonempty Adam7 raw Stored/None IDAT input is the following
36-byte filter-plus-index sequence. It is an independent oracle, not a second
encoder invocation:

```text
pass 1: 00 00
pass 2: 00 04
pass 3: 00 14 18
pass 4: 00 02 00 16
pass 5: 00 0A 0C 0E
pass 6: 00 01 03 00 0B 0D 00 15 17
pass 7: 00 05 06 07 08 09 00 0F 10 11 12 13
```

This proves all seven geometries: `(0,0)`, `(4,0)`, `(0,4)/(4,4)`,
`(2,0)/(2,4)`, `(0,2)/(2,2)/(4,2)`, the three two-pixel rows beginning at
`x=1`, and the two five-pixel rows beginning at `y=1`. It also catches the
especially easy error of putting the first pass rows in normal image order.

The eager test must additionally assert:

- IHDR is width 5, height 5, depth `08`, colour type `03`, compression/filter
  method `00`, and interlace method `01`.
- `IHDR → PLTE → tRNS → IDAT → IEND` ordering and every chunk CRC are correct.
- Decompressed Stored payload equals the literal sequence above; it must not be
  constructed by production pass helpers.
- Public decode expands every one of the 25 coordinates to the expected RGB or
  RGBA palette value. This is needed in addition to raw bytes: raw bytes alone do
  not prove palette expansion, and decode-back alone does not prove pass order.

## Preflight and resource acceptance contract

The key invariant is that normal and Adam7 are separately exact. For `None`, the
current calculation remains `(width + 1) * height` for Indexed8. For Adam7,
derive the same three quantities from the pass sum before planning Stored blocks:

```text
passes = _png_adam7_passes(width, height, 1, 8)
scanlines = Σ ((pass.row_bytes + 1) * pass.height) for nonempty passes
blocks, idat_length = _png_indexed_stored_idat_length(scanlines)
frame = _png_frame_facts(plte_length, canonical_trns_length, idat_length)
selected_work = frame.total_length
```

Every multiplication/addition is checked `UInt64`; neither a normal-raster size
nor an approximate seven-eighths estimate is acceptable. `PngFrameFacts` is also
the sole authority for IDAT and IEND offsets, so a new Adam7-specific framing
calculator would be a drift risk.

Required preflight tests, for **both** `None` and `Adam7`:

1. At the exact computed output/work/budget thresholds, eager construction and
   chunk construction succeed and the result reports the exact final byte count.
2. One less than each relevant output/work threshold rejects before output. The
   eager writer remains at position 0 and no `EncodeResult` is returned.
3. One-less caller budget/limit rejection returns `Err` from chunk construction;
   no `PngChunkEncoder` exists to pull, and a snapshot of the caller budget is
   unchanged.
4. Width, height, and pixel rejections continue to occur before the same single
   charge. Keep the source-construction budget separate from the encode budget so
   the test identifies the encoder's atomicity, not `PngIndexedImage::new`'s
   defensive-copy charge.

## Caller-buffered qualification

Run each case against a fresh eager Adam7 encoding of the same immutable source.
Use the established schedules `[0,1]`, `[1]`, and `[0,1,3,2,5]`.

- `written <= lease.capacity`; `total_written` advances by accepted bytes only.
- A zero-capacity lease returns `NeedOutput`, writes zero bytes, and leaves its
  sentinel byte untouched.
- Every unaccepted byte in a ragged lease remains sentinel-filled.
- Concatenated accepted bytes equal fresh eager bytes exactly, including all
  framing/CRC bytes and the seven-pass IDAT payload.
- After `Finished`, repeated pulls write zero bytes, keep the terminal total, and
  do not change later sentinel-filled leases.
- A released first lease produces a zero-write sticky failure; a later valid
  lease receives the same terminal error and remains untouched.

Unlike mutable `ImageView` Adam7 profiles, `PngIndexedImage` makes a defensive
copy and has no mutation revision. Do not add artificial replay-fingerprint or
revision behavior merely to imitate other profiles; retain the current immutable
indexed ownership contract.

## Recommended acceptance checklist

| Requirement | Concrete proof |
|---|---|
| Explicit Indexed8 Adam7 only | New eager/chunk selectors accept `Adam7`; their `None` route agrees with frozen Indexed8 wrappers. No `PngIndexedBitDepth` or generic image-model widening. |
| Exact Type-3 framing | Literal fixture asserts `08 03 00 00 01`, PLTE then canonical `tRNS`, then IDAT/IEND, and validates all chunk CRCs. |
| Seven-pass raster | The 5×5 independent 36-byte Stored input above is observed after IDAT decompression. Empty-pass behavior is covered separately by a small-dimension case. |
| Palette fidelity | 25-coordinate public decode-back proves RGB and alpha lookup; opaque-palette case proves `tRNS` omission, mixed-alpha case proves the shortest canonical table. |
| Filter boundary | Stored/None output has one `00` tag per nonempty pass row. No `Adaptive`, Fixed, or Dynamic indexed API is introduced. |
| Exact/atomic accounting | Exact and one-less normal/Adam7 output-work-budget tests assert no eager bytes, no chunk result/lease, and no caller-budget delta on rejection. |
| Lease semantics | Zero/one/ragged drains equal eager output; tails, accepted-only totals, released-lease failure, and sticky completion are proven. |
| Portability/regression | Run `moon -C modules/mb-image test png --target all --frozen` serially for `wasm`, `wasm-gc`, `js`, and `native`; retain frozen Indexed8 and low-bit vectors. |

## Explicitly out of scope

- Indexed Type-1/2/4 Adam7, packed-pass tails, or changes to `PngIndexedBitDepth`.
- Quantization, palette generation/deduplication, dithering, or an indexed
  `ImageView` / generic `ImageEncoder` representation.
- Adaptive filters, Fixed/Dynamic DEFLATE strategy selection, or all-strategy
  indexed factories. Existing Indexed8 is deliberately Stored/None.
- A second encoder, full-raster/pass staging, FFI/codec delegation, wrappers,
  copied source trees, target-specific code, release automation, or decoder
  model changes.

## Primary repository anchors

- `modules/mb-image/png/png.mbt` — `PngIndexedImage` ownership, the public
  Indexed8/low-bit types, and the existing interlace strategy type.
- `modules/mb-image/png/encode.mbt` — indexed preflight/frame accounting,
  canonical `tRNS`, and the `ImageView`-only Adam7 filtered cursor.
- `modules/mb-image/png/structural.mbt` — the single Adam7 pass geometry
  authority.
- `modules/mb-image/png/stream_encode.mbt` — machine construction, indexed
  normal-row scanline emission, framed byte output, and lease lifecycle.
- `modules/mb-image/png/encode_test.mbt` and `stream_encode_test.mbt` — existing
  independent Adam7 pass fixtures, indexed CRC/decode tests, and hostile indexed
  lease helpers to extend rather than duplicate.
- `.planning/research/v025-INDEXED-LOW-BIT-ENCODE.md` — the preceding milestone's
  explicit scope guard and Indexed8 framing/ownership decisions.
