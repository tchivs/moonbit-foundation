---
phase: 49-portable-gray16-public-evidence
researched: 2026-07-22
status: ready_for_planning
requirements: [GRAY16-03]
files_recommended:
  - modules/mb-image/png/encode_test.mbt
  - modules/mb-image/png/stream_encode_test.mbt
---

# Phase 49 Research: Portable Gray16 Public Evidence

## Recommendation

Add public-evidence tests only in the existing PNG eager and caller-buffered
test files. Reuse `PngEncoder::new_gray16_with_strategies` and
`PngChunkEncoder::new_gray16_with_strategies`; do not change the encoder,
decoder, storage API, public factories, build configuration, scripts, or test
directory layout.

The implementation already provides the required production behavior:

- Phase 48 routes all six `Stored` / `FixedOrStored` /
  `DynamicOrFixedOrStored` × `None` / `Adaptive` pairs through one bounded
  Gray16 path.
- `PngEncodeMachine` freezes the source mutation revision after preflight and
  rejects Fixed/Dynamic drift before a caller lease is written.
- The public decoder deliberately canonicalizes a PNG Gray16 sample to an
  RGB8 pixel using the sample's PNG big-endian high byte. It does not expose a
  U16 decoded image or preserve the low byte in its public output.

That last point makes two evidence layers necessary: inspect inflated PNG wire
scanlines for complete 16-bit preservation, then independently prove the
public decoder's documented high-byte-to-RGB canonicalization.

## Minimal Test Shape

### `modules/mb-image/png/encode_test.mbt`

Add one compact Gray16 public-eager evidence helper and two tests.

1. `png_encode_gray16_public_fidelity_image(endianness)` creates a 3×2 packed
   `ChannelOrder::Gray` / `ComponentType::U16` source with the six
   non-symmetric samples below. Construct the descriptor with tight rows and
   canonical metadata, as `png_encode_gray16_image` already does.

   | Pixel order | PNG wire sample | Little-endian storage writes | Big-endian storage writes |
   | --- | --- | --- | --- |
   | row 0, x 0 | `12 34` | `34`, `12` | `12`, `34` |
   | row 0, x 1 | `ab cd` | `cd`, `ab` | `ab`, `cd` |
   | row 0, x 2 | `00 ff` | `ff`, `00` | `00`, `ff` |
   | row 1, x 0 | `7f 01` | `01`, `7f` | `7f`, `01` |
   | row 1, x 1 | `80 02` | `02`, `80` | `80`, `02` |
   | row 1, x 2 | `fe 10` | `10`, `fe` | `fe`, `10` |

   Write through `set_component_byte`; do not introduce raw backing access or
   a fixture file. The non-symmetric pairs prevent source-endianness reversal
   and high/low-byte collapse from passing accidentally.

2. Add a small test-local PNG IDAT helper for the eager evidence. It should
   walk the already-produced complete PNG chunk sequence, concatenate IDAT
   payload bytes, and feed the package-private bounded `PngInflateState` /
   `accept_to` machinery into an `Array[Byte]`. It must assert a complete
   zlib stream and use a fixture-sized upper bound. This is a test oracle, not
   an encoder buffer or a new runtime utility.

   For `Stored` + `None`, assert the inflated bytes are exactly:

   ```text
   00 12 34 ab cd 00 ff 00 7f 01 80 02 fe 10
   ```

   Here each `00` is the row filter tag. Encode both source endiannesses and
   require identical complete PNG output and identical inflated bytes. Also
   assert IHDR `[24,25,28] == [0x10,0x00,0x00]`.

3. In the same test, decode the eager PNG only through the public
   `ImageDecoder::decode(PngDecoder::new(), ...)`. Assert its descriptor is
   `Rgb` with three U8 channels, then for each input sample assert all three
   RGB channels equal the wire high byte (`12`, `ab`, `00`, `7f`, `80`, `fe`).
   Deliberately do **not** expect low-byte round-trip through the public
   decoder; the decoder contract in `raster_decode.mbt` documents high-byte
   canonicalization without scaling, rounding, or colour management.

4. A second eager public test loops all six explicit strategy/filter pairs on
   the same generated fixture. For each output, assert the Gray16 IHDR fields,
   full public decoder canonicalization, and complete decode. The exact raw
   inflated byte assertion is only required for `Stored` + `None`, because it
   is the unfiltered semantic wire oracle; Adaptive residual bytes and
   Fixed/Dynamic tokenization must not be treated as opaque snapshots.

5. Add a compact frozen-compatibility assertion alongside this evidence (or
   extend the existing `PNG filter strategy eager frozen compatibility vectors`
   test) for the existing one-pixel Gray8, RGB8, and straight-RGBA8 Stored
   bytes. Reuse the literal vectors already frozen in `encode_test.mbt`; do
   not derive expected values from the current encoder.

### `modules/mb-image/png/stream_encode_test.mbt`

Add one local `png_stream_gray16_public_fidelity_image()` with the same 3×2
sample grid and one public caller-buffered evidence test. Keeping this helper
local follows the current eager/chunk test organization and avoids widening a
test API.

For every six strategy/filter combinations:

1. Produce the eager oracle with `PngEncoder::new_gray16_with_strategies`.
2. Create a fresh `PngChunkEncoder::new_gray16_with_strategies` for each
   schedule; never reuse an encoder after a drain.
3. Exercise an empty lease first and require `written == 0`,
   `total_written == 0`, `NeedOutput`, and an unchanged sentinel.
4. Drain independent encoders with `[0UL, 1UL]`, `[1UL]`, and the established
   deterministic ragged schedule
   `[0UL, 8UL, 4UL, 1UL, 13UL, 2UL, 5UL, 3UL, 21UL]`.
5. Require every drain to equal the eager bytes exactly. While draining,
   assert progress is accepted-only (`total_written` advances by `written`),
   the final outcome is `Finished`, and one later sentinel lease receives
   zero bytes and the sticky `Finished` outcome.

This reuses the proven Gray8 hostile-capacity model at
`stream_encode_test.mbt` without creating a second stream driver. Existing
Phase 48 replay-mutation tests remain untouched; Phase 49 only extends the
public capacity matrix and target evidence.

## Four-Target Verification

Run the complete public PNG test package independently after implementation;
do not use native results as a proxy for another target.

```powershell
moon -C modules/mb-image test png --target js --frozen
moon -C modules/mb-image test png --target wasm --frozen
moon -C modules/mb-image test png --target wasm-gc --frozen
moon -C modules/mb-image test png --target native --frozen
```

Run the focused new eager and chunk test names first on native while iterating,
then use the four complete commands as the phase acceptance gate. A target
failure must be diagnosed as portability evidence; do not relax the fixture,
skip a target, or add a target-specific fallback.

## Risks and Guardrails

| Risk | Mitigation |
| --- | --- |
| Public decode loses U16 low bytes by design. | Keep exact wire proof at the inflated scanline layer; assert only high-byte RGB canonicalization at the public decoder layer. |
| An endianness-symmetric source could hide byte-order bugs. | Use both source endiannesses and six non-symmetric samples; require identical PNG and exact `high, low` scanlines. |
| Compression/filter choices change payload representation. | Use Stored/None for exact inflated wire bytes; use all six pairs for public decode and eager/chunk identity, not whole-file snapshots. |
| Zero-capacity handling may be accidentally masked by a drain helper. | Inspect the first empty lease directly, including its sentinel, before invoking drains. |
| Legacy regressions may pass only indirectly. | Keep explicit frozen Gray8/RGB8/RGBA8 vectors in the target-level public evidence. |
| Evidence expands implementation scope. | No new API, encoding feature, decoder feature, script, directory, fixture file, staging buffer, or release automation is allowed. |

## Plan Boundary

The implementation plan should modify exactly:

- `modules/mb-image/png/encode_test.mbt`
- `modules/mb-image/png/stream_encode_test.mbt`

It must not modify production PNG/storage code, `.planning/STATE.md`,
`.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, build tooling, or create
new scripts/directories.
