# Feature Landscape: v0.6 PNG Interchange

**Domain:** Bounded, pure-MoonBit portable PNG interchange for `mb-image`
**Researched:** 2026-07-20
**Scope decision:** A strict static-PNG subset, not a general PNG implementation. It adds eager `ImageDecoder`/`ImageEncoder` parity after QOI streaming; it does not add a PNG streaming public API.

## Product Boundary

PNG defines five colour types, 1--16-bit samples, Adam7 interlace, ancillary metadata, and APNG. A general decoder must support that complete surface. MNF v0.6 should instead support only **non-interlaced, 8-bit truecolour (type 2) and truecolour-with-alpha (type 6)**, mapping them to existing tightly packed top-left `rgb8`/straight-`rgba8` images. This matches current portable image contracts while accepting ordinary RGB/RGBA PNGs regardless of filter, IDAT split, or DEFLATE strategy.

## Table Stakes

| Feature | Why expected | Complexity | v0.6 contract |
|---|---|---:|---|
| Prefix-only PNG probe | Codec selection must not consume a reader. | Low | Recognize the eight-byte PNG signature; deterministic `NeedMore` before eight bytes; enforce `CodecLimits.max_probe_bytes`. |
| Static 8-bit RGB/RGBA decode | Direct counterpart to existing portable image forms. | High | Accept only IHDR `(depth=8, type=2/6, compression=0, filter=0, interlace=0)`; return encoded-sRGB `rgb8` or straight-`rgba8`. |
| Complete framing and integrity validation | PNG framing is image correctness. | High | Validate signature, exact IHDR-first/once, checked non-zero geometry, legal chunk-type bytes, per-chunk CRC, consecutive IDAT, one empty IEND, and no post-IEND bytes. Return no image until terminal validation succeeds. |
| One zlib stream across arbitrary IDAT splits | PNG permits IDAT splits within a DEFLATE block, checksum, or scanline. | High | Incrementally feed concatenated IDAT payload to the inflater; never assume alignment or buffer whole IDAT chunks. |
| Bounded zlib/DEFLATE inflate | Normal PNGs contain stored, fixed-Huffman, and dynamic-Huffman blocks. | High | Validate zlib CMF/FLG and Adler-32; reject dictionaries; support stored/fixed/dynamic blocks; reject reserved blocks, bad Huffman tables, and invalid backward distances; use a 32 KiB history ring. |
| All filter reconstructions | PNG filter type is per scanline; type 0 only is not interoperable. | Med | Implement None, Sub, Up, Average, Paeth (0--4), including first-row/first-pixel behaviour and overflow-safe predictor arithmetic. |
| Checked resource accounting | Tiny compressed data can declare huge images or expand excessively. | High | Reuse `CodecLimits`/`Budget` for checked geometry, input, output, pixels, work, allocation, chunk length/count and decompressed scanline bytes. Check header bounds before allocation and enforce them during parsing/inflation. |
| Stable hostile-input failures | Tests and automation need typed failures, not panics or target variance. | High | Cover truncation, bad CRC/length/order, nonconsecutive IDAT, bad IHDR, malformed zlib/DEFLATE/Huffman/distance/checksum, scanline/filter mismatch, resource exhaustion and trailing data. |
| Canonical RGB/RGBA encode | PNG allows many valid bytes; deterministic evidence needs one output. | High | Preflight compatible packed top-left builtin encoded-sRGB `rgb8`/straight-`rgba8` sources before any write. Fix signature → IHDR → IDAT → IEND, filtering, zlib header, DEFLATE plan, IDAT split, Adler-32 and CRCs. |
| Deterministic baseline compression | Adaptive filtering/LZ search makes equivalent files differ. | Med | Emit Filter None rows and a documented stored-DEFLATE block policy with fixed maximum block size. It is a safe canonical interchange baseline, not a compression-ratio claim. |
| Explicit ancillary disposition | Silent metadata/colour loss is unsafe. | Med | CRC-check bounded chunks. Discard only unknown non-critical ancillary data when preservation is false and report loss in `MetadataDisposition`; fail when preservation is requested. Reject semantics-changing `PLTE`, `tRNS`, `gAMA`, `cHRM`, `iCCP`, `sRGB`, `cICP`, HDR and APNG chunks. |
| Public four-target workflow | The codec matters only through public portable APIs. | Med | One `png-portable` example: decode fixture → `flip_horizontal` → canonical encode; print fixed dimensions, byte count, digest and disposition on `js`, `wasm`, `wasm-gc`, `native`. |

## Differentiators

| Feature | Value proposition | Complexity | Notes |
|---|---|---:|---|
| Fail-closed whole-datastream acceptance | Never exposes pixels while later CRC/IEND/trailing validation is unknown. | High | Deliberately favors automation and hostile-input safety over progressive display. |
| Exact canonical bytes | Enables cross-target byte/digest fixture evidence despite PNG encoding freedom. | Med | Requires fixed filters, wrapper, DEFLATE blocks, IDAT partitioning and CRCs. |
| Internal IDAT/inflate streaming with eager result | Avoids duplicate compressed buffers while keeping the established public eager API. | High | Implementation property only; no v0.6 resumable PNG API. |
| Generated adversarial vectors | Fixture-owned schedules localize framing/CRC/DEFLATE/filter/limit evidence. | Med | Keep provenance and stable error identifiers with small spec-derived bytes. |

## Deliberate Deferrals

| Deferred capability | Why exclude it | What to do instead |
|---|---|---|
| Greyscale, palette and `tRNS` (types 0, 3, 4) | Packed-bit unpacking, PLTE validation, palette lookup and transparency expansion widen conversion policy. | Fail `CapabilityUnavailable`; add only with a separately specified expansion-to-RGBA contract. |
| 16-bit PNG | Existing portable interchange is U8; conversion is lossy and U16 expands the image model. | Reject depth 16; plan with a first-class U16 image contract. |
| Adam7 | Seven-pass geometry/filter state/scatter writes increase hostile-input surface. | Require interlace 0; research separately. |
| Colour-management/HDR chunks | ICC, gamma, cICP and HDR need an explicit colour pipeline; ignoring them mislabels data as builtin sRGB. | Reject them; no implicit conversion. |
| Text/EXIF/physical metadata preservation | Conflicts with canonical no-metadata output and needs its own limits/round-trip policy. | Discard only under explicit non-preserving decode options and report disposition. |
| APNG | Frames, blend/dispose/timing/canvas state are a different product. | Reject `acTL`, `fcTL`, `fdAT`. |
| Public resumable PNG I/O | Couples chunk framing, zlib bit input, filters and output buffers into a new public state machine. | Keep v0.6 eager; reuse QOI streaming conventions only later. |
| Compression optimisation/benchmarks | Adaptive filters and LZ match search are performance work, not correctness. | Ship stored-block canonical output; benchmark later with declared workloads. |
| FFI, registry and release work | Outside portable codec correctness. | Keep the path pure MoonBit and evidence-focused. |

## Feature Dependencies

```text
PNG probe
  → chunk reader + CRC + ordering
    → IHDR subset + checked geometry
      → bounded zlib/DEFLATE
        → scanline accounting + filters 0..4
          → owned image + IEND/trailing validation
            → hostile four-target vectors

canonical source preflight
  → filter-none scanlines
    → fixed stored-DEFLATE + Adler-32
      → fixed IDAT split + CRC
        → exact digest vectors
          → public decode → flip → encode example
```

Every stage charges the existing `CodecLimits`/`Budget` authority; none may allocate or expose an image before checked derived bounds are known.

## MVP Recommendation

1. **Structural core:** probe, chunk/CRC/order state, IHDR gate, checked limits and hostile framing vectors.
2. **Decode interoperability:** zlib/DEFLATE, filters 0--4, RGB/RGBA vectors with arbitrary IDAT partitioning.
3. **Canonical evidence:** filter-none/stored-block encoder, exact bytes/digests and public four-target decode → operation → encode proof.

Do not weaken this subset by silently accepting colour-affecting ancillary chunks or by describing it as a full PNG decoder.

## Acceptance Evidence

1. Valid non-interlaced 8-bit type 2/6 inputs using every filter and arbitrary IDAT splits yield exact pixels.
2. Every malformed case fails before image return with stable framing, integrity, IHDR, zlib/DEFLATE, scanline, resource or trailing-data diagnostics.
3. No path retains a whole IDAT merely due to chunking; all input/output/pixel/work/budget ceilings remain enforced during hostile input.
4. Compatible sources encode to byte-identical canonical PNG on all four targets; preflight failures write zero bytes.
5. The public example uses public contracts only and emits one stable evidence line per target.

## Sources

- [W3C PNG Specification, Third Edition](https://www.w3.org/TR/png-3/) — chunk framing/order, IHDR combinations, IDAT concatenation, filters, CRC/error handling, unknown chunks and decoder conformance. **MEDIUM** (primary specification, cross-checked).
- [RFC 1950: zlib format](https://datatracker.ietf.org/doc/html/rfc1950) — wrapper, no-dictionary policy, Adler-32 and required validation. **MEDIUM** (primary specification, cross-checked).
- [RFC 1951: DEFLATE](https://datatracker.ietf.org/doc/rfc1951/) — stored/fixed/dynamic blocks, reserved-block rejection and distance/length constraints. **MEDIUM** (primary specification, cross-checked).
- Existing MNF [`CodecLimits`](../../modules/mb-image/codec/contracts.mbt), QOI and PPM codecs — eager reader/writer, budget, canonical-output, encoded-sRGB and metadata-disposition conventions. **HIGH** (local implementation evidence).
