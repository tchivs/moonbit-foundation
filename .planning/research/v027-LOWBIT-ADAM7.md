# v0.27 Research: Low-Bit Indexed Adam7 PNG Encode

**Scope:** Add the smallest explicit Type-3 Adam7 capability for the existing
unpacked `PngIndexedImage` at bit depths 1, 2, and 4, while preserving the
shipped Type-3/1,/2,/4 non-interlaced and Type-3/8 Adam7 contracts.

**Researched:** 2026-07-24  
**Overall confidence:** HIGH for the repository seams and legacy constraints;
MEDIUM for PNG-format facts independently checked against the current W3C
recommendation.

## Decision

Implement low-bit Adam7 as an additive interlace selector on the existing
selected-depth APIs, not as another encoder or a packed source format.

```moonbit
PngEncoder::encode_indexed_with_interlace_strategy(
  encoder, source, bit_depth, interlace_strategy,
  writer, limits, budget, diagnostics,
)

PngChunkEncoder::new_indexed_with_interlace_strategy(
  source, bit_depth, interlace_strategy, limits, budget, diagnostics,
)
```

`PngInterlaceStrategy::Adam7` is the only new selection. The existing
`encode_indexed` and `new_indexed` must become explicit `None` forwards and
retain their byte-for-byte non-interlaced output. `encode_indexed8`,
`new_indexed8`, and both existing Indexed8 selector APIs remain unchanged.
Keep the source model canonical and unpacked: each source pixel remains one
validated index byte; only the selected pass row is packed while the single
acknowledged machine emits it.

This mirrors the successful v0.26 Indexed8 shape, but low-bit Adam7 is not a
one-line generalization. The present preflight admits Adam7 only for
`PngIndexedWireProfile::Eight`, and `_png_indexed8_adam7_scanline_byte` returns
one source index per pass payload byte. v0.27 must replace those two
Eight-specific decisions with a depth-aware pass fact and a packed-pass byte
provider. Reusing the Indexed8 provider for a low-bit profile would emit one
index per byte, producing wrong IDAT lengths, Adler/CRC coverage, resource
facts, and image data.

## Minimum Viable Contract

### Supported wire profiles

| Source | Selected profile | IHDR depth/type/interlace | Raster route |
|---|---|---|---|
| Existing `PngIndexedImage` | `PngIndexedBitDepth::One` | `01 03 00 00 01` | Adam7 pass-local 1-bit packing |
| Existing `PngIndexedImage` | `PngIndexedBitDepth::Two` | `02 03 00 00 01` | Adam7 pass-local 2-bit packing |
| Existing `PngIndexedImage` | `PngIndexedBitDepth::Four` | `04 03 00 00 01` | Adam7 pass-local 4-bit packing |

All three profiles stay **Stored DEFLATE + filter None**. The frame order stays
`IHDR -> PLTE -> optional canonical tRNS -> IDAT -> IEND`. There is no source
copy, no full pass/image/output staging, and no second eager or chunk state
machine.

### Packed pass-row geometry

Use `_png_adam7_passes(width, height, 1UL, depth)` as the sole geometry source
for both preflight and emission. It supplies the established seven
`(x, y, dx, dy)` origins/strides and computes each pass's own width, height,
and `row_bytes`. Passing `depth`, rather than the hard-coded `8` used by the
Indexed8 path, is mandatory.

For each nonempty pass `p`:

```text
pass_width  = ceil((image_width  - p.x) / p.dx), or 0 when image_width  <= p.x
pass_height = ceil((image_height - p.y) / p.dy), or 0 when image_height <= p.y
row_bytes   = ceil(pass_width * depth / 8)
pass_bytes  = pass_height * (1 + row_bytes)
raw_total   = sum(pass_bytes for nonempty passes)
```

All multiplications, round-up additions, and running sums must use the same
checked arithmetic as current preflight. A filter byte `00` appears before
**every nonempty pass row**. A pass is a reduced image: its row packing restarts
at its own first selected x coordinate. It must never use full-image packed row
boundaries or carry bit state into the next pass/row.

### MSB-first packing and tails

For a payload byte in pass row `r`, initialize `packed = 0`. For each visible
slot `s` in `[0, 8 / depth)`, obtain the canonical source code at:

```text
pass_column = payload_byte_index * (8 / depth) + s
x = p.x + pass_column * p.dx
y = p.y + r * p.dy
```

and place it at `shift = 8 - depth - s * depth`. Do not scale an index as a
grayscale level. Do not read slots where `pass_column >= p.width`. Because the
byte starts at zero, unused low-order bits in the final byte of every pass row
are canonically zero. PNG permits those tail bits to be unspecified, but zero
is required by MNF for deterministic output and independent vector tests.

The first test fixture must be deliberately non-symmetric and make all seven
passes nonempty; its dimensions must also make at least one pass row non-byte
aligned for each depth. A single 5x5 fixture is sufficient for all-seven-pass
coverage, but it does **not** guarantee a 1-bit tail. Add focused odd/narrow
fixtures where needed rather than weakening the seven-pass oracle.

### Palette and transparency remain profile facts

The palette is not resized for Adam7. Before any output or budget mutation,
require actual PLTE entries to be at most 2, 4, or 16 for depth 1, 2, or 4.
The cap applies to `palette_length / 3`, not only to indices observed in the
source. PLTE remains actual-entry-count times three bytes; it is never padded
to `2^depth`.

Continue the current canonical tRNS rule: scan the source alpha table, emit no
tRNS when every entry is `255`, otherwise emit through the last non-opaque
entry. Its length is based on the actual palette table, not a pass and not the
selected capacity. Adam7 changes only the IDAT raster order, never PLTE/tRNS
order, contents, or CRC lifecycle.

## Atomic Preflight and Budget Contract

Extend `_png_encode_indexed_preflight_with_profile` so its Adam7 branch accepts
all four indexed wire profiles. The required ordering is:

1. Validate u32 dimensions, pixel count, selected palette cap, and the finite
   low-bit profile.
2. Build all seven pass facts using the selected depth; sum only nonempty
   `(pass.row_bytes + 1) * pass.height` values with checked arithmetic.
3. Derive Stored block count/IDAT length, `PngFrameFacts`, complete output
   length, and selected work from that Adam7 raw total and actual PLTE/tRNS
   lengths.
4. Apply width, height, pixels, output-byte, and work limits.
5. Make the existing single `budget.charge`, then construct the one active
   `PngEncodeMachine`.

Thus an exact limit passes; a one-less output or work limit, a selected-depth
palette overflow, checked arithmetic failure, or any earlier limit failure
returns before eager writer progress, chunk encoder creation, lease exposure,
or budget mutation. Do not retain Indexed8's full-image `row_bytes` as a proxy:
it is valid for machine fields used by the non-interlaced route, but Adam7
planning and cursor bounds must be driven by the pass sum.

## Recommended Implementation Shape

Keep `PngIndexedWireProfile` private. Add a small shared mapper from the public
`PngIndexedBitDepth` to `One | Two | Four`, then reuse it in both public
low-bit selector families. The non-interlaced wrappers call their new APIs with
`None`; the new APIs call `PngEncodeMachine::new_with_indexed_profile` exactly
once.

Inside `PngEncodeMachine::scanline_byte`, branch on indexed source plus Adam7.
Replace the Eight-only helper with a profile/depth-aware indexed Adam7 helper.
It should locate the requested pass and pass row from the same `_png_adam7_passes`
result used by preflight, yield `00` at each pass-row boundary, and then either:

- return one scalar `index_at` for depth 8 (preserving v0.26 behavior), or
- construct exactly one MSB-first packed byte for depth 1, 2, or 4 using mapped
  pass coordinates and a zero-initialized tail.

This is a bounded replay calculation, not staging: it may recompute the small
seven-pass geometry per requested output byte as the existing Indexed8 helper
does, but it must allocate neither a pass raster nor a packed image. A small
private location/fact helper is worthwhile only if both preflight and the byte
provider consume it; do not fork Adam7 arithmetic into two subtly different
implementations.

## Evidence Required Before Declaring the Feature Shipped

### Eager and private preflight evidence

- For each depth, independently parse a Stored IDAT and compare its inflated
  bytes to a hand-authored seven-pass raw raster. The expected raster must
  contain filter tags, packing, pass order, and tail zeros; it must not call
  production Adam7, packer, row-byte, or preflight helpers.
- Assert IHDR depth/type/compression/filter/interlace, chunk order, PLTE,
  shortest canonical tRNS, every chunk CRC, IDAT length, and IEND.
- Publicly decode opaque output as RGB8 and transparent output as RGBA8, and
  assert every source coordinate's palette RGB and alpha. Include a final tail
  pixel assertion for every selected depth.
- White-box preflight tests must establish selected-depth all-seven-pass raw
  totals/frame/work facts, exact budget charge, exact-limit success, and
  one-less output/work plus cap+one palette atomic failure.

### Chunk and hostile-lifecycle evidence

For every selected depth, use the recommended
`new_indexed_with_interlace_strategy(..., Adam7, ...)` factory and prove:

- zero-capacity, one-byte, and ragged schedules (`[0,1]`, `[1]`, and
  `[0,1,3,2,5]`) equal freshly produced eager bytes;
- `total_written` advances only by accepted bytes, and every unaccepted
  sentinel-filled lease tail stays unchanged;
- a later pull after completion is zero-write `Finished` and leaves its entire
  destination untouched;
- a released first lease creates a zero-write sticky failure which is replayed
  unchanged into a later sentinel-filled lease;
- independently parse the **collected chunk bytes**, not eager bytes, for the
  Type-3 Adam7 frame/raster/CRC oracle and public decode.

Run the ordinary frozen PNG package gate last on `wasm`, `wasm-gc`, `js`, and
`native`. Retain the current Type-3/1,/2,/4 non-interlaced literal vectors and
the v0.26 Indexed8 Adam7 vectors in that package run; byte parity alone is not
an external wire proof.

## Proposed Phases

### Phase 83 — Low-Bit Indexed Adam7 Machine and Eager Contract

**Owns:** profile-aware Adam7 pass facts, exact preflight/admission, scalar
mapped packed-pass emission, additive eager selector, thin chunk selector
construction, and eager/private wire/atomic/legacy tests.

**Exit:** Type-3/1,/2,/4 Adam7 creates correct framed Stored/None PNGs through
the sole machine; all selected-depth frame, work, output, and budget facts are
atomic; old non-interlaced APIs and bytes are frozen.

### Phase 84 — Low-Bit Indexed Adam7 Streaming Qualification

**Owns:** hostile caller-buffer evidence, stream-origin independent parser and
public decode assertions, frozen compatibility execution, and the four-target
package gate. It should modify no encoder architecture.

**Exit:** every selected low-bit Adam7 route is eager-identical under hostile
leases, has sticky completion/failure semantics, has independent chunk-origin
wire evidence, and is portable across the four declared targets.

**Ordering rationale:** geometry, packing, and atomic frame facts must be
authoritative before a caller-buffer API can be qualified. Once Phase 83 makes
the machine correct, Phase 84 is deliberately evidence-only around the existing
`present -> destination.set -> acknowledge` lifecycle.

## Risks and Non-Goals

| Risk | Failure mode | Guardrail |
|---|---|---|
| Hard-code 8-bit pass geometry | Low-bit IDAT/frame/work math and cursor boundaries are wrong. | Call `_png_adam7_passes(..., 1UL, depth)` in both preflight and emission. |
| Pack against global x positions | Pass rows begin in the wrong bit slot or cross a pass-row boundary. | Pack from `pass_column = 0` for every pass row. |
| Dirty tail bits | Byte output becomes nondeterministic despite valid PNG decode. | Start every packed byte at zero and set visible slots only. |
| Apply cap to used codes only | PNG may declare an illegal PLTE count for its bit depth. | Check actual palette entries before all frame/limit/budget work. |
| Shared eager/chunk parity only | A shared raster/framing defect can pass. | Use test-local raw pass vectors, CRC parser, and public decode on chunk-origin bytes. |
| Late failure | Writer/lease/budget observations diverge from atomic contract. | Finish selected-depth pass totals and all limits before the one charge. |
| Generalize beyond scope | Compatibility and test matrix explode before the packed contract is proven. | Keep Stored/None, current source model, and one machine. |

Explicitly exclude adaptive filtering; Fixed/Dynamic indexed compression;
quantization, dithering, scaling, or palette generation; generic image-model
widening; decoder changes; image/pass/output staging; FFI; wrappers; copied
source trees; and release automation. Do not change legacy Type-3/1,/2,/4
non-interlaced bytes, Type-3/8 non-interlaced bytes, or the existing Indexed8
Adam7 bytes/APIs.

## Sources and Confidence

- Repository source and completed phase evidence: `modules/mb-image/png/{png,
  encode, stream_encode, structural, encode_test, encode_wbtest,
  stream_encode_test}.mbt`, v0.25 Phases 79–80, and v0.26 Phases 81–82.
  **HIGH** — direct inspection confirms the current profile, preflight, pass,
  acknowledgement, hostile-lease, and legacy-freeze seams.
- [W3C PNG Specification (Third Edition)](https://www.w3.org/TR/png-3/).
  **MEDIUM** — the research confidence classifier rates the web-search route
  MEDIUM; it confirms Type-3's legal depths, required/capped PLTE, indexed
  MSB-first packing, optional tail bits, tRNS relation, and Adam7's seven
  pass-local raster order.

**Open question:** choose a compact all-seven-pass low-bit fixture set during
Phase 83. This is not an API blocker: the suite needs enough dimensions to
exercise every pass and each selected depth's tail behavior, and exact vector
lengths must be authored by tests rather than predicted by production helpers.
