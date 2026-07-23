# Architecture Research: v0.19 GrayAlpha8 Adam7 PNG

**Project:** MoonBit Native Foundation
**Milestone:** v0.19 GrayAlpha8 Adam7 PNG
**Researched:** 2026-07-23
**Confidence:** HIGH — derived from the current PNG implementation and the completed RGB/RGBA Adam7 and GrayAlpha16 Adam7 milestones.

## Recommendation

Add GrayAlpha8 Adam7 as two explicit factory pairs that select the already
profile-aware encoder machine. Do not add a new profile, encoder, cursor,
staging buffer, decoder route, or target-specific implementation: the existing
`GrayAlpha8` profile is already complete for Type-4/8 admission and all shared
Adam7 machinery is parameterized by profile, channel count, and interlace
strategy.

The only intended production change is to expose Adam7 at the current
GrayAlpha8 eager and caller-buffered public boundaries, then remove the one
preflight rejection that currently says GrayAlpha8 must be non-interlaced. All
other work belongs in public regression evidence.

```text
legal packed U8 GrayAlpha ImageView
              |
              v
PngEncoder::new_graya8_with_{interlace,all}_strategies
PngChunkEncoder::new_graya8_with_{interlace,all}_strategies
              |
              v
PngEncodeMachine::new_with_profile(GrayAlpha8, ..., Adam7)
              |
              v
shared atomic preflight -> shared Adam7 filtered cursor
              |                    |
              |                    +-> None / Adaptive pass-local filters
              v
Stored / FixedOrStored / DynamicOrFixedOrStored planning and replay
              |
              v
IHDR Type 4, depth 8, interlace 1 -> IDAT -> IEND
              |
              +-> PngDecoder / PngChunkDecoder -> canonical RGBA8 result
```

## Current Component Map

| Component | Existing responsibility | v0.19 integration |
|---|---|---|
| `modules/mb-image/png/png.mbt` | Defines `PngEncodeProfile`, `PngEncoder`, public strategies, and the eager decoder facade. `new_graya8*` currently fixes `PngInterlaceStrategy::None`; `new_graya16*` is the established explicit Adam7 factory shape. | Keep `GrayAlpha8`; add `new_graya8_with_interlace_strategy(...)` and `new_graya8_with_all_strategies(...)`. Existing `new_graya8*` factories must continue to choose `None` exactly. |
| `modules/mb-image/png/stream_encode.mbt` | Defines `PngChunkEncoder` and the one `PngEncodeMachine` used by eager and caller-buffered paths. | Mirror the two eager factories. Each delegates directly to `PngEncodeMachine::new_with_profile(... GrayAlpha8 ..., interlace_strategy, ...)`; do not introduce a chunk-only traversal. |
| `modules/mb-image/png/encode.mbt` | Profile admission, scanline accounting, scalar source reads, adaptive filter selection, DEFLATE planning, and the atomic budget ledger. | Permit `GrayAlpha8 + Adam7`; retain the existing admission arm and route every strategy through the current profile-aware implementation. |
| `modules/mb-image/png/structural.mbt` | Sole Adam7 geometry authority (`PngAdam7Pass` / `_png_adam7_passes`) plus decode limits. | No production change. The encoder obtains the seven pass geometries with `channels = 2`, `bit_depth = 8`; decoder already uses the same geometry. |
| `modules/mb-image/png/raster_decode.mbt` | Reconstructs filters, owns a bounded two-row Adam7 scratch buffer, and scatters pass pixels into the owned decoded image. | No production change. Type-4/8 reaches the existing 2-channel path, which canonicalizes to straight RGBA8. |
| `modules/mb-image/png/stream_decode.mbt` | Implements public, resumable PNG decode over a private byte-fed state machine. | No production change. It maps IHDR colour type 4 to two source channels and hands interlaced input to `PngRasterSink`. |
| `encode_test.mbt` / `stream_encode_test.mbt` | Public eager wire/decode and caller-buffered hostile-schedule evidence. | Own all v0.19 behavior proof: literal pass raster, public decode, all six pairs, zero/one/ragged leases, atomic failures, sticky terminals, frozen legacy vectors, and four-target execution. |

## Public API Shape

Mirror the proven GrayAlpha16 additive surface, substituting the existing
GrayAlpha8 profile:

```text
PngEncoder::new_graya8_with_interlace_strategy(interlace_strategy)
PngEncoder::new_graya8_with_all_strategies(
  compression_strategy, filter_strategy, interlace_strategy)

PngChunkEncoder::new_graya8_with_interlace_strategy(
  source, interlace_strategy, limits, budget, diagnostics)
PngChunkEncoder::new_graya8_with_all_strategies(
  source, compression_strategy, filter_strategy, interlace_strategy,
  limits, budget, diagnostics)
```

The convenience interlace factory fixes Stored/None. The all-strategies factory
is the sole new surface that crosses all three compression selections, both
filter selections, and `None`/`Adam7`. Existing `new_graya8`,
`new_graya8_with_compression_strategy`,
`new_graya8_with_filter_strategy`, and `new_graya8_with_strategies` remain
non-interlaced routes. This preserves both API compatibility and frozen output
bytes for a pre-existing call site.

Do not widen generic `PngEncoder::new_with_interlace_strategy` for this work.
The explicit GrayAlpha8 family keeps profile selection opt-in and matches the
existing API policy for GrayAlpha16.

## Admission and Atomic Preflight

`_png_encode_source(source, PngEncodeProfile::GrayAlpha8)` already admits the
right source contract before reading pixels:

- nonempty packed image;
- 32-bit PNG width and height;
- builtin encoded sRGB metadata, top-left orientation, no opaque metadata;
- `ChannelOrder::GrayAlpha`, U8 components, and `AlphaMode::Straight`;
- tightly packed rows of `width * 2` scalar bytes.

The only GrayAlpha8 interlace blocker is the explicit arm in
`_png_encode_preflight_with_interlace_profile` that rejects every interlace
strategy other than `None`. Remove only that arm. Keep equivalent Gray8 and
Gray16 exclusions intact, and do not alter descriptor admission.

After admission, `_png_encode_preflight_with_filter_layout_idat_limit_profile`
already provides the required one transaction:

1. obtains channel count and checked raster geometry;
2. calls `_png_adam7_passes(width, height, 2, 8)` for Adam7;
3. sums each nonempty `pass.height * (pass.row_bytes + 1)` exactly;
4. performs every strategy's planning traversals and the final replay
   traversal before one selected-work budget charge;
5. checks width, height, pixels, output bytes, and work limits; and
6. only then constructs the output machine.

Therefore descriptor, geometry, output/work, and budget failures remain atomic
for both eager writers and chunk leases. No separate GrayAlpha8 preflight or
staging allocation is warranted.

## Adam7 Traversal, Filtering, and Compression

`_png_adam7_passes` is the sole geometry authority. It stores each pass's
origin, stride, dimensions, and `row_bytes`; both encode and decode use its
seven standard records. For GrayAlpha8, each pass pixel is two source bytes:

```text
PNG row bytes: filter, gray, alpha, gray, alpha, ...
IHDR: bit depth 8, colour type 4, compression method 0,
      filter method 0, interlace method 1
```

`PngFilteredCursor::next` already switches to
`_png_adam7_cursor_location` when the interlace strategy is Adam7. It resolves
the scalar logical position against fresh pass geometry, and its candidate
reader derives the global source coordinates. Adaptive selection calls
`_png_adam7_row_winner` per pass-local row. Its Sub/Up/Average/Paeth predictors
therefore reset on every pass and cannot observe a previous pass's final row.
This is the correct PNG behavior and is already shared by RGB8/RGBA8 and
GrayAlpha16 Adam7.

The same cursor feeds all strategies:

- **Stored:** a filtered match traversal validates the selected byte sequence
  before output, then a match cursor replays it.
- **FixedOrStored:** the preflight traverses the filtered producer for Stored
  and Fixed planning, chooses Fixed only when it is no larger, then replays the
  chosen plan.
- **DynamicOrFixedOrStored:** it additionally derives bounded dynamic
  frequencies and bits, and chooses Dynamic only on a strict complete-PNG win.

`PngEncodeMachine::new_with_profile` already creates `PngFilteredMatchCursor`
for every Adam7 selection in its Stored, Fixed, and Dynamic state branches.
The machine owns the source mutation revision, presents one byte, and advances
only after acknowledgement. GrayAlpha8 uses ordinary U8 source reads, so it
does not need the special U16 component-wire branch; the Adam7 condition itself
selects the required replay cursor for all three plans.

## Decode Contract and Public Schedules

No decoder capability needs to be added. Structural validation already accepts
Type-4 at depth 8 or 16, and the decode machine maps Type-4 to two source
channels. For interlaced input, `PngRasterSink` allocates the output plus two
reusable maximum-width packed rows, resets predictor rows per pass, and scatters
completed pass rows at their Adam7 coordinates. For Type-4/8 it writes the gray
byte to R, G, and B and the alpha byte to A. Both `PngDecoder` and
`PngChunkDecoder` expose that same straight-RGBA8 canonicalization.

Public evidence should use both decode facades where useful, but the milestone
does not change their contracts. The required schedule matrix is on the encoder
side and must use fresh `PngChunkEncoder` instances:

| Schedule | Required assertions |
|---|---|
| Zero-capacity lease | No byte written, no artificial progress, and no mutation of the caller tail. |
| One-byte lease | Exact eager-byte sequence, accepted-only total progress, and no duplicate presentation. |
| Deterministic ragged leases | Exact eager identity across every pass boundary, filter byte, DEFLATE boundary, CRC, and IEND. |
| Post-success pull | `Finished` is sticky; it writes zero bytes and preserves total accepted progress. |
| Replay-mutation path for Fixed/Dynamic | A detected source revision change produces one typed sticky terminal before the next lease changes. |

Pair these with legal sources that exercise all seven passes (a 5×5 or similarly
ragged image) and all six compression/filter combinations. The wire case should
use non-symmetric `(gray, alpha)` values so a channel swap cannot pass by
accident. Inflate the known Stored/None payload in test code and assert the
full pass-order Type-4/8 raster, not merely IHDR and decode output.

## Smallest Integration Plan

1. **Phase 59 — Explicit GrayAlpha8 Adam7 factories**
   - Add the eager/chunk interlace and all-strategy factory pairs.
   - Remove the single GrayAlpha8 Adam7 preflight rejection.
   - Add focused eager and chunk Stored/None pass-profile regressions proving
     Type-4/8 IHDR, full seven-pass raster, and unchanged non-interlaced
     factory bytes.

2. **Phase 60 — Bounded all-strategy streaming semantics**
   - Prove the shared profile-aware cursor, atomic preflight, pass-local
     adaptive filtering, and all six compression/filter selections under Adam7.
   - Prove zero/one/ragged schedules, accepted-only acknowledgement, and sticky
     replay terminals. Production edits are not expected unless tests find a
     composition defect in the already shared machine.

3. **Phase 61 — Portable public interchange evidence**
   - Add literal multipass wire and public RGBA8 decode proof; exercise eager
     and chunk APIs and preserve GrayAlpha8 non-interlaced plus all historical
     PNG vectors.
   - Qualify with the ordinary frozen four-target command:
     `moon -C modules/mb-image test png --target all --frozen`.

This order is intentionally code-first: Phase 59 exposes the missing additive
capability, Phase 60 proves the bounded behavior shared by strategies, and
Phase 61 proves the consumer-visible contract across portable targets. It does
not create release automation, workspace copies, an alternate source tree,
or a second encoder.

## Anti-Patterns

| Avoid | Why | Use instead |
|---|---|---|
| A `GrayAlpha8Adam7` profile or parallel encode machine | It duplicates profile admission, preflight, cursor, replay, and terminal-state logic that already composes. | Existing `GrayAlpha8` plus `PngInterlaceStrategy::Adam7`. |
| Interlace inference from the source descriptor | It silently changes legacy factories and bytes. | Explicit new factories only. |
| Image-sized pass buffers or source staging | It weakens the bounded, caller-buffered design and is not necessary for scalar traversal. | `PngFilteredMatchCursor` and existing pass-local rows. |
| Decoder/model widening | Decoder already accepts Type-4/8 and intentionally returns canonical RGBA8. | Evidence-only coverage of the existing public boundary. |
| Separate target runners or release scripts | The frozen public PNG suite already qualifies all portable targets. | One standard `moon ... --target all --frozen` gate. |

## Verification Anchors

| Concern | Authoritative code/test seam |
|---|---|
| Explicit factory compatibility | `png.mbt`, `stream_encode.mbt`, legacy byte vectors in `encode_test.mbt` and `stream_encode_test.mbt` |
| Profile admission and atomic failure | `_png_encode_source` and `_png_encode_preflight_with_interlace_profile` in `encode.mbt` |
| Adam7 geometry/filter isolation | `_png_adam7_passes`, `_png_adam7_cursor_location`, `_png_adam7_row_winner` |
| All strategy planning/replay | `_png_encode_preflight_with_filter_layout_idat_limit_profile` and `PngEncodeMachine::new_with_profile` |
| Public Type-4 decode behavior | `structural.mbt`, `stream_decode.mbt`, `raster_decode.mbt`, `PngDecoder`/`PngChunkDecoder` tests |
| Portable qualification | `moon -C modules/mb-image test png --target all --frozen` |

## Sources

- Current implementation: `modules/mb-image/png/png.mbt`, `encode.mbt`,
  `stream_encode.mbt`, `structural.mbt`, `raster_decode.mbt`, and
  `stream_decode.mbt` — HIGH confidence.
- Existing public test suites: `modules/mb-image/png/encode_test.mbt` and
  `stream_encode_test.mbt` — HIGH confidence.
- v0.18 decision history in `.planning/milestones/v0.18-*` — HIGH confidence
  for the proven GrayAlpha16 Adam7 factory/evidence shape.
