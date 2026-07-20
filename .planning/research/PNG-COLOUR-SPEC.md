# PNG Colour Fidelity: Specification Findings

**Scope:** v0.7 portable eager PNG decoder  
**Confidence:** HIGH for PNG container rules (W3C primary specification); MEDIUM for the proposed staged product boundary.

## Normative container rules

The current primary source is the [W3C PNG Third Edition](https://www.w3.org/TR/png-3/) (Recommendation, 2025). Its chunk-order table makes `cHRM`, `gAMA`, `iCCP`, and `sRGB` singleton chunks: each appears **at most once** and, if present, **before both `PLTE` and `IDAT`**. A duplicate or late instance is a non-conforming datastream and should be reported as malformed by MNF's strict decoder rather than silently selecting one.

| Chunk | Required structure / validation | Meaning |
|---|---|---|
| `sRGB` | exactly 1 byte; rendering intent must be `0..3` | Samples are sRGB. Its implied legacy values are `gAMA=45455` and the fixed sRGB `cHRM` coordinates. |
| `gAMA` | exactly 4 bytes; unsigned integer is gamma × 100000 | Transfer information only; it does not apply to alpha. Zero must be rejected before any reciprocal/power calculation. |
| `cHRM` | exactly 32 bytes; eight unsigned x/y values × 100000 | White point plus RGB primaries. Meaningful colour conversion also needs transfer information (`gAMA` or a higher-precedence space). |
| `iCCP` | profile name 1–79 valid Latin-1 bytes with no leading/trailing/consecutive spaces; NUL; compression method exactly 0; then zlib stream | Embedded ICC profile; its declared colour space must match PNG type (RGB for 2/3/6, greyscale for 0/4). Bound both compressed and inflated sizes. |

The Third Edition defines precedence among understood colour chunks: `cICP` (1), `iCCP` (2), `sRGB` (3), then `cHRM` + `gAMA` (4). Although `cICP` is outside the v0.7 feature request, its presence cannot be treated as innocuous: it has higher precedence in current PNG. `sRGB` and `iCCP` together are **discouraged** (`should not`), not an unconditional syntax prohibition; an implementation must not let lower-precedence `gAMA`/`cHRM` override an understood higher-precedence chunk. The specification also recommends at most one embedded profile, explicit (`iCCP`) or implicit (`sRGB`).

## Safe, bounded v0.7 recommendation

Implement a chunk-state pass before pixel expansion, producing an immutable colour-description object carried with the decoded image. Support and validate `sRGB`, `gAMA`, and `cHRM`; select the W3C precedence deterministically. Preserve alpha as linear/unassociated data. For `sRGB`, expose the rendering intent and use the fixed sRGB interpretation; for `gAMA` + `cHRM`, retain the exact integers and only perform a transform after validating that the chromaticities produce a usable, non-degenerate conversion matrix.

Do **not** claim full ICC colour management in v0.7. For `iCCP`, validate the PNG envelope and bounded zlib payload, retain profile bytes/name and the fact that the pixels are ICC-tagged, then either (a) return that metadata with unconverted samples, or (b) fail with an explicit `unsupported ICC colour transform` result when the requested output requires canonical sRGB pixels. Never discard `iCCP` and label the output as sRGB/default RGB. The same rule applies to `cICP`: retain/explicitly reject it until its transfer functions are implemented.

This gives portable eager decode a coherent contract without importing a native colour-management stack: **metadata-preserving decode is supported; canonical-colour conversion is supported only for declared, validated spaces.** A raw-RGBA convenience API must carry the colour description or require an explicit caller policy; otherwise it creates silent semantic loss.

## Acceptance checks

- Reject duplicate, post-`PLTE`/`IDAT`, wrong-length, invalid-intent, invalid-compression-method, truncated, or decompression-limit-violating colour chunks.
- Test `sRGB` plus conflicting `gAMA`/`cHRM`: sRGB wins; lower-priority metadata cannot change decoded semantics.
- Test `iCCP` + `sRGB` and `cICP` + legacy chunks: surface the conflict/preference in diagnostics/metadata; never choose by encounter order.
- Test gamma correction and compositing separately: gamma is never applied to alpha, and compositing belongs in linear light.
- Include fixtures for indexed, greyscale, RGB, and alpha PNG types; `iCCP` profile class must agree with the PNG colour type.

## Exact sources

- W3C, [PNG Specification (Third Edition), §4.3 colour-space precedence](https://www.w3.org/TR/png-3/#color-spaces), [§5.6 ordering](https://www.w3.org/TR/png-3/#5ChunkOrdering), [§11.3.2 colour chunks](https://www.w3.org/TR/png-3/#11cHRM), and [§13.16 alpha processing](https://www.w3.org/TR/png-3/#13Alpha-channel-processing). Primary normative source.
- W3C, [PNG Specification (Second Edition), §11.3.3](https://www.w3.org/TR/2003/REC-PNG-20031110/#11addinfo), cross-check for legacy `sRGB`/`iCCP` behaviour and values.

**Open follow-up:** an ICC transform engine and full `cICP` HDR/video handling need a later, separately scoped design; they are not safe to approximate inside a portable eager decoder.
