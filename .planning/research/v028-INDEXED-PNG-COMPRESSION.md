# v0.28 Research: Indexed PNG Compression Profiles

**Scope:** the next MoonBit-native vertical slice for explicit compression
selection on the existing Type-3 indexed PNG routes.

**Researched:** 2026-07-24  
**Repository confidence:** LOW by the configured `classify-confidence` seam
for provider `codebase` (including `--verified`). The concrete facts below are
nevertheless marked **VERIFIED** only where they were read from the current
working tree; recommendations are explicitly labelled **SUGGESTED**.

## Recommendation

Make v0.28 an **Indexed Fixed-or-Stored PNG** milestone. Add a new explicit
indexed selector that accepts the existing `PngCompressionStrategy`, supports
`Stored` and `FixedOrStored`, and returns the established capability error for
`DynamicOrFixedOrStored` in this milestone. Keep `PngFilterStrategy::None`
fixed. Do not expose indexed adaptive filters, Dynamic DEFLATE, a broader LZ
window, or a second encoder yet.

This is the smallest slice that improves useful Type-3 output: flat and
repetitive palettes can avoid Stored-DEFLATE expansion while callers retain a
deterministic bounded fallback. It also avoids a misleading new enum that
would need an incompatible future expansion for Dynamic. The existing global
strategy enum is already public and has the intended three-stage vocabulary;
the indexed APIs can admit only the documented supported subset.

The recommended milestone goal is:

> Library users can explicitly request deterministic, bounded Fixed-or-Stored
> compression for a non-interlaced `PngIndexedImage` at Type-3/1, /2, /4, or
> /8, without changing any legacy Stored/filter-None indexed byte stream or
> caller-buffered lifecycle. Existing Adam7 routes remain explicit Stored/None
> compatibility baselines.

### Why compression first, not filters

**VERIFIED:** the generic encoder already has complete bounded `Stored`,
`FixedOrStored`, and `DynamicOrFixedOrStored` planning, plus acknowledgement
safe Fixed/Dynamic replay. It is currently tied to `ImageView`-backed
`PngFilteredMatchCursor`; indexed construction bypasses that route and hard
wires `Stored` plus `None`. The same private producer generalisation is needed
for either indexed filters or indexed compression.

**SUGGESTED:** begin by generalising that producer only enough to replay
canonical filter-None indexed scanline bytes through the current 1--4-distance
matcher. This introduces a single independent decision (Stored versus Fixed).
Adaptive filters would add five byte-wise candidates per row, row-winner
accounting, packed-low-bit previous-row semantics, and an interaction matrix
with every compression choice. Dynamic adds another planning and replay pass
on top of the same source abstraction. Neither belongs in the first indexed
compression profile.

The logical order after this milestone is therefore: (1) indexed
Fixed-or-Stored, (2) if demand warrants it, indexed Dynamic strict-win support,
then (3) separately scoped indexed adaptive filtering. Do not bundle (2) or
(3) into v0.28.

## Verified Current Contract

| Area | Finding | Evidence |
|---|---|---|
| Source model | `PngIndexedImage` owns an immutable unpacked U8 index raster, RGB triples, and one alpha value per palette entry. It validates dimensions, index bounds, palette shape/count, then makes a private copy. | `modules/mb-image/png/png.mbt` |
| Wire profiles | Private `PngIndexedWireProfile::{One,Two,Four,Eight}` centralises depth, palette cap, and `PngEncodeProfile`. Public `PngIndexedBitDepth` selects the low-bit three. | `encode.mbt` |
| Existing public APIs | `encode_indexed8[_with_interlace_strategy]`, `encode_indexed[_with_interlace_strategy]`, and chunk counterparts are the public Type-3 seams. Their no-interlace wrappers explicitly forward `None`. | `encode.mbt`, `stream_encode.mbt` |
| Compatibility baseline | All current indexed entry points build `PngEncodeMachine::new_with_indexed_profile`; it fixes `strategy: Stored` and `filter_strategy: None`. | `stream_encode.mbt` |
| Layouts | Indexed non-interlaced 1/2/4/8 and indexed Adam7 1/2/4/8 are already implemented through the sole acknowledged machine. Low-bit pass packing is scalar and zero-tails each pass row. | `encode.mbt`, `stream_encode.mbt`, v0.26/v0.27 archives |
| Framing | `PngFrameFacts` derives `IHDR -> PLTE -> optional canonical tRNS -> IDAT -> IEND` offsets. Indexed preflight uses actual PLTE length and shortest alpha prefix. | `encode.mbt` |
| Atomicity | Indexed preflight checks dimensions, palette capacity, packed/pass scanlines, Stored IDAT/frame lengths, output/work limits, then performs exactly one `budget.charge` before a machine exists. | `encode.mbt` |
| Output lifecycle | Both eager and caller-buffered paths use `present -> destination/writer accepts byte -> acknowledge`; CRC and Adler state advance only on acknowledgement. Chunk failures and terminal results are sticky. | `encode.mbt`, `stream_encode.mbt` |
| Portability | The PNG package declares `+js+wasm+wasm-gc+native`; current indexed tests already cover public decode, CRC/frame parsing, atomic admission, ragged/zero/one-byte leases, released leases, and target gates. | `moon.pkg`, `encode*_test.mbt`, `stream_encode*_test.mbt` |

## Architecture Seams and Required Refactor Boundary

The necessary change is not an API-only switch. The generic compressed path
owns `PngFilteredCursor`/`PngFilteredMatchCursor`, Fixed and Dynamic planners,
and Fixed/Dynamic replay states. Those cursors currently take
`@storage.ImageView`; indexed output instead calls `PngEncodeMachine::scanline_byte`
directly from `PngIndexedImage` and has no match cursor. The generic plans also
currently embed the legacy 57-byte non-palette PNG frame constant, whereas an
indexed winner must use `PngFrameFacts` because PLTE and optional tRNS shift the
complete output size.

**SUGGESTED private shape:** introduce one small private filter-None raw-byte
producer/cursor for indexed output, parameterised by `PngIndexedImage`, wire
profile, and interlace strategy. It must return exactly the same logical
uncompressed scanline byte at any offset as the existing indexed
`PngEncodeMachine::scanline_byte`, without retaining image-sized scanlines,
tokens, compressed bytes, pass rasters, or a caller lease. Reuse it in:

1. Stored traversal/replay accounting;
2. Fixed match planning and exact bit/Adler/fingerprint accounting; and
3. Fixed acknowledgement-safe replay.

Either make `PngFilteredMatchCursor` an internal tagged source cursor or add a
parallel indexed cursor only if the matcher itself remains shared. Do not copy
the 1--4-distance matcher or the Fixed DEFLATE byte emitter. Convert generic
fixed/dynamic plan finalisation to take an already-calculated `PngFrameFacts`
or an ancillary-frame length, rather than reusing `total_length = idat + 57`.
For v0.28, do not invoke the Dynamic planner/emitter; this refactor merely
keeps that later route possible without an API reset.

### Accounting contract

For every explicit indexed `FixedOrStored` request, preflight must produce all
candidate facts before writer progress, chunk construction, lease exposure, or
budget mutation:

1. Existing selected-depth dimensions, palette capacity, non-interlaced or
   Adam7 scanline geometry, PLTE, and canonical tRNS facts.
2. Exact Stored IDAT/frame/work facts (the current compatibility baseline).
3. Exact Fixed bits, zlib/IDAT/frame length, matcher work, and scanline
   fingerprint from a fresh bounded indexed cursor walk.
4. The established policy: choose Fixed when its complete frame length is
   `<=` Stored; otherwise choose Stored. This only affects the new explicit
   opt-in and therefore keeps every old byte vector frozen.
5. Limits and one atomic charge against the selected exact output/work facts.

`PngFrameFacts` must remain the sole owner of PLTE/tRNS/IDAT/IEND offsets; the
machine should continue to own CRC ranges. The Indexed source is immutable, so
Fixed replay should validate its planned raw fingerprint/work at EOB, but it
does not need an `ImageView` mutation-revision check.

## Proposed Public Surface

**SUGGESTED:** add only additive methods and make old methods literal
`Stored` forwards. Keep the `PngEncoder` receiver to preserve the established
style even though indexed methods do not consume its generic image profile.

```moonbit
PngEncoder::encode_indexed8_with_compression_strategy(
  encoder, source, strategy, writer, limits, budget, diagnostics,
)
PngEncoder::encode_indexed_with_compression_strategy(
  encoder, source, bit_depth, strategy, writer, limits, budget, diagnostics,
)
PngChunkEncoder::new_indexed8_with_compression_strategy(
  source, strategy, limits, budget, diagnostics,
)
PngChunkEncoder::new_indexed_with_compression_strategy(
  source, bit_depth, strategy, limits, budget, diagnostics,
)
```

Do **not** add combined compression/filter/interlace selectors in v0.28.
Supporting Fixed-or-Stored for `PngInterlaceStrategy::None` is the minimum
vertical improvement. Leave the existing Adam7 indexed APIs explicitly
Stored/None, byte-frozen, and return a typed capability error if a future
combined selector is accidentally attempted. This prevents the first slice
from multiplying its test matrix by four profile depths times two layouts.

The `DynamicOrFixedOrStored` input to the new compression methods should fail
before planning/budget charge with a stable capability context such as
`indexed-dynamic-compression-unavailable`; do not silently treat it as
FixedOrStored. That makes the method forward-compatible while truthful.

## Required Evidence and Adversarial Tests

### Wire and selection tests

- Independently parse eager bytes for 1, 2, 4, and 8 bit Type-3 non-interlaced
  output. Validate IHDR, PLTE, shortest tRNS, chunk order, CRCs, zlib Adler,
  and raw inflated scanlines. Expectations must not call production planning,
  matcher, packer, or frame helpers.
- Use declared flat/repetitive opaque and partial-alpha palettes that force a
  Fixed win for at least one low-bit and Indexed8 case. Assert Fixed output is
  strictly smaller or equal to Stored and uses a Fixed DEFLATE block. Include a
  literal-heavy case that falls back to byte-identical Stored.
- Verify public RGB8/RGBA8 decode at every source coordinate, including odd
  widths and zero-tailed packed final bytes. Filtering remains `None` in every
  inflated row.
- Freeze all shipped Stored Type-3/1,/2,/4,/8 non-interlaced vectors and every
  current Type-3 Adam7 vector. New `Stored` selector output must equal its old
  corresponding API byte-for-byte.

### Preflight and hostile lifecycle tests

- For both a Fixed winner and Stored fallback, prove exact output/work limits
  pass, one-less output/work fails before writer/lease observation, and the
  budget has not changed after every rejection. Retain selected-depth palette
  overflow and checked-arithmetic rejection coverage.
- White-box the Fixed plan's exact deflate byte count, ancillary-aware complete
  frame length, matcher work and raw fingerprint. At EOB, a mismatched replay
  work/fingerprint must yield a sticky typed failure, never a wrong final
  length or progress count.
- Drain each new route under zero-capacity, one-byte, and ragged schedules;
  concatenate accepted bytes and compare to fresh eager output. Assert
  accepted-only totals, untouched sentinel tails, zero-write `Finished`, and
  released-lease sticky failure replay.
- Independently parse **collected chunk-origin** bytes (not merely eager
  parity), then public-decode the result. Run the ordinary frozen PNG package
  gate on wasm, wasm-gc, js, and native; outline the named target test first to
  ensure a filtered run is not vacuous.

## Milestone Requirements and Phase Boundaries

| ID | Atomic requirement | Phase |
|---|---|---|
| **INDEXCOMPRESS-01** | Users can explicitly choose `Stored` or `FixedOrStored` for non-interlaced Type-3/1,/2,/4,/8 eager and caller-buffered encoding. Existing indexed methods are explicit Stored forwards; Dynamic is rejected as unavailable. | 85 |
| **INDEXCOMPRESS-02** | The selected route reuses one bounded indexed raw-byte/match producer and one acknowledged machine; Fixed is chosen only when its exact complete Type-3 frame is no larger than Stored, otherwise Stored is emitted. No filter beyond None, staging, second encoder, or matcher widening is introduced. | 85 |
| **INDEXCOMPRESS-03** | Preflight computes selected-depth palette/frame/pass facts and exact Stored/Fixed output/work facts before one budget charge; exact limits pass and one-less output/work, palette overflow, Dynamic request, and checked failures are atomic. | 86 |
| **INDEXCOMPRESS-04** | New Fixed-or-Stored output preserves Type-3 framing, PLTE/tRNS canonicalisation, filter-None packed scanlines/tails, Adler/CRC correctness, deterministic eager/chunk parity, and public RGB8/RGBA8 decode. | 86 |
| **INDEXCOMPRESS-05** | Four-target hostile-schedule qualification independently proves chunk-origin wire/DEFLATE selection, immutable compatibility vectors, accepted-only progress, sentinel preservation, sticky terminals, and all frozen indexed paths. | 87 |

### Phase 85 — Indexed Compression Contract and Bounded Producer

Add the explicit selectors, Stored forwarding compatibility tests, explicit
Dynamic rejection, and the private indexed raw-byte/match-cursor abstraction.
It should establish a Fixed plan for non-interlaced indexed bytes but not yet
claim public portable qualification.

### Phase 86 — Ancillary-Aware Fixed Planning and Acknowledged Replay

Integrate exact Fixed-or-Stored candidate selection with `PngFrameFacts`,
preflight, selected work/budget accounting, the existing CRC/Adler machine,
and eager wire/decode evidence. This phase owns one atomic admission path,
not a second indexed encoder.

### Phase 87 — Indexed Compression Qualification

Add hostile caller-buffer tests, independent chunk-origin parser/oracle,
compatibility freezes, declared compression corpus, and four-target proof. No
architecture changes belong here.

## Scope Fences

Excluded from v0.28: indexed Adam7 compression selection (existing Adam7 stays
Stored/None); indexed adaptive filters; Dynamic indexed DEFLATE; generic
indexed model widening or decoder work; a packed public source model;
quantization, palette generation, dithering, scaling; a 32 KiB dictionary or
broader matching; image/pass/output/token staging; FFI, host adapters, copied
source trees, registry publication, release automation, APNG, colour, or
metadata expansion.

## Sources

- **VERIFIED, repository:** `modules/mb-image/png/{png,encode,stream_encode,
  encode_test,encode_wbtest,stream_encode_test,stream_encode_wbtest}.mbt` and
  `modules/mb-image/png/moon.pkg`.
- **VERIFIED, project history:** `.planning/milestones/v0.10-REQUIREMENTS.md`,
  `.planning/milestones/v0.11-REQUIREMENTS.md`,
  `.planning/milestones/v0.27-{REQUIREMENTS,ROADMAP}.md`, and
  `.planning/research/{v0.11-png-dynamic-huffman,v025-INDEXED-LOW-BIT-ENCODE,
  v027-LOWBIT-ADAM7}.md`.

## Open Questions

1. Decide during Phase 85 whether the four proposed `*_with_compression_strategy`
   methods need a follow-up `*_with_compression_and_interlace_strategy` later,
   or whether indexed Adam7 should remain deliberately Stored-only indefinitely.
   This is not a v0.28 blocker.
2. Choose a compact target-neutral indexed corpus that produces both a Fixed
   win and a Stored fallback at all four depths without depending on source
   copies or an external compressor.
3. Re-check the exact selected-work formula after the shared indexed match
   cursor exists; it must include every planning/replay matcher walk exactly
   once and should be specified by tests before public claim language is
   finalised.
