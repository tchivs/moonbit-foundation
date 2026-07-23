# Phase 77: Indexed PNG Transparency - Research

**Researched:** 2026-07-24
**Domain:** Canonical Type-3/8 PNG `tRNS` emission over the existing eager Indexed8 path
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- Extend `PngIndexedImage` with per-entry alpha while keeping its owning, validated source contract and all opaque Phase 76 bytes unchanged.
- Canonicalize tRNS: omit it when every alpha is 255; otherwise emit bytes through the last non-255 entry, including intermediate opaque values.
- Preserve source validation/ownership and preflight atomicity before writer or budget exposure; alpha count must equal palette count.
- Extend the same private variable framing facts to emit `IHDR → PLTE → tRNS → IDAT → IEND`, with independent chunk order/CRC and public generic RGBA8 decode evidence.
- Scope is eager Indexed8 only. Caller-buffered parity, Indexed low bit depths, Adam7, strategy families, model widening, and quantization remain deferred.

### the agent's Discretion

None recorded.

### Deferred Ideas (OUT OF SCOPE)

None recorded.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| INDEX-03 | Indexed sources with palette alpha emit canonical optional `tRNS` and decode publicly as RGB8 or RGBA8 with exact palette semantics. | Extend the owning Indexed8 source, derive a canonical optional ancillary span in the shared frame facts, emit/acknowledge its CRC in the existing byte machine, and prove opaque RGB8 plus transparent RGBA8 through independent wire and public-decode tests. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`; `.planning/phases/77-indexed-png-transparency/77-CONTEXT.md`] |
</phase_requirements>

## Summary

Phase 76 already provides the exact seam required for this phase: `PngIndexedImage` owns validated index and RGB-palette bytes, `_png_encode_indexed_preflight` calculates a scalar `PngFrameFacts`, and `PngEncodeMachine` emits a byte at a time while checksum state advances only after writer acknowledgement. The current zero-PLTE case deliberately preserves legacy byte positions; the indexed case already shifts IDAT/IEND from its PLTE span. [VERIFIED: codebase: `modules/mb-image/png/png.mbt:201-320`; `modules/mb-image/png/encode.mbt:288-320,2022-2085`; `modules/mb-image/png/stream_encode.mbt:692-723,1428-1468`]

PNG Type 3 defines `tRNS` as zero to 256 one-byte alpha values paired by palette index. A shorter list implies alpha 255 for all remaining entries, so the locked “through the last non-255” rule is both canonical and semantically exact. `tRNS` must follow PLTE and precede IDAT; each chunk has its own CRC over type plus payload. [CITED: https://www.w3.org/TR/png-3/#11tRNS] [CITED: https://www.w3.org/TR/png-3/#5Chunk-layout] [CITED: https://www.w3.org/TR/png-3/#5Chunk-ordering]

The existing generic decoder is already compatible with the intended output: it requires PLTE before Type-3 `tRNS`, accepts no more alpha bytes than palette entries, assigns absent tail values `255`, changes generic output to four channels when transparency is present, and writes palette RGB plus the per-index alpha. Phase 77 is therefore an eager-encoder/source-contract increment, not a decoder redesign. [VERIFIED: codebase: `modules/mb-image/png/stream_decode.mbt:350-439,491-552`; `modules/mb-image/png/raster_decode.mbt:680-711`]

**Primary recommendation:** Keep one owning `PngIndexedImage`, one indexed preflight, and one acknowledged `PngEncodeMachine`; add alpha storage plus an optional `tRNS` frame segment, while leaving the all-255/zero-`tRNS` numeric layout and bytes identical to Phase 76.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Validate and own indexed palette alpha | API / Backend | Database / Storage | The PNG library boundary must reject malformed caller bytes before its owned allocation or later encode admission; the owned source is the persistence boundary within the process. [VERIFIED: codebase: `modules/mb-image/png/png.mbt:223-289`; Phase 77 context] |
| Canonical optional `tRNS` length | API / Backend | — | Canonicality is a deterministic transform of the validated alpha table, not a client/UI decision and not a PNG decoder concern. [CITED: https://www.w3.org/TR/png-3/#11tRNS] [VERIFIED: codebase: Phase 77 context] |
| Chunk layout and byte emission | API / Backend | — | `PngFrameFacts` and `PngEncodeMachine` already own byte offsets, preflight total length, pending-byte delivery, and checksum acknowledgement. [VERIFIED: codebase: `modules/mb-image/png/encode.mbt:288-320`; `modules/mb-image/png/stream_encode.mbt:692-723,1405-1510`] |
| Public RGB8/RGBA8 semantic expansion | API / Backend | — | The generic `PngDecoder` chooses three or four output channels based on transparency and maps indexed palette entries to output pixels. [VERIFIED: codebase: `modules/mb-image/png/stream_decode.mbt:491-552`; `modules/mb-image/png/raster_decode.mbt:680-711`] |
| Wire/CRC and atomicity evidence | API / Backend | — | Package tests can independently parse emitted chunks and observe writer/budget state without changing public runtime architecture. [VERIFIED: codebase: `modules/mb-image/png/encode_test.mbt:917-1052`; `modules/mb-image/png/encode_wbtest.mbt:1070-1128`] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| MoonBit `moon` toolchain | `0.1.20260713` (`75c7e1f`, 2026-07-13) | Compile and execute the portable PNG package tests. | It is the repository's pinned v0.1 toolchain and is installed locally. [VERIFIED: local `moon --version`; `AGENTS.md`] |
| Existing `modules/mb-image/png` implementation | Phase 76 commit `87290a7` (2026-07-24) | Own source validation, bounded preflight, byte machine, PNG CRC, generic decode, and test anchors. | The locked scope extends this exact implementation rather than introducing a package or a parallel encoder. [VERIFIED: git history; Phase 77 context; `modules/mb-image/png/{png,encode,stream_encode,stream_decode,raster_decode}.mbt`] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| W3C PNG Third Edition | Recommendation, 2025-06-24 | Normative `tRNS`, chunk-order, and CRC semantics. | Use to decide wire layout and oracle assertions, not as runtime code. [CITED: https://www.w3.org/TR/png-3/] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Extend `PngIndexedImage` and the existing encoder machine | Create a generic RGBA `ImageView` route | Rejected: palette-index and palette-alpha semantics would be discarded or require prohibited model widening; the locked decision requires the dedicated owning PNG source. [VERIFIED: codebase: Phase 77 context; `modules/mb-image/png/png.mbt:220-222`] |
| Optional canonical `tRNS` | Always emit one full palette-sized `tRNS` | Valid PNG but violates the locked canonical representation and makes all-opaque output differ from frozen Phase 76 bytes. [CITED: https://www.w3.org/TR/png-3/#11tRNS] [VERIFIED: codebase: Phase 77 context] |
| Extend `PngFrameFacts` | Add a separate indexed transparency writer | Rejected: it would duplicate the bounded traversal and acknowledgement protocol that already prevents divergent preflight, framing, or CRC behavior. [VERIFIED: codebase: `modules/mb-image/png/encode.mbt:288-320`; `modules/mb-image/png/stream_encode.mbt:1405-1510`; Phase 77 context] |

**Installation:** No external package installation is required. [VERIFIED: codebase: Phase 77 context; `modules/mb-image/png`]

## Architecture Patterns

### System Architecture Diagram

```text
Caller: indices + RGB palette + alpha table
                 |
                 v
  PngIndexedImage::new / validation
  - checked dimensions and index shape
  - RGB entries: 1..256; indices in range
  - alpha count == palette entries
  - one defensive owned allocation
                 |
                 v
  _png_encode_indexed_preflight
  - derive canonical tRNS length: 0 or last(alpha != 255)+1
  - limits and one budget admission before output
  - PngFrameFacts: IHDR -> PLTE -> [tRNS] -> IDAT -> IEND
                 |
          admission failure ---------> Err, writer position 0, budget unchanged
                 |
                 v
  PngEncodeMachine (one acknowledged byte traversal)
  - present byte -> writer accepts -> acknowledge byte
  - PLTE/tRNS/IDAT CRC states advance only after acceptance
                 |
                 v
             PNG bytes
                 |
                 v
  Generic PngDecoder
  opaque/no tRNS -> RGB8       tRNS present -> RGBA8
```

The optional bracket is the only new branch; the all-opaque branch must take the exact Phase 76 no-`tRNS` layout. [VERIFIED: codebase: Phase 77 context; `modules/mb-image/png/encode.mbt:299-320`; `modules/mb-image/png/stream_encode.mbt:1428-1468`; `modules/mb-image/png/stream_decode.mbt:491-552`]

### Recommended Project Structure

```text
modules/mb-image/png/
├── png.mbt                 # public owning PngIndexedImage constructor and accessors
├── encode.mbt              # indexed preflight and extended scalar PngFrameFacts
├── stream_encode.mbt       # one pending-byte emitter and acknowledged PLTE/tRNS/IDAT CRCs
├── encode_test.mbt         # public wire oracle, decode-back, and atomicity evidence
└── encode_wbtest.mbt       # private frame facts and acknowledgement timing
```

The five files are the exact Phase 76 ownership boundary and remain sufficient for Phase 77. [VERIFIED: codebase: `.planning/phases/76-indexed8-source-eager-plte/76-01-SUMMARY.md`; Phase 77 context]

### Pattern 1: Validated single owned source with contiguous segments

**What:** Keep the source immutable and represent its data in one charged `OwnedBytes` allocation. Extend the stored layout from `[indices | RGB palette]` to `[indices | RGB palette | alpha table]`, with scalar lengths/offsets or accessors that prevent internals from exposing mutable caller input. [VERIFIED: codebase: `modules/mb-image/png/png.mbt:201-320`; Phase 77 context]

**When to use:** Only for the dedicated eager Indexed8 PNG input. Do not widen `ImageView`, `ImageFormat`, or generic encoder APIs. [VERIFIED: codebase: Phase 77 context; `modules/mb-image/png/encode.mbt:2139-2148`]

**Example:**

```moonbit
// Source pattern: existing PngIndexedImage validation, extended with alpha validation.
// The planner should preserve validation-before-ownership ordering.
let palette_entries = rgb_palette.length().to_uint64() / 3UL
if alpha.length().to_uint64() != palette_entries {
  return Err(_png_encode_capability("indexed8-alpha-count"))
}
// validate all indices, then charge/copy indices + RGB palette + alpha once
```

The equality condition is locked; the final allocation arithmetic must include alpha bytes and stay checked. [VERIFIED: codebase: Phase 77 context; `modules/mb-image/png/png.mbt:242-289`]

### Pattern 2: Scalar optional ancillary span in shared frame facts

**What:** Generalize `PngFrameFacts` from its current optional PLTE span to explicit `plte_*`, `trns_*`, `idat_start`, `iend_start`, and `total_length` facts. Derive `tRNS` length before all resource-limit and budget admission checks; make its start/size zero or otherwise unobservable when absent so the opaque branch retains its existing positions. [VERIFIED: codebase: `modules/mb-image/png/encode.mbt:288-320,2022-2085`; Phase 77 context]

**When to use:** For the fixed Type-3/8 eager profile only. The phase must not add caller-buffered state, low-bit indexed packing, Adam7, or compression/filter strategy variants. [VERIFIED: codebase: Phase 77 context]

**Example:**

```moonbit
// Source: canonical Type-3 tRNS semantics from PNG Third Edition.
let mut trns_length = 0UL
for entry = 0UL; entry < palette_entries; entry = entry + 1UL {
  if source.alpha_at(entry).unwrap() != b'\xff' {
    trns_length = entry + 1UL
  }
}
// frame: IHDR -> PLTE -> (tRNS only when trns_length > 0) -> IDAT -> IEND
```

Trailing fully opaque entries are implicitly 255, while opaque values before the last non-opaque entry remain required bytes. [CITED: https://www.w3.org/TR/png-3/#11tRNS] [VERIFIED: codebase: Phase 77 context]

### Pattern 3: Pending-byte acknowledgement owns integrity state

**What:** Seed a dedicated `trns_crc` with the `tRNS` type; emit type/payload/CRC from the frame ranges; update the CRC only when a payload byte is acknowledged. The existing PLTE and IDAT paths demonstrate the required state transition. [VERIFIED: codebase: `modules/mb-image/png/stream_encode.mbt:719-723,900-902,1428-1468,1490-1510`]

**When to use:** Every byte source that crosses a potentially failing writer boundary. Do not advance `trns_crc` during preview (`present`) or before a successful `writer.write`. [VERIFIED: codebase: `modules/mb-image/png/stream_encode.mbt:1469-1510`]

### Anti-Patterns to Avoid

- **Always writing 256 transparency bytes:** It is legal only when no more than the palette count, but it breaks the required canonical payload and opaque byte compatibility. [CITED: https://www.w3.org/TR/png-3/#11tRNS] [VERIFIED: codebase: Phase 77 context]
- **Treating `tRNS` as a PLTE payload extension:** PLTE is RGB triples only; tRNS is a separate ancillary chunk with a separate type, ordering, length, and CRC. [CITED: https://www.w3.org/TR/png-3/#11PLTE] [CITED: https://www.w3.org/TR/png-3/#11tRNS] [CITED: https://www.w3.org/TR/png-3/#5Chunk-layout]
- **Adding alpha after source ownership/preflight:** That permits malformed alpha shape to reach writer/budget observation, violating the locked atomic boundary. [VERIFIED: codebase: Phase 77 context; `modules/mb-image/png/png.mbt:223-289`; `modules/mb-image/png/encode.mbt:2022-2085`]
- **Creating a separate transparency encoder:** It bypasses the shared frame arithmetic and acknowledgement lifecycle, making output-limit, CRC, and legacy-byte divergence likely. [VERIFIED: codebase: `modules/mb-image/png/stream_encode.mbt:692-723,1405-1510`; Phase 77 context]
- **Testing only decode-back:** Decoder success cannot prove chunk ordering, canonical payload length, or CRC. Retain the independent wire walker alongside the public semantic test. [VERIFIED: codebase: `modules/mb-image/png/encode_test.mbt:917-981`; Phase 77 context]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| A second PNG encoder/streamer for transparent Indexed8 | Parallel traversal, preflight, or writer loop | Extend `PngEncodeMachine` and `PngFrameFacts` | Existing code centralizes output-length admission and acknowledgement-based integrity; a duplicate path risks a different atomicity contract. [VERIFIED: codebase: `modules/mb-image/png/encode.mbt:2022-2085`; `modules/mb-image/png/stream_encode.mbt:692-723`] |
| General image-model palette-alpha support | `ImageFormat`/`ImageView` widening | PNG-only `PngIndexedImage` | Indexed palette semantics belong to this wire format and are explicitly excluded from generic model widening. [VERIFIED: codebase: Phase 77 context; `modules/mb-image/png/png.mbt:220-222`] |
| Production CRC implementation | New generic CRC table/helper | Existing `_png_crc_for_type` / `_png_crc_step` pattern | The production encoder already uses the required type-seeded rolling CRC lifecycle. [VERIFIED: codebase: `modules/mb-image/png/stream_encode.mbt:900-902,1490-1510`] |
| Test oracle coupled to production helpers | Calling production CRC/frame/decode helpers to validate framing | Existing test-local `png_indexed_crc32`, slice, and U32 walker pattern | The oracle must fail if production framing/CRC code is consistently wrong; a local test CRC is intentionally independent. [VERIFIED: codebase: `modules/mb-image/png/encode_test.mbt:917-981`] |

**Key insight:** The only intentional local reimplementation is test-side CRC/chunk parsing; it is evidence, not runtime behavior. [VERIFIED: codebase: `modules/mb-image/png/encode_test.mbt:917-981`]

## Common Pitfalls

### Pitfall 1: Confusing optional alpha data with optional alpha semantics

**What goes wrong:** An encoder emits no `tRNS` after accepting a partial alpha table, or trims intermediate `255` entries before a later transparent entry. [VERIFIED: codebase: Phase 77 context]

**Why it happens:** For indexed PNG, tRNS length is not required to equal PLTE length; missing tail entries are implicitly opaque. That makes “drop every opaque byte” incorrect, while “last non-255 plus one” is canonical. [CITED: https://www.w3.org/TR/png-3/#11tRNS]

**How to avoid:** Validate alpha cardinality equal to palette cardinality, scan the complete alpha table during preflight, and use `last(alpha != 255) + 1`, with zero meaning no chunk. [VERIFIED: codebase: Phase 77 context]

**Warning signs:** A test source `[0, 255, 128, 255]` produces payload `[0, 128]` or a tRNS-free PNG; both are wrong. [VERIFIED: codebase: Phase 77 context; PNG semantics cited above]

### Pitfall 2: Preserving opaque output semantically but not byte-for-byte

**What goes wrong:** All alpha values equal 255 but the implementation still adds an empty/opaque tRNS span or shifts IDAT/IEND offsets. [VERIFIED: codebase: Phase 77 context]

**Why it happens:** Frame-fact arithmetic is currently conditioned only on PLTE, and a naive “always reserve tRNS header” calculation can alter legacy indexed output even when no chunk is emitted. [VERIFIED: codebase: `modules/mb-image/png/encode.mbt:299-320`; Phase 77 context]

**How to avoid:** Model `tRNS` as an optional 0-or-(12+payload) span and compare all-255 output against the Phase 76 frozen byte vector as well as zero-`tRNS` frame facts. [VERIFIED: codebase: `modules/mb-image/png/encode_test.mbt:951-981`; `modules/mb-image/png/encode_wbtest.mbt:1070-1120`; Phase 77 context]

**Warning signs:** A formerly 89-byte 2x1/two-entry opaque vector changes size, contains `tRNS`, or moves its IDAT start from 51. [VERIFIED: codebase: `modules/mb-image/png/encode_test.mbt:951-981`; `modules/mb-image/png/encode_wbtest.mbt:1070-1120`]

### Pitfall 3: Advancing tRNS CRC before delivery succeeds

**What goes wrong:** A writer failure/retry makes emitted bytes and integrity state disagree. [VERIFIED: codebase: `modules/mb-image/png/stream_encode.mbt:1469-1510`]

**Why it happens:** Byte generation is separate from acknowledgement, and rolling CRC mutation belongs to acknowledgement rather than preview. [VERIFIED: codebase: `modules/mb-image/png/stream_encode.mbt:1469-1510`]

**How to avoid:** Mirror the PLTE payload range exactly for tRNS: seed with its type in construction, mutate only in `acknowledge`, and test the byte immediately before/after payload acknowledgment through white-box facts. [VERIFIED: codebase: `modules/mb-image/png/stream_encode.mbt:900-902,1428-1510`; `modules/mb-image/png/encode_wbtest.mbt:1070-1120`]

**Warning signs:** Independent `tRNS` CRC fails while PLTE/IDAT CRCs pass, or a white-box preview CRC byte changes before the last payload acknowledgement. [VERIFIED: codebase: `modules/mb-image/png/encode_test.mbt:917-981`; Phase 77 context]

### Pitfall 4: Claiming RGBA8 support without a public generic decode assertion

**What goes wrong:** The wire test passes but the output remains RGB8, loses alpha, or assigns alpha to the wrong palette index. [VERIFIED: codebase: Phase 77 context]

**Why it happens:** Indexed decoding expands RGB from PLTE and alpha from a distinct tRNS table; channel choice is decided before raster population. [VERIFIED: codebase: `modules/mb-image/png/stream_decode.mbt:491-552`; `modules/mb-image/png/raster_decode.mbt:680-711`]

**How to avoid:** Decode emitted bytes through `@codec.ImageDecoder::decode(PngDecoder::new(), ...)`, assert four channels, and inspect RGB plus alpha for indices that exercise an explicit alpha, an intermediate opaque alpha, and an implicit trailing alpha of 255. [VERIFIED: codebase: `modules/mb-image/png/encode_test.mbt:887-915`; `modules/mb-image/png/stream_decode.mbt:491-552`; `modules/mb-image/png/raster_decode.mbt:680-711`]

**Warning signs:** The same emitted PNG decodes as three channels despite having `tRNS`, or a palette entry after the tRNS payload does not receive alpha 255. [VERIFIED: codebase: `modules/mb-image/png/stream_decode.mbt:491-552`; `modules/mb-image/png/raster_decode.mbt:697-702`]

## Code Examples

Verified implementation patterns from the existing package and the PNG specification:

### Canonical Type-3 tRNS payload

```moonbit
// Source: https://www.w3.org/TR/png-3/#11tRNS
// Payload has entries [0..trns_length); entries after it decode as 255.
let mut trns_length = 0UL
for index = 0UL; index < palette_entries; index = index + 1UL {
  if source.alpha_at(index).unwrap() != b'\xff' {
    trns_length = index + 1UL
  }
}
```

The implementation must retain intermediate opaque values because the payload is index-positioned, not a sparse list. [CITED: https://www.w3.org/TR/png-3/#11tRNS] [VERIFIED: codebase: Phase 77 context]

### Frame arithmetic and acknowledged CRC range

```moonbit
// Source pattern: modules/mb-image/png/encode.mbt and stream_encode.mbt.
// Each non-empty ancillary chunk adds 12 bytes of framing plus its payload.
let trns_start = plte_start + 12UL + plte_length
let idat_start = if trns_length == 0UL {
  trns_start
} else {
  trns_start + 12UL + trns_length
}

// In acknowledge(), not in present()/byte_at():
if offset >= frame.trns_start + 8UL &&
  offset < frame.trns_start + 8UL + frame.trns_length {
  self.trns_crc = _png_crc_step(self.trns_crc, accepted)
}
```

The actual code should retain checked additions and the exact existing field/style conventions. [VERIFIED: codebase: `modules/mb-image/png/encode.mbt:299-320`; `modules/mb-image/png/stream_encode.mbt:1428-1510`]

### Independent wire and public RGBA8 proof

```moonbit
// Public semantic path: encode the indexed source, then decode through PngDecoder.
let decoded = @codec.ImageDecoder::decode(
  PngDecoder::new(), reader, options, limits, budget, diagnostics,
).unwrap()
inspect(decoded.image().view().format().channel_count(), content="4")
// Assert RGB and alpha for a transparent entry and a tail entry omitted from tRNS.
```

Keep this separate from a local chunk walker that verifies chunk sequence, `tRNS` payload, and each CRC with `png_indexed_crc32`. [VERIFIED: codebase: `modules/mb-image/png/encode_test.mbt:887-981`; `modules/mb-image/png/stream_decode.mbt:491-552`; `modules/mb-image/png/raster_decode.mbt:697-702`]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Phase 76 Type-3/8 only has `IHDR → PLTE → IDAT → IEND` and decodes as RGB8. | PNG Type-3 supports an optional `tRNS` after PLTE and before IDAT; its presence drives RGBA semantics. | PNG Third Edition Recommendation, 2025-06-24; Phase 77 scope. [CITED: https://www.w3.org/TR/png-3/#11tRNS] | Phase 77 adds one optional ancillary span while opaque Phase 76 bytes remain frozen. [VERIFIED: codebase: Phase 77 context; `modules/mb-image/png/encode_test.mbt:951-981`] |

**Deprecated/outdated:** None for this bounded eager subset. No Phase 76 API is removed; `PngIndexedImage` is extended compatibly under the locked source contract. [VERIFIED: codebase: Phase 77 context]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | None. Source behaviour, wire constraints, and implementation seams were inspected; normative PNG claims are cited to the current W3C Recommendation. | — | — |

## Open Questions

None. The locked context fixes source ownership, alpha cardinality, canonicalization, eager-only scope, output ordering, atomicity, and deferred features. [VERIFIED: codebase: `.planning/phases/77-indexed-png-transparency/77-CONTEXT.md`]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| MoonBit `moon` | Compile and execute the PNG package suite | ✓ | `0.1.20260713` | — [VERIFIED: local `moon --version`] |
| `moonc` / `moonrun` | Toolchain compilation/runtime | ✓ | `v0.10.4+2cc641edf` / `0.1.20260713` | — [VERIFIED: local `moonc -v`; local `moonrun --version`] |

**Missing dependencies with no fallback:** None. [VERIFIED: local version probes]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Codec library has no authentication boundary. [VERIFIED: codebase: `modules/mb-image/png`] |
| V3 Session Management | no | Codec library has no session state. [VERIFIED: codebase: `modules/mb-image/png`] |
| V4 Access Control | no | Codec library has no authorization surface. [VERIFIED: codebase: `modules/mb-image/png`] |
| V5 Input Validation | yes | Require alpha count equal to validated palette count before ownership; retain checked geometry, exact index length/range, codec limits, and one pre-output budget admission. [VERIFIED: codebase: Phase 77 context; `modules/mb-image/png/png.mbt:223-289`; `modules/mb-image/png/encode.mbt:2022-2085`] |
| V6 Cryptography | no | PNG CRC detects corruption but is not a cryptographic control. [CITED: https://www.w3.org/TR/png-3/#5Chunk-layout] |

### Known Threat Patterns for Indexed PNG Transparency

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Alpha table length differs from RGB palette entries | Tampering / Denial of Service | Reject before allocation, source construction, preflight budget charge, or writer output. [VERIFIED: codebase: Phase 77 context; `modules/mb-image/png/png.mbt:242-289`] |
| Overflow/limit failure after layout is partially committed | Denial of Service | Compute optional `tRNS` framing with checked arithmetic before limit checks and the single work charge. [VERIFIED: codebase: `modules/mb-image/png/encode.mbt:299-320,2022-2085`; Phase 77 context] |
| Type-3 tRNS before PLTE or after IDAT | Tampering | Emit only `IHDR → PLTE → tRNS → IDAT → IEND`; independently walk the result. [CITED: https://www.w3.org/TR/png-3/#5Chunk-ordering] [VERIFIED: codebase: Phase 77 context] |
| Incorrect ancillary CRC caused by writer failure timing | Tampering | Add a type-seeded `trns_crc` that changes only on acknowledged payload bytes; validate independently in tests. [CITED: https://www.w3.org/TR/png-3/#5Chunk-layout] [VERIFIED: codebase: `modules/mb-image/png/stream_encode.mbt:1469-1510`; Phase 77 context] |
| Implicit opaque alpha applied incorrectly at decode | Tampering | Publicly verify a palette index after the trimmed payload becomes `255`; existing decoder logic establishes this fallback. [CITED: https://www.w3.org/TR/png-3/#11tRNS] [VERIFIED: codebase: `modules/mb-image/png/raster_decode.mbt:697-702`] |

## Sources

### Primary (HIGH confidence)

- Codebase: `.planning/phases/77-indexed-png-transparency/77-CONTEXT.md` — locked wire, ownership, canonicalization, atomicity, and scope decisions. [VERIFIED: codebase]
- Codebase: `modules/mb-image/png/{png.mbt,encode.mbt,stream_encode.mbt}` — exact existing source/preflight/frame/acknowledgement seams. [VERIFIED: codebase]
- Codebase: `modules/mb-image/png/{stream_decode.mbt,raster_decode.mbt}` — existing Type-3 `tRNS` validation and RGB8/RGBA8 expansion behavior. [VERIFIED: codebase]
- Codebase: `modules/mb-image/png/{encode_test.mbt,encode_wbtest.mbt}` — independent CRC walker, public decode, atomicity, and frame-fact precedent. [VERIFIED: codebase]

### Secondary (MEDIUM confidence)

- [PNG Third Edition, W3C Recommendation (2025-06-24)](https://www.w3.org/TR/png-3/) — Type-3 tRNS payload/tail semantics, PLTE/tRNS/IDAT ordering, and chunk CRC definition. [CITED: https://www.w3.org/TR/png-3/]

### Tertiary (LOW confidence)

- None. [VERIFIED: research session]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — no external runtime dependency or package is introduced; the installed MoonBit toolchain and Phase 76 implementation were inspected. [VERIFIED: local version probes; codebase]
- Architecture: HIGH — current source ownership, frame arithmetic, emitter ranges, acknowledgement lifecycle, and decoder transparency path were inspected directly. [VERIFIED: codebase]
- Pitfalls: HIGH — each pitfall follows from a locked Phase 77 decision, existing byte-machine seam, or current W3C PNG normative rule. [VERIFIED: codebase; CITED: https://www.w3.org/TR/png-3/]

**Research date:** 2026-07-24
**Valid until:** 2026-08-23
