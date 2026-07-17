---
moonbit:
  import:
    - path: moonbit-foundation/mb-color/model
      alias: model
    - path: moonbit-foundation/mb-color/transfer
      alias: transfer
    - path: moonbit-foundation/mb-color/quantize
      alias: quantize
    - path: moonbit-foundation/mb-color/alpha
      alias: alpha
    - path: moonbit-foundation/mb-color/profile
      alias: profile
    - path: moonbit-foundation/mb-core/budget
      alias: budget
---

# mb-color

Portable, explicit reference color semantics for MoonBit Native Foundation.

`mb-color` is an independently versioned `0.1.0` candidate module. No API is
stable and no public release is claimed. Publication remains blocked until
ownership of the intended `moonbit-foundation` mooncakes.io namespace is
verified.

## 0.1.0 candidate contract

| Field | Exact value |
| --- | --- |
| Module | `moonbit-foundation/mb-color` |
| Version/status | `0.1.0` candidate; no stable API or public release is claimed |
| License | Apache-2.0 ([repository license](../../LICENSE)) |
| Repository metadata | `https://github.com/moonbit-foundation/moonbit-foundation` |
| Direct module dependency | `moonbit-foundation/mb-core = 0.1.0` |
| Required targets | `+js+wasm+wasm-gc+native` |

The runnable examples below import public packages directly and are checked by
`moon check README.mbt.md --frozen --target <target>` for every required target.
Candidate compatibility requires migration notes for public changes; it is not
a stable Semantic Versioning promise.

The module has five independently consumable public packages, in publication
order: `model`, `transfer`, `quantize`, `alpha`, and `profile`. This order is a
release sequence, not an implied dependency chain.

## Explicit model and sRGB transfer

Normalized constructors accept only finite values in the closed interval
`[0,1]`; invalid values are rejected rather than clamped or replaced. Encoded
sRGB and linear sRGB are different opaque types, so transfer direction is
visible in every signature.

For encoded `e`, decoding uses the inclusive low branch:

```text
e <= 0.04045 ? e / 12.92 : ((e + 0.055) / 1.055) ^ 2.4
```

For linear `l`, encoding also uses the inclusive low branch:

```text
l <= 0.0031308 ? 12.92 * l : 1.055 * l ^ (1 / 2.4) - 0.055
```

The public absolute tolerances are `1e-12` for one decode or encode and `2e-12`
for round trips away from the published rounded-threshold discontinuities.

```mbt check
///|
test "typed sRGB transfer exposes its numerical contract" {
  let encoded = @model.EncodedSrgbComponent::new(0.5).unwrap()
  let linear = @transfer.decode_srgb(encoded)
  inspect(linear.transfer() == @model.TransferIdentity::LinearSrgb, content="true")
  let roundtrip = @transfer.encode_srgb(linear)
  inspect(
    (roundtrip.value() - 0.5).abs() <= @transfer.roundtrip_absolute_tolerance(),
    content="true",
  )
  inspect(@transfer.decode_absolute_tolerance(), content="0.000000000001")
  inspect(@transfer.encode_absolute_tolerance(), content="0.000000000001")
}
```

## Deterministic quantization

Float-to-eight-bit conversion is an explicit, typed operation. It scales a
validated value by 255 and uses round-to-nearest, ties-to-even; it never calls a
backend rounding primitive and never silently saturates invalid input. Encoded
sRGB and alpha have separate entry points.

```mbt check
///|
test "encoded sRGB and alpha quantize without losing identity" {
  let color = @quantize.quantize_encoded_srgb(
    @model.EncodedSrgbComponent::new(0.5).unwrap(),
  )
  let coverage = @quantize.quantize_alpha(
    @model.NormalizedAlpha::new(0.5).unwrap(),
  )
  inspect(color.value().to_uint64(), content="128")
  inspect(coverage.value().to_uint64(), content="128")
  inspect(
    @quantize.quantize_encoded_srgb(
      @quantize.dequantize_encoded_srgb(color),
    ).value().to_uint64(),
    content="128",
  )
}
```

## Straight and premultiplied alpha

Straight and premultiplied values are four distinct opaque public states:
normalized straight/premultiplied and encoded-eight straight/premultiplied.
Conversions are directional and preserve the encoded-sRGB or linear-sRGB
domain. Zero alpha has one canonical result in both directions: all color
components are zero. A premultiplied encoded component greater than alpha is
invalid and is rejected, never clamped.

Encoded conversion uses checked widened multiplication and exact rational
ties-to-even rounding. Exhaustive evidence proves that
premultiplied-to-straight-to-premultiplied is exact for every valid encoded pair.
Straight-to-premultiplied-to-straight is lossy at low nonzero alpha; its observed
maximum component error is 127 code values, so no stronger identity is claimed.

```mbt check
///|
fn readme_color8(value : Int) -> @model.EncodedSrgb8Component {
  @model.EncodedSrgb8Component::new(value.to_uint64()).unwrap()
}

///|
fn readme_alpha8(value : Int) -> @model.EncodedAlpha8 {
  @model.EncodedAlpha8::new(value.to_uint64()).unwrap()
}

///|
test "encoded alpha conversion is explicit, canonical, and fail closed" {
  let straight = @alpha.StraightEncodedSrgba8::new(
    readme_color8(255),
    readme_color8(128),
    readme_color8(1),
    readme_alpha8(0),
  )
  let zero = @alpha.premultiply_encoded(straight).unwrap()
  inspect(zero.r().value().to_uint64(), content="0")
  inspect(zero.g().value().to_uint64(), content="0")
  inspect(zero.b().value().to_uint64(), content="0")
  inspect(
    @alpha.PremultipliedEncodedSrgba8::new(
      readme_color8(2),
      readme_color8(0),
      readme_color8(0),
      readme_alpha8(1),
    ) is Err(_),
    content="true",
  )
}
```

Normalized constructors and conversions are equally explicit:

```mbt check
///|
test "normalized alpha preserves transfer identity" {
  let straight = @alpha.StraightNormalizedSrgba::linear(
    @model.LinearSrgbComponent::new(0.4).unwrap(),
    @model.LinearSrgbComponent::new(0.2).unwrap(),
    @model.LinearSrgbComponent::new(0.1).unwrap(),
    @model.NormalizedAlpha::new(0.5).unwrap(),
  )
  let premultiplied = @alpha.premultiply_normalized(straight).unwrap()
  inspect(
    premultiplied.transfer() == @model.TransferIdentity::LinearSrgb,
    content="true",
  )
  let restored = @alpha.unpremultiply_normalized(premultiplied).unwrap()
  inspect(restored.alpha().value(), content="0.5")
}
```

## Bounded opaque profile identity

Built-in sRGB identity is direct. Other profile data is an opaque byte payload
with an explicit case-preserving format tag. Tags use the exact ASCII grammar
`[A-Za-z0-9][A-Za-z0-9._+-]{0,31}`; `icc` is only a canonical identity label.
It does not certify that bytes are a valid ICC profile.

The caller supplies `max_payload_bytes`. Tag and payload-limit validation happen
before `mb-core/bytes` performs checked narrowing, allocator approval, atomic
bytes/allocation/allocation-size budget charging, allocation, and copying.
Arbitrary bytes, including an empty payload, round-trip exactly and independently
of the caller buffer. No ICC header is parsed, no transform is computed, and no
semantic equivalence or ICC conformance is claimed.

```mbt check
///|
fn readme_profile_budget(size : UInt64) -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=size,
      allocations=1UL,
      allocation_size=size,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work=0UL,
    ),
  )
}

///|
#warnings("-35")
test "caller-bounded opaque profile bytes round-trip exactly" {
  let builtin = @profile.ProfileIdentity::builtin_srgb()
  inspect(builtin.is_builtin_srgb(), content="true")
  let source = b"\x00\x01\x7f\xff"
  let stored = @profile.OpaqueProfile::from_bytes(
    @profile.ProfileFormatTag::icc(),
    source,
    @profile.ProfileLimits::new(4UL),
    readme_profile_budget(4UL),
  ).unwrap()
  inspect(stored.tag().value(), content="icc")
  inspect(stored.length(), content="4")
  inspect(stored.view().get(3UL).unwrap().to_uint64(), content="255")
}
```

## Evidence and provenance

`fixtures/color/srgb-reference-vectors.json` is generated from the published W3C
CSS Color 4 and ICC sRGB formulas, which are the primary sources. Its endpoints,
thresholds, adjacent values, and other numeric points are project-selected
formula-derived reference points computed by the repository generator.
`fixtures/color/derived-edge-vectors.json` is separately labeled
repository-derived evidence for quantization, alpha, profile limits, and
adversarial cases. Both are generated by
`scripts/fixtures/Generate-ColorVectors.ps1`, registered with SHA-256, source,
license, retrieval date, and redistribution status in `fixtures/manifest.json`,
and reproduced as four package-local generated vector tables. No external
fixture bytes are copied or relabeled as project-authored.

## Exact dependency DAG

The checked package graph is independent of publication order:

- `model -> mb-core/error`
- `transfer -> model` (plus the MoonBit standard `math` package)
- `quantize -> model + mb-core/error + mb-core/checked`; it does not import
  `transfer`
- `alpha -> model + quantize + mb-core/error + mb-core/checked`
- `profile -> mb-core/error + mb-core/budget + mb-core/bytes`; it imports no
  color package

There is no root facade or prelude. The module does not contain additional color
spaces, CSS syntax, gamut mapping, interpolation, image/pixel layout, rendering,
codecs, profile transforms, or an ICC parser.

## Supported targets

Every public package and every example above is checked on the same matrix:

| Target | Status |
| --- | --- |
| `js` | Required |
| `wasm` | Required |
| `wasm-gc` | Required |
| `native` | Required and preferred |

Core algorithms and models are implemented in MoonBit, require no GUI,
filesystem, ambient host state, or native adapter, and keep their own changelog
and version lifecycle.

## Candidate evidence and deferred scope

The exact fixture identities are `color-srgb-reference-vectors` with SHA-256
`ecc7c7d693ea13067a731dc5456677a74222f9ca28163939ab616222a3e00331`
and `color-derived-edge-vectors` with SHA-256
`e4f879895414fb0f78cbdd80dba2805e6c8c68202a16a5764b7b93760fe547c7`.
Their sources, authorship, retrieval date, Apache-2.0 license, redistribution
status, and expected use are recorded in
[`fixtures/manifest.json`](../../fixtures/manifest.json). See the
[0.1.0 candidate changelog](CHANGELOG.md) for the unpublished compatibility
record.

Deferred scope includes additional color spaces, gamut mapping, CSS parsing,
interpolation, image layout/rendering, full ICC parsing or transforms, registry
publication, and performance claims. LLVM is experimental and is not part of
the support matrix.

## Publication source contract

The records below are the exact pre-publication source intent for the `0.1.0`
candidate. The install command becomes usable only after registry publication;
it is not evidence that Mooncakes currently renders or resolves this module.
Package imports are listed in policy order, and the shared support, security,
changelog, compatibility, migration, and RFC routes remain explicit.

<!-- mnf-publication-source:v1 -->
01|install|moon add moonbit-foundation/mb-color@0.1.0
02|imports|moonbit-foundation/mb-color/model,moonbit-foundation/mb-color/transfer,moonbit-foundation/mb-color/quantize,moonbit-foundation/mb-color/alpha,moonbit-foundation/mb-color/profile
03|status|candidate
04|targets|js,wasm,wasm-gc,native
05|toolchain|moon=0.1.20260713;moonc=0.10.4;moonrun=0.1.20260713
06|class|exact
07|support|docs/support.md
08|security|SECURITY.md
09|changelog|CHANGELOG.md
10|migration|not-required
11|rfc|not-required
12|impacts|none
13|registry-source|moon.mod.json
14|registry-render|unknown;proof=PROV-05;phase=8
15|ambiguity|none
<!-- /mnf-publication-source -->
