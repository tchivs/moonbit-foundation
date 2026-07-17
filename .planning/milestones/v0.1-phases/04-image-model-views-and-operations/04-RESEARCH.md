# Phase 4: Image Model, Views, and Operations - Research

**Researched:** 2026-07-17
**Domain:** Portable image layout validation, retained views, deterministic U8 operations, bounded metadata, and codec-facing contracts in MoonBit
**Confidence:** HIGH for repository architecture and pinned-toolchain behavior; MEDIUM for standards-derived orientation and generic stride guidance

<user_constraints>
## Locked Decisions

- Descriptors explicitly name dimensions, component type, channel order, layout, planes, strides, endianness, color/profile identity, alpha mode, orientation, and metadata. No ambient defaults.
- The model may describe packed or planar U8/U16/F32 storage; Phase 4 operations support only encoded-sRGB `Rgb8`, straight `Rgba8`, and premultiplied `Rgba8`.
- Owned images require positive dimensions. Plane ranges are checked half-open byte ranges with nonnegative strides, sufficient row bytes, contained storage, and no overlapping planes.
- Immutable views retain storage. Mutable views are callback-scoped leases and cannot escape or overlap. Crops are zero-copy when the layout can represent them.
- Orientation uses the eight Exif states. Orientation application allocates a canonical TopLeft result; ordinary crop/flip/resize operate in stored coordinates and preserve the orientation field.
- Nearest resize maps `floor(dst_index * src_extent / dst_extent)` using checked integer arithmetic. It performs no filtering or implicit color conversion.
- Metadata is bounded and deterministically ordered. Duplicate keys are rejected. Each operation has a testable preserve/transform/discard disposition.
- Codec contracts use `mb-core` Reader/Writer/budgets/diagnostics and never paths, URLs, global registries, or a required Seeker.
- All public packages, examples, fixtures, semantic interfaces, imports, and publication files qualify on `js`, `wasm`, `wasm-gc`, and `native`.

## Research Discretion Resolved

- Use focused packages `model`, `storage`, `ops`, `metadata`, and `codec`; do not create a root facade.
- Keep owned images strictly positive-sized. Permit a canonical empty immutable crop view only as a non-owning result; mutable empty crops are rejected because they provide no useful lease and complicate alias rules.
- Reject duplicate metadata keys at construction. Store entries sorted by canonical key bytes so equality and disposition tests are target-independent.
- Report unsupported representations with existing `CoreError` `CapabilityUnavailable` plus bounded stable context tokens. Do not expand `mb-core` error vocabulary during this phase.
- Operations that could alias allocate a distinct output. The initial copy operation is source-view to fresh owned image; no public in-place copy contract is introduced.
</user_constraints>

## Summary

Phase 4 should build a general validated descriptor around a deliberately narrow executable format spine. Validation must finish before allocation or access: positive logical dimensions, checked row-byte calculations, stride sufficiency, per-plane extent, storage containment, and pairwise disjoint ranges. The implementation should reuse `mb-core/checked` for arithmetic/ranges, `mb-core/bytes` for retained immutable views and callback-scoped mutation, `mb-core/io` for codec seams, and `mb-color` for alpha/profile semantics. [VERIFIED: codebase inspection]

The descriptor should own layout vocabulary absent from `mb-color`: no-alpha state, component storage type, channel order, endianness, plane layout, subsampling, and Exif orientation. `mb-color` remains authoritative only for sRGB identities, straight/premultiplied alpha conversion, quantization, and opaque profile identity. This avoids turning color semantics into storage semantics or introducing a reverse dependency. [VERIFIED: codebase inspection]

Stride is independent of visible row width and may include padding; planar layouts require independently validated plane starts, strides, and extents. Microsoft guidance confirms both properties, while the repository's half-open checked ranges provide the exact safe representation. Negative stride and bottom-up addressing are excluded from Phase 4, so all offsets remain unsigned and monotone. [CITED: https://learn.microsoft.com/en-us/windows/win32/medfound/image-stride]

Exif orientation is a closed eight-state mapping. States 5-8 exchange display width and height. The model stores orientation as metadata; `apply_orientation` is the only operation that rewrites pixel coordinates and normalizes the field to TopLeft. [CITED: https://www.cipa.jp/std/documents/e/DC-X010-2017.pdf]

**Primary recommendation:** validate a closed descriptor before constructing storage, retain a single backing owner through immutable views, map all mutation through one callback lease, implement deterministic fresh-output U8 operations, and keep codec interfaces limited to prefix probing plus Reader/Writer decode/encode.

## Architecture and Reuse Map

| Phase 4 responsibility | Package | Existing dependency | Required boundary |
|---|---|---|---|
| Descriptor vocabulary and validation | `mb-image/model` | `mb-core/checked`, `mb-core/error`, `mb-color/model`, `mb-color/profile` | Storage/layout semantics remain image-owned; opaque validated descriptor exposes no freely mutable fields. |
| Owned image and views | `mb-image/storage` | `mb-core/bytes`, `budget`, `checked`; image model | `OwnedImage` retains `OwnedBytes`; `ImageView` retains `ByteView`; mutation occurs only inside `with_mut_view`. |
| Copy, crop, flips, orientation, nearest resize, pixel conversion | `mb-image/ops` | model/storage, `mb-color/alpha` | Closed U8 format dispatch; fresh output for alias safety; checked coordinate arithmetic. |
| Bounded ordered metadata | `mb-image/metadata` | `mb-core/bytes`, `budget`, `error`; color profile | Reject duplicates and oversize values; stable ordering; per-operation disposition result. |
| Codec-facing contracts | `mb-image/codec` | model/storage, `mb-core/io`, `budget`, `error` | Probe accepts caller-owned prefix bytes; decode consumes Reader; encode writes Writer; no seek assumption or registry. |

## Validation Pipeline

Perform descriptor construction in this order and return a structured error at the first failed invariant:

1. Reject zero width or height for owned images and enforce declared width/height/pixel limits.
2. Validate closed enum combinations: component type, channel order, alpha semantics, endianness relevance, and plane count.
3. Compute logical row bytes, plane row counts, stride products, and allocation extents with `checked_mul`/`checked_add`; never narrow before the full-width check.
4. Require `stride >= logical_row_bytes`; padding is permitted and is never interpreted as pixels.
5. Build `CheckedRange::from_start_length` for every plane and require containment in the backing storage range.
6. Reject every pair of overlapping plane ranges, including two logical planes sharing the same bytes. Touching half-open ranges are allowed.
7. Validate metadata count, key/value sizes, total bytes, profile payload limit, and duplicate-free canonical key ordering.
8. Only after all pure validation succeeds, allocate/copy backing storage or expose access.

The general descriptor can represent planar data, but Phase 4 operations return `CapabilityUnavailable` with an operation/layout token unless the descriptor is one of the three supported packed U8 formats. This makes the model extensible without pretending the initial algorithms are universal.

## Storage, Lifetime, and Budget Contract

`@checked.Dimensions::new` accepts zero axes, so image constructors must enforce positive dimensions explicitly. `OwnedBytes::new` and `from_bytes` already charge bytes, allocation count, and maximum allocation size. Charging the same fields before calling them would double-charge. [VERIFIED: codebase inspection]

The safe Phase 4 allocation sequence is:

- validate image dimension ceilings and pixel/work ceilings without consuming storage budget;
- validate all layout arithmetic and required storage length;
- invoke `OwnedBytes` exactly once to own storage charging and allocation;
- do not separately call `Budget::charge` for bytes/allocation/allocation-size;
- where an operation needs a work quota, charge work only after every fallible pure validation and immediately before the no-fail deterministic loop.

Because the current public `Budget` has no refund transaction, a constructor must not consume dimension/work charges before a later allocation can fail. Tests must assert the exact post-failure remaining budget for invalid descriptors, allocator rejection, and unsupported layouts.

One `OwnedBytes` permits only one active mutable lease. `with_mut_view` therefore acquires one whole/enclosing lease, maps logical plane/row offsets internally, and invalidates all derived handles at callback exit. It must not acquire independent leases per plane. Immutable crops retain a `ByteView` plus descriptor-relative origin/range metadata; zero-copy is valid only when every referenced row and plane remains representable without fabricating contiguity.

## Deterministic Operation Contracts

### Coordinates and crops

- Rectangles are half-open `[x, x+width) x [y, y+height)` and all additions are checked.
- A zero-area immutable crop returns one canonical empty non-owning view; it performs no backing access.
- Nonempty crops preserve stored-coordinate orientation and metadata.
- Packed padded rows remain views by preserving parent stride and checked start offset.

### Copy and flips

- `copy` produces a fresh tightly packed owned image and copies logical row bytes only; padding is not observable output.
- Horizontal and vertical flips produce fresh images in Phase 4, eliminating backing-alias ambiguity because `ByteView` intentionally exposes no storage identity.
- Orientation metadata is preserved by plain copy/flip. `apply_orientation` implements the Exif mapping and sets orientation to TopLeft.

### Nearest resize

For each destination coordinate use:

```text
source = min(source_extent - 1,
             floor(destination * source_extent / destination_extent))
```

Compute the product with checked `UInt64`; do not use `mb-color/quantize.round_ratio_ties_even`, floating point, pixel centers, filtering, or hidden color conversion. Explicitly test 1xN, Nx1, upscale, downscale, final pixel, and multiplication-overflow rejection.

### Pixel conversion

- `Rgb8 -> StraightRgba8`: append opaque alpha 255.
- `StraightRgba8 -> Rgb8`: accept only all-opaque pixels unless an explicitly named lossy option is provided; lossy mode reports alpha discard.
- `StraightRgba8 <-> PremultipliedRgba8`: call `mb-color/alpha` contracts so ties-to-even, `p <= a`, and canonical zero-alpha behavior remain identical.
- Conversion updates format/alpha fields and preserves profile identity only when color identity is unchanged.

## Metadata Disposition

Represent metadata as bounded core fields plus ordered opaque codec entries. Keys are validated nonempty ASCII tokens with a project cap; values are bounded retained bytes. Construction sorts keys and rejects duplicates. Operations return or expose a deterministic disposition record so loss is machine-testable:

| Operation | Disposition |
|---|---|
| copy, crop | Preserve all metadata and orientation. |
| horizontal/vertical flip, resize | Preserve metadata; retain stored-coordinate orientation. |
| apply orientation | Preserve other metadata; transform orientation to TopLeft. |
| RGB/RGBA or alpha-mode conversion | Transform format/alpha; preserve color/profile identity; report any explicit lossy alpha discard. |
| codec decode/encode | Codec supplies an ordered disposition; unknown keys are never silently reinterpreted. |

## Codec Contract

`Reader` does not imply `Seeker`, and bounded readers may be non-seeking. Therefore probing must accept a caller-supplied immutable prefix view and report match/no-match/need-more without consuming a stream. Decoding accepts `&Reader`, explicit options and budgets, and returns an owned image plus metadata disposition/diagnostics. Encoding accepts an image view, `&Writer`, explicit options and budgets. No contract opens files, resolves URLs, rewinds a reader, registers codecs globally, or implements PPM; Phase 5 owns the first codec implementation.

MoonBit trait objects support this backend-neutral shape, while package coherence keeps implementations controlled by the defining package policy. [CITED: https://docs.moonbitlang.com/en/latest/language/methods.html] [CITED: https://docs.moonbitlang.com/en/latest/language/packages.html]

## Requirements Coverage

| Requirement | Research-backed implementation evidence |
|---|---|
| IMAG-01 | Opaque explicit descriptor with dimensions, storage/layout, color/alpha, orientation, and metadata identities. |
| IMAG-02 | Ordered validation pipeline with checked arithmetic, ranges, containment, overlap rejection, and budget rules before access/allocation. |
| IMAG-03 | Retained immutable views, callback-scoped mutable leases, validated disjoint split rules, and representable zero-copy crops. |
| IMAG-04 | Fresh-output copy, flips, Exif orientation application, integer-floor nearest resize, and closed U8 conversions. |
| IMAG-05 | Bounded sorted duplicate-free metadata plus per-operation preserve/transform/discard evidence. |
| IMAG-06 | Reader/Writer/prefix-based codec contracts without filesystem, seek, registry, or concrete codec policy. |
| IMAG-07 | Generated adversarial fixtures and exact four-target package/interface/publication qualification. |

## Verification Architecture

- Add public black-box tests for every descriptor constructor, view lifetime, supported operation, metadata disposition, and codec double.
- Add white-box tests for one-byte-short planes, padded rows, checked overflow, pairwise overlap, stale mutable leases, orientation 1-8 coordinate tables, and resize edge mappings.
- Generate package-local MoonBit vectors for plane layouts, orientation coordinate maps, nearest resize cases, pixel conversions, and metadata ordering. Follow `Generate-ColorVectors.ps1`: invariant culture, UTF-8 without BOM, LF output, deterministic rendering, `-Check`, SHA-256, and fixture manifest provenance.
- Include negative compile/interface fixtures proving no mutable handle escape API, no filesystem/URL/registry codec seam, no root re-export facade, and no unapproved dependency direction.
- After each plan run the focused package command, then `pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required`. The final phase gate must pass all four targets and tracked-read-only checks.

## Planning Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Budget double charge or irreversible partial consumption | Let `OwnedBytes` own storage charges; charge work only immediately before no-fail loops; assert remaining budget on every failure path. |
| Descriptor promises unsupported algorithms | Closed per-operation format predicates and `CapabilityUnavailable` tokens. |
| Undetectable backing alias | Initial mutating/copy operations allocate fresh outputs; mutable access remains within one owner lease. |
| Orientation ambiguity | Generated eight-state source-to-destination coordinate table and display-dimension assertions. |
| Planar offset/stride overflow | Checked full-width arithmetic and half-open plane ranges before any narrowing or access. |
| Metadata nondeterminism/loss | Sorted duplicate-free storage and explicit disposition values asserted per operation. |
| Codec accidentally requires rewind or host state | Prefix-only probe, Reader/Writer methods, test doubles that are non-seeking and short-progress capable. |
| Policy drift while replacing scaffold | Change implementation, exact policy topology, generated interface, README, fixtures, and negative cases atomically in each plan. |

## Recommended Plan Decomposition

1. Descriptor vocabulary, validation, and exact package-policy spine.
2. Owned storage, immutable views, callback-scoped mutable views, and crop semantics.
3. Bounded ordered metadata and disposition model.
4. Fresh copy and flips.
5. Exif orientation application and generated orientation evidence.
6. Integer-floor nearest resize and pixel-format/alpha conversion.
7. Backend-neutral codec contracts with non-seeking test doubles.
8. Cross-package fixtures, documentation, scaffold removal, policy closure, and four-target phase verification.

## Sources

- Local: `modules/mb-core/{checked,bytes,budget,io,error}`, generated interfaces, and tests.
- Local: `modules/mb-color/{model,alpha,quantize,profile}`, generated interfaces, tests, and `scripts/fixtures/Generate-ColorVectors.ps1`.
- Local: `policy/foundation.json`, `scripts/quality.ps1`, fixture policy/manifest, RFC 0001, and Phase 2/3 artifacts.
- CIPA, Exif orientation vocabulary: https://www.cipa.jp/std/documents/e/DC-X010-2017.pdf
- Microsoft, image stride and planar addressing: https://learn.microsoft.com/en-us/windows/win32/medfound/image-stride
- MoonBit methods/trait objects: https://docs.moonbitlang.com/en/latest/language/methods.html
- MoonBit package and trait coherence: https://docs.moonbitlang.com/en/latest/language/packages.html
- MoonBit primitive/view semantics: https://docs.moonbitlang.com/en/stable/language/fundamentals.html

---

*Phase: 04-image-model-views-and-operations*
*Research completed: 2026-07-17*
