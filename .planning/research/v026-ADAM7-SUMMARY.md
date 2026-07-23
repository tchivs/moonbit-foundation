# v0.26 Research Summary: Indexed8 Adam7 PNG Encode

**Scope:** `modules/mb-image/png` gains explicit Adam7 encoding for the existing
immutable `PngIndexedImage` at PNG Type-3/8 only.

**Confidence:** HIGH for repository seams, preserved contracts, and test anchors;
MEDIUM for the hand-derived 5×5 raw-raster fixture values, which must land as an
independent red test before implementation is accepted.

## Recommended Scope

Add exactly two additive public APIs, using the already-public
`PngInterlaceStrategy`:

```moonbit
PngEncoder::encode_indexed8_with_interlace_strategy(
  source, interlace_strategy, writer, limits, budget, diagnostics,
)
PngChunkEncoder::new_indexed8_with_interlace_strategy(
  source, interlace_strategy, limits, budget, diagnostics,
)
```

`Adam7` is the new opt-in; `None` remains valid. The old
`encode_indexed8`/`new_indexed8` APIs stay unchanged, explicitly forward `None`,
and retain their frozen Type-3/8 non-interlaced bytes. The new route stays
Indexed8, Stored DEFLATE, filter None, PLTE, and canonical optional `tRNS`.

Implement it inside the existing acknowledged `PngEncodeMachine`, not as an
eager buffer or second chunk encoder. Reuse `_png_adam7_passes(width, height,
1UL, 8)` as the only pass geometry authority; an Indexed8 Adam7 byte is a scalar
`PngIndexedImage::index_at(pass.x + col * pass.dx, pass.y + row * pass.dy)`.
Emit one `00` filter byte per nonempty pass row. A geometry-only pass-location
helper may be factored from the current ImageView-specific cursor, but the
indexed source must not be forced into `ImageView`.

## Explicit Exclusions

- Indexed Type-3/1, /2, or /4 Adam7; packed-pass traversal and changes to
  `PngIndexedBitDepth`.
- Adaptive filters; Fixed/Dynamic compression; generic indexed `ImageEncoder`
  or image-model changes; palette generation, quantization, or dithering.
- Whole-image/pass/output staging, a second encoder, FFI, target wrappers,
  copied trees, decoder changes, and release automation.

## Candidate Requirements

| ID | Requirement | Acceptance summary |
|---|---|---|
| **INDEXADAM7-01** | Users can explicitly encode a valid `PngIndexedImage` as Type-3/8 Adam7 through eager and caller-buffered APIs. | New APIs select Adam7; IHDR is `08 03 00 00 01`; both construct the same machine. Legacy wrappers retain `08 03 00 00 00` and unchanged signatures. |
| **INDEXADAM7-02** | Adam7 traversal is bounded, exact, and source-native. | Preflight sums each nonempty `_png_adam7_passes(...,1,8)` row plus its filter byte with checked arithmetic; scalar `index_at` pass reads emit no full-raster staging. |
| **INDEXADAM7-03** | Indexed palette/transparency framing and public fidelity remain correct. | `IHDR → PLTE → optional shortest tRNS → IDAT → IEND`, correct CRCs; opaque omits tRNS; public decode reproduces every palette RGB/RGBA pixel. |
| **INDEXADAM7-04** | Selected layout admission is atomic and exact. | Adam7-specific IDAT/frame/work/output totals drive the one budget charge; exact limits pass, one-less output/work/pixel failures leave writer/lease/budget unchanged. |
| **INDEXADAM7-05** | Caller-buffered Adam7 retains existing lifecycle semantics and compatibility. | Fresh eager/chunk byte equality under zero/one/ragged schedules, sentinel tails, accepted-only totals, released-lease sticky failure, sticky completion, and frozen Indexed8/low-bit vectors. |
| **INDEXADAM7-06** | The route is portable and independently qualified. | Independent seven-pass raw IDAT oracle plus public decode, ordinary PNG package gate on wasm, wasm-gc, js, and native. |

## Suggested Phase Order

1. **Phase 81 — Indexed8 Adam7 machine and eager wire contract**
   - Extract a geometry-only cursor-location helper from the ImageView path.
   - Thread `PngInterlaceStrategy` through indexed preflight and
     `new_with_indexed_profile`; retain `None` wrappers.
   - Compute Adam7 scanlines/frame/work before the sole charge; add scalar
     Indexed8 pass emission in `PngEncodeMachine::scanline_byte`.
   - Deliver `INDEXADAM7-01` through `INDEXADAM7-04` with legacy freezes.

2. **Phase 82 — Indexed8 Adam7 streaming and qualification**
   - Add the thin caller-buffered selector to the completed machine.
   - Reuse Indexed hostile-drain/released-lease helpers and add chunk-origin
     parser/decode evidence.
   - Deliver `INDEXADAM7-05` and `INDEXADAM7-06` with the four-target gate.

**Ordering rationale:** pass geometry and preflight facts must be authoritative
before the stream adapter can expose a valid machine. Once eager framing is
correct, chunk work is intentionally lifecycle qualification rather than another
encoder implementation.

## Critical Risks and Guardrails

| Risk | Guardrail |
|---|---|
| Normal row math used for pass data | Derive scanlines, Stored IDAT length, frame offsets, work, and limits from the checked seven-pass sum. |
| ImageView-only traversal is misapplied | Share geometry only; use immutable `PngIndexedImage::index_at` directly. |
| Missing pass filter tags / wrong pass order | Independent hand-authored 5×5 raster oracle asserts all seven pass rows and their `00` tags after IDAT inflation. |
| Legacy non-interlaced regression | Old Indexed8 wrappers explicitly pass None; retain 89-byte opaque and 112-byte transparent literal vectors plus low-bit regressions. |
| Palette/tRNS/CRC drift | Independently parse every chunk and CRC; assert actual PLTE length and shortest canonical alpha table. |
| A staged or duplicated transport path | Both public routes must create `PngEncodeMachine::new_with_indexed_profile`; preserve `present → write → acknowledge`. |
| Parity hides a shared traversal defect | Require both raw-wire oracle and public RGB8/RGBA8 decode, not only eager/chunk equality. |

## Minimum Acceptance Evidence

- Transparent and opaque non-symmetric 5×5 Indexed8 fixtures; the transparent
  fixture uses distinct palette entries and a shortened canonical `tRNS`.
- Exact IHDR/chunk order/CRC assertions and an independent 36-byte inflated
  Stored/None pass raster oracle for the all-seven-pass fixture. Expected
  preflight anchors: 36 scanlines, one Stored block, 47-byte IDAT, 143-byte
  transparent PNG—confirm by test, never by production helper.
- Public decode validates all 25 coordinates as RGBA8 for transparency and RGB8
  for the opaque counterpart; separate small geometry covers empty Adam7 passes.
- Exact versus one-less output/work/budget admission for `None` and `Adam7`,
  with zero eager writer position and unchanged caller budget on rejection.
- Chunk schedules `[0,1]`, `[1]`, `[0,1,3,2,5]`, with accepted-only progress,
  untouched tails, sticky success, and released-lease sticky failure.
- Final ordinary gate: `moon -C modules/mb-image test png --target all --frozen`.

## Planning Notes

The preferred API spelling above is supported by consistency with existing
explicit Adam7 selector families, but it remains a small public-naming decision.
Diagnostics content should not become an acceptance assertion unless its public
read API is verified; typed errors and atomicity are the current stable contract.

**Sources:** `v026-ADAM7-ARCHITECTURE.md`, `v026-ADAM7-TESTS.md`, and
`v026-ADAM7-PITFALLS.md`; current PNG source/tests and v0.24/v0.25 milestones.
