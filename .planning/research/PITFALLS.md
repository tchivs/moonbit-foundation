# Domain Pitfalls: v0.17 GrayAlpha16 PNG Interchange

**Domain:** Packed U16 grayscale-plus-alpha image data and non-interlaced PNG type 4 / bit-depth-16 encoding
**Researched:** 2026-07-23
**Overall confidence:** HIGH for repository-specific risks; MEDIUM for normative PNG claims (verified against the W3C PNG Third Edition).

## Operating Boundary

This milestone is an additive, explicit GrayAlpha16 encoder profile. It must reuse the MoonBit-owned model, checked storage, bounded preflight, filtering, DEFLATE planning, and acknowledgement-safe replay already used by Gray16 and GrayAlpha8. It must not introduce a second encoder, source-copy/staging path, FFI, target branches, release automation, or registry work.

The intended wire contract is one filter byte followed by, for each pixel, `gray_hi gray_lo alpha_hi alpha_lo`. PNG color type 4 is grayscale followed by alpha; it permits bit depth 16, requires 16-bit samples in network order, and uses unassociated (straight) alpha. [PNG specification](https://www.w3.org/TR/png-3/) **MEDIUM**.

## Critical Pitfalls

### 1. U16 source storage is mistaken for PNG wire order

**What goes wrong:** The current `_png_wire_byte` special-case only maps a one-component `Gray16` sample: it computes `position / 2`, always reads channel `0`, then swaps only the two bytes of that component for little-endian storage. Reusing it unchanged for GrayAlpha16 would duplicate gray or omit alpha; treating the packed backing order as wire order would reverse both components on a little-endian source.

**Why it happens:** `channels` currently means the byte stride used by filters and row arithmetic, while U16 component access additionally needs pixel index, component lane, component-byte index, and source endianness.

**Prevention:** Generalize the wire reader around the four-byte pixel layout:

```text
position / 4          -> x
(position % 4) / 2    -> component lane: 0=gray, 1=alpha
position % 2          -> wire byte: 0=MSB, 1=LSB
source endianness     -> storage byte: Big=wire byte; Little=1-wire byte
```

Use that one reader for filter scoring, fixed planning, dynamic frequency/bit planning, and replay. Do not materialize an endian-converted row.

**Detection:** A Stored/None 2x1 vector with non-symmetric, non-equal components (for example Gray=`0x1234`, Alpha=`0xA7C5`, then Gray=`0xD2E1`, Alpha=`0x4C3B`) must expose the exact filter-plus-payload sequence `00 12 34 A7 C5 D2 E1 4C 3B`. Construct the same pixels in both little- and big-endian backing storage and require byte-identical PNG output.

**Phase placement:** Phase 53 model/storage contract adds U16 GrayAlpha construction and component-byte tests; Phase 54 owns the generalized wire reader and both storage orders; Phase 55 keeps the public literal wire oracle.

**Confidence:** HIGH — current `encode.mbt` limits special wire ordering to `PngEncodeProfile::Gray16`; the Gray16 predecessor established this exact failure class.

### 2. Type-4/16-bit profile metadata is only half-upgraded

**What goes wrong:** Adding factories but retaining the existing `GrayAlpha8` profile decisions emits type 4 with depth 8. Adding a new profile but forgetting one IHDR or preflight branch can instead emit depth 16 with type 0/6, calculate a two-byte row stride, or accidentally permit Adam7.

**Prevention:** Add a distinct private `GrayAlpha16` profile and make all profile decisions exhaustive: admission is packed `ChannelOrder::GrayAlpha`, `ComponentType::U16`, straight alpha, canonical metadata, and tight rows; PNG IHDR is `bit_depth=16`, `colour_type=4`, `compression=0`, `filter=0`, `interlace=0`; preflight and public eager/chunk factories force `PngInterlaceStrategy::None`. Keep U8 GrayAlpha on its existing profile.

**Detection:** Test every eager and caller-buffered factory family (Stored, FixedOrStored, DynamicOrFixedOrStored crossed with None and Adaptive) for IHDR bytes `10 04 00 00 00`. Test U8 GrayAlpha, U16 Gray, RGB8, and RGBA8 inputs are rejected by the GrayAlpha16 factory before output, budget charge, or a usable chunk encoder is exposed. Exercise the private profile with Adam7 only to prove defensive rejection.

**Phase placement:** Phase 54; Phase 55 repeats the IHDR assertion through public factories.

**Confidence:** HIGH — current profile selection in `png.mbt`, source admission in `encode.mbt`, and stream constructors are separate seams.

### 3. Gray and alpha lanes or alpha association silently change

**What goes wrong:** Symmetric values or fully opaque alpha make `(gray, alpha)`, `(alpha, gray)`, and premultiplied data appear valid. A generic U16/RGBA helper is especially likely to put alpha after three color lanes or perform a colour conversion that no type-4 profile requested.

**Prevention:** Treat GrayAlpha16 as exactly two packed, straight-alpha components. Extend the current model guard deliberately: it currently rejects every non-U8 GrayAlpha identity, including U16, before allocation. Permit only the specified U16 packed/endian variants; do not widen GrayAlpha to planar, non-sRGB, rotated, premultiplied, or opaque metadata-bearing images. Preserve the existing explicit operation boundaries unless the milestone separately authorizes them.

**Detection:** Model/storage tests must read and write all four component bytes independently, reject byte index `2`, and prove lane `0` is gray and lane `1` alpha. Wire fixtures require unequal gray and alpha values at every byte. A low-alpha source is required to catch accidental premultiplication.

**Phase placement:** Phase 53, before PNG factory work; Phase 55 verifies the consumer-visible lane order.

**Confidence:** HIGH — `validate_gray_alpha_identity` currently hard-codes U8/little-endian and the v0.16 verification intentionally rejects U16 GrayAlpha.

### 4. Decoder canonicalization is claimed as U16 round-trip fidelity

**What goes wrong:** The decoder already accepts type 4/16 and reconstructs rows with a four-byte filter distance, but its public image result is RGBA8: it copies the high gray byte into R/G/B and the high alpha byte into A. A test that compares decode output to all four source bytes will fail for the intended contract; a test that compares only equal high/low values can hide a bad encoder or a lane swap.

**Prevention:** State two separate guarantees. The encoder preserves all U16 bytes on the PNG wire; the existing public decoder canonicalizes to straight RGBA8 `(G_hi, G_hi, G_hi, A_hi)`, discarding low bytes. No decoder model expansion is needed for this encoding milestone.

**Detection:** Assert the complete decompressed Stored/None scanline bytes and separately decode through the public API with distinct low bytes. Require exactly the documented high-byte RGBA pixels. Include at least one filter-Sub or Adaptive row so the decoder's `bpp=4` reconstruction is exercised, not only filter None.

**Phase placement:** Phase 54 adds a focused internal decoder/filter regression only if absent; Phase 55 owns public wire-versus-canonicalization evidence.

**Confidence:** HIGH — `_png_write_16bit_grayscale_alpha_row` already exposes only high bytes while preserving alpha in RGBA8.

### 5. Four-byte row arithmetic bypasses limits, work, or atomic admission

**What goes wrong:** Reusing the GrayAlpha8 `channels=2` result makes `row_bytes=width*2` when GrayAlpha16 needs `width*4`. That underestimates scanline, stored block, IDAT, planner traversal, output, and work sizes; alternatively unguarded `width*4`, `(row_bytes+1)*height`, and plan totals can overflow before limits are compared.

**Prevention:** Define the new profile's filter/pixel byte stride as `4`, even though its semantic sample count is `2`. Keep every derived value inside the existing checked arithmetic ledger, including scanline filter bytes, blocks, stored/fixed/dynamic output, adaptive candidate work, and budget reservation. The full preflight must finish before eager writing or returning a caller-buffered encoder.

**Detection:** For each strategy path, test exact-limit success and one-over failure for dimensions, output, work, and budget. Assert eager writer position remains zero; the chunk factory returns an error rather than an encoder; supplied sentinel bytes remain unchanged. Add a width that would overflow `width*4` or the scanline product on the active integer representation.

**Phase placement:** Phase 54. Phase 55 only rechecks ordinary hostile-capacity parity, not every private arithmetic branch.

**Confidence:** HIGH — the shared preflight currently derives row bytes from its profile `channels`, so a mistaken `2` directly corrupts the resource ledger.

### 6. Caller-buffered replay validates only Gray16 mutations

**What goes wrong:** `PngChunkEncoder::pull` calls a method named `validate_gray16_replay_revision()` before touching the destination. If it does not cover GrayAlpha16, Fixed/Dynamic planning can replay a source mutated after admission and emit bytes inconsistent with its preflight plan; if failure occurs after a destination write, the caller lease contract is broken.

**Prevention:** Generalize the revision check to every profile whose plan rereads U16 source bytes, or explicitly include GrayAlpha16. Validate before `present()` and before `destination.set`; retain the existing sticky `Failed` semantics. Do not add a staging copy as a workaround.

**Detection:** Force Fixed and Dynamic choices with a periodic GrayAlpha16 corpus, drain some framing bytes, mutate one gray low byte and one alpha high byte through a component lease, then require the next pull to return `Failed` with `written=0`, unchanged total, and an untouched sentinel. A later pull must return the same error and still not touch its lease.

**Phase placement:** Phase 54 tests the production replay invariant; Phase 55 tests successful zero/one/ragged schedules and sticky `Finished` using fresh encoders.

**Confidence:** HIGH — v0.15's Gray16 replay regression is a direct precedent, and the current method name is a scope-warning sign.

## Moderate Pitfalls

### 7. Legacy vectors are regenerated from the changed encoder

**What goes wrong:** Recomputing Gray8, Gray16, GrayAlpha8, RGB8, or RGBA8 expectations at test time makes an output regression pass by definition. Extending a match over profiles can also alter legacy IHDR or byte selection without a compile error.

**Prevention:** Preserve literal pre-v0.17 vectors in both eager and chunk test files. The only new literal is a compact GrayAlpha16 Stored/None oracle; Adaptive and compressed routes compare a fresh chunk encoder to its fresh eager peer, rather than to an opaque full-file snapshot.

**Detection:** Retain type/bit-depth and complete-byte assertions for frozen legacy vectors, plus a source-level check that the legacy `new()`/configured routes still select `LegacyRgbOrRgba`.

**Phase placement:** Phase 53 establishes model compatibility controls; Phase 55 owns the full literal legacy matrix.

**Confidence:** HIGH — v0.15/v0.16 public-evidence phases used exactly this safeguard.

### 8. A portable suite is replaced by a native-only or target-conditional test

**What goes wrong:** Endianness and `UInt64`/array behaviour may accidentally pass on native while JS, Wasm, or Wasm-GC diverges. Target-specific fixtures mask the portable contract instead of proving it.

**Prevention:** Keep a single pure-MoonBit test matrix with no target branches, FFI, or source copies. Run the PNG package independently on `js`, `wasm`, `wasm-gc`, and `native` (or the equivalent `--target all` execution), after confirming the named GrayAlpha16 tests are selected.

**Detection:** Record per-target test counts and require the same public type-4/16 wire, decode canonicalization, hostile lease, and legacy-vector tests on all four targets. The current all-target command exceeded this research session's 60-second execution window, so the v0.17 phase must supply fresh qualification rather than relying solely on v0.16's archived 196/196 result.

**Phase placement:** Phase 55.

**Confidence:** HIGH for required coverage from project policy and prior milestones; MEDIUM for a fresh current-suite result (not obtained in this research pass).

## Minor Pitfalls

### 9. Tests prove only IHDR fields, not the sample sequence

**Prevention:** Decompress or otherwise inspect the compact Stored/None scanline payload. Assert filter byte plus all eight data bytes for a two-pixel vector; IHDR `16/4/0` alone cannot reveal swapped components or byte order.

**Phase placement:** Phase 55.

### 10. New generic helpers accidentally broaden operations outside interchange

**Prevention:** Keep model/storage admission and the PNG encoder as the only production scope. Continue to reject unsupported GrayAlpha transforms until a separately planned operation contract exists. No new FFI, external codec, release automation, or generated source copies are an acceptable remedy for GrayAlpha16.

**Phase placement:** Phase 53 scope checks; repeat as a Phase 55 diff review.

## Phase-Specific Warnings

| Recommended phase | Main risk | Required mitigation and exit evidence |
|---|---|---|
| **53 — GrayAlpha16 model contract** | U16 GrayAlpha remains rejected, or model broadening changes existing descriptors/operations | Add explicit packed U16 straight-alpha identity and bounded component-byte access; reject planar/premultiplied/noncanonical variants; retain U8 GrayAlpha and legacy model regressions. |
| **54 — bounded Type-4/16 encoder path** | Four-byte samples are misordered, mis-sized, or replayed after mutation | Add a private GrayAlpha16 profile; centralize endian/lane wire access; emit IHDR `16/4/0`; use stride 4 in all filters/plans; prove atomic limits/budgets and Fixed/Dynamic mutation failures. |
| **55 — public portable interchange evidence** | Correct-looking factories lack a consumer-visible wire/lease/compatibility guarantee | Literal non-symmetric wire vector; documented RGBA8 high-byte canonicalization; eager/chunk identity under zero, one-byte, and ragged leases; untouched tails/sticky terminals; frozen legacy vectors; four-target run. |

## Sources

- `modules/mb-image/model/descriptor.mbt` — current GrayAlpha identity is U8-only and straight-alpha-only. **HIGH (verified local code)**
- `modules/mb-image/png/{png.mbt,encode.mbt,stream_encode.mbt,raster_decode.mbt}` — profile seams, current Gray16-only byte-order mapping, preflight arithmetic, chunk replay, and existing type-4/16 decoder canonicalization. **HIGH (verified local code)**
- `.planning/milestones/v0.15-phases/47-*`, `48-*`, `49-*` — U16 byte-order, atomic-limit, replay, hostile-lease, and four-target precedent. **HIGH (verified archived artifacts)**
- `.planning/milestones/v0.16-phases/50-*`, `51-*`, `52-*` — GrayAlpha model boundary, literal type-4 vectors, and six-pair public-evidence pattern. **HIGH (verified archived artifacts)**
- [W3C PNG Specification, Third Edition](https://www.w3.org/TR/png-3/) — type 4 permits depths 8/16; sample order is gray then alpha; 16-bit samples are MSB-first; alpha is unassociated. **MEDIUM (primary web source; confidence classified via research seam)**

## Research Gaps

- No fresh v0.17 four-target test result is claimed here: the existing all-target PNG command exceeded the session's 60-second command window. The v0.16 archived all-target evidence is a precedent, not v0.17 qualification.
- The public API names for the new descriptor and factories are a planning decision. The interoperability requirements above hold whether they are named `graya16` or another explicitly documented additive family.
