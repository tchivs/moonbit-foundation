# Phase 21: Bounded PNG Decode and DEFLATE - Research

**Researched:** 2026-07-21  
**Domain:** Pure-MoonBit, bounded PNG raster decode and zlib/DEFLATE  
**Confidence:** MEDIUM — repository seams are directly verified; format rules are cited from primary specifications.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Decode all legal zlib/DEFLATE block forms—stored, fixed Huffman,
  and dynamic Huffman—across arbitrary IDAT boundaries for the Phase 20
  non-interlaced 8-bit RGB/RGBA profile.
- **D-02:** Reconstruct all five PNG filters with byte-per-pixel values 3/4
  into existing encoded-sRGB RGB8/straight-RGBA8 image contracts.
- **D-03:** Keep `PngDecoder` and existing eager `ImageDecoder`/`Reader`
  contracts. Internal incremental byte/bit/scanline state is private; no
  public push/pull PNG API is introduced.
- **D-04:** No image becomes visible until zlib header, all DEFLATE blocks,
  Adler-32, exact filtered-byte accounting, IEND, and strict EOF succeed.
  Output storage and budget charging follow existing checked contracts.
- **D-05:** DEFLATE history is bounded to 32 KiB; malformed trees, reserved
  symbols, invalid distances, expansion, checksum, and reader failures are
  deterministic typed errors with no partial result.
- **D-06:** Use small independently derived valid/invalid fixtures, including
  stored/fixed/dynamic blocks, all filter modes, IDAT splits, checksum failures,
  overlap distances, and limits. Run package evidence on js, wasm, wasm-gc,
  and native.

### the agent's Discretion

Choose private package/file layout and test fixture generation that preserve
acyclic dependencies and keep `deflate` reusable internally without exposing a
generic public compression API.

### Deferred Ideas (OUT OF SCOPE)

Canonical PNG encoding and public workflow are Phase 22. FFI, registry,
release automation, compression benchmarks, Adam7, palette, grayscale,
`tRNS`, 16-bit, APNG, and public streaming are out of this phase.
</user_constraints>

## Project Constraints (from AGENTS.md)

- Core algorithms and shared data models must be MoonBit; native is primary, but js, wasm, wasm-gc, and native remain conformant. [VERIFIED: AGENTS.md; modules/mb-image/png/moon.pkg]
- Keep package dependencies acyclic; public packages must not force consumers to import the ecosystem; do not introduce FFI or GUI state. [VERIFIED: AGENTS.md]
- Public operations must be deterministic, SemVer-conscious, and usable without GUI state. [VERIFIED: AGENTS.md]
- Public package behavior needs black-box `*_test.mbt`; internal representation/invariant tests use `*_wbtest.mbt`. [VERIFIED: AGENTS.md]
- New fixture records must carry manifest provenance, SHA-256, license, redistribution status, and expected-use metadata. [VERIFIED: docs/policies/licensing-and-fixtures.md; fixtures/manifest.json]
- The project requests graph-first code discovery, but no graph MCP tool is available and GSD graphify is disabled; this research used targeted repository reads as the documented fallback. [VERIFIED: AGENTS.md; `gsd-tools graphify status`]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| PNG-04 | Decode non-interlaced 8-bit truecolour RGB/RGBA PNG with every filter into portable contracts. | Preserve Phase-20 IHDR gate; stream every uncompressed byte through a private scanline sink that writes RGB8/RGBA8 only after inverse filters 0–4. [VERIFIED: 21-CONTEXT.md; modules/mb-image/storage/owned_image.mbt] |
| PNG-05 | Decode stored/fixed/dynamic zlib/DEFLATE across arbitrary IDAT boundaries and reject malformed/over-budget data deterministically. | One IDAT byte source feeds a bounded zlib inflater with fixed-size history, canonical tree validation, exact output counting, terminal Adler-32, and deferred PNG tail validation. [CITED: https://www.rfc-editor.org/rfc/rfc1950.html; https://www.rfc-editor.org/rfc/rfc1951.html; https://www.w3.org/TR/png-3/] |
</phase_requirements>

## Summary

Phase 21 should replace only the Phase-20 terminal `deflate-and-raster-pending` path with a single-pass pipeline inside the existing `tchivs/mb-image/png` package. The current `_png_validate_transport` consumes and discards each IDAT payload, so it cannot be called before inflation on a forward-only reader. Refactor its chunk machine into an IDAT source that maintains the same signature, chunk-order, CRC, profile, metadata, input-limit, IEND, and strict-EOF rules while yielding the concatenation of consecutive IDAT payload bytes exactly once. [VERIFIED: modules/mb-image/png/structural.mbt; 20-VERIFICATION.md]

Keep all inflater types and helpers package-private in `png`; use source files named for `deflate` rather than a new `tchivs/mb-image/deflate` package. This is the smallest way to make bit I/O, canonical trees, Adler-32, and history reusable by PNG internals without changing the policy-verified public interface, which currently permits only `PngDecoder` and `PngDecoder::new()`. [VERIFIED: policy/foundation.json; scripts/quality/Assert-Policy.ps1]

**Primary recommendation:** Implement a sink-driven, byte-at-a-time zlib inflater over a single logical IDAT source; write reconstructed bytes to a private `OwnedImage`, and return `DecodeResult` only after inflater completion, exact scanline completion, IDAT exhaustion, IEND, and EOF all pass. [CITED: https://www.w3.org/TR/png-3/; VERIFIED: modules/mb-image/codec/contracts.mbt]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| PNG framing, CRC, IDAT continuity, IEND/EOF | Library codec (`png` structural state) | `mb-core/io` | The codec owns PNG semantics; the reader remains forward-only. [VERIFIED: modules/mb-image/png/structural.mbt; modules/mb-core/io/traits.mbt] |
| Logical compressed-byte stream | Private `PngIdatSource` | PNG chunk state | IDAT payloads concatenate regardless of chunk boundaries and must retain per-chunk CRC validation. [CITED: https://www.w3.org/TR/png-3/] |
| zlib header, Adler-32, DEFLATE blocks | Private `png/deflate*.mbt` | IDAT source and scanline sink | zlib encapsulates DEFLATE and its checksum; it is not a public generic compression API. [CITED: https://www.rfc-editor.org/rfc/rfc1950.html; https://www.rfc-editor.org/rfc/rfc1951.html] |
| Filter reconstruction and decoded-pixel writes | Private PNG raster sink | `mb-image/storage` | The sink knows bpp 3/4 and the established RGB8/RGBA8 descriptor contract. [VERIFIED: modules/mb-image/storage/owned_image.mbt; modules/mb-image/storage/views.mbt] |
| Allocation authority and visible success | Existing `ImageDecoder` result boundary | `Budget`, `OwnedImage` | `OwnedImage::new_operation` owns the caller charge; `DecodeResult` is constructed only at terminal success. [VERIFIED: modules/mb-image/codec/contracts.mbt; modules/mb-image/storage/owned_image.mbt] |

## Standard Stack

### Core

| Library / component | Version | Purpose | Why standard |
|---|---:|---|---|
| Existing `tchivs/mb-image/png` package | workspace | Sole public decoder and private structural/raster implementation | Foundation policy already locks its four-target interface to `PngDecoder` only. [VERIFIED: policy/foundation.json; modules/mb-image/png/moon.pkg] |
| `mb-core/checked`, `budget`, `bytes`, `io`, `error` | workspace | Checked geometry, caller authority, bounded owned buffers, reader progress, typed diagnostics | These are the existing codec primitives used by PNG Phase 20 and QOI/PPM. [VERIFIED: modules/mb-image/png/structural.mbt; modules/mb-image/qoi/decode.mbt] |
| `mb-image/model`, `storage`, `metadata`, `mb-color/model`, `mb-color/profile` | workspace | RGB8/RGBA8 descriptor and encoded-sRGB/straight-alpha output | QOI already constructs the required image metadata and storage through these contracts. [VERIFIED: modules/mb-image/qoi/decode.mbt; modules/mb-image/storage/owned_image.mbt] |

### Supporting

| Component | Purpose | When to use |
|---|---|---|
| `scripts/fixtures/Generate-PngDecodeVectors.ps1` (new) | Deterministically renders small declarative decode vectors and validates fixture schema/manifest freshness | For all Phase-21 legal/hostile PNG evidence; never call production inflater code. [ASSUMED] |
| Existing Png quality lane | Policy/interface, fixture freshness, and `--target all` evidence | Extend its exact allowlists and stages after decoder sources/tests are added. [VERIFIED: scripts/quality/Assert-Policy.ps1; scripts/quality/Invoke-MoonQuality.ps1] |

### Alternatives Considered

| Instead of | Could use | Tradeoff |
|---|---|---|
| Private `png/deflate*.mbt` implementation | Separate `mb-image/deflate` package | A separate package would need exported cross-package entry points and expand the policy/public surface; it is unnecessary for this phase. [VERIFIED: policy/foundation.json; ASSUMED: MoonBit package-visibility implication] |
| Streaming IDAT source | Buffer all IDAT payloads then inflate | Whole-IDAT staging defeats the bounded forward-reader design and makes input limits less direct. [VERIFIED: 21-CONTEXT.md; CITED: https://www.w3.org/TR/png-3/] |
| In-house pure MoonBit inflater | FFI zlib/libpng | FFI violates the locked pure-MoonBit, four-target scope. [VERIFIED: AGENTS.md; REQUIREMENTS.md] |

**Installation:** None. This phase installs no external package. [VERIFIED: modules/mb-image/png/moon.pkg]

## Package Legitimacy Audit

Not applicable: Phase 21 adds no external dependency or registry package. [VERIFIED: 21-CONTEXT.md; modules/mb-image/png/moon.pkg]

## Architecture Patterns

### System Architecture Diagram

```text
caller @io.Reader
      |
      v
PngTransport ------------------------------------------------------+
 signature -> IHDR/profile preflight -> consecutive IDAT source    |
     | CRC/type/order/input accounting                              |
     v                                                              |
PngIdatSource (one logical byte stream; no chunk semantic boundary) |
     |                                                              |
     v                                                              |
zlib: CMF/FLG -> DEFLATE blocks -> Adler-32                        |
     |                         |                                   |
     |                         +--> 32 KiB history / canonical trees|
     v                                                              |
PngRasterSink: filter tag -> recon byte -> private OwnedImage      |
     | exact filtered-byte count / bpp=3 or 4                      |
     v                                                              |
IDAT exhaustion -> trailing chunk checks -> empty IEND -> EOF -----+
     |
     v
DecodeResult(image, empty disposition, exact PNG bytes_read)
```

### Recommended Project Structure

```text
modules/mb-image/png/
├── png.mbt                         # existing public PngDecoder; terminal orchestration
├── structural.mbt                  # refactored private PngTransport + PngIdatSource
├── deflate_bits.mbt                # private LSB-first bit reader over PngIdatSource
├── deflate_huffman.mbt             # private canonical-code validation and decode tables
├── deflate_inflate.mbt             # private zlib wrapper, block decoder, 32 KiB history
├── raster_decode.mbt               # private descriptor/metadata, scanline sink, filters
├── generated_vectors*.mbt          # retained Phase-20 structural matrix
├── generated_decode_vectors*.mbt   # new generated Phase-21 matrix, private test helpers
├── png_test.mbt                    # black-box public decoder evidence
├── deflate_wbtest.mbt              # white-box bit/tree/zlib/history invariants
└── raster_decode_wbtest.mbt        # white-box filter/accounting invariants
fixtures/png/
├── cases.json                      # retained structural corpus
└── decode-cases.json               # new declarative legal/hostile raster corpus
scripts/fixtures/
└── Generate-PngDecodeVectors.ps1   # new independent fixture renderer/checker
```

Update `modules/mb-image/png/moon.pkg`, `policy/foundation.json`, `scripts/quality/Assert-Policy.ps1`, and `scripts/quality/Invoke-MoonQuality.ps1` to admit exactly these source/test files and the unchanged public semantic interface. The Png lane's exact source/file allowlists make this mandatory, not optional. [VERIFIED: modules/mb-image/png/moon.pkg; policy/foundation.json; scripts/quality/Invoke-MoonQuality.ps1]

### Pattern 1: Single-pass transport with a terminal handoff

**What:** Split current `_png_validate_transport` into a private transport object that first parses the signature/IHDR and yields IDAT payload bytes, then has a separate terminal method that consumes IDAT CRCs, proves no bytes remain in the logical zlib stream, validates post-IDAT chunks/IEND, and probes EOF. [VERIFIED: modules/mb-image/png/structural.mbt; CITED: https://www.w3.org/TR/png-3/]

**When to use:** Always. The caller has only `&@io.Reader`; a first validation pass cannot be replayed. [VERIFIED: modules/mb-image/codec/contracts.mbt]

**Required sequencing:**

1. Parse signature and first IHDR, run the existing checked profile/resource preflight, and create the private descriptor.
2. Start `PngIdatSource`; it carries chunk length, running CRC, input counter, and structural state, and transparently crosses zero/nonzero consecutive IDAT chunks.
3. Inflate exactly one zlib stream. After its Adler-32, require the logical IDAT source to have no remaining payload bytes (zero-length IDATs may still be consumed); otherwise return `zlib-trailing`.
4. Only then let `PngTransport::finish_after_idat()` apply existing ancillary/semantic policy, require a zero-length IEND, and strict EOF.

### Pattern 2: Sink-driven bounded inflate

**What:** The inflater owns compressed-bit state and a 32,768-byte ring. It forwards every literal or expanded match byte to one raster sink method; the sink rejects byte `filtered_output + 1` before writing. [CITED: https://www.rfc-editor.org/rfc/rfc1951.html; VERIFIED: modules/mb-image/png/structural.mbt]

**When to use:** For stored, fixed, and dynamic blocks. Do not materialize a decompressed intermediate buffer. [VERIFIED: 21-CONTEXT.md]

**Exact private APIs (recommended):**

```moonbit
// All declarations stay package-private; names describe planner targets,
// not new public contracts.
fn _png_decode_zlib(
  source : PngIdatSource,
  sink : PngRasterSink,
) -> Result[Unit, @error.CoreError]

fn PngRasterSink::push(self : PngRasterSink, byte : Byte) -> Result[Unit, @error.CoreError]
fn PngIdatSource::finish_zlib(self : PngIdatSource) -> Result[Unit, @error.CoreError]
fn PngTransport::finish_after_idat(self : PngTransport) -> Result[UInt64, @error.CoreError]
```

The signature is a project-pattern recommendation rather than copied MoonBit source; keep it private and adapt it to the compiler's ownership checks. [ASSUMED]

### Pattern 3: Canonical Huffman validation before decoding symbols

**What:** Build canonical codes from declared code lengths, then decode using a bounded trie/table. For each alphabet, count lengths, calculate `next_code`, reject lengths above 15 (7 for code-length alphabet), reject over-subscribed code spaces, and reject an invalid/incomplete tree except the RFC-permitted one-symbol distance cases. Require literal/length symbol 256, reject literal/length symbols 286–287 and distance symbols 30–31 when encountered. [CITED: https://www.rfc-editor.org/rfc/rfc1951.html]

**When to use:** Fixed trees use generated fixed lengths and the same builder; dynamic trees use HLIT/HDIST/HCLEN plus repeat expansion. This prevents divergent fixed/dynamic semantics. [CITED: https://www.rfc-editor.org/rfc/rfc1951.html]

**Dynamic-tree limits:** allocate lengths for at most 286 literal/length and 32 distance entries; decode code-length entries in RFC order; reject code 16 before a prior length and any repeat whose total exceeds `HLIT + HDIST + 258`. Code-length repeats cross the literal/distance boundary as one sequence. [CITED: https://www.rfc-editor.org/rfc/rfc1951.html]

### Pattern 4: Direct-row reconstruction into private image storage

**What:** Allocate `OwnedImage` only after the retained Phase-20 preflight succeeds, then call `with_mut_view`. At decompressed byte 0 of each row read a filter tag 0–4; reconstruct the next `row_bytes` bytes directly into the current image row. Obtain left from the current reconstructed row, above from row `y-1`, and upper-left from row `y-1, x-bpp`; use zero where absent. This needs no full decompressed buffer or two private row allocations. [VERIFIED: modules/mb-image/storage/owned_image.mbt; modules/mb-image/storage/views.mbt; CITED: https://www.w3.org/TR/png-3/]

**Filter rules:** use byte arithmetic modulo 256; Sub uses left, Up uses above, Average uses floor((left + above)/2) with a wider integer, and Paeth computes `p=a+b-c` with signed/wider intermediates and ties `a`, then `b`, then `c`. The bpp is bytes, not pixels: 3 for RGB and 4 for RGBA. [CITED: https://www.w3.org/TR/png-3/]

### Anti-Patterns to Avoid

- **Validate then inflate:** Current validation consumes IDAT data; a forward-only reader cannot be rewound. Refactor into one source instead. [VERIFIED: modules/mb-image/png/structural.mbt; modules/mb-image/codec/contracts.mbt]
- **Treating an IDAT end as DEFLATE/zlib/scanline end:** Chunk boundaries can split any zlib feature, including Adler-32. [CITED: https://www.w3.org/TR/png-3/]
- **Whole-IDAT or whole-filtered staging:** It weakens bounded behavior and duplicates image-sized storage. [VERIFIED: 21-CONTEXT.md]
- **Writing a public `PngStreamDecoder`, public inflater, or encoder:** The policy lane explicitly rejects extra public stream types and Phase 22 owns encode. [VERIFIED: scripts/quality/Assert-Policy.ps1; 21-CONTEXT.md]
- **Using `Byte` arithmetic for Average/Paeth intermediates:** It can overflow before modulo reduction. [CITED: https://www.w3.org/TR/png-3/]

## Don't Hand-Roll

| Problem | Don't build | Use instead | Why |
|---|---|---|---|
| Checked derived geometry and narrowing | ad hoc `UInt64` multiplication/casts | `@checked.checked_mul`, `checked_add`, and existing descriptor constructors | Existing helpers produce stable overflow failures before allocation. [VERIFIED: modules/mb-image/png/structural.mbt; modules/mb-core/checked/checked.mbt] |
| Caller resource accounting | duplicate counters in PNG | `Budget::child` for preflight and `OwnedImage::new_operation` for the one output allocation/charge | Keeps hierarchical budget semantics and atomic preflight behavior. [VERIFIED: modules/mb-core/budget/budget.mbt; modules/mb-image/storage/owned_image.mbt] |
| Reader progress / bounded chunk windows | direct Reader loops that accept zero progress | `@io.read_exact` and `BoundedReader` patterns | Existing I/O contracts distinguish EOF, no-progress, and partial failure. [VERIFIED: modules/mb-core/io/exact.mbt; modules/mb-core/io/bounded.mbt] |
| Image descriptor, metadata, and mutable storage | raw byte array as public image | QOI's `ImageDescriptor` / empty metadata / `OwnedImage` construction pattern | Preserves encoded-sRGB and straight-alpha portable contracts. [VERIFIED: modules/mb-image/qoi/decode.mbt] |
| External decompressor | FFI zlib/libpng or a registry dependency | private pure-MoonBit DEFLATE files in `png` | Locked scope requires portable MoonBit implementation. [VERIFIED: AGENTS.md; REQUIREMENTS.md] |

**Key insight:** only DEFLATE's domain logic (bitstream, trees, history) belongs in this phase; resource, I/O, image, and error contracts already exist and must remain the source of truth. [VERIFIED: modules/mb-core/budget/budget.mbt; modules/mb-image/codec/contracts.mbt]

## Runtime State Inventory

| Category | Items Found | Action Required |
|---|---|---|
| Stored data | None — repository audit found only versioned JSON fixtures and no database/datastore configuration for PNG decoding. [VERIFIED: repository `rg` audit, 2026-07-21] | Code/fixture change only; no data migration. |
| Live service config | None — this is a portable library package with no service integration/configuration surface. [VERIFIED: AGENTS.md; repository `rg` audit, 2026-07-21] | None. |
| OS-registered state | None — no task, service-manager, or launcher registration is involved in a private codec implementation. [VERIFIED: repository `rg` audit, 2026-07-21] | None. |
| Secrets/env vars | None — no secret, environment variable, network, or credential integration is in the phase scope. [VERIFIED: REQUIREMENTS.md; repository `rg` audit, 2026-07-21] | None. |
| Build artifacts | `modules/mb-image/png/pkg.generated.mbti` is compiler-generated and will change when sources are compiled; it is not a runtime migration. [VERIFIED: modules/mb-image/png/pkg.generated.mbti; scripts/quality/Assert-Policy.ps1] | Regenerate through the normal MoonBit build/test and update policy interface assertion only if the intentionally unchanged public API differs. |

## Common Pitfalls

### Pitfall 1: Losing one-byte transport semantics at IDAT boundaries

**What goes wrong:** The inflater works for a one-chunk PNG yet fails when a chunk ends in a bit field, dynamic-tree repeat, stored length, match, or Adler-32.  
**Why it happens:** PNG makes IDAT boundaries non-semantic.  
**How to avoid:** `PngIdatSource` returns one logical byte sequence; tests split every selected valid stream at every byte offset and at semantic sub-boundaries.  
**Warning signs:** Any code branches on “end of current IDAT” inside bit decoding. [CITED: https://www.w3.org/TR/png-3/]

### Pitfall 2: Incorrect DEFLATE bit order and stored-block alignment

**What goes wrong:** Fixed fields or canonical Huffman codes decode backwards; stored blocks accept corrupt `NLEN`.  
**Why it happens:** Fields are packed LSB-first, while canonical code construction is described MSB-first and must be bit-reversed for an LSB-fed decoder. Stored blocks discard only remaining bits to the next byte boundary and require `NLEN == ~LEN & 0xffff`.  
**How to avoid:** One bit reader with an explicit accumulator/bit-count, a tested `reverse_bits(code, length)`, and dedicated stored-block tests.  
**Warning signs:** Valid fixed streams fail while stored streams pass, or byte-aligned-only fixtures are the sole evidence. [CITED: https://www.rfc-editor.org/rfc/rfc1951.html]

### Pitfall 3: Accepting malformed dynamic trees

**What goes wrong:** Repeat codes overrun declared alphabets, missing EOB causes unbounded reads, or unused/reserved symbols are decoded.  
**Why it happens:** Dynamic header counts are compact and repeat codes span literal/length and distance lengths.  
**How to avoid:** Bound every alphabet and repeat before writing, validate canonical occupancy, require EOB 256, and reject reserved literal/length/distance symbols at use.  
**Warning signs:** A malformed tree error appears only after output has exceeded expected filtered bytes. [CITED: https://www.rfc-editor.org/rfc/rfc1951.html]

### Pitfall 4: Failing to support overlap copies or history across blocks

**What goes wrong:** `<length=5,distance=2>` copies only two bytes, or a match crossing a DEFLATE block fails.  
**Why it happens:** Matches may overlap and may refer to the previous 32 KiB across block boundaries.  
**How to avoid:** Copy one byte at a time: read `(history_position - distance) mod 32768`, then immediately append that byte to both history and sink; require `1 <= distance <= min(produced, 32768)`.  
**Warning signs:** Repetitive-pixel fixtures decode differently from an independent oracle. [CITED: https://www.rfc-editor.org/rfc/rfc1951.html]

### Pitfall 5: Declaring success before all terminal checks

**What goes wrong:** A decoder returns an image before Adler-32, extra IDAT data, bad trailing PNG chunks, IEND, or EOF are checked.  
**Why it happens:** `OwnedImage` is constructed before bytes can be decoded, but visibility is a separate public-result decision.  
**How to avoid:** Store the image only in local scope; create `DecodeResult` after `finish_zlib`, exact raster count, `finish_after_idat`, and strict EOF all return `Ok`.  
**Warning signs:** A malformed checksum test can inspect a result or implementation returns from inside `with_mut_view`. [VERIFIED: modules/mb-image/codec/contracts.mbt; modules/mb-image/storage/owned_image.mbt]

### Pitfall 6: Breaking Phase-20 safety evidence while refactoring

**What goes wrong:** A new source file/import fails the Png lane, or previously tested structural errors now become inflater errors.  
**Why it happens:** The quality lane has exact production-source, package-file, import, and public-interface allowlists.  
**How to avoid:** Preserve structural test records and their precedence, update the generator only for phase-21 success changes, and amend all allowlists in the same task that adds source files.  
**Warning signs:** `Invoke-MoonQuality.ps1 -Lane Png` fails before MoonBit tests run. [VERIFIED: 20-VERIFICATION.md; scripts/quality/Assert-Policy.ps1; scripts/quality/Invoke-MoonQuality.ps1]

## Code Examples

Verified implementation patterns adapted to this repository:

### Filter-byte sink boundary

```moonbit
// Repository pattern: return typed error rather than expose partial output.
// Source: modules/mb-image/storage/owned_image.mbt and W3C PNG filtering.
fn PngRasterSink::push(self, value) {
  if self.filtered_seen >= self.filtered_expected {
    return Err(_png_error("png-filtered-output"))
  }
  // If at row start: validate filter 0..4; otherwise reconstruct with
  // current/previous row image bytes, then set the one output byte.
  // Increment filtered_seen only after the byte is accepted.
  ...
}
```

The ellipsis is intentional: it denotes a private implementation task, not a fallback or public API. The checked count and error-return style are established repository patterns. [VERIFIED: modules/mb-image/png/structural.mbt; modules/mb-image/storage/views.mbt]

### Atomic eager result orchestration

```moonbit
let transport = _png_start_transport(reader, options, limits, budget)?
let image = @storage.OwnedImage::new_operation(descriptor, budget, allocator, work)?
image.with_mut_view(fn(view) {
  let sink = PngRasterSink::new(view, header)?
  _png_decode_zlib(transport.idat_source(), sink)
})?
transport.finish_zlib()?            // exact logical IDAT end and CRC state
transport.finish_after_idat()?      // tail chunks, IEND, strict EOF
Ok(@codec.DecodeResult::new(image, empty_disposition()?, transport.bytes_read()))
```

Adapt ownership details to MoonBit compiler constraints, but retain this ordering. `OwnedImage::new_operation`, callback-scoped mutation, and terminal `DecodeResult` construction are verified repository APIs. [VERIFIED: modules/mb-image/storage/owned_image.mbt; modules/mb-image/codec/contracts.mbt]

## State of the Art

| Old approach | Current approach | When changed | Impact |
|---|---|---|---|
| Phase-20 fixed-scratch validator consumes/discards every IDAT byte then returns capability unavailable. | Phase-21 single-pass IDAT source yields the same bytes to private zlib/raster code while retaining structural validation. | This phase | Allows eager decode on a non-seeking reader without weakening Phase-20 checks. [VERIFIED: modules/mb-image/png/structural.mbt; 21-CONTEXT.md] |
| Structural fixture corpus proves framing/resource acceptance only. | Separate decode corpus proves actual pixels, filters, DEFLATE forms, hostile trees/checksums, and split invariance. | This phase | Avoids mistaking parser acceptance for decode interoperability. [VERIFIED: 20-VERIFICATION.md; 21-CONTEXT.md] |

**Deprecated/outdated:** Do not retain `deflate-and-raster-pending` as a success-adjacent terminal for a fully supported valid stream after this phase; structural failures still retain their established typed contexts. [VERIFIED: 21-CONTEXT.md; modules/mb-image/png/png.mbt]

## Implementation Plan and Exact Task Order

1. **Lock the decoder-only package inventory and add red tests.** Update the Png policy source/file allowlists and lane expected files for the private decoder source/test files; add public red tests that valid legal PNGs no longer end at `deflate-and-raster-pending`. Preserve `PngDecoder` as the sole semantic interface. [VERIFIED: policy/foundation.json; scripts/quality/Assert-Policy.ps1]
2. **Refactor structural transport, without changing rejection semantics.** Replace `_png_validate_transport` with private `PngTransport` / `PngIdatSource`; retain CRC-before-policy, IHDR preflight, metadata rejection, input accounting, contiguous IDAT, and strict tail rules. Add white-box split/CRC/state tests before inflater integration. [VERIFIED: modules/mb-image/png/structural.mbt; 20-VERIFICATION.md]
3. **Implement and prove private zlib/DEFLATE primitives.** Add bit reader, Adler-32, canonical tree builder, stored/fixed/dynamic decode, and 32 KiB overlap-safe history. Drive them through a private byte sink with tiny independent raw vectors before PNG wrapping. [CITED: https://www.rfc-editor.org/rfc/rfc1950.html; https://www.rfc-editor.org/rfc/rfc1951.html]
4. **Implement raster sink and terminal atomic orchestration.** Add RGB/RGBA descriptor/metadata helpers copied from QOI semantics, direct image-row reconstruction for filters 0–4, exact filtered-byte accounting, and terminal zlib/PNG completion. Keep error categories/codes stable and all contexts deterministic. [VERIFIED: modules/mb-image/qoi/decode.mbt; modules/mb-image/codec/contracts.mbt]
5. **Add independent declarative PNG decode evidence.** Create `fixtures/png/decode-cases.json`, manifest record, generator, generated test helpers, public black-box outcomes, and white-box invariants. Cover stored/fixed/dynamic streams, all filters, RGB/RGBA, IDAT split schedules, checksum/tree/distance/expansion/resource failures, and no-partial-result behavior. [VERIFIED: fixtures/png/cases.json; fixtures/manifest.json; 21-CONTEXT.md]
6. **Run the full isolated evidence lane.** Execute generator freshness, PNG tests on all four targets, and Png policy lane; run the parent image quality lane only if the changed policy command requires it. [VERIFIED: scripts/quality/Invoke-MoonQuality.ps1]

## Fixture Strategy

Create a second declarative corpus rather than converting the Phase-20 structural matrix into a decoder oracle. Each `decode-cases.json` row must name: compressed form (`stored`, `fixed`, `dynamic`), raw filtered bytes, expected decoded pixels, explicit IDAT split schedule, typed failure expectation (if hostile), limits, budget profile, and provenance. The generator may construct PNG chunk framing and CRCs, but it must not call any `png/*.mbt` production function to calculate expected pixels, filter reversal, canonical trees, or Adler-32. [ASSUMED]

Use two independent derivations per accepted vector: a literal/spec-audited small zlib payload (not generated by production bitwriter) plus checked raw filtered/pixel expectations. Validate fixture source bytes with a non-production standard-library decompressor in generator development or a committed one-time audited digest record; do not make the production inflater the only oracle. This is a test-design recommendation requiring a concrete tool choice during execution. [ASSUMED]

Minimum matrix:

| Area | Required independent cases |
|---|---|
| Valid raster | One RGB and one RGBA image for each filter 0–4; include left/above/upper-left nonzero values and Average/Paeth tie behavior. [CITED: https://www.w3.org/TR/png-3/] |
| Block forms | At least one stored, one fixed, and one dynamic zlib stream; each also undergoes split-at-every-byte transport schedules. [CITED: https://www.rfc-editor.org/rfc/rfc1951.html; https://www.w3.org/TR/png-3/] |
| Matches | A cross-block history match and an overlapping match (`distance < length`) yielding known pixels. [CITED: https://www.rfc-editor.org/rfc/rfc1951.html] |
| zlib negatives | Bad CMF/CM/CINFO/FCHECK, FDICT, truncation, reserved BTYPE, bad stored complement, Adler mismatch, and bytes after Adler inside IDAT. [CITED: https://www.rfc-editor.org/rfc/rfc1950.html; https://www.rfc-editor.org/rfc/rfc1951.html] |
| Dynamic negatives | Invalid HCLEN order/length, repeat-16 without prior value, repeat overflow, oversubscribed/incomplete invalid tree, missing EOB, reserved 286–287/30–31 use. [CITED: https://www.rfc-editor.org/rfc/rfc1951.html] |
| Resource/atomicity | Decompressed byte `expected+1`, short filtered output, invalid filter tag, distance beyond history/produced output, caller Reader error, post-allocation decode failure with no `DecodeResult`, and preflight Budget unchanged. [VERIFIED: modules/mb-image/codec/contracts.mbt; modules/mb-image/png/png_test.mbt] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | A second PowerShell generator can verify accepted vectors with a non-production decompressor without adding a runtime dependency. | Fixture Strategy | The execution plan needs a different independent-oracle mechanism. |
| A2 | Private source-file helpers in the existing `png` package best satisfy “internally reusable deflate” while keeping the policy public API unchanged. | Standard Stack / Architecture | Planner may need a MoonBit visibility spike if a separate package is desired. |
| A3 | The displayed private helper signatures can be adapted directly to MoonBit ownership rules. | Code Examples | Names or ownership passing style may require compiler-driven adjustment, not a public API change. |

## Open Questions

1. **What private scratch allocation ceiling should be encoded for the 32 KiB history ring?**
   - What we know: DEFLATE distances are capped at 32,768 bytes, and current codecs allocate private scratch under a private budget. [CITED: https://www.rfc-editor.org/rfc/rfc1951.html; VERIFIED: modules/mb-image/qoi/decode.mbt]
   - What's unclear: whether the project wants history allocated as one `OwnedBytes` with a private 32 KiB budget or as a fixed compiler array in all four targets.
   - Recommendation: use one `OwnedBytes::new(32768UL, private_budget(32768UL))` initially, because it follows established portable allocation/lease patterns; keep it entirely private. [ASSUMED]
2. **Should `max_work` account for compressed-input parsing beyond the retained `filtered_output + image_bytes` formula?**
   - What we know: Phase 20 validates and fixtures the formula `filtered_output + image_bytes` before output and `OwnedImage::new_operation` is the sole caller charge. [VERIFIED: modules/mb-image/png/structural.mbt; fixtures/png/cases.json]
   - What's unclear: whether a new work formula is permitted without invalidating already accepted structural resource contexts.
   - Recommendation: preserve the Phase-20 formula in this phase; enforce `max_input_bytes`, fixed dynamic-tree bounds, and exact decompressed-byte ceiling for additional DoS control. Treat a formula expansion as a separately reviewed contract change. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| MoonBit toolchain | Compile/test private portable decoder | ✓ | moon `0.1.20260713`; moonc `v0.10.4+2cc641edf` | None — required |
| PowerShell | Existing/new deterministic fixture and quality scripts | ✓ | PowerShell host available in current workspace | None — existing workflow |
| External packages / FFI | None | N/A | — | No installation or FFI permitted |

**Missing dependencies with no fallback:** None.  
**Missing dependencies with fallback:** The independent accepted-vector oracle mechanism is an execution choice, not a runtime dependency; use a local standard-library decompressor or an audited fixture digest if no suitable tool is available. [ASSUMED]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | No | Offline pure binary decoder has no identity boundary. [VERIFIED: 21-CONTEXT.md] |
| V3 Session Management | No | No session state. [VERIFIED: 21-CONTEXT.md] |
| V4 Access Control | No | Package exposes no new service/authorization surface. [VERIFIED: policy/foundation.json] |
| V5 Input Validation | Yes | Existing typed `CoreError`, checked arithmetic, bounded reader progress, chunk CRC/state, zlib/DEFLATE validation, exact output accounting. [VERIFIED: modules/mb-core/error/core_error.mbt; modules/mb-core/io/bounded.mbt; CITED: https://www.rfc-editor.org/rfc/rfc1951.html] |
| V6 Cryptography | No | CRC-32 and Adler-32 are integrity/error-detection checks, not cryptographic controls; do not use them as authentication. [CITED: https://www.w3.org/TR/png-3/; https://www.rfc-editor.org/rfc/rfc1950.html] |

### Known Threat Patterns for PNG/DEFLATE

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Expansion bomb / endless output | Denial of service | Preflight image/filter count, reject sink byte `expected+1`, cap input and work, bounded history. [VERIFIED: modules/mb-image/png/structural.mbt; 21-CONTEXT.md] |
| Malformed dynamic tree / reserved symbol | Tampering | Fixed alphabet maxima, canonical occupancy validation, repeat bounds, required EOB, reserved-code rejection. [CITED: https://www.rfc-editor.org/rfc/rfc1951.html] |
| Invalid back-reference / overlap bug | Tampering / denial of service | `distance <= min(produced,32768)` and byte-at-a-time ring copy. [CITED: https://www.rfc-editor.org/rfc/rfc1951.html] |
| Chunk-boundary desynchronization | Tampering | One logical IDAT source with CRC checked at each physical chunk and terminal zlib exhaustion. [CITED: https://www.w3.org/TR/png-3/] |
| Partial-object exposure | Elevation / tampering | Private local `OwnedImage`; only terminal `DecodeResult` is public. [VERIFIED: modules/mb-image/codec/contracts.mbt; 21-CONTEXT.md] |

## Sources

### Primary (repository-verified)

- `modules/mb-image/png/structural.mbt`, `png.mbt`, and `20-VERIFICATION.md` — current one-pass constraint, structural contexts, resource formula, and verified Phase-20 evidence.
- `modules/mb-image/codec/contracts.mbt`, `storage/owned_image.mbt`, `storage/views.mbt`, `qoi/decode.mbt` — exact eager result, allocation, mutable-view, metadata, and error patterns.
- `modules/mb-core/{checked,budget,bytes,io,error}` — checked arithmetic, caller Budget, private allocation, reader, and typed-error contracts.
- `policy/foundation.json`, `scripts/quality/Assert-Policy.ps1`, `scripts/quality/Invoke-MoonQuality.ps1` — exact Png package/API/file inventory and all-target quality lane.

### Secondary (official specifications; cited)

- [RFC 1951 — DEFLATE Compressed Data Format](https://www.rfc-editor.org/rfc/rfc1951.html) — bit packing, block forms, canonical codes, dynamic headers, length/distance tables, 32 KiB history, overlap semantics.
- [RFC 1950 — ZLIB Compressed Data Format](https://www.rfc-editor.org/rfc/rfc1950.html) — CMF/FLG/FDICT/FCHECK, wrapper terminal Adler-32, and compliance checks.
- [PNG Specification, Third Edition](https://www.w3.org/TR/png-3/) — contiguous arbitrary IDAT concatenation, filtered scanlines, filters 0–4, and PNG/zlib checksum distinction.

### Tertiary (LOW confidence)

- Context7 was unavailable in this runtime; tool-classified webfetch research confidence was LOW even though the cited sources are primary official publications. The affected implementation-mechanics assumptions are listed in the Assumptions Log.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — all recommended code is existing workspace code and no package is added. [VERIFIED: repository inspection]
- Architecture: HIGH — Phase-20 parser consumes IDAT and the public policy interface is exact/verified; single-pass refactor follows that constraint. [VERIFIED: modules/mb-image/png/structural.mbt; policy/foundation.json]
- DEFLATE/PNG protocol rules: MEDIUM — directly cited primary standards, but the research seam classified fallback webfetch LOW because Context7 was unavailable.
- Pitfalls: HIGH — supported by both Phase-20 implementation evidence and primary specifications.

**Research date:** 2026-07-21  
**Valid until:** 2026-08-20 for stable format standards and current workspace contracts.
