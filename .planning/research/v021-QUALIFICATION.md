# v0.21 RGBA16 PNG Decode Qualification

**Requirement:** `RGBA16DEC-04`  
**Researched:** 2026-07-23  
**Confidence:** LOW — required confidence classification for the direct local provider is LOW; claims below are tied to inspectable repository anchors.

## Decision

Qualify the explicit Type-6/16 route with two independent, fixed public PNG wire literals, never with `PngEncoder`, the fixture generator, or generic decoder output:

1. a non-interlaced 2×5 Type-6/16 literal with filter tags 0–4; and
2. a 5×5 Type-6/16 Adam7 literal with all seven passes nonempty.

All source component pairs must have unequal high/low bytes and the four lanes must differ. Explicit tests compare every stored byte at every final coordinate; the same literals prove frozen generic eager/chunk output, hostile no-result behaviour, and the normal four-target package test. This is qualification only: no second parser, staging raster, target-specific fixture, generated explicit oracle, or generic result widening.

## Evidence inspected

| Anchor | Finding | Qualification consequence |
|---|---|---|
| `fixtures/png/decode-cases.json:84,89-101` | Existing `16rgba-filters`, invalid depth/`tRNS`/zlib, and resource cases are generated generic vectors. | Retain as generic regressions; RGBA8 expected pixels cannot prove U16 preservation. |
| `fixtures/png/decode-cases.json:106` | `adam7-rgba16-all-passes` is 5×5 Type-6/16 with exhaustive IDAT splits, but generic high-byte expected output. | Keep transport regression; add a fixed explicit component-byte oracle. |
| `modules/mb-image/png/png_test.mbt:16-183` | Phase 64 has independent Type-4/16 filter/Adam7 literals, component-byte oracles, generic projections, resource boundary. | Mirror the pattern with bpp 8 and four U16 channels. |
| `modules/mb-image/png/stream_decode_test.mbt:403-720` | GrayAlpha16 helpers prove eager/chunk bytes, schedules, budgets, diagnostics, finish transfer, sticky terminals. | Generalize by profile/component count rather than clone a lifecycle. |
| `modules/mb-image/png/stream_decode_wbtest.mbt:274-328` | First-IDAT profile admission validates IHDR, metadata, iCCP, sRGB, Adam7 before allocation. | Add RGBA16 facts and retain no-lifecycle/no-outcome assertions. |
| `modules/mb-image/png/structural.mbt:536-637` | Type-6/16 uses 8 source bytes/pixel; resource helpers charge image, two rows, filtered output and work separately. | Derive explicit limits from packed RGBA16, not generic RGBA8. |

## Independent vectors

### Five-filter non-interlaced vector

Place a complete CRC-valid Type-6/16 2×5 stored-DEFLATE literal in `png_test.mbt`, with rows `None`, `Sub`, `Up`, `Average`, and `Paeth`. Hand author its framing, DEFLATE residuals, Adler-32 and CRCs outside production code. Do not call an encoder or filter helper to make the vector.

```text
wire:    Rhi,Rlo,Ghi,Glo,Bhi,Blo,Ahi,Alo
stored:  Rlo,Rhi,Glo,Ghi,Blo,Bhi,Alo,Ahi
generic: Rhi,Ghi,Bhi,Ahi
```

For every pixel, assert both component-byte indices for all four channels. It must not use equal pairs, symmetric lanes, or only `None`. A source row is 16 bytes and a filtered row is 17; total filtered bytes are 85. Explicit image storage is 80 bytes. These are review sentinels against a Type-4 bpp or generic 4-byte image calculation.

### Seven-pass Adam7 vector

Add a different fixed 5×5 Type-6/16 Adam7 literal. Derive expected final bytes from a documented coordinate formula or separately written row-major table—not encoder/decoder output. Assert all eight stored bytes at each final coordinate, which proves pass-local filtering and final scatter.

Its pass row widths are 8, 8, 16, 8, 24, 16 and 40 bytes. Filtered total is 211; maximum reusable row is 40; explicit image is 200. The established accounting model therefore yields 280 reserved bytes (`200 + 2×40`) and 411 work (`200 + 211`). Verify those values against final implementation; generic Adam7 costs only 100 image bytes and is not an acceptable substitute.

## Qualification matrix

| Concern | Required evidence | Required public observation |
|---|---|---|
| Explicit non-interlaced | Five-filter literal via `PngDecoder::decode_rgba16` | Packed little-endian `rgba16`, top-left, straight alpha, encoded-sRGB identity; all component bytes equal independent `Rlo,Rhi,Glo,Ghi,Blo,Bhi,Alo,Ahi`. |
| Explicit Adam7 | Seven-pass literal via eager selector | Every final coordinate retains all eight bytes; high-byte or pass-order-only checks are insufficient. |
| Chunk fidelity | Both literals via `PngChunkDecoder::new_rgba16` | Empty start then one-byte/ragged schedules; active pushes consume exactly supplied bytes; only `finish()` returns a result; complete output/metadata/budget/diagnostics match fresh eager peer. |
| Frozen generic | Same literals via generic eager/chunk constructors | RGBA8 remains `Rhi,Ghi,Bhi,Ahi`; preserve progress, result, diagnostics, resource remainder, `NeedInput`, and replay semantics. |
| Accepted colour | CRC-valid `sRGB` form | Built-in sRGB metadata and unchanged component bytes. |
| Profile rejection | Wrong depth/type, native-alpha `tRNS`, legacy `gAMA`/`cHRM`, authenticated iCCP | Explicit eager/chunk fails before public result; first-IDAT test proves no lifecycle, no outcome, unchanged budget. |
| Framing hostility | `16rgba-depth-4`, `16rgba-trns` variants, `16rgba-malformed` | Generated suite stays green; add public explicit chunk evidence for native-alpha `tRNS`, legacy metadata and malformed IDAT. |
| Resources | Fresh exact/one-less limits for both literals | Exact success; one-less image/output/work failure is atomic, result-free and sticky under later input. |

## Exact resource and terminal evidence

Use new budget/diagnostics instances for every trial. For the non-interlaced vector prove output 85/84, image 80/79 (`image-bytes`), and work 165/164 (`work`) exact/one-less boundaries. For Adam7 prove exact/one-less values after confirming helper accounting: image 200, output 211, rows 80, work 411. If a documented descriptor charge changes a number, derive it from checked code and record why rather than relax it.

Hostile chunk cases must prove: early `finish()` exposes no image; malformed/profile/metadata input terminates atomically; later push consumes zero and repeated `finish()` replays first terminal without budget/diagnostic mutation; generic Type-6/16 is still accepted as historical RGBA8 even when explicit profile rejects metadata.

## Minimal placement

| File | Qualification responsibility |
|---|---|
| `modules/mb-image/png/png_test.mbt` | Independent vectors, descriptor/component-byte/generic projection, eager limit tests. |
| `modules/mb-image/png/stream_decode_test.mbt` | Parameterized explicit schedule helper, eager/chunk parity, generic compatibility, terminal replay. |
| `modules/mb-image/png/stream_decode_wbtest.mbt` | RGBA16 first-IDAT pre-allocation profile evidence. |
| `fixtures/png/decode-cases.json` and generated vectors | Existing generic corpus only; never the explicit U16 oracle. |

Production changes are justified only if the matrix finds a defect, such as a missing Type-6/16 explicit packed-store branch in normal-row or Adam7 scatter. Generic Type-6/16 high-byte writers remain untouched.

## Final gate

Use focused tests during development, then run the only final qualification command unwrapped and unfiltered in the ordinary tree:

```powershell
moon -C modules/mb-image test png --target all --frozen
```

No copied tree, target-only vector, generated expected output, or quality-script substitute is valid. Record wasm, wasm-gc, js and native outcomes in verification.

## Risks

1. Generated Type-6 vectors prove generic high-byte behaviour, not U16 lane preservation.
2. bpp 4, equal pairs, or only `None` hides filter and component-offset defects.
3. Generic Adam7 Type-6/16 deliberately reads offsets 0,2,4,6 and drops lows; explicit profile needs a profile-specific packed store after shared reconstruction.
4. Generic resource constants use 4 bytes/pixel; explicit RGBA16 uses 8.
5. Eager success alone does not prove accepted counts, withheld result, or sticky terminal state.

## Sources

- `fixtures/png/decode-cases.json:79,84,89-106`
- `modules/mb-image/png/png_test.mbt:16-183`
- `modules/mb-image/png/stream_decode_test.mbt:403-720`
- `modules/mb-image/png/stream_decode_wbtest.mbt:274-328`
- `modules/mb-image/png/stream_decode.mbt:492-553`
- `modules/mb-image/png/raster_decode.mbt:330-475,560-665`
- `modules/mb-image/png/structural.mbt:536-637`
- `.planning/milestones/v0.20-phases/64-grayalpha16-decode-qualification/64-RESEARCH.md`
