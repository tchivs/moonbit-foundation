---
moonbit:
  import:
    - path: tchivs/mb-core/budget
      alias: budget
    - path: tchivs/mb-core/bytes
      alias: bytes
    - path: tchivs/mb-font/font
      alias: font
---

# mb-font

`tchivs/mb-font` admits a bounded standalone TrueType-outline SFNT from a
caller-provided byte view and exposes named integer font metrics, deterministic
Unicode scalar mapping, and basic legacy horizontal kerning. It is a pure
MoonBit foundation package: it does not discover files, call host font APIs,
decode outline paths, or shape text.

## 0.1.0 candidate contract

| Field | Exact value |
| --- | --- |
| Public package | `tchivs/mb-font/font` |
| Version/status | `0.1.0` candidate; unpublished |
| Required targets | `js`, `wasm`, `wasm-gc`, and `native` |
| Preferred target | `native` |
| Only direct module dependency | `tchivs/mb-core` |
| Accepted input | one standalone `0x00010000` TrueType-outline SFNT |

The package retains the caller-provided `ByteView`; it does not copy the whole
font or take filesystem ownership. The caller supplies both semantic
`FontLimits` and an authoritative `Budget`. Admission validates the complete
Phase 98 profile and charges its byte/work cost before publishing an opaque
`Font`.

```mbt check
///|
fn readme_storage_budget() -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=1UL,
      allocations=1UL,
      allocation_size=1UL,
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
      allocations=0UL,
      allocation_size=0UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work=16384UL,
    ),
  )
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

## Retained-source validity

Every public `Font` query checks the retained root view's mutation revision.
Unicode mapping, per-glyph metrics, and kerning check again after their
table-local reads and before publishing a value. Any mutation, including
mutation followed by restoration of the original byte, permanently invalidates
that admitted value because the revision changed.

## Deliberate boundary

Phase 98 provides admission, named global/per-glyph metrics, one-scalar Unicode
mapping, and the scoped legacy pair-kerning profile above. It does not provide
outline/path decoding, text shaping, GPOS/GSUB, string normalization,
discovery/fallback, hinting, rasterization, collection/web-font support, FFI, or
ambient host discovery.

Phase 98 conformance uses deterministic generated micro-fonts. Licensed
real-font end-to-end evidence, including provenance records, belongs to
Phase 100 and is not claimed by this candidate.
