# Phase 3: Reference Color Semantics - Research

**Researched:** 2026-07-17
**Domain:** Portable sRGB component semantics, deterministic quantization, alpha representation, and bounded opaque profile metadata in MoonBit
**Confidence:** HIGH for repository architecture and pinned-toolchain behavior; MEDIUM for standards-derived numerical guidance because the GSD confidence seam classifies official web sources as MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Component, color-space, and transfer identity
- **D-01:** Public values make component representation, color-space identity, transfer function, and alpha mode explicit. No constructor or operation may obtain any of these from an ambient or undocumented default.
- **D-02:** Use opaque validated component types for normalized finite reference values and encoded 8-bit values. A universal public `Color` bag with freely combinable fields is prohibited; constructors must reject invalid combinations.
- **D-03:** Phase 3's normative built-ins are sRGB primaries/white point with either encoded-sRGB or linear-sRGB transfer. Space identity and transfer identity remain explicit concepts so later extensions do not redefine existing values.

### sRGB conversion and quantization
- **D-04:** Normalized reference components accept only finite values in `[0,1]`. NaN, infinity, and out-of-range values are structured errors; conversion never silently clamps, wraps, or substitutes a default.
- **D-05:** Encoded-sRGB to linear-sRGB and the inverse use the normative piecewise transfer curve with constants and branch boundaries recorded in the public contract and reference evidence. CPU MoonBit behavior is the correctness oracle on all four targets.
- **D-06:** Floating conversion assertions use operation-specific documented absolute tolerances. Float-to-8-bit quantization is a separate explicit operation using round-to-nearest, ties-to-even; validated input means no implicit saturation is required. Research must confirm a portable implementation against the pinned toolchain and official sources.

### Straight and premultiplied alpha
- **D-07:** Straight and premultiplied representations are distinct explicit public states; APIs do not guess or toggle alpha mode implicitly.
- **D-08:** Premultiplication and unpremultiplication operate on validated normalized values and encoded 8-bit values. Encoded operations use widened checked arithmetic and the same documented ties-to-even rule rather than backend casts.
- **D-09:** Zero alpha has one canonical result: color components are zero for both premultiply and unpremultiply. For nonzero alpha, a premultiplied encoded component greater than alpha is invalid and returns a structured error rather than being clamped. Round-trip identity is asserted only where mathematically guaranteed; otherwise error bounds are documented.

### Bounded profile identity and opaque metadata
- **D-10:** Built-in sRGB identity is represented directly. Non-built-in profile data crosses the public seam as an opaque, bounded payload with an explicit format tag; bytes round-trip exactly without interpreting or validating ICC contents.
- **D-11:** Opaque payload creation uses `mb-core` owned bytes/validated views and charges declared size/allocation budgets before copying or retaining data. Oversize, budget rejection, and invalid tag failures are structured and deterministic.
- **D-12:** Phase 3 does not inspect headers, compute transforms from profiles, or claim ICC conformance. A stable optional digest/identifier may be exposed only as identity metadata and must not imply semantic equivalence.

### Reference evidence and qualification
- **D-13:** Reference vectors come from official or otherwise primary specifications and are registered through the repository fixture provenance policy with origin, license/redistribution status, retrieval date, and digest. Hand-authored edge vectors are separate and labeled as derived tests.
- **D-14:** Conformance combines provenance-recorded conversion vectors with invariants: endpoint behavior, branch boundaries, monotonicity, finite/range preservation, quantization bounds, alpha zero/boundary cases, and bounded profile round-trip.
- **D-15:** Every public package and README example is checked on `js`, `wasm`, `wasm-gc`, and `native`. Exact semantic interfaces, imports, publication contents, package DAG, negative fixtures, and tracked-read-only behavior remain Required-lane gates.

### Package and dependency boundary
- **D-16:** Prefer focused acyclic packages such as model/components, transfer/conversion, alpha, and profile rather than a root catch-all. `mb-color` depends only on the minimum portable `mb-core` packages it uses; no reverse or image dependency is allowed.
- **D-17:** Remove the Phase 1 root scaffold once real public packages and checked documentation replace it. Keep the module independently versioned and candidate until later stability review.
- **D-18:** Additional spaces/transfers, chromatic adaptation, gamut mapping, interpolation, CSS syntax, image/pixel layout, codecs, rendering, and full ICC parsing are outside this phase.

### the agent's Discretion
- Exact MoonBit type and package names, internal polynomial/piecewise implementation structure, fixture file format, and tolerance magnitudes are left to research and planning, provided the locked semantics above remain explicit, portable, and independently testable.
- The planner may split the phase into sequential packages/waves and add property or adversarial tests beyond the minimum matrix.

### Deferred Ideas (OUT OF SCOPE)
- Full ICC parsing, profile validation, and profile-driven transforms are deferred beyond Phase 3.
- Additional color spaces and transfer functions, chromatic adaptation, gamut mapping, interpolation, and CSS color syntax require later accepted scope.
- Image storage/layout, channel order, pixel format, codecs, and rendering remain in their owning later phases.
</user_constraints>

## Summary

Phase 3 should be implemented as five small portable packages in this order: `model`, `transfer`, `quantize`, `alpha`, and `profile`. The public model must use opaque validated types and distinct straight/premultiplied aggregate types; no root re-export package or universal `Color` bag should be introduced. The existing repository policy already enforces exact target sets, package imports, generated interfaces, publication contents, fixture provenance, fail-closed negative cases, and read-only qualification, so policy and implementation must change atomically. [VERIFIED: codebase inspection]

The reference transfer functions should use the published sRGB thresholds and constants directly with `Double` and `@math.pow`, while assertions use absolute tolerances instead of exact floating equality. The pinned MoonBit standard library defines `Double` as IEEE-754 binary64, but its `Double::round()` is round-half-up and the JS target delegates `pow` to `Math.pow` while the non-JS targets use MoonBit's shared implementation. Therefore ties-to-even must be implemented explicitly and power-function results must be compared with operation-specific tolerances. [CITED: https://docs.moonbitlang.com/en/stable/language/fundamentals.html] [VERIFIED: pinned MoonBit core source]

Opaque profile metadata should be copied into `mb-core/bytes.OwnedBytes` only after an explicit caller-supplied maximum is checked; `OwnedBytes::from_bytes` already narrows, precharges bytes/allocation/allocation-size budget, then copies. The format tag is identity metadata, not validation. Phase 3 should not parse the 128-byte ICC header, trust its profile-size field, or compute a digest. [VERIFIED: codebase inspection] [CITED: https://www.color.org/specifications/ICC.1-2022-05.pdf]

**Primary recommendation:** implement standards-literal transfer functions, explicit integer/rational ties-to-even helpers, distinct alpha-state types, and an opaque caller-bounded profile wrapper over `mb-core`, then qualify every behavior and policy edge on all four required targets.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Validated normalized and encoded components | `mb-color/model` | `mb-core/error` | Color semantics are domain-owned; structured invalid-input failures reuse the foundation vocabulary. [VERIFIED: RFC 0001 and codebase inspection] |
| Encoded-sRGB/linear-sRGB transfer | `mb-color/transfer` | `moonbitlang/core/math` | Pure portable MoonBit owns the oracle; only the standard power implementation is required. [VERIFIED: codebase inspection] |
| Float/integer quantization | `mb-color/quantize` | `mb-core/checked` | Color owns rounding policy; core owns checked widened arithmetic and narrowing. [VERIFIED: codebase inspection] |
| Straight/premultiplied conversion | `mb-color/alpha` | `model`, `quantize`, `mb-core/checked` | Distinct states and conversion behavior are color semantics; integer safety and rounding are reused. [VERIFIED: codebase inspection] |
| Built-in/opaque profile identity | `mb-color/profile` | `mb-core/bytes`, `mb-core/budget` | Color owns identity; core owns bounded storage, views, and budget charging. [VERIFIED: codebase inspection] |
| Fixture and interface enforcement | Root quality policy | Package tests | Repository policy owns provenance and exact allowlists; packages own semantic tests. [VERIFIED: codebase inspection] |

## Phase Requirements

<phase_requirements>

| ID | Description | Research Support |
|---|---|---|
| COLR-01 | Represent components, color-space identity, transfer function, and alpha mode without implicit defaults. | Opaque component types, explicit identity enums/values, and distinct alpha-state aggregates. |
| COLR-02 | Convert encoded sRGB and linear sRGB with documented finite/range/rounding/tolerance behavior. | Exact piecewise constants, finite/range validation, `@math.pow`, explicit tolerance contract. |
| COLR-03 | Premultiply/unpremultiply with specified zero-alpha and rounding semantics. | Normalized formulas, widened integer rational formulas, canonical zero, ties-to-even helper. |
| COLR-04 | Validate behavior against provenance-recorded vectors and invariants on every target. | Generated standards-derived fixtures, separate adversarial vectors, four-target Required lane. |
| COLR-05 | Preserve bounded profile identity/opaque metadata without full ICC parsing. | Caller limits plus `OwnedBytes`, validated tag, exact byte view, no header inspection. |

</phase_requirements>

## Exact Numerical Contract

### Normalized domain

Use `Double` for the reference normalized domain. `Double` is MoonBit's IEEE-754 64-bit floating type, while `Float` is 32-bit; the narrower type would unnecessarily weaken the reference oracle. [CITED: https://docs.moonbitlang.com/en/stable/language/fundamentals.html]

Constructors must evaluate `is_nan()` and `is_inf()` before the closed-range check and return structured errors; do not use `clamp`, because the locked contract requires rejection. The pinned core exposes `Double::is_nan`, `Double::is_inf`, `Double::floor`, and saturating `Double::to_int`; after validation and scaling to `[0,255]`, conversion to `Int` is in range. [VERIFIED: pinned MoonBit core source]

### sRGB decoding: encoded to linear

For validated encoded component `e` in `[0,1]`:

```text
if e <= 0.04045:
  linear = e / 12.92
else:
  linear = ((e + 0.055) / 1.055) ^ 2.4
```

The threshold, constants, and inclusive low branch match the current W3C CSS Color 4 definition and ICC's official sRGB interpretation material. [CITED: https://www.w3.org/TR/css-color-4/#predefined-sRGB] [CITED: https://registry.color.org/rgb-registry/files/sRGB.pdf]

### sRGB encoding: linear to encoded

For validated linear component `l` in `[0,1]`:

```text
if l <= 0.0031308:
  encoded = 12.92 * l
else:
  encoded = 1.055 * (l ^ (1 / 2.4)) - 0.055
```

The equivalent official sample expresses the power branch as `l > 0.0031308`, which makes the low branch inclusive. [CITED: https://www.w3.org/TR/css-color-4/#color-conversion-code] [CITED: https://registry.color.org/rgb-registry/files/sRGB.pdf]

The rounded published thresholds do not make the two mathematical branches exactly continuous: at `0.04045`, the decoding branches differ by approximately `2.33e-9`, and at `0.0031308`, encoding branches differ by approximately `2.85e-8`. Tests must assert the specified branch selection, not impose an invented continuity invariant. [VERIFIED: local numerical evaluation of cited formulas]

### Tolerance strategy

Use absolute tolerances only in the normalized `[0,1]` domain:

| Operation | Recommended absolute tolerance | Reason |
|---|---:|---|
| standards vector: encoded -> linear | `1.0e-12` | Covers binary64/power implementation last-bit variation while remaining much smaller than 8-bit quantization steps. [VERIFIED: pinned-toolchain structure; tolerance is project recommendation] |
| standards vector: linear -> encoded | `1.0e-12` | Same cross-backend power rationale; threshold branch is asserted separately. [VERIFIED: pinned-toolchain structure; tolerance is project recommendation] |
| encode(decode(x)) or decode(encode(x)) away from a branch discontinuity | `2.0e-12` | Accounts for two floating operations; do not apply across the rounded-threshold discontinuity. [VERIFIED: local numerical evaluation; tolerance is project recommendation] |
| normalized premultiply/unpremultiply for nonzero alpha | `1.0e-12` | One multiply/divide over validated values; zero alpha is exact canonical zero. [CITED: https://www.w3.org/TR/css-color-4/#interpolation-alpha] |

Integer quantization and encoded alpha outputs must be exact and use no tolerance. The planner should make these constants named public documentation values or named test constants so later implementations cannot silently widen them.

### Portable ties-to-even

Do not call `Double::round()`: on the pinned toolchain it is explicitly half-up, including the JS binding to `Math.round`. [VERIFIED: pinned MoonBit core source]

For a validated nonnegative scaled `Double` in `[0,255]`, use:

```moonbit
let lower = scaled.floor().to_int()
let fraction = scaled - lower.to_double()
if fraction < 0.5 { lower }
else if fraction > 0.5 { lower + 1 }
else if lower % 2 == 0 { lower }
else { lower + 1 }
```

For exact nonnegative integer ratio `numerator / denominator`, use widened `UInt64`, checked multiplication when forming the numerator, then quotient/remainder classification:

```moonbit
let q = numerator / denominator
let r = numerator % denominator
let twice_r = r * 2
if twice_r < denominator { q }
else if twice_r > denominator { q + 1 }
else if q % 2 == 0 { q }
else { q + 1 }
```

This exact algorithm was compiled and tested with the pinned toolchain on `js`, `wasm`, `wasm-gc`, and `native`; test cases included `0.5 -> 0`, `1.5 -> 2`, and `2.5 -> 2`. [VERIFIED: pinned-toolchain four-target spike]

For 8-bit premultiplication use `round_even(component * alpha / 255)` with checked widened multiplication. Since 255 is odd, an exact half tie cannot occur in this division, but using the common helper preserves one documented policy. For nonzero-alpha unpremultiplication use `round_even(premultiplied * 255 / alpha)`; ties are possible when `alpha` is even. [VERIFIED: integer arithmetic]

## Alpha Contract

For normalized values, premultiply each rectangular RGB component as `p = c * a`; for nonzero alpha unpremultiply as `c = p / a`. W3C CSS Color defines these operations for rectangular color spaces. [CITED: https://www.w3.org/TR/css-color-4/#interpolation-alpha]

Phase 3 deliberately chooses a stricter zero rule than general CSS interpolation: both directions return canonical RGB zero when alpha is zero. For encoded integer data, validate `premultiplied_component <= alpha` before unpremultiplication; W3C PNG guidance also identifies values above alpha as invalid premultiplied data and recommends zero output for zero alpha. [CITED: https://www.w3.org/TR/PNG-Encoders.html]

Recommended distinct public aggregate states:

- `StraightNormalizedSrgba` and `PremultipliedNormalizedSrgba`, containing explicit encoded/linear component types plus alpha. [VERIFIED: design recommendation constrained by D-01/D-07]
- `StraightEncodedSrgba8` and `PremultipliedEncodedSrgba8`, containing validated 8-bit components and alpha. [VERIFIED: design recommendation constrained by D-02/D-08]
- Constructors encode both space (`sRGB`) and transfer (`encoded-sRGB` or `linear-sRGB`) in the type or required identity arguments; there is no implicit default constructor. [VERIFIED: design recommendation constrained by D-01/D-03]

Do not claim arbitrary premultiply/unpremultiply round-trip identity. Guaranteed identities include canonical zero-alpha output, alpha 255 for encoded values, endpoints, and values whose rational operation is exact. Other encoded round trips should assert a documented component error bound, recommended at most one 8-bit code value after one premultiply/unpremultiply pair, with exhaustive enumeration used to verify the bound before documenting it. [VERIFIED: integer quantization analysis; bound must be exhaustively confirmed during implementation]

## Opaque Profile Seam

ICC.1:2022 defines a profile as a byte-structured artifact with a 128-byte header and an exact size field, but Phase 3 must not inspect those fields. The format tag records the caller's claimed representation only; it does not certify that the bytes satisfy ICC. [CITED: https://www.color.org/specifications/ICC.1-2022-05.pdf]

Recommended API shape:

```text
ProfileIdentity
  - builtin_srgb()
  - opaque(OpaqueProfile)

ProfileFormatTag
  - opaque validated ASCII token, 1..32 bytes
  - canonical icc() constructor

ProfileLimits
  - max_payload_bytes: UInt64 (required, caller supplied)

OpaqueProfile::from_bytes(tag, source: Bytes, limits, budget)
  1. validate tag
  2. compare source length with limits.max_payload_bytes
  3. call OwnedBytes::from_bytes(source, budget)
  4. retain OwnedBytes privately; expose length and immutable ByteView
```

`OwnedBytes::from_bytes` performs checked narrowing, allocator approval, atomic budget precharge for bytes/one allocation/allocation size, allocation, then copy. Reusing it satisfies the required pre-allocation failure ordering without duplicating storage code. [VERIFIED: `modules/mb-core/bytes/owned_bytes.mbt` and `modules/mb-core/budget/budget.mbt`]

Use a caller-supplied maximum rather than a global default. This keeps codec/application policy explicit and lets the same value work in a sandbox or a desktop tool. The tag grammar should be ASCII `[A-Za-z0-9][A-Za-z0-9._+-]{0,31}` and preserve exact accepted bytes/case; `icc()` should emit one documented canonical spelling such as `icc`. [VERIFIED: design recommendation]

Empty payloads should be allowed by the opaque carrier if within limits: the carrier promises byte preservation, not profile validity. Tests and documentation must make clear that `format=icc` plus arbitrary bytes does not claim ICC conformance. [VERIFIED: design consequence of D-10/D-12]

Omit a digest in Phase 3. The exact retained bytes plus format tag already provide identity data, while adding hashing would introduce an unrelated algorithm/API decision. A future digest may be layered on as identity metadata without changing the opaque carrier. [VERIFIED: design recommendation constrained by D-12]

## Standard Stack

### Core

| Library/package | Version | Purpose | Why Standard |
|---|---:|---|---|
| MoonBit `Double` and `moonbitlang/core/math` | pinned toolchain `0.1.20260713` / core accompanying compiler | Binary64 validation, floor, and power | Official standard library, portable across the four required targets. [VERIFIED: local toolchain and pinned core source] |
| `moonbit-foundation/mb-core/error` | workspace `0.1.0` candidate | Structured invalid-input/state/resource failures | Existing public error vocabulary and exact interface policy. [VERIFIED: codebase inspection] |
| `moonbit-foundation/mb-core/checked` | workspace `0.1.0` candidate | Widened checked multiply/narrowing | Existing overflow-before-work contract. [VERIFIED: codebase inspection] |
| `moonbit-foundation/mb-core/budget` | workspace `0.1.0` candidate | Explicit bytes/allocation/allocation-size limits | Atomic preflight/commit charging already implemented. [VERIFIED: codebase inspection] |
| `moonbit-foundation/mb-core/bytes` | workspace `0.1.0` candidate | Owned profile bytes and immutable views | Existing precharged copy and retained-view semantics. [VERIFIED: codebase inspection] |

### Supporting

| Mechanism | Purpose | When to Use |
|---|---|---|
| MoonBit black-box `*_test.mbt` | Validate only public color contracts | Every public package. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html] |
| MoonBit white-box `*_wbtest.mbt` | Validate branch, rational rounding, and representation invariants | Internal helpers and exhaustive encoded domains. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html] |
| Literate `.mbt.md` | Four-target public examples | Module README and package-facing documentation. [CITED: https://docs.moonbitlang.com/en/stable/language/docs.html] |
| Root PowerShell Required lane | Exact policy/interface/package/target/fixture/read-only gate | Every task/wave and final phase gate. [VERIFIED: codebase inspection] |

No external package is required or recommended. Package legitimacy audit is therefore not applicable. [VERIFIED: dependency analysis]

## Architecture Patterns

### System Architecture Diagram

```text
validated caller input
        |
        +--> model constructors --> explicit component/space/transfer/alpha state
        |                              |
        |                              +--> transfer --> normalized reference result
        |                              |
        |                              +--> quantize --> exact encoded-8 result
        |                              |
        |                              +--> alpha --> distinct straight/premultiplied state
        |
        +--> profile tag + bytes + explicit limits + Budget
                                       |
                                       +--> validate size/tag
                                       +--> mb-core OwnedBytes precharge/copy
                                       +--> immutable exact-byte view

fixtures/manifest.json + generated vectors --> package conformance tests
policy/foundation.json ---------------------> exact DAG/interface/publication gate
```

### Recommended Project Structure and DAG

```text
modules/mb-color/
├── model/       # opaque components and explicit identities
├── transfer/    # sRGB encoded <-> linear reference functions
├── quantize/    # normalized <-> encoded-8 and shared ties-even helpers
├── alpha/       # distinct straight/premultiplied conversions
├── profile/     # builtin identity and bounded opaque payload
└── README.mbt.md

model    -> mb-core/error
transfer -> model, mb-core/error, moonbitlang/core/math
quantize -> model, mb-core/error, mb-core/checked
alpha    -> model, quantize, mb-core/error, mb-core/checked
profile  -> mb-core/error, mb-core/budget, mb-core/bytes
```

No package imports the module root, `mb-image`, a host package, or a package to its right in the order above. The root scaffold is removed instead of becoming a re-export/prelude. [VERIFIED: design recommendation constrained by repository DAG]

### Pattern 1: Validate at construction

Store `Double` or `Byte` behind opaque fields. Constructors reject non-finite/range-invalid values; accessors return the validated scalar. Conversion functions accept only validated types, so internal transfer and alpha code never needs clamping. [VERIFIED: established Phase 2 repository pattern]

### Pattern 2: Separate semantic identity from representation

Keep space, transfer, component encoding, and alpha mode independently explicit but prevent invalid combinations with typed constructors/aggregate types. Do not expose a public struct whose fields can be freely recombined. [VERIFIED: D-01/D-02]

### Pattern 3: Exact integer decisions before narrowing

Represent 8-bit arithmetic in `UInt64`, form numerators through `@checked.checked_mul`, decide rounding from quotient/remainder, verify `<=255`, then narrow. Never let target-specific floating casts decide encoded output. [VERIFIED: D-08 and pinned-toolchain analysis]

### Pattern 4: Policy and topology change atomically

When a package lands, update its `moon.pkg`, public interface, exact imports, publication files, tests, and `policy/foundation.json` in the same plan. The Required lane compares these as closed allowlists. [VERIFIED: codebase inspection]

### Anti-Patterns to Avoid

- **`Double::round()` for quantization:** it is half-up, not ties-to-even. [VERIFIED: pinned MoonBit core source]
- **Exact equality for `pow` results:** JS and non-JS use different implementations; use absolute tolerances and exact branch tests. [VERIFIED: pinned MoonBit core source]
- **Clamping invalid public inputs:** it violates the locked rejection contract and hides caller defects.
- **Continuity assertion at rounded sRGB thresholds:** the published branch constants have small discontinuities. [VERIFIED: local numerical evaluation of cited formulas]
- **Parsing or trusting ICC header size:** this expands scope and changes opaque transport into validation. [CITED: https://www.color.org/specifications/ICC.1-2022-05.pdf]
- **Re-export root/prelude:** it hides exact imports and invites a catch-all dependency.
- **Copied external fixture bytes without confirmed redistribution:** the repository policy rejects them. [VERIFIED: codebase inspection]

## Fixture Provenance and Negative Cases

Generate standards-derived numeric vectors with a checked-in deterministic project generator rather than copying external files. Register the generated output in `fixtures/manifest.json` with `origin=generated`, official formula URL in `source`, the project generator as author, retrieval date, actual SHA-256, `Apache-2.0`, `redistribution_status=not-applicable`, and a COLR-specific expected use. This preserves derivation evidence without mislabeling external bytes as project-authored. [VERIFIED: repository fixture policy; strategy is recommendation]

Keep two clearly separate artifacts:

1. `fixtures/color/srgb-reference-vectors.json` — endpoints, official sample values, both thresholds, and values on both sides generated from the cited formula.
2. `fixtures/color/derived-edge-vectors.json` — locally authored invalid inputs, tie cases, alpha boundaries, and profile limit cases, labeled as derived/adversarial rather than normative.

Required negative/adversarial classes:

- component constructors: NaN, positive/negative infinity, negative finite value, value above 1;
- transfer: exact threshold, immediate representable neighbors around each threshold, endpoints, monotonic sequence, and output finite/range preservation;
- quantize: exact scaled `0.5`, `1.5`, `2.5`, near-half neighbors, 0, 1, and all 256 encoded values for dequantize/requantize;
- alpha: zero alpha with nonzero straight color, zero premultiplied values, component greater than alpha, alpha 1/254/255, and exhaustively enumerated `(component, alpha)` encoded pairs;
- profile: empty/overlong/invalid-ASCII tag, payload one byte over explicit maximum, insufficient bytes budget, zero allocation budget, insufficient allocation-size budget, exact-limit success, empty payload success, and byte-for-byte view round-trip;
- policy: undeclared package, reverse/extra import, semantic-interface drift, publication-file drift, missing target, missing/mismatched fixture digest, unconfirmed external redistribution, and quality command mutating tracked files. [VERIFIED: repository policy seam and phase decisions]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Fractional exponent | Custom polynomial/log-exp approximation | `@math.pow` | Standard-library portable behavior; tolerate final-bit target variance. [VERIFIED: pinned MoonBit core source] |
| Buffer ownership/bounds | New color-specific byte container | `mb-core/bytes.OwnedBytes` and `ByteView` | Existing retained storage, bounds, allocation ordering, and tests. [VERIFIED: codebase inspection] |
| Resource accounting | Local counters/default profile maximum | Explicit `ProfileLimits` plus `mb-core/budget` | Existing atomic hierarchical preflight and structured failures. [VERIFIED: codebase inspection] |
| ICC validation/transforms | Header/tag parser or color-management engine | Opaque format tag plus exact bytes | Full ICC is deferred and materially larger than the seam. [CITED: https://www.color.org/specifications/ICC.1-2022-05.pdf] |
| Backend rounding casts | `round`, `to_int`, or saturation as policy | Explicit ties-even helper over validated values | The pinned `round` rule is wrong for this contract and casts obscure tie behavior. [VERIFIED: pinned MoonBit core source] |
| Fixture provenance validator | New color-only manifest | Existing `fixtures/manifest.json` and `Assert-FixtureManifest` | Repository-wide schema already validates containment, dates, digest, origin, and redistribution. [VERIFIED: codebase inspection] |

## Common Pitfalls

### Pitfall 1: Wrong boundary comparator

**What goes wrong:** `0.04045` or `0.0031308` takes the power branch.
**Why it happens:** implementations paraphrase the formula and lose the inclusive low branch.
**How to avoid:** name constants and test exact threshold plus immediate neighbors.
**Warning signs:** endpoint vectors pass but branch-boundary vectors fail. [CITED: https://www.w3.org/TR/css-color-4/#color-conversion-code]

### Pitfall 2: Accidental half-up rounding

**What goes wrong:** half-way quantization differs from the locked ties-to-even rule.
**Why it happens:** MoonBit's pinned `Double::round()` and JS `Math.round` are half-up.
**How to avoid:** centralize explicit floor/parity and quotient/remainder helpers.
**Warning signs:** `0.5 -> 1` or `2.5 -> 3`. [VERIFIED: pinned MoonBit core source]

### Pitfall 3: Alpha state becomes ambiguous

**What goes wrong:** a caller passes premultiplied data where straight data is expected.
**Why it happens:** an enum field or Boolean is separated from untyped RGB components.
**How to avoid:** use distinct opaque aggregate types and explicit conversion names.
**Warning signs:** APIs accept a generic RGBA plus `premultiplied=true`.

### Pitfall 4: Budget check after copy

**What goes wrong:** oversized opaque data allocates before rejection.
**Why it happens:** profile code copies to a local array, then charges the budget.
**How to avoid:** explicit maximum check first, then call `OwnedBytes::from_bytes` directly.
**Warning signs:** a profile constructor creates `FixedArray` or calls `Bytes.copy`. [VERIFIED: existing mb-core ordering]

### Pitfall 5: Fixture provenance overclaim

**What goes wrong:** derived values are described as official vectors or external bytes are committed without redistribution confirmation.
**Why it happens:** formula source, generated output, and copied fixture are conflated.
**How to avoid:** generated standards-derived and project-adversarial artifacts are separate and accurately labeled.
**Warning signs:** `origin=generated` with no generator, or an external record marked `not-applicable`. [VERIFIED: repository fixture policy]

## Code Examples

### Transfer branch

```moonbit
// Formula source: https://www.w3.org/TR/css-color-4/#color-conversion-code
fn decode_srgb(value : Double) -> Double {
  if value <= 0.04045 {
    value / 12.92
  } else {
    @math.pow((value + 0.055) / 1.055, 2.4)
  }
}
```

This example assumes an already validated opaque input type in production; raw `Double` is shown only to isolate the numerical pattern. [CITED: https://www.w3.org/TR/css-color-4/#color-conversion-code]

### Encoded alpha ratio

```moonbit
fn round_ratio_ties_even(numerator : UInt64, denominator : UInt64) -> UInt64 {
  let q = numerator / denominator
  let r = numerator % denominator
  let twice_r = r * 2
  if twice_r < denominator { q }
  else if twice_r > denominator { q + 1 }
  else if q % 2 == 0 { q }
  else { q + 1 }
}
```

Production code must obtain `numerator` via checked multiplication and must reject zero denominator before calling the helper. [VERIFIED: four-target pinned-toolchain spike and design requirement]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| `moon` | Four-target build/test/docs | yes | `0.1.20260713` (`75c7e1f`) | none needed |
| `moonc` | Compiler | yes | `v0.10.4+2cc641edf` | none needed |
| `moonrun` | Wasm execution/tests | yes | `0.1.20260713` (`75c7e1f`) | none needed |
| PowerShell | Root Required lane | yes | repository workflow already executes | none needed |

[VERIFIED: local environment probes]

No external service, native library, ICC engine, or package installation is required.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | no | No identity boundary in a pure color library. |
| V3 Session Management | no | No sessions or mutable service state. |
| V4 Access Control | no | No privileged operation or resource lookup. |
| V5 Input Validation | yes | Opaque constructors, finite/range checks, checked arithmetic, explicit maximum, and budget-before-allocation. |
| V6 Cryptography | no | Digest is deliberately omitted; fixture SHA-256 remains repository provenance tooling, not a color API. |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| NaN/infinity bypasses range comparisons | Tampering | Explicit non-finite rejection before range checks. [VERIFIED: IEEE-754 behavior and D-04] |
| Oversized opaque profile triggers allocation pressure | Denial of Service | Caller maximum plus atomic `Budget` precharge before `OwnedBytes` allocation. [VERIFIED: codebase inspection] |
| Integer overflow in alpha numerator | Tampering/DoS | `UInt64` plus checked multiplication and checked narrowing. [VERIFIED: mb-core contract] |
| Invalid premultiplied component is silently repaired | Tampering | Reject component greater than alpha; never clamp. [CITED: https://www.w3.org/TR/PNG-Encoders.html] |
| Opaque bytes mislabeled as validated ICC | Spoofing | Documentation and types state format tag is identity metadata only. [CITED: https://www.color.org/specifications/ICC.1-2022-05.pdf] |

## State of the Art

| Old/current scaffold approach | Phase 3 approach | Impact |
|---|---|---|
| Private root probe with no public API | Focused public candidate packages with exact allowlists | Real semantic surface replaces scaffold without root catch-all. [VERIFIED: codebase inspection] |
| Implicit/default color metadata common in convenience APIs | Explicit space, transfer, representation, and alpha state | Ambiguous combinations become unrepresentable. [VERIFIED: locked decision] |
| Backend/library rounding operation | Explicit ties-to-even classification | Deterministic encoded output on every target. [VERIFIED: pinned-toolchain spike] |
| ICC parsing as prerequisite for profile support | Bounded opaque byte carrier | Future codecs can preserve metadata without expanding v0.1 scope. [VERIFIED: locked decision] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| — | None. All technical facts are verified from the codebase/pinned toolchain or cited to official primary material; recommendations are labeled as such. | — | — |

## Open Questions

No blocking research questions remain. The planner should encode the recommended tolerance constants, 32-byte tag bound, caller-supplied profile maximum, and no-digest decision explicitly so they are reviewable rather than left as implementation accidents.

## Project Constraints (from AGENTS.md)

- Core algorithms and shared models are implemented in MoonBit; no foreign color stack is used.
- Native remains preferred, but every Phase 3 public package supports `js`, `wasm`, `wasm-gc`, and `native`.
- Any future FFI stays narrow, isolated, documented, replaceable, and outside this phase.
- Public package dependencies are acyclic and explicitly documented; `mb-color` imports only required `mb-core` packages.
- APIs remain candidate; stable claims require the later policy gate and SemVer obligations.
- Operations are deterministic and require no GUI, filesystem, process-global, locale, or host state.
- Performance claims require reproducible workloads; Phase 3 makes no unsupported performance claim.
- New modules or breaking architectural changes require RFCs; Phase 3 stays inside accepted RFC 0001.
- GSD workflow is mandatory for edits; this research is produced through the active Phase 3 planning workflow.
- The codebase knowledge graph was checked but `.planning/graphs/graph.json` is absent; repository file/interface inspection is the permitted fallback. [VERIFIED: local inspection]

## Sources

### Primary official material (GSD seam: MEDIUM confidence)

- https://www.w3.org/TR/css-color-4/ — current sRGB definitions, conversion sample, and normalized alpha premultiplication.
- https://registry.color.org/rgb-registry/files/sRGB.pdf — ICC official interpretation of IEC sRGB component transfer functions.
- https://webstore.iec.ch/en/publication/6169 — official IEC 61966-2-1 identity and scope; detailed standard text is paywalled.
- https://www.color.org/specifications/ICC.1-2022-05.pdf — ICC profile architecture, header, and exact byte-size semantics.
- https://www.w3.org/TR/PNG-Encoders.html — encoded premultiplied validity, unpremultiplication, nearest-integer guidance, and zero-alpha output.
- https://docs.moonbitlang.com/en/stable/language/fundamentals.html — MoonBit numeric type definitions.
- https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html — test imports, target declarations, and four-target behavior.
- https://docs.moonbitlang.com/en/stable/language/docs.html — literate/document test behavior.
- https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html — target and test command surface.

### Repository and pinned-toolchain evidence (HIGH confidence)

- `C:/Users/Admin/.moon/lib/core/builtin/double_round*.mbt` — pinned half-up `Double::round`, floor behavior, and JS binding.
- `C:/Users/Admin/.moon/lib/core/builtin/double_pow_*.mbt` — JS `Math.pow` versus shared non-JS implementation.
- `modules/mb-core/*/pkg.generated.mbti` and source — public error/checked/budget/bytes contracts and allocation ordering.
- `policy/foundation.json`, `fixtures/manifest.json`, and `scripts/quality/*.ps1` — exact package/interface/provenance/negative/read-only seams.
- Four-target temporary MoonBit spike — explicit floor/parity and quotient/remainder ties-to-even compiled and passed on `js`, `wasm`, `wasm-gc`, and `native`; temporary source was removed after the probe.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependency; all required runtime/library seams are locally present and version-pinned.
- Architecture: HIGH — locked decisions, accepted RFC, Phase 2 public interfaces, and exact policy enforcement agree.
- Numerical constants: MEDIUM — official W3C/ICC sources are primary, but GSD's websearch confidence classifier returns MEDIUM even when verified.
- Portable rounding: HIGH — pinned source inspection plus a passing four-target compile/test spike.
- Pitfalls: HIGH — derived from exact locked behavior, pinned backend implementations, and repository fail-closed gates.

**Research date:** 2026-07-17
**Valid until:** 2026-08-16 for project/policy findings; re-check MoonBit numeric implementation if the pinned toolchain changes.
