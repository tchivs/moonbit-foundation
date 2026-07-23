# v0.26 Architecture Research: Indexed8 Adam7 PNG Encode

**Scope:** Add an explicit Type-3/8 Adam7 encode route for `PngIndexedImage` in
`modules/mb-image/png`, after v0.24 Indexed8 and v0.25 non-interlaced
Indexed1/2/4.  This is an architecture recommendation, not an implementation.

**Confidence:** HIGH for repository seams and regression anchors (direct source
inspection); MEDIUM for the format rule that is already embodied in the
repository's PNG decoder.

## Decision

Add only two additive public selectors, both taking the existing
`PngInterlaceStrategy`:

```moonbit
PngEncoder::encode_indexed8_with_interlace_strategy(
  source, interlace_strategy, writer, limits, budget, diagnostics,
)

PngChunkEncoder::new_indexed8_with_interlace_strategy(
  source, interlace_strategy, limits, budget, diagnostics,
)
```

`PngInterlaceStrategy::None` is valid in the additive selector; `Adam7` is the
new capability.  Keep `PngEncoder::encode_indexed8` and
`PngChunkEncoder::new_indexed8` unchanged as wrappers that explicitly forward
`None`.  This freezes their public signatures and their exact old Type-3/8
non-interlaced bytes, while making Adam7 an explicit opt-in consistent with
the existing GrayAlpha8/16 and RGBA16 selector families.

Do **not** add `Eight` to public `PngIndexedBitDepth`: that enum deliberately
names only the v0.25 low-bit feature and would blur the frozen `Indexed8`
route with a future low-bit Adam7 promise.  Do **not** make `encode_indexed`
or `new_indexed` accept an interlace parameter in v0.26.  Low-bit indexed
Adam7 remains its own later bounded-contract decision.

The new selectors must still force the indexed profile's current fixed
strategy: Type 3, depth 8, Stored DEFLATE, filter None, PLTE, canonical optional
`tRNS`, and no generic `ImageEncoder` widening.  The only selected dimension
is IHDR interlace method (`0` or `1`).

## Why the integration is small

v0.25 already has the correct source and profile plumbing:

| Existing seam | Evidence | v0.26 reuse |
|---|---|---|
| Indexed owner | `PngIndexedImage` stores canonical unpacked indices, palette, and alpha in `png.mbt`; `index_at`, `palette_byte_at`, and `alpha_at` are private accessors. | Keep exactly this source.  Adam7 reads one index at a mapped coordinate; it never repacks or copies the image. |
| Fixed Indexed8 compatibility profile | `PngIndexedWireProfile::Eight`, `.depth`, `.palette_cap`, and `.profile` in `encode.mbt`; `new_with_indexed` forwards to it. | Retain Eight as the single profile source of truth.  Only thread interlace selection beside it. |
| One acknowledged encoder machine | `PngEncodeMachine` owns framing, CRC, Stored zlib, `present`, and `acknowledge` in `stream_encode.mbt`; eager and chunk APIs both create it. | Extend this machine, never create an Adam7 eager encoder or a second chunk machine. |
| Adam7 geometry authority | `_png_adam7_passes(width, height, source_channels, bit_depth)` and `PngAdam7Pass` in `structural.mbt`. | Call with `(width, height, 1UL, 8)` for Indexed8. Its seven pass records define both exact scanline totals and coordinate traversal. |
| Existing Adam7 cursor shape | `_png_adam7_cursor_location`, `_png_adam7_raw_byte`, and `PngFilteredCursor::next` in `encode.mbt` serialize scalar pass-local rows without retaining a pass collection. | Extract/generalize only the *geometry lookup* to accept scalar layout facts, then add the indexed scalar reader. Filter None means no adaptive-row state is needed. |
| Existing Indexed raster emission | `PngEncodeMachine::scanline_byte` in `stream_encode.mbt` emits non-interlaced filter byte `0`, direct 8-bit values, or v0.25 packed low-bit values. | Add an Indexed8/Adam7 branch that emits `0` at each pass-row start and `source.index_at(pass.x + col*pass.dx, pass.y + row*pass.dy)` otherwise. |
| Public decode oracle | `raster_decode.mbt` extracts indexed 1/2/4/8 samples MSB-first in both regular and Adam7 paths and enforces palette bounds. | Decode v0.26 output through public RGB8/RGBA8 APIs after independent raw-raster assertions. |

## Recommended private design

### 1. Generalize pass location, not the encoder

Introduce a geometry-only helper near the current `_png_adam7_cursor_location`,
for example:

```moonbit
fn _png_adam7_cursor_location_for_layout(
  width : UInt64,
  height : UInt64,
  source_channels : UInt64,
  bit_depth : Int,
  index : UInt64,
) -> Result[(PngAdam7Pass, UInt64, UInt64), @error.CoreError]
```

It reuses `_png_adam7_passes` and the current checked `offset + (row_bytes +
1) * height` scan.  The existing ImageView helper becomes a thin `(source.width(),
source.height(), channels, 8, index)` wrapper.  Indexed8 calls the same helper
with `(source.width(), source.height(), 1UL, 8, index)`.  This avoids duplicate
Adam7 math while preserving the sole structural pass authority.

Avoid changing `PngFilteredCursor` to accept a sum type or making
`PngIndexedImage` imitate `ImageView`.  That would couple a fixed Stored/None
indexed path to all adaptive/fixed/dynamic replay mechanisms and increase the
risk surface for no v0.26 benefit.

### 2. Thread interlace through the indexed private APIs

Candidate signature changes:

```moonbit
_png_encode_indexed_preflight_with_profile(
  source, wire_profile, interlace_strategy, limits, budget,
)

PngEncodeMachine::new_with_indexed_profile(
  source, wire_profile, interlace_strategy, limits, budget, diagnostics,
)
```

The retained `new_with_indexed` invokes that constructor with
`PngIndexedWireProfile::Eight` and `PngInterlaceStrategy::None`.  v0.25
`new_indexed` likewise passes `None` for One/Two/Four.  The new Indexed8
selectors pass Eight plus the caller's explicit strategy.

For indexed preflight, retain all v0.25 steps (u32 dimensions, pixel multiply,
palette cap, canonical tRNS length, `PngFrameFacts`, limits, then exactly one
budget charge).  Change only `scanlines`:

- `None`: preserve existing `(width + 1) * height` Type-3/8 arithmetic exactly.
- `Adam7`: sum `checked_mul(pass.row_bytes + 1, pass.height)` for each nonempty
  pass from `_png_adam7_passes(width, height, 1UL, 8)`.

The Stored block count, IDAT size, frame size, selected work, output/work
limits, and one charge must derive from that selected scanline total.  PLTE
length and canonical `tRNS` length remain based on real palette entries; they
do not become seven-pass data and do not expand to 256 entries.

### 3. Extend only `scanline_byte` for the Indexed8 source

When `indexed_source` is present and the profile is Indexed8 with `Adam7`:

1. Resolve `(pass, pass_row, in_row)` through the geometry helper.
2. Emit `0x00` when `in_row == 0`; that resets filter None at every pass row.
3. Otherwise `column = in_row - 1`; read
   `source.index_at(pass.x + column * pass.dx, pass.y + pass_row * pass.dy)`.

The current Stored zlib provider invokes `scanline_byte` one logical byte at a
time and commits its state only in `acknowledge`.  Thus this preserves preview,
CRC, Adler, repeated-present, eager-writer, and chunk-lease semantics without
an output-sized staging buffer.  No cursor collection, pass image, packed
staging image, or copied index raster is needed; the largest extra state is a
few scalar pass coordinates calculated on demand.

## Build order

1. **Lock legacy before touching traversal.** Add/update literal assertion(s)
   for a v0.24 Indexed8 opaque and transparent vector through both old APIs.
   Verify IHDR interlace byte stays `0`, complete bytes/CRCs are unchanged, and
   no source or API signature is altered.
2. **Make Adam7 geometry source-agnostic.** Extract the scalar-layout location
   helper in `encode.mbt`; add white-box boundary coverage for all seven pass
   offsets, zero-sized passes, the final byte, and `width/height` ragged cases.
   This is a semantics-preserving refactor for existing profiles.
3. **Make indexed preflight interlace-aware.** Extend
   `_png_encode_indexed_preflight_with_profile` and machine construction. Add
   interlaced exact scanline/Stored-IDAT/frame/work admission tests before
   public selectors. Keep `Indexed1/2/4` rejected or routed only to None.
4. **Add the scalar Indexed8 Adam7 branch.** Implement the pass-coordinate
   `scanline_byte` case. Test independently inflated seven-pass index rows
   (not an encoder helper) plus PLTE/tRNS chunk order and IHDR `8,3,0,0,1`.
5. **Expose eager and chunk mirrors.** Add only the two selectors above; both
   call the same `new_with_indexed_profile` machine. Add eager/chunk byte
   identity under zero, one-byte, and ragged lease schedules, release failure,
   sticky completion, and atomic admission.
6. **Qualify outward behaviour.** Decode opaque output via `PngDecoder` as
   RGB8 and alpha output as RGBA8; compare every pixel of a non-symmetric
   5×5 (all seven passes nonempty). Run the ordinary PNG package on `wasm`,
   `wasm-gc`, `js`, and `native`.

## Candidate file and symbol ownership

| File | Candidate symbols | Change |
|---|---|---|
| `modules/mb-image/png/png.mbt` | public declarations near `PngInterlaceStrategy` / `PngIndexedBitDepth` | Documentation/API declaration only if required by MoonBit method exposure; do not change `PngIndexedBitDepth`. |
| `modules/mb-image/png/encode.mbt` | `_png_adam7_cursor_location`; `_png_encode_indexed_preflight_with_profile`; `PngEncoder::encode_indexed8` | Extract layout helper, add interlaced Indexed8 preflight, keep the legacy eager wrapper at None, add its opt-in companion. |
| `modules/mb-image/png/stream_encode.mbt` | `PngChunkEncoder::new_indexed8`; `PngEncodeMachine::new_with_indexed_profile`; `PngEncodeMachine::scanline_byte` | Add thin chunk companion; store selected interlace in the existing machine; add scalar indexed Adam7 scanline read. |
| `modules/mb-image/png/structural.mbt` | `_png_adam7_passes`, `PngAdam7Pass` | Reuse unchanged. Do not create a second indexed pass table. |
| `modules/mb-image/png/encode_wbtest.mbt` | indexed frame/preflight tests | Geometry offsets, selected scanlines, frame totals, exact budget/work, no mutation before failure. |
| `modules/mb-image/png/encode_test.mbt` | v0.24 Indexed8 vectors and Adam7 public wire helpers | Frozen non-interlaced bytes; independent seven-pass index-raster oracle; public RGB8/RGBA8 decode. |
| `modules/mb-image/png/stream_encode_test.mbt` | existing `png_stream_indexed_*` hostile helpers | New Adam7 helper reusing the established zero/one/ragged, sentinel, release, and terminal assertions. |

## Evidence required for acceptance

1. **Exact legacy freeze:** existing `encode_indexed8` and `new_indexed8`
   output byte-for-byte the current opaque and tRNS vectors, including IHDR
   interlace `0`, chunk order, CRCs, and Stored IDAT payload.
2. **Independent Adam7 wire proof:** a test-local seven-pass enumerator for a
   non-symmetric 5×5 Indexed8 source produces filter-0 rows in pass order. It
   must not call `_png_adam7_passes`, the new cursor helper, or `scanline_byte`
   to generate its expectation. Assert IHDR is `depth=8`, `colour=3`,
   `compression=0`, `filter=0`, `interlace=1` and extract/inflate IDAT before
   comparing the expected raster.
3. **Palette semantics:** exact PLTE then shortest canonical tRNS ordering;
   opaque output omits tRNS, partial alpha preserves only through the final
   non-opaque entry. Decode to exact palette RGB/RGBA pixels.
4. **Atomic selected layout:** output-byte/work one-short and exact budgets,
   zero pixel/work budget, and ragged 1×N/N×1/5×5 geometry reject or charge
   exactly as preflight specifies—before writer output or chunk lease writes.
5. **One machine proof:** eager and chunk `Adam7` byte identity on fresh
   sources under `[0,1]`, `[1]`, and a ragged schedule; accepted-only totals,
   untouched suffix sentinels, released lease sticky zero-write failure, and
   post-finish zero-write `Finished` all hold.
6. **Four-target ordinary gate:** unfiltered `moon -C modules/mb-image test png
   --target <wasm|wasm-gc|js|native> --frozen` runs after focused tests. Do not
   treat a `-f` command as proof unless the runner actually honours it.

## Risks and guardrails

| Risk | Failure mode | Guardrail |
|---|---|---|
| Reuse the ImageView Adam7 reader directly | `PngIndexedImage` lacks `get_byte`/revision semantics; an adapter risks hidden allocation or model widening. | Share only geometry; read `index_at` directly. |
| Use width-wide non-interlaced row math for Adam7 | IDAT length, output limit, work and Adler boundaries disagree with emitted bytes. | Calculate every selected Adam7 total from `_png_adam7_passes(...,1,8)` before the single charge. |
| Treat pass rows as one continuous row | Filter context or row tags leak across a pass boundary. | Emit a `0` tag for every pass row, using the cursor's `in_row == 0` rule. |
| Broaden v0.25 `new_indexed` | Accidentally promises low-bit Adam7, changes its API, or combines packed traversal with this milestone. | Only additive Indexed8 named selectors; low-bit public selectors stay non-interlaced. |
| Replace legacy wrappers | Existing Indexed8 interlace-0 bytes or API signatures regress. | Wrappers explicitly pass `None`; retain literal byte/CRC compatibility tests. |
| Stage a pass raster or whole image | Violates bounded-memory goals and complicates caller-buffer semantics. | The producer holds only machine scalar state and reads the immutable source per emitted byte. |
| Parity-only tests | Both paths can share the same bad pass traversal. | Require independent raw seven-pass raster and public decode-back in addition to eager/chunk parity. |

## Explicit non-goals

- Indexed1/2/4 Adam7, packed-pass traversal, adaptive filters, Fixed/Dynamic
  compression, quantization/dithering, a generic indexed image model, or FFI.
- Any change to `PngIndexedImage`, its ownership/allocation contract, legacy
  Indexed8 method signatures, or existing non-interlaced emitted bytes.
- Image-sized source/pass/output staging or a separate eager/chunk encoder.

## Source evidence

- `.planning/PROJECT.md`, `.planning/MILESTONES.md`, and
  `.planning/milestones/v0.25-REQUIREMENTS.md`: v0.25 explicitly deferred
  `INDEXADAM7` until packed indexed traversal had a bounded contract; v0.26
  should keep that work limited to Indexed8 rather than silently widen low-bit.
- `modules/mb-image/png/{png,encode,stream_encode,structural,raster_decode}.mbt`:
  current source/profile/machine/traversal and decoder seams.
- `modules/mb-image/png/{encode_test,encode_wbtest,stream_encode_test}.mbt`:
  current Indexed8/low-bit compatibility, exact wire, admission, and hostile
  lease anchors; existing GrayAlpha/RGBA Adam7 evidence establishes the
  additive-selector and seven-pass-oracle pattern.
