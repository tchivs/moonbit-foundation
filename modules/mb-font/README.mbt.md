---
moonbit:
  import:
    - path: tchivs/mb-core/budget
      alias: budget
    - path: tchivs/mb-core/bytes
      alias: bytes
    - path: tchivs/mb-core/math
      alias: math
    - path: tchivs/mb-font/font
      alias: font
---

# mb-font

`tchivs/mb-font` admits a bounded standalone static TrueType-outline or CFF1
SFNT and inspects TTC/OTC versions 1 and 2 from a caller-provided byte view. A
selected static-glyf or static-CFF1 face enters the same opaque `Font` contract
with named integer metrics, deterministic Unicode scalar mapping, basic legacy
horizontal kerning, and transactional `Path2` outlines. It is a pure MoonBit
foundation package: it does not discover files, call host font APIs, rasterize
glyphs, or shape text.

## 0.1.0 candidate contract

| Field | Exact value |
| --- | --- |
| Public package | `tchivs/mb-font/font` |
| Version/status | `0.1.0` candidate; unpublished |
| Required targets | `js`, `wasm`, `wasm-gc`, and `native` |
| Preferred target | `native` |
| Only direct module dependency | `tchivs/mb-core` |
| Accepted input | one standalone static `0x00010000` TrueType-outline or `OTTO` CFF1 SFNT, or TTC/OTC v1/v2 inspection plus selected static-glyf/static-CFF1 admission |

The package retains the caller-provided `ByteView`; it does not copy the whole
font or take filesystem ownership. The caller supplies both semantic
`FontLimits` and an authoritative `Budget`. Admission validates the complete
Phase 99 profile and charges its byte/work cost before publishing an opaque
`Font`.

```mbt check
///|
fn readme_storage_budget() -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=4096UL,
      allocations=1UL,
      allocation_size=4096UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work=0UL,
    ),
  )
}

///|
fn readme_admission_budget() -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=4096UL,
      allocations=3UL,
      allocation_size=4096UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work=16384UL,
    ),
  )
}

///|
fn readme_outline_budget() -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=0UL,
      allocations=32UL,
      allocation_size=4096UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work=16384UL,
    ),
  )
}

///|
fn readme_collection_budget() -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=8192UL,
      allocations=32UL,
      allocation_size=4096UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work=131072UL,
    ),
  )
}

///|
fn readme_generated_empty_font() -> Bytes {
  b"\x00\x01\x00\x00\x00\x0a\x00\x80\x00\x03\x00 OS/2\x00\x00\x00\x00\x00\x00\x00\xac\x00\x00\x00Ncmap\x00\x0c\x00&\x00\x00\x00\xfc\x00\x00\x00$glyf\x00\x00\x00\x00\x00\x00\x01 \x00\x00\x00\x00head_\x13@\xe5\x00\x00\x01 \x00\x00\x006hhea\x00\x01\x00\x01\x00\x00\x01X\x00\x00\x00$hmtx\x01\xf4\x00\x00\x00\x00\x01|\x00\x00\x00\x04loca\x00\x00\x00\x00\x00\x00\x01\x80\x00\x00\x00\x04maxp\x002\x00\xc1\x00\x00\x01\x84\x00\x00\x00 name\x00\x06\x00\x00\x00\x00\x01\xa4\x00\x00\x00\x06post\x00\x03\x00\x00\x00\x00\x01\xac\x00\x00\x00 \x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x03\x00\x01\x00\x00\x00\x0c\x00\x04\x00\x18\x00\x00\x00\x02\x00\x02\x00\x00\x00\x00\xff\xff\x00\x00\xff\xff\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\xe2\xfa\x1bg_\x0f<\xf5\x00\x00\x03\xe8\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\x00\x02\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x01\xf4\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x01\x00@\x00\x10\x00@\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00@\x00\x10\x00\x01\x00\x00\x00\x00\x00\x06\x00\x00\x00\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
}

///|
fn readme_path_is_empty(path : @math.Path2) -> Bool {
  path.length() == 0 && path.get(0) is None
}

///|
fn readme_read_u16(source : Bytes, offset : Int) -> UInt64 {
  (source[offset].to_uint64() << 8) | source[offset + 1].to_uint64()
}

///|
fn readme_read_u32(source : Bytes, offset : Int) -> UInt64 {
  (source[offset].to_uint64() << 24) |
  (source[offset + 1].to_uint64() << 16) |
  (source[offset + 2].to_uint64() << 8) |
  source[offset + 3].to_uint64()
}

///|
fn readme_put_u32(output : Array[Byte], offset : Int, value : UInt64) -> Unit {
  output[offset] = (value >> 24).to_byte()
  output[offset + 1] = (value >> 16).to_byte()
  output[offset + 2] = (value >> 8).to_byte()
  output[offset + 3] = value.to_byte()
}

///|
fn readme_generated_collection() -> Bytes {
  let standalone = readme_generated_empty_font()
  let directory_start = 256
  let output = Array::make(directory_start + standalone.length(), b'\x00')
  readme_put_u32(output, 0, 0x74746366UL)
  readme_put_u32(output, 4, 0x00010000UL)
  readme_put_u32(output, 8, 1UL)
  readme_put_u32(output, 12, directory_start.to_uint64())
  for index, byte in standalone {
    output[directory_start + index] = byte
  }
  let table_count = readme_read_u16(standalone, 4).to_int()
  for index = 0; index < table_count; index = index + 1 {
    let record = 12 + index * 16
    let old_offset = readme_read_u32(standalone, record + 8)
    readme_put_u32(
      output,
      directory_start + record + 8,
      old_offset + directory_start.to_uint64(),
    )
  }
  Bytes::from_array(output)
}

///|
test "caller-owned ByteView, limits, and budget form the admission boundary" {
  let owner = @bytes.OwnedBytes::from_bytes(b"", readme_storage_budget()).unwrap()
  let limits = @font.FontLimits::new(
    max_source_bytes=4096UL,
    max_tables=32UL,
    max_table_bytes=1024UL,
    max_glyphs=16UL,
    max_name_records=16UL,
    max_cmap_records=16UL,
    max_kern_subtables=16UL,
    max_kern_pairs=256UL,
    max_outline_points=4096UL,
    max_outline_contours=256UL,
    max_outline_components=256UL,
    max_outline_instruction_bytes=1024UL,
    max_post_name_bytes=256UL,
    max_work=16384UL,
  ).unwrap()
  let rejected = match
    @font.Font::open(owner.view(), limits, readme_admission_budget()) {
    Ok(_) => false
    Err(_) => true
  }
  inspect(rejected, content="true")
}

///|
test "generated bytes expose the direct guarded Path2 outline query" {
  let owner = @bytes.OwnedBytes::from_bytes(
    readme_generated_empty_font(),
    readme_storage_budget(),
  ).unwrap()
  let limits = @font.FontLimits::new(
    max_source_bytes=4096UL,
    max_tables=32UL,
    max_table_bytes=1024UL,
    max_glyphs=16UL,
    max_name_records=16UL,
    max_cmap_records=16UL,
    max_kern_subtables=16UL,
    max_kern_pairs=256UL,
    max_outline_points=4096UL,
    max_outline_contours=256UL,
    max_outline_components=256UL,
    max_outline_instruction_bytes=1024UL,
    max_post_name_bytes=256UL,
    max_work=16384UL,
  ).unwrap()
  let admitted = @font.Font::open(
    owner.view(),
    limits,
    readme_admission_budget(),
  ).unwrap()
  let glyph = admitted.glyph_id(0UL).unwrap()
  let path = admitted.outline(glyph, readme_outline_budget()).unwrap()
  inspect(readme_path_is_empty(path), content="true")
}

///|
test "caller-owned collection inspection selects one static glyf Font" {
  let source = readme_generated_collection()
  let owner = @bytes.OwnedBytes::from_bytes(
    source,
    readme_storage_budget(),
  ).unwrap()
  let collection_limits = @font.FontCollectionLimits::new(
    max_source_bytes=4096UL,
    max_faces=1UL,
    max_tables_per_face=16UL,
    max_table_records=16UL,
    max_dsig_records=1UL,
    max_dsig_bytes=1UL,
    max_retained_bookkeeping_bytes=4096UL,
    max_work=131072UL,
  ).unwrap()
  let font_limits = @font.FontLimits::new(
    max_source_bytes=4096UL,
    max_tables=32UL,
    max_table_bytes=1024UL,
    max_glyphs=16UL,
    max_name_records=16UL,
    max_cmap_records=16UL,
    max_kern_subtables=16UL,
    max_kern_pairs=256UL,
    max_outline_points=4096UL,
    max_outline_contours=256UL,
    max_outline_components=256UL,
    max_outline_instruction_bytes=1024UL,
    max_post_name_bytes=256UL,
    max_work=16384UL,
  ).unwrap()
  let collection = @font.FontCollection::open(
    owner.view(),
    collection_limits,
    readme_collection_budget(),
  ).unwrap()
  inspect(collection.face_count().unwrap(), content="1")
  inspect(
    collection.face_profile(0UL).unwrap() == @font.FontFaceProfile::StaticGlyf,
    content="true",
  )
  inspect(
    collection.dsig_status().unwrap() == @font.FontCollectionDsigStatus::Absent,
    content="true",
  )
  let selected = collection.open_face(
    0UL,
    font_limits,
    readme_admission_budget(),
  ).unwrap()
  inspect(selected.units_per_em().unwrap(), content="1000")
  inspect(
    readme_path_is_empty(
      selected
      .outline(selected.glyph_id(0UL).unwrap(), readme_outline_budget())
      .unwrap(),
    ),
    content="true",
  )
}
```

## Named global metrics

An admitted font exposes explicit metric sources instead of a synthesized
"recommended" line box:

- `units_per_em()` and `global_bounds()` are admitted from `head`.
- `hhea_line_metrics()` returns the signed `hhea` ascent, descent, and line gap.
- `typographic_line_metrics()` returns the signed `OS/2` typographic triplet.

These values remain source-named so downstream layout policy can choose between
them deliberately.

## Opaque glyph identities and horizontal metrics

`Font::glyph_id(value)` validates a numeric identity for the receiving font.
`Font::horizontal_metrics(id)` revalidates that identity and returns an opaque
`GlyphHorizontalMetrics` value with:

- the `hmtx` advance width and signed left side bearing;
- optional bounds from the common `glyf` header;
- a checked, sign-aware derived right side bearing.

For the compact `hmtx` tail, glyphs reuse only the final long-metric advance
width; every tail glyph keeps its own signed left side bearing. Equal adjacent
`loca` offsets identify an empty glyph, whose bounds are `None` and whose ink
extent is zero for right-bearing derivation.

## Deterministic Unicode mapping

`Font::glyph_for_scalar(scalar)` accepts exactly one signed `Int` Unicode scalar
and returns one opaque `GlyphId`. For example,
`font.glyph_for_scalar(0x0041)` is one valid BMP query and
`font.glyph_for_scalar(0x1F600)` uses the same method for a supplementary
scalar. Negative values, surrogate values in `0xD800..0xDFFF`, and values above
`0x10FFFF` return `InvalidInput`/`InvalidRange` with the
`font-unicode-scalar-range` context. A valid scalar absent from the selected map
returns glyph zero; that neutral result never masks malformed or unsupported
font data.

Opening validates every supported format-4 or format-12 record and selects one
Unicode mapping by this fixed priority:

1. platform 0, encoding 4, format 12;
2. platform 3, encoding 10, format 12;
3. platform 0, encoding 3, format 4;
4. platform 3, encoding 1, format 4.

Record order cannot change the winner. Aliased records may share one checked
subtable, but duplicate canonical keys are rejected. A miss in the selected map
does not fall back to a lower-ranked record. Queries binary-search compact
admitted facts without allocating a decoded character map or consuming the
opening budget.

## Basic legacy horizontal kerning

`Font::kerning(left, right)` accepts exactly one pair of opaque glyph IDs,
revalidates both IDs against the receiving font, and returns one signed `Int`
adjustment in font units. The query supports only the classic OpenType version-0
table with exactly one horizontal kerning-value format-0 subtable whose coverage
is `0x0001`.

- An absent `kern` table, an empty supported pair set, or a pair miss returns
  zero.
- A supported pair hit returns its exact positive or negative signed value.
- A structurally valid but unsupported profile returns
  `Capability`/`CapabilityUnavailable` from `kerning`.
- Malformed recognized envelopes, lengths, search helpers, pair order, or glyph
  ranges fail `Font::open` with `Data`/`InvalidEncoding`; they never become a
  neutral-zero query result.

`max_kern_subtables` and `max_kern_pairs` are explicit nonzero admission
ceilings. Subtable and pair scans are preflighted with `max_work` and the
authoritative budget before attacker-controlled loops. Successful queries are
allocation-free and budget-neutral binary searches over already admitted facts.

## Simple and bounded composite outlines

`Font::outline(glyph, budget)` revalidates the opaque glyph identity against the
receiving font and returns the shared `mb-core/math` `Path2`. The query owns a
fresh caller `Budget`; it never spends the admission budget or publishes an
empty/partial path for a failed decode.

- Equal `loca` offsets return an empty `Path2`. A valid zero-contour body also
  returns an empty path without executing or interpreting its instructions.
- Simple glyphs validate endpoints, instruction envelopes, packed/repeated
  flags, signed coordinate deltas, table `maxp`, and retained limits before
  allocation. Contour order and winding are preserved. Consecutive off-curve
  points create their exact implied midpoint, quadratic segments are lowered in
  encoded order, and every contour closes explicitly.
- Bounded one-level composites accept ordered simple or empty components.
  Components support signed XY placement, encoded-real parent/child point
  attachment, uniform scale, independent x/y scale, and a general 2-by-2
  F2DOT14 matrix. Scaled, unscaled, and default XY offset policies are distinct
  and deterministic.
- Component order remains path-command order. Encoded real points alone enter
  attachment numbering; implied midpoints do not. One `USE_MY_METRICS` marker
  and overlap metadata are accepted without changing outline geometry or the
  separately admitted horizontal metrics.

Serialized coordinates, F2DOT14 coefficients, transforms, midpoints, and
attachment translations stay in checked signed `Int64` Q15 arithmetic. Only
the final `Point2` construction crosses to public `Double` coordinates, so the
same bytes produce the same command kinds, order, and exact values on `js`,
`wasm`, `wasm-gc`, and `native`.

## Outline limits, budgets, and failures

`FontLimits` retains four nonzero outline ceilings:
`max_outline_points`, `max_outline_contours`, `max_outline_components`, and
`max_outline_instruction_bytes`. The implementation intersects those limits
with `maxp`, cumulative `max_work`, and the independent query `Budget`.
Count-driven loops and scratch/output allocations are preflighted and charged
before traversal or allocation; exact-fit succeeds and one-short fails without
partial geometry.

Every outline query checks the retained source revision before decoding and
again after the complete private result is ready. Its structured failures keep
the five public categories distinct:

- `InvalidInput` for a foreign or out-of-range glyph identity;
- `Data` for malformed streams, descriptors, cycles, references, bounds,
  checked-arithmetic failure, or actual glyph point, contour, component, or
  instruction facts that exceed admitted `maxp` claims;
- `Capability` for a valid but deferred profile such as deeper composite
  geometry, phantom-point attachment, or grid rounding;
- `Resource` for exhaustion of retained `FontLimits`, cumulative `max_work`, or
  the caller's query `Budget`;
- `State` for retained-source revision drift before publication.

## Glyph ownership and the shaping transaction seam

Every opaque `GlyphId` is privately bound to the physical `Font` that issued
it. Aliases of that same `Font` accept the value; a distinct admitted font
rejects it with `InvalidInput`/`InvalidRange` and context
`font-glyph-owner` before range, table, outline, or budget work. The numeric
`GlyphId::value` contract and every v0.34 public query signature remain
unchanged.

The additive cross-module seam is exactly:

```moonbit
pub fn[T] Font::with_shape_transaction(
  self : Font,
  budget : @budget.Budget,
  body : (FontShapeScope) ->
    Result[(T, @budget.ResourceCharge), @error.CoreError],
) -> Result[T, @error.CoreError]
```

`FontShapeScope` is public-abstract: it has no public constructor, source/table
accessor, mutation probe, charge method, or commit operation. The callback
stages one value and one immutable text-side charge. `mb-font` combines that
charge with its private font-side charge, preflights the complete caller and
ancestor hierarchy, performs the final retained-source guard, and invokes the
only `Budget::charge` before publishing `T`.

MoonBit's generic `T` can nominally carry a captured or returned scope, so this
contract does not claim static lifetime enforcement. All aliases share runtime
scope state that closes on every callback exit. A later scope operation fails
exactly with category `State`, code `InvalidRange`, operation
`font-shape-scope`, and context `font-shape-scope-closed`. The seam is
synchronous and request-scoped; it creates no persistent cache and makes no
concurrent-mutation guarantee when one retained `Font` or `Budget` authority is
shared.

## Retained-source validity

Every public `Font` query checks the retained root view's mutation revision.
Unicode mapping, per-glyph metrics, kerning, and outlines check again after
their table-local work and before publishing a value. Any mutation, including
mutation followed by restoration of the original byte, permanently invalidates
that admitted value because the revision changed.

## Collection inspection and selected-face admission

`FontCollection::open` recognizes TTC/OTC versions 1 and 2 under explicit
`FontCollectionLimits` and a caller budget. It exposes only the face count,
ordered face profiles, and DSIG status. `Absent` and `PresentUnverified` are
structural observations; `PresentUnverified` is never a cryptographic trust
decision. A `StaticGlyf` or `StaticCff` face may be selected through
`FontCollection::open_face` and then uses the existing opaque `Font`,
`FontLimits`, budget, metrics, mapping, kerning, and outline operations. CFF2,
variable, and other unsupported profiles remain inspect-only and fail
selection with a `Capability` outcome.

The licensed interoperability derivative is the exact 757,428-byte
`DejaVuSans-two-face-v1.ttc` with SHA-256
`833d406d389d4ef3b0a38f168af7d51ca16c88605e1727f6d631871a4e05f80b`.
It is deterministically derived from the immutable DejaVu Sans 2.37 parent,
retains the upstream notice and license, contains two static-glyf faces sharing
the same 20 table ranges, and both selected faces equal the standalone public
oracle. The manifest and metadata-only collection oracle record the parent,
generator, notice, exact sharing, and standalone-oracle lineage.

## Portable qualification contract

Phase 100 qualifies the candidate contract with two complementary immutable-byte
oracles: a generated micro-font and a licensed real-font specimen.
`font-complete-public` is the exact compact complete-feature command
oracle: its 580-byte checksum-correct font has `unitsPerEm=1000`, maps U+0041 to
glyph 1 and U+10300 to glyph 2, reports zero global and named line metrics,
publishes an exact 5-command simple `Path2` and 10-command one-level composite
`Path2`, and returns `-37` for the glyph 1/glyph 2 kerning pair. The simple and
composite command fingerprints are respectively
`5fc6ebd87a17e0b581a44ccdb3e800c1f6b9f8b1f6da6cef5c4471021d626ed9`
and
`33f2ddb06317d5002afea389c0cb73c031bfc83458097c4bc4b466134e6a9a88`.
This small fixture makes the complete public call sequence, including the
format-4 branch, readable and exact.

DejaVu Sans 2.37 is the representative interoperability oracle. The repository
contains the exact 757,076-byte `DejaVuSans.ttf` with SHA-256
`7da195a74c55bef988d0d48f9508bd5d849425c1770dba5d7bfc6ce9ed848954`
and its exact 8,816-byte notice with SHA-256
`7a083b136e64d064794c3419751e5c7dd10d2f64c108fe5ba161eae5e5958a93`.
Both came from the immutable upstream release URL
`https://github.com/dejavu-fonts/dejavu-fonts/releases/download/version_2_37/dejavu-sans-ttf-2.37.zip`,
were retrieved on 2026-07-27, retain the exact license expression
`Bitstream-Vera AND LicenseRef-DejaVu-Arev`, and have confirmed redistribution
status in `fixtures/manifest.json`.

The separately versioned
`mnf-powershell-closed-sfnt-reader/1.1.0` oracle does not invoke `mb-font`.
Against its independently checked facts, the public workflow freezes:

- `unitsPerEm=2048`, global bounds `(-2090,-948)..(3673,2524)`,
  `hhea=(1901,-483,0)`, and typographic metrics `(1556,-492,410)`;
- U+0041 to glyph 36 with `(advance=1401, lsb=16)`, bounds
  `(16,0)..(1384,1493)`, and a 13-command `Path2` fingerprint of
  `ccb4bab2977fff264d8a8421ccb01e333b837e02bc7b5eb6c67e435ffcd2d308`;
- U+034C to glyph 765 with `(advance=0, lsb=-842)`, bounds
  `(-842,1221)..(-182,1680)`, and a 48-command one-level composite `Path2`
  fingerprint of
  `f5dfde0b4b9620c9de27a766cdd3fee9efa89f7fd1044c9d9f68ce2e94aed827`;
- U+10300 to glyph 5373 with `(advance=1550, lsb=100)`, bounds
  `(100,-29)..(1450,1493)`, and a 13-command `Path2` fingerprint of
  `c082fb5502ff6694c084a4ebce10d0208171a9c8079051cb544868b44e92267a`;
- glyph 36/glyph 57 legacy kerning of `-131`; and U+00E9 mapping, metrics,
  and bounds with its outline correctly reported as
  `CapabilityUnavailable` at the grid-rounding boundary.

Component identities, raw table inventory, raw `cmap` records, selected-record
internals, contour classification, and other parser facts remain
offline-oracle-only. They are not public `mb-font` assertions.

Static CFF1 qualification adds canonical generated name-keyed, CID-keyed,
hostile, Type 2, geometry, limit, and mutation vectors without adding a fixture
API. The exact upstream licensed specimens are Source Sans 3 3.052R
`SourceSans3-Regular.otf` (334,924 bytes, SHA-256
`08df266400933d3178d081a45f94a08814c3e55b4b7dd2e0ff69cb1329f13ab6`)
and Source Han Serif JP 2.003R `SourceHanSerifJP-Regular.otf` (6,210,796 bytes,
SHA-256
`e5f502bb193c28829895b098498f0f9dd8f658c760b0f83656ad41c1137a8785`).
Both retain their exact upstream OFL-1.1 license files and confirmed
redistribution records in `fixtures/manifest.json`.

The qualification freezes semantic agreement between the independent
fontTools-based reader and AFDKO-based reader for their shared CFF facts. OTS is
used only as a structural admission observation; it is not a semantic oracle.
`benchmarks/font-cff` is a non-published evidence module whose generated
payload is package-private. Production `mb-font` contains no licensed CFF bytes
and exposes no fixture API.

The closed hostile matrix covers malformed directory ranges, recognized
unsupported profiles, retained-source mutation, checked range overflow,
source-limit exact/one-short, open-budget exact/one-short, outline-budget
exact/one-short, and recognized nested composites. Every case freezes the
public stage, category, code, stable context, requested/limit fields when
applicable, and publication outcome; failed opens publish no `Font`, and failed
outlines publish no partial `Path2`.

Run the complete focused contract on `js`, `wasm`, `wasm-gc`, and `native`:

```powershell
./scripts/quality.ps1 `
  -Lane FontQualification `
  -EvidenceDirectory artifacts/release-qualification/font-v3
```

The command checks fixture provenance and generated-source drift, the exact
public interface and sole `mb-core` dependency, all standalone, generated,
licensed, hostile, limit, budget, and mutation assertions on each target, the
complete package, and literate examples. The fresh
`font-complete-public-v3` report writes exactly four ordered target records
(`js.json`, `wasm.json`, `wasm-gc.json`, and `native.json`) plus
`comparison.json`. Only top-level `target` and `runner` fields are removed for
comparison; toolchain, fixtures, standalone facts, collection facts, hostile
outcomes, mutation atomicity, boundaries, dependencies, focused identities,
and pass state remain byte-visible. All four records must have identical
normalized semantics before evidence is considered passing.

Wave 6 separately records an observation-only native baseline. That record
does not define a threshold, cross-target or cross-library comparison, verdict,
ranking, superiority claim, release gate, or stability claim.

The repository-wide Required lane is separate evidence and is deliberately
bounded:

```powershell
./scripts/quality/Invoke-RequiredBounded.ps1 `
  -EvidenceDirectory artifacts/release-qualification/required `
  -TimeoutSeconds 900
```

A Required failure or timeout remains a failure with captured diagnostics; it
does not modify or relabel focused font qualification evidence.

## Deliberate boundary

The qualified candidate provides standalone admission, bounded TTC/OTC
inspection, selected static-glyf and static-CFF1 admission, named
global/per-glyph metrics, one-scalar Unicode mapping, scoped legacy pair
kerning, complete unhinted TrueType simple outlines, bounded one-level
TrueType composite outlines, and bounded CFF1 Type 2 cubic `Path2` extraction.
It deliberately excludes WOFF1/WOFF2 admission, CFF2 selection or execution,
variable instantiation, DSIG cryptographic trust, runtime file or host-font discovery,
ambient filesystem/network I/O, FFI, GUI or canvas state, shaping, layout,
fallback, hinting execution, grid rounding, rasterization, color and bitmap
glyphs, collection extraction/materialization, font
authoring/writing/editing/subsetting, additional formats, and deeper composite
expansion. The offline qualification tools may inspect committed bytes, but
production and portable tests acquire no ambient host capability.

This qualification does not publish the module, promote it to stable, add a
new registry publication, change release policy, or broaden the executable font
profiles beyond selected static glyf.
