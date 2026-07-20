# PNG Interchange Pitfalls: v0.6

**Domain:** Strict, bounded PNG/zlib/DEFLATE over MNF portable image contracts
**Researched:** 2026-07-20
**Confidence:** MEDIUM for format rules (primary specifications); HIGH for existing-contract integration (local code evidence).

## Operating Rule

This milestone is a strict static 8-bit RGB/RGBA subset, not a full PNG decoder. Every rejected input must fail deterministically before a `DecodeResult` is returned. Expected phase names below are planning recommendations: **Phase 20 — structural core**, **Phase 21 — bounded inflate and decode**, **Phase 22 — canonical encode and four-target evidence**.

## Critical Pitfalls

### 1. Chunk boundaries are mistaken for zlib, DEFLATE, or row boundaries

**What goes wrong:** The parser assumes an IDAT contains a whole zlib stream, DEFLATE block, Adler-32, or scanline. Valid images split any of those boundaries; hostile inputs exploit the same assumption to lose bytes or desynchronise state.

**Prevention:** Make IDAT a byte supplier for one inflater state. Preserve bit-buffer, 32 KiB history, Adler accumulator, current scanline/filter state, and CRC state across every IDAT boundary. Permit zero-length IDAT, but require all IDAT chunks to be consecutive.

**Detection:** Vectors split at every zlib-header, DEFLATE-header, dynamic-tree, back-reference, filter-byte, scanline, Adler-32, and CRC boundary. Verify the same typed result on all four targets.

**Owner:** Phase 20 defines consecutive-IDAT state; Phase 21 proves split-independent inflate/scanline behaviour.

### 2. Geometry and expansion arithmetic overflows before limits apply

**What goes wrong:** `width × height × channels`, row-byte, filtered-byte, work, or allocation calculations wrap or are narrowed before comparison. A small compressed input can then allocate too little, write out of range, or bypass `CodecLimits`.

**Prevention:** Parse IHDR as unsigned 32-bit values; reject zero/unsupported fields; use `@checked` for every derived value; compare each intermediate against `max_width`, `max_height`, `max_pixels`, `max_output_bytes`, and `max_work` before `OwnedImage::new_operation`. Keep the native budget as the final allocation authority, not a substitute for preflight.

**Detection:** Test maximum dimensions, exact-limit success, one-over-limit failure, multiplication overflow, row-byte overflow, and compressed streams that emit more than the precomputed filtered-data total.

**Owner:** Phase 20.

### 3. DEFLATE parser accepts malformed dynamic trees or illegal back-references

**What goes wrong:** Dynamic Huffman repeat codes overrun their declared code-length arrays; incomplete/oversubscribed trees decode ambiguously; reserved `BTYPE=11` is treated as another block; a distance refers before output or exceeds the 32 KiB window.

**Prevention:** Bound all dynamic-tree counters to RFC-defined alphabet sizes before writing; validate canonical code-length construction; reject reserved blocks and invalid literal/length or distance symbols; require `distance <= produced_output` and `distance <= 32768`; perform overlapping copies bytewise through the ring/history rule.

**Detection:** Unit-level bitstream vectors for repeat overflow, missing end-of-block, oversubscribed/incomplete trees, reserved block, stored LEN/NLEN mismatch, illegal length/distance, distance-before-output, and overlapping copies.

**Owner:** Phase 21.

### 4. Checksums are validated too late, inconsistently, or not at all

**What goes wrong:** CRC is computed over data only (not type+data), final CRC/Adler bytes are confused with compressed data, ancillary chunks bypass CRC, or the image returns before its terminal integrity checks.

**Prevention:** Incrementally CRC each exact chunk type plus data and compare before state transition. Validate zlib CMF/FLG before inflate, reject FDICT for PNG, and compare Adler-32 only after exactly the precomputed filtered payload is reconstructed. Do not return an image before IEND and strict trailing-data validation.

**Detection:** Independently mutate signature, chunk type, payload, CRC, zlib header, and Adler bytes. Assert no successful `DecodeResult` and stable error contexts for each.

**Owner:** Phase 20 for PNG CRC; Phase 21 for zlib/Adler terminal state.

### 5. Filter reconstruction uses the wrong byte geometry or arithmetic

**What goes wrong:** `bpp` is treated as pixels rather than bytes, the first row reads an uninitialised prior row, 8-bit Average overflows before division, Paeth tie rules differ by target, or a filter byte is accepted after the expected row count.

**Prevention:** For the v0.6 subset use `bpp=3` (RGB) or `4` (RGBA) bytes. Retain exactly previous and current unfiltered rows. Implement predictor calculations in signed/wider integer arithmetic and reduce modulo 256 only at reconstruction. Stop inflate after exactly `height × (1 + row_bytes)` filtered bytes.

**Detection:** Specification-derived 1×N/N×1 vectors, each filter on RGB and RGBA, first-row/first-pixel cases, values near 0/255, and output-one-byte-short/long cases.

**Owner:** Phase 21.

### 6. Narrow PNG subset silently changes pixel or colour meaning

**What goes wrong:** The decoder accepts `tRNS`, palette, gamma, ICC, sRGB/cICP, HDR, or APNG chunks but drops their semantics and labels output builtin encoded sRGB. That is silent loss, not harmless ancillary handling.

**Prevention:** Enforce type 2/6, 8-bit, non-interlaced IHDR before allocation. Reject known pixel/colour/animation-affecting chunks deterministically. For unknown ancillary chunks, CRC-check and discard only when `DecodeOptions.preserve_opaque_metadata=false`, recording a lossy `MetadataDisposition`; fail under preservation.

**Detection:** Fixtures for each prohibited chunk, duplicate/misordered ancillary chunks, unknown lowercase ancillary with both option values, and unknown uppercase critical chunk. Verify no source image with semantic metadata reaches the canonical encoder.

**Owner:** Phase 20 policy and parser; Phase 22 source/disposition proof.

### 7. “Canonical PNG” is under-specified

**What goes wrong:** The encoder says “use DEFLATE” or “choose the best filter.” Output then differs by target, refactor, hash-map order, or compression heuristic, defeating exact vectors and portable evidence.

**Prevention:** Write an encoder byte contract: IHDR fields; no ancillary chunks; Filter None per row; exact zlib header; stored blocks of fixed maximum length; fixed IDAT partition; big-endian fields; CRC32 and Adler32 algorithms; one IEND. Preflight all source capability, output and work limits before the first writer call.

**Detection:** Golden bytes plus digest for RGB/RGBA, dimensions crossing a stored-block boundary, writer short-write/error cases, and all-target equality. Test incompatible format, non-builtin profile, non-top-left orientation, premultiplied alpha, opaque metadata, and one-over-limit source produce zero output bytes.

**Owner:** Phase 22.

## Moderate Pitfalls

### 8. Chunk length is trusted as an allocation request

**What goes wrong:** A 31-bit PNG-legal length is accepted into an array or `Int` before local limits are applied, allowing memory pressure or signed conversion bugs even for unknown ancillary chunks.

**Prevention:** Parse length as `UInt64`, reject above local remaining-input and configured chunk/input ceilings, then consume incrementally with CRC. The only retained buffers should be fixed parser/inflater/scanline state and the checked destination image.

**Owner:** Phase 20.

### 9. Strictness is applied inconsistently at terminal boundaries

**What goes wrong:** The inflater accepts unused zlib bytes in the final IDAT while the outer reader accepts data after IEND, or error handling changes depending on `require_complete_input` without a documented rule.

**Prevention:** Specify one v0.6 terminal policy: reject bytes after zlib Adler within the IDAT sequence and reject any content after IEND. Keep all trailing checks in one terminal state machine and document any deliberate incompatibility with permissive PNG viewers.

**Owner:** Phase 21 terminal inflater; Phase 20 outer terminal reader.

### 10. Internal decompression streaming leaks partial image state

**What goes wrong:** A malformed final CRC or IEND is discovered after the decoder has allocated and filled an `OwnedImage`; code returns or exposes it through a callback/reference anyway.

**Prevention:** Treat the image as private construction state and create `DecodeResult` only after every terminal check. The eager public contract must remain atomic: success gives one complete image; failure gives only an error.

**Owner:** Phase 21, verified in Phase 22 public workflow.

### 11. Performance work smuggles in nondeterminism or unbounded retention

**What goes wrong:** “Optimisation” adds adaptive filter scoring, full compressed-IDAT collection, input-backed aliases, unbounded diagnostic text, or target-specific bit tricks before baseline conformance is proven.

**Prevention:** Start with fixed-size ring/two-row buffers and stored-block encoding. Benchmark only after exact conformance, with declared fixtures and no changed output contract. Avoid FFI and target-specific code.

**Owner:** Phase 22 evidence; later performance work is out of scope.

## Minor Pitfalls

### 12. Reader/writer errors lose codec context or progress

**Prevention:** Follow PPM/QOI remapping: preserve underlying category/code, report codec operation/context and exact completed bytes. Include reader and writer short/error fixtures.

**Owner:** Phases 20--22.

### 13. Probe and decode disagree

**Prevention:** Share the literal signature predicate; probe only caller-owned bytes and enforce its separate limit. Test every signature prefix and non-PNG near-match.

**Owner:** Phase 20.

### 14. Generated fixtures become an oracle copied from the implementation

**Prevention:** Keep small source/provenance-tagged specification-derived byte vectors and independently hand-check expected pixels/checksums. Use generated mutations only as additional adversarial coverage.

**Owner:** Phases 20--22.

## Phase-Specific Warnings

| Expected phase | Main risk | Mandatory mitigation | Exit evidence |
|---|---|---|---|
| 20 — structural core | framing/CRC/order/geometry bypasses; semantic chunk loss | unsigned checked parser, incremental CRC, explicit chunk-policy state, atomic IHDR preflight | hostile header/chunk matrix and zero-allocation-before-limit tests |
| 21 — bounded inflate and decode | IDAT desync, malformed Huffman, expansion, wrong filters, partial-success leak | one incremental inflater, RFC validation, 32 KiB ring, exact filtered-byte budget, private construction image | split-boundary corpus, DEFLATE negative corpus, all-filter pixel vectors |
| 22 — canonical encode and evidence | nondeterministic bytes, output-before-preflight, contract drift across targets | fixed stored-block byte contract, source capability gate, golden bytes/digests, public workflow | four-target exact digest plus zero-byte negative encode proof |

## Sources

- [W3C PNG Specification, Third Edition](https://www.w3.org/TR/png-3/) — arbitrary IDAT boundaries, chunk/CRC rules, error handling, unknown chunks, and its explicit warning that compressed-chunk errors can cause buffer overruns. **MEDIUM** (primary source, cross-checked).
- [RFC 1950: zlib](https://datatracker.ietf.org/doc/html/rfc1950) — CMF/FLG, FDICT, Adler-32, and required decompressor checks. **MEDIUM** (primary source, cross-checked).
- [RFC 1951: DEFLATE](https://datatracker.ietf.org/doc/rfc1951/) — block types, bounded intermediate storage, distance/length limits, and invalid reserved block semantics. **MEDIUM** (primary source, cross-checked).
- Existing MNF `modules/mb-image/codec/contracts.mbt`, `qoi`, and `ppm` codecs — established `CodecLimits`, `Budget`, eager atomic result, error-remapping, encoded-sRGB, and metadata-disposition conventions. **HIGH** (local implementation evidence).
