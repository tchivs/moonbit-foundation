# Phase 12: Strict PPM End-to-End Filter Coverage - Research

**Researched:** 2026-07-20  
**Domain:** portable strict-P6 decode → geometry → straight-RGBA processing → P6 encode integration evidence  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Use a small fixed strict PPM RGB input, decode through the public PPM API, crop and rotate before conversion, then grayscale and blur the straight RGBA result before source-over and RGB conversion/encoding.
- **D-02:** Preserve the existing metadata compatibility and budget contracts; every step receives an explicit budget and the vector asserts deterministic encoded bytes/digest plus selected semantic pixels.
- **D-03:** Use one named right-angle rotation and a radius-zero or one clamp-edge blur chosen by research for a compact, non-degenerate filter proof.
- **D-04:** The vector and at least one hostile resource/error boundary must execute on js, wasm, wasm-gc, and native with output assertions that prove the new sequence, not a pre-existing PPM path.
- **D-05:** Keep the change in Phase-11 portable pipeline tests/example support files; do not modify release scripts, benchmark harnesses, or public APIs.

### the agent's Discretion
- Select exact image dimensions/pixels, crop rectangle, rotation direction, blur radius, overlay pixels, expected byte encoding, and helper placement from existing test patterns.

### Deferred Ideas (OUT OF SCOPE)
- Additional codecs, filter families, optimized paths, and release automation remain outside this proof-only phase.
</user_constraints>

## Project Constraints (from AGENTS.md)

- Keep the proof in MoonBit and retain the portable `js`, `wasm`, `wasm-gc`, and `native` target contract. [VERIFIED: AGENTS.md; `modules/mb-image/ops/moon.pkg`]
- Do not add an API or dependency edge: `ops` deliberately does not import `ppm`, while the existing executable already imports both. [VERIFIED: `modules/mb-image/ops/moon.pkg`; `examples/ppm-portable/main/moon.pkg`]
- Binary evidence must use exact bytes/digest plus semantic assertions, not an opaque snapshot. [VERIFIED: AGENTS.md]
- This phase must not modify release, publication, configuration, untracked tooling, or benchmark files. [VERIFIED: parent task; `12-CONTEXT.md`]

## Summary

Close the audit debt by extending the existing `examples/ppm-portable/main/main.mbt`, rather than creating a second example or changing `mb-image` production packages. The executable is the only existing Phase-11 support point that can legally compose the public `@ppm` codec with `@ops`, because `ops` has no codec dependency. Extend the existing public/adversarial processing-pipeline tests only for the portable geometry/processing evidence and hostile budget boundary. [VERIFIED: `.planning/v0.3-v0.3-MILESTONE-AUDIT.md`; `examples/ppm-portable/main/moon.pkg`; `modules/mb-image/ops/moon.pkg`]

**Primary recommendation:** Use a 3×3 neutral-RGB strict P6 input, crop `(1,0,2,3)`, `rotate_90`, bridge to straight RGBA8, grayscale, then radius-one clamp-edge `box_blur`; source-over it on a decoded/converted opaque 3×2 P6 background, convert strictly back to RGB8, and encode the exact 29-byte P6 result.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Strict P6 ingress/egress | API / Backend | — | `PpmDecoder`/`PpmEncoder` consume explicit Reader/Writer and policy objects. |
| Crop and physical rotation | API / Backend | Storage | `@ops.crop`/`rotate_90` allocate fresh packed images under caller budgets. |
| RGB/RGBA bridge and filters | API / Backend | Color model | Public ops enforce straight-RGBA encoded-sRGB and perform linear-light processing. |
| Deterministic proof/oracles | CLI executable + test tier | — | The portable example is executable on all four targets; package tests prove the hostile boundary. |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---|---:|---|---|
| MoonBit `moon` | `0.1.20260713` | Four-target execution | Installed project toolchain. [VERIFIED: local `moon --version`] |
| `tchivs/mb-image/ppm` | workspace `0.1.0` candidate | Strict P6 decode/encode | Existing public codec boundary. [VERIFIED: `modules/mb-image/ppm/moon.pkg`] |
| `tchivs/mb-image/ops` | workspace `0.1.0` candidate | Geometry, conversion, filters, composite | Existing public consumer API. [VERIFIED: `modules/mb-image/ops/*.mbt`] |

No external package is installed; therefore a package-legitimacy audit is not applicable.

## Architecture Patterns

### System Architecture Diagram

```text
strict P6 3×3 source ──decode──> RGB8 + builtin-sRGB/TopLeft/empty metadata
  └─ crop(1,0,2,3) ─> 2×3 RGB8 ─ rotate_90 ─> 3×2 RGB8
       └─ RGB8→straight-RGBA8 ─ grayscale ─ box_blur(radius=1) ─┐
strict P6 3×2 background ─decode─> RGB8 ─ RGB8→straight-RGBA8 ──┤
                                                                  └─ source_over ─> RGBA8
                                                                        └─ strict RGBA8→RGB8 ─ encode ─> exact P6 bytes
```

### Recommended File Scope

```text
examples/ppm-portable/main/main.mbt                  # positive strict PPM E2E vector
modules/mb-image/ops/processing_pipeline_test.mbt    # public geometry/filter semantic support
modules/mb-image/ops/processing_pipeline_wbtest.mbt  # hostile blur-budget atomicity
```

Do not alter `modules/mb-image/ops/*.mbt` production implementation, package manifests, README, benchmarks, release scripts, or config. [VERIFIED: `12-CONTEXT.md`; parent task]

### Fixed Positive Vector

Use this source P6 payload (11-byte header + 27-byte raster, 38 bytes total):

```text
P6\n3 3\n255\n
# rows: source x=0 is discarded by crop
01 02 03 | 00 00 00 | ff ff ff
04 05 06 | 40 40 40 | c0 c0 c0
07 08 09 | 80 80 80 | 20 20 20
```

The crop deliberately removes the non-neutral sentinel first column, so a wrong crop origin is observable. `rotate_90` must yield neutral levels `[80,40,00] / [20,c0,ff]`; rotation changes the non-square crop from 2×3 to 3×2 and normalizes metadata orientation to `TopLeft`. [VERIFIED: `modules/mb-image/ops/geometry.mbt:65-132,170-202`; `modules/mb-image/ops/geometry_test.mbt`]

Use a decoded opaque 3×2 background P6 (its RGB bytes may be a visibly different six-pixel sequence) only after converting it to straight RGBA8. It remains metadata-compatible with the filtered source because strict PPM decode creates encoded sRGB, builtin sRGB profile, `TopLeft`, no alpha, and empty opaque metadata; conversion adds straight alpha, and the processing operations retain this compatible identity. [VERIFIED: `modules/mb-image/ppm/decode.mbt:104-126`; `modules/mb-image/ops/processing.mbt:15-21,123-137`; `modules/mb-image/ops/convert.mbt:415-427`]

Choose `radius=1UL`, not zero: `box_blur` uses a 3×3 clamp-to-edge window and charges `pixel_count * 9`, so it is non-degenerate and differentiates both radius and edge policy. [VERIFIED: `modules/mb-image/ops/processing.mbt:180-216`]

### Explicit Budgets and Limits

Every allocation/codec call gets a fresh explicit `Budget`, following `example_budget` in the current executable. For the 3×2 post-rotation image use these exact minima:

| Stage | Output/resources | Explicit budget minimum |
|---|---|---|
| source decode 3×3 | 27 bytes, 9 pixels, work 38 | bytes 27, allocations 1, allocation_size 27, width 3, height 3, pixels 9, work 38 |
| crop 2×3 | 18 bytes, 6 pixels, work 18 | bytes 18, allocations 1, allocation_size 18, width 2, height 3, pixels 6, work 18 |
| `rotate_90` 3×2 | 18 bytes, 6 pixels, work 18 | bytes 18, allocations 1, allocation_size 18, width 3, height 2, pixels 6, work 18 |
| RGB8→RGBA8 | 24 bytes, 6 pixels, work 24 | bytes 24, allocations 1, allocation_size 24, width 3, height 2, pixels 6, work 24 |
| grayscale | 24 bytes, 6 pixels, work 6 | bytes 24, allocations 1, allocation_size 24, width 3, height 2, pixels 6, work 6 |
| blur radius 1 | 24 bytes, 6 pixels, work 54 | bytes 24, allocations 1, allocation_size 24, width 3, height 2, pixels 6, work 54 |
| decoded 3×2 background | 18 bytes, 6 pixels, work 29 | bytes 18, allocations 1, allocation_size 18, width 3, height 2, pixels 6, work 29 |
| background RGB8→RGBA8 | 24 bytes, 6 pixels, work 24 | bytes 24, allocations 1, allocation_size 24, width 3, height 2, pixels 6, work 24 |
| source-over | 24 bytes, 6 pixels, work 6 | bytes 24, allocations 1, allocation_size 24, width 3, height 2, pixels 6, work 6 |
| strict RGBA8→RGB8 | 18 bytes, 6 pixels, work 18 | bytes 18, allocations 1, allocation_size 18, width 3, height 2, pixels 6, work 18 |
| writer/encode | 29 bytes, width 3, height 2, work 29 | writer capacity 29; encoder budget width 3, height 2, work 29 |

Codec/parser ceilings should be explicit and at least `max_input_bytes=64`, `max_output_bytes=64`, `max_width=3`, `max_height=3`, `max_pixels=9`, `max_work=64`; parser ceilings can reuse the current bounded pattern. [VERIFIED: `examples/ppm-portable/main/main.mbt`; `modules/mb-image/ppm/decode.mbt:242-342`; `modules/mb-image/ppm/encode.mbt:142-194`]

## Deterministic Oracles

The neutral crop means grayscale is exact semantic identity for color channels, while radius-one blur remains a real linear-light filter. The independently calculated final blur levels are `72, 84, 93 / 75, a4, c6`; all alpha bytes remain `ff`. The opaque filtered source fully covers the opaque background during source-over, so strict RGBA→RGB succeeds and makes any accidental alpha drop unnecessary. The test must assert intermediate post-rotate dimensions/pixels and post-blur selected pixels as well as final output; otherwise a simplified pipeline could reproduce final bytes. [VERIFIED: `modules/mb-image/ops/processing.mbt:161-216`; `modules/mb-image/ops/convert.mbt:238-286`]

Expected encoded result:

```text
50 36 0a 33 20 32 0a 32 35 35 0a
72 72 72 84 84 84 93 93 93 75 75 75 a4 a4 a4 c6 c6 c6
```

- Exact length: `29`
- Rolling-257 digest used by the existing example: `714923673`
- SHA-256 identity: `005700d6602b144bafcf3d869deee85619c8279c749bf33ca6fea8b43dbe78bf`
- Semantic assertions: crop/rotation extent `3×2`, rotated first/last RGB `80` and `ff`, grayscale RGB channel equality plus `ff` alpha, blurred `(0,0)=72 72 72 ff`, blurred `(2,1)=c6 c6 c6 ff`, composite and encoded output dimensions/bytes/empty diagnostics.

The digest and SHA are additional identity checks, never replacements for exact bytes and semantic pixels. [VERIFIED: existing digest/matches pattern in `examples/ppm-portable/main/main.mbt`; AGENTS.md]

## Common Pitfalls

### Metadata gate after rotation

`composite_source_over` rejects a profile mismatch, orientation mismatch, or nonempty opaque metadata before it charges the budget. Use two strict-decoded inputs and convert them through the public bridge; do not construct alternate metadata or use a non-TopLeft test fixture. [VERIFIED: `modules/mb-image/ops/processing.mbt:123-137`; `modules/mb-image/ppm/decode.mbt:104-126`]

### Blur must be non-degenerate

`radius=0` is explicitly an identity window. Select radius one and assert a changed blurred pixel plus exact work 54. [VERIFIED: `modules/mb-image/README.mbt.md:198-203`; `modules/mb-image/ops/processing.mbt:180-216`]

### Do not add PPM imports to `ops`

The `ops` package has intentionally separate dependencies; adding codec imports just to make an ops test decode PPM would change the public dependency DAG. The real decoder proof belongs in the existing executable. [VERIFIED: `modules/mb-image/ops/moon.pkg`; `examples/ppm-portable/main/moon.pkg`; `modules/mb-image/README.mbt.md`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| P6 parsing/serialization | test-local PPM parser/writer | `@codec.ImageDecoder::decode` / `@codec.ImageEncoder::encode` with `PpmDecoder`/`PpmEncoder` | The existing codec enforces exact EOF, canonical headers, limits, diagnostics, and progress. |
| RGB/RGBA representation change | direct alpha-byte mutation | `rgb8_to_straight_rgba8` and `straight_rgba8_to_rgb8` | Conversion enforces capability, metadata disposition, budget, and strict opaque-alpha policy. |
| Grayscale/blur/composite oracle implementation | production-like duplicate filter | exact fixture bytes + selected semantic pixels | A duplicate implementation would share the same color/rounding errors and weaken the proof. |

## Hostile Boundary

Extend `processing_pipeline_wbtest.mbt` with a named path that succeeds through owned RGB crop, `rotate_90`, RGB→RGBA conversion, and grayscale, then invokes `box_blur(..., 1UL, budget)` with all output resources sufficient except `work=53UL`. It must return `Resource/BudgetExceeded`, operation `image-box-blur`, context `image-box-blur-output-budget`, and leave every `ResourceLimits` member unchanged. This directly proves the non-degenerate filter's preflight/atomicity on all four targets without forcing a `ppm` dependency into `ops`. [VERIFIED: `modules/mb-image/ops/processing.mbt:61-66,180-216`; `modules/mb-image/ops/processing_pipeline_wbtest.mbt`]

## Validation Architecture

Skipped: `.planning/config.json` explicitly sets `workflow.nyquist_validation` to `false`.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V5 Input Validation | Yes | strict PPM parser limits; checked crop and codec dimensions; explicit budgets |
| V6 Cryptography | No | SHA-256 is an evidence identity, not a security control |
| V2/V3/V4 | No | No authentication, session, or access-control surface is introduced |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Oversized/radius-amplified processing work | Denial of service | explicit codec/operation budgets and the radius-one hostile preflight test |
| Misleading byte-only proof | Tampering | exact P6 bytes + digest + intermediate semantic/metadata assertions |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | Precomputed final P6 digest/SHA from the documented linear-light/ties-even algorithm must be confirmed by the first four-target execution before locking the implementation. | Deterministic Oracles | A backend floating-point/quantization difference would require updating the fixed oracle only after inspecting the public result. |

## Open Questions

None that block planning. The first implementation task should run the four executable targets before committing the fixed digest; retain only a value observed identically on all four.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| `moon` | executable/tests | ✓ | `0.1.20260713` | — |
| `moonc` | compilation | ✓ | `v0.10.4+2cc641edf` | — |
| `moonrun` | target execution | ✓ | `0.1.20260713` | — |

## Sources

### Primary (HIGH confidence)

- `.planning/v0.3-v0.3-MILESTONE-AUDIT.md` — exact remaining integration debt.
- `.planning/phases/11-portable-processing-pipeline-evidence/11-VERIFICATION.md` — existing proof conventions and four-target commands.
- `examples/ppm-portable/main/main.mbt` — current public codec/bridge/byte-oracle pattern.
- `modules/mb-image/ops/geometry.mbt`, `processing.mbt`, `convert.mbt` — actual API, metadata, budget, and algorithm contracts.
- `modules/mb-image/ops/processing_pipeline_test.mbt`, `processing_pipeline_wbtest.mbt` — reusable public/hostile test pattern.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependencies; exact local workspace APIs inspected.
- Architecture: HIGH — constrained by the current executable imports and public API contracts.
- Oracles: MEDIUM until four-target execution validates the calculated digest; exact bytes, dimensions, and policy are otherwise code-derived.

**Research date:** 2026-07-20  
**Valid until:** 2026-08-19
