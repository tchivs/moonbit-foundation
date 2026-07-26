# Phase 97: Font Admission and Metrics - Pattern Map

**Mapped:** 2026-07-26  
**Files analyzed:** 17 proposed new/modified files  
**Analogs found:** 17 / 17 role or repository-pattern matches; no same-format SFNT implementation exists

## Scope Extracted from Context and Research

The phase creates one independently publishable `tchivs/mb-font` module with one public portable package and private file-level SFNT implementation pieces. The explicit proposed map comes from `97-RESEARCH.md`; `README.md` is additionally implied by the CONTEXT integration requirement to update top-level documentation.

Phase 97 does **not** add a real-font binary, fixture-manifest entry, filesystem adapter, FFI package, cmap lookup, kerning, outline decoding, or `Path2` dependency. Generated micro-fonts stay self-contained in package test sources.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `modules/mb-font/moon.mod.json` | config | batch | `modules/mb-image/moon.mod.json` | exact repository role |
| `modules/mb-font/README.mbt.md` | config/docs | request-response examples | `modules/mb-svg/README.mbt.md` | exact repository role |
| `modules/mb-font/CHANGELOG.md` | config/docs | batch | `modules/mb-svg/CHANGELOG.md` | exact repository role |
| `modules/mb-font/font/moon.pkg` | config | batch | `modules/mb-image/qoi/moon.pkg` | exact package role |
| `modules/mb-font/font/font.mbt` | model/service facade | request-response | `modules/mb-color/profile/profile.mbt` and `modules/mb-image/codec/contracts.mbt` | role match |
| `modules/mb-font/font/limits.mbt` | model/validation | request-response | `modules/mb-image/codec/contracts.mbt` | exact semantic-limits role |
| `modules/mb-font/font/cursor.mbt` | utility/parser | transform | `modules/mb-image/qoi/decode.mbt` plus `modules/mb-core/bytes/views.mbt` | partial; no random-access BE cursor exists |
| `modules/mb-font/font/directory.mbt` | service/parser | transform | `modules/mb-image/qoi/decode.mbt` | role/data-flow match |
| `modules/mb-font/font/tables.mbt` | service/parser | transform | `modules/mb-image/qoi/decode.mbt` | role/data-flow match |
| `modules/mb-font/font/metrics.mbt` | service/model | request-response/transform | `modules/mb-image/qoi/decode.mbt` and `modules/mb-color/profile/profile.mbt` | role match |
| `modules/mb-font/font/generated_fonts.mbt` | test utility | transform | `modules/mb-image/png/stream_decode_wbtest.mbt` | exact generated-binary-builder role |
| `modules/mb-font/font/font_test.mbt` | test | request-response | `modules/mb-image/qoi/decode_test.mbt` | exact hostile-codec black-box role |
| `modules/mb-font/font/font_wbtest.mbt` | test | transform | `modules/mb-image/qoi/decode_wbtest.mbt` and `modules/mb-image/png/stream_decode_wbtest.mbt` | exact white-box role |
| `moon.work` | config | batch | existing module member entries in `moon.work` | exact |
| `policy/foundation.json` | config/policy inventory | batch | existing `tchivs/mb-image/png` inventory block | exact |
| `scripts/quality/Assert-Policy.ps1` | utility/quality gate | batch | existing PNG scoped policy gate | exact |
| `README.md` | config/docs | batch | existing bilingual module tables | exact |

## Pattern Assignments

### `modules/mb-font/moon.mod.json` (config, batch)

**Analog:** `modules/mb-image/moon.mod.json`

**Copy** the metadata keys, candidate `0.1.0` version, Apache license, repository/readme fields, native preference, and four-target declaration. **Adapt** the identity/description and reduce dependencies to `tchivs/mb-core` only.

```json
// modules/mb-image/moon.mod.json:1-14
{
  "name": "tchivs/mb-image",
  "version": "0.1.0",
  "description": "...",
  "license": "Apache-2.0",
  "repository": "https://github.com/tchivs/moonbit-foundation",
  "readme": "README.mbt.md",
  "preferred-target": "native",
  "supported-targets": "+js+wasm+wasm-gc+native",
  "deps": {
    "tchivs/mb-core": "0.1.0",
    "tchivs/mb-color": "0.1.0"
  }
}
```

The font manifest must omit `mb-color` and every image/canvas/svg/host dependency.

---

### `modules/mb-font/README.mbt.md` (config/docs, request-response examples)

**Analog:** `modules/mb-svg/README.mbt.md`

**Copy** the literate frontmatter/import style, concise boundary section, explicit candidate status, and complete target statement.

```markdown
<!-- modules/mb-svg/README.mbt.md:1-20 -->
---
moonbit:
  import:
    - path: tchivs/mb-svg/svg
      alias: svg
---

# mb-svg

...

## Boundary

...

## Status

`candidate` stability. Pure MoonBit across `js`, `wasm`, `wasm-gc`, and `native`.
```

**Adapt** the example to `tchivs/mb-font/font` and document only caller-provided `ByteView` admission, explicit `FontLimits`/`Budget`, named integer metrics, source-mutation invalidation, and the static standalone TrueType profile. State deferred formats/capabilities rather than implying them.

---

### `modules/mb-font/CHANGELOG.md` (config/docs, batch)

**Analog:** `modules/mb-svg/CHANGELOG.md`

```markdown
<!-- modules/mb-svg/CHANGELOG.md:1-11 -->
# Changelog

All notable changes to `tchivs/mb-svg` will be recorded in this file. This module follows an independent release lifecycle.

## 0.1.0 candidate (unpublished) - 2026-07-24

Compatibility status: candidate. Pre-1.0 candidates carry no compatibility promise beyond the executable four-class policy.

### Added
```

**Copy** the independent lifecycle/candidate structure. **Adapt** the date and one added entry to the Phase 97 admission and metrics contract; do not claim cmap, kerning, outline, shaping, rasterization, or real-font qualification.

---

### `modules/mb-font/font/moon.pkg` (config, batch)

**Analog:** `modules/mb-image/qoi/moon.pkg`

```moonbit
// modules/mb-image/qoi/moon.pkg:1-6,15-17
import {
  "tchivs/mb-core/budget",
  "tchivs/mb-core/bytes",
  "tchivs/mb-core/checked",
  "tchivs/mb-core/error",
  "tchivs/mb-core/io",
}

supported_targets = "+js+wasm+wasm-gc+native"

warnings = "-29"
```

**Copy** `budget`, `bytes`, `checked`, `error`, targets, and the local warnings style. **Adapt** by omitting `io` and all non-core imports: `Font::open` consumes a `ByteView`, not a `Reader` or filesystem capability. Add `math` only if the final public integer bounds representation genuinely uses an existing core type; do not import it speculatively.

---

### `modules/mb-font/font/font.mbt` (model/service facade, request-response)

**Analogs:** `modules/mb-color/profile/profile.mbt`; `modules/mb-image/codec/contracts.mbt`

Use the established opaque-value pattern: private fields, validated constructors, and named accessors. `Font` must be constructed only inside the complete admission coordinator.

```moonbit
// modules/mb-color/profile/profile.mbt:62-76
pub struct ProfileFormatTag {
  priv value_value : String
}

pub fn ProfileFormatTag::new(
  value : String,
) -> Result[ProfileFormatTag, @error.CoreError] {
  if valid_profile_tag(value) {
    Ok({ value_value: value })
  } else {
    Err(invalid_profile_tag(value.length().to_uint64()))
  }
}
```

```moonbit
// modules/mb-image/codec/contracts.mbt:134-175
pub struct DecodeResult {
  priv image_value : @storage.OwnedImage
  priv disposition_value : @metadata.MetadataDisposition
  priv bytes_read_value : UInt64
}

pub fn DecodeResult::new(...) -> DecodeResult { ... }
pub fn DecodeResult::image(self : DecodeResult) -> @storage.OwnedImage { ... }
pub fn DecodeResult::bytes_read(self : DecodeResult) -> UInt64 { ... }
```

**Copy:** opaque structs, explicit semantic getter names, `Result[..., CoreError]` where state can invalidate a query, and no public representation fields.

**Adapt:** `Font` retains the root `ByteView`, opening revision, normalized private table windows/facts, and creates a `GlyphId` only after checking `< glyph_count`. Keep `hhea_line_metrics` and `typographic_line_metrics` separate. Return stored integer facts; do not choose a “best” line metric or convert to floating point. Prefer `FontBounds?` for the absent header of a zero-length glyph, subject to `.mbti` review.

Every public `Font` query should call one private uniform revision guard even if the requested fact was cached. A source-reading query checks before reading and immediately before returning.

---

### `modules/mb-font/font/limits.mbt` (model/validation, request-response)

**Analog:** `modules/mb-image/codec/contracts.mbt`

```moonbit
// modules/mb-image/codec/contracts.mbt:11-42
/// Explicit caller-owned ceilings ... independent from the authoritative Budget.
pub struct CodecLimits {
  priv max_probe_bytes_value : UInt64
  priv max_input_bytes_value : UInt64
  priv max_output_bytes_value : UInt64
  priv max_width_value : UInt64
  priv max_height_value : UInt64
  priv max_pixels_value : UInt64
  priv max_work_value : UInt64
}

pub fn CodecLimits::new(
  max_probe_bytes~ : UInt64,
  ...
  max_work~ : UInt64,
) -> CodecLimits { ... }
```

**Copy** private fields, named constructor arguments, individual accessors, `UInt64` logical quantities, and the documentation that semantic limits are independent of the shared budget.

**Adapt** dimensions to font semantics: source bytes, tables, individual/aggregate table bytes, glyphs, bounded `name`/`cmap`/`post` records or bytes, and work. If zero is invalid for a ceiling, make `FontLimits::new` return `Result` and reject it with a stable `CoreError`; do not silently clamp or substitute defaults.

---

### `modules/mb-font/font/cursor.mbt` (utility/parser, transform)

**Closest analogs:** `modules/mb-core/bytes/views.mbt`; `modules/mb-image/qoi/decode.mbt`

There is no existing random-access big-endian table cursor. Build the private cursor from a table-local `ByteView`, not a root view plus an attacker offset.

```moonbit
// modules/mb-core/bytes/views.mbt:150-217
pub struct ByteView {
  priv backing : FixedArray[Byte]
  priv start : Int
  priv length_value : Int
  priv revision : MutationRevision
}

pub fn ByteView::get(self : ByteView, index : UInt64)
  -> Result[Byte, @error.CoreError] { ... }

pub fn ByteView::subview(
  self : ByteView,
  relative_start : UInt64,
  length : UInt64,
) -> Result[ByteView, @error.CoreError] { ... }
```

```moonbit
// modules/mb-image/qoi/decode.mbt:83-101
fn qoi_read_one(...) -> Result[(Byte, UInt64), @error.CoreError] {
  let next = match @checked.checked_add(consumed, 1UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  match qoi_limit("input-bytes", next, limits.max_input_bytes()) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  ...
}
```

**Copy:** checked-next-position before read, immediate error propagation, and stable byte progress. **Adapt:** implement `read_u8/u16/i16/u32` in big-endian order over the local view; all multi-byte widths must prove a checked contained range before the first byte is consumed. Keep the cursor private and do not expose raw tags/offsets.

---

### `modules/mb-font/font/directory.mbt` (service/parser, transform)

**Analog:** `modules/mb-image/qoi/decode.mbt`

Use the decoder’s fail-closed ordering: parse private facts, reject malformed/unsupported declarations, preflight limits/work, and return a value only at the end.

```moonbit
// modules/mb-image/qoi/decode.mbt:105-174
fn qoi_parse_header(...) -> Result[(QoiHeader, UInt64), @error.CoreError] {
  ...
  if bytes[0] != b'q' || ... {
    return Err(qoi_error(
      @error.ErrorCategory::Data,
      @error.ErrorCode::InvalidEncoding,
      "qoi-magic",
    ))
  }
  ...
  Ok((QoiHeader::{ width, height, channels, transfer }, consumed))
}
```

```moonbit
// modules/mb-image/qoi/decode.mbt:413-470
pub impl @codec.ImageDecoder for QoiDecoder with fn decode(...) {
  let (header, initial_consumed) = match qoi_parse_header(...) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let pixels = match @checked.checked_mul(header.width, header.height) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  ...
  let image = match @storage.OwnedImage::new_operation(...) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  ...
}
```

**Adapt to SFNT:** derive `12 + numTables * 16` with checked arithmetic; derive canonical search helpers from `numTables`; require ascending unique tags, 4-byte aligned checked ranges, containment, non-overlap, required tags, table checksums, and the font-wide `head.checksumAdjustment`. Convert each accepted record to a table-local `ByteView` immediately.

Do not copy PNG/QOI checksum algorithms: SFNT uses its own big-endian 32-bit sum, virtual zero padding, and special `head` treatment. That format-specific algorithm has no codebase analog.

---

### `modules/mb-font/font/tables.mbt` (service/parser, transform)

**Analog:** private `QoiHeader` plus `qoi_parse_header` in `modules/mb-image/qoi/decode.mbt:10-15,105-174`.

**Copy** the pattern of private fact structs and small table-local decoders returning `Result[PrivateFacts, CoreError]`. **Adapt** into decoders for only the Phase 97 facts:

- `head`: version/magic, units per em, global bounds, `indexToLocFormat`;
- TrueType `maxp`: supported version and glyph count;
- `hhea`: named line metrics and `numberOfHMetrics`;
- `OS/2`: version-dependent structural length and typographic metrics;
- bounded structural envelopes for `cmap`, `name`, and `post`;
- profile rejection for CFF/CFF2, variations, color/bitmap tables, collections, and web-font containers.

Private table decoders must not construct `Font`; the coordinator in `font.mbt` owns the only publication point after all cross-table facts agree.

---

### `modules/mb-font/font/metrics.mbt` (service/model, request-response/transform)

**Analog:** checked preflight and private-facts flow in `modules/mb-image/qoi/decode.mbt:213-251,413-470`.

```moonbit
// modules/mb-image/qoi/decode.mbt:213-251
fn qoi_descriptor(
  header : QoiHeader,
  payload : UInt64,
) -> Result[@model.ImageDescriptor, @error.CoreError] {
  let row_bytes = match @checked.checked_mul(header.width, header.channels) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  ...
  @model.ImageDescriptor::new(...)
}
```

**Copy** the checked derivation-before-construction pattern. **Adapt** it to:

- exact `hmtx` length = `4 * numberOfHMetrics + 2 * (numGlyphs - numberOfHMetrics)`;
- tail glyphs repeat only the final advance width and read a distinct signed LSB;
- `loca` has exactly `numGlyphs + 1` nondecreasing entries in the selected short/long form;
- normalized `loca` offsets are contained in `glyf`; equal offsets represent empty glyphs;
- only a non-empty glyph’s common 10-byte `glyf` header is read for declared bounds;
- checked widened RSB = `advance - (lsb + xMax - xMin)`, with a documented zero extent for an empty glyph.

Do not parse contours, flags, coordinates, components, instructions, phantom points, or `USE_MY_METRICS` in this file.

---

### `modules/mb-font/font/generated_fonts.mbt` (test utility, transform)

**Analog:** deterministic in-language PNG construction in `modules/mb-image/png/stream_decode_wbtest.mbt`.

```moonbit
// modules/mb-image/png/stream_decode_wbtest.mbt:1223-1241
fn png_wb_append_chunk(
  output : Array[Byte],
  kind : Array[Byte],
  payload : Array[Byte],
) -> Unit {
  let length = payload.length().to_uint64()
  for shift in [24, 16, 8, 0] {
    output.push((length >> shift).to_byte())
  }
  ...
  for byte in payload { ...; output.push(byte) }
  ...
}

fn png_wb_short_raster_png() -> Bytes {
  let output : Array[Byte] = []
  ...
  Bytes::from_array(output)
}
```

```moonbit
// modules/mb-image/png/stream_decode_wbtest.mbt:1055-1059
fn png_wb_append(source : Bytes, suffix : Bytes) -> Bytes {
  let result : Array[Byte] = []
  for byte in source { result.push(byte) }
  for byte in suffix { result.push(byte) }
  Bytes::from_array(result)
}
```

**Copy** small byte append/write helpers, named constructors, deterministic arrays, and mutation helpers. **Adapt** with `put_u16/i16/u32`, tag/table builders, 4-byte padding, table checksum recomputation, whole-font adjustment recomputation, and direct mutation by named table/field. Keep vectors auditable and self-contained; do not add a generator requiring Python/FontTools or a licensed binary.

---

### `modules/mb-font/font/font_test.mbt` (test, request-response)

**Analog:** `modules/mb-image/qoi/decode_test.mbt`

```moonbit
// modules/mb-image/qoi/decode_test.mbt:2-11,37-58
fn qoi_probe_limits() -> @codec.CodecLimits {
  @codec.CodecLimits::new(
    max_probe_bytes=8UL,
    ...
    max_work=512UL,
  )
}

fn decode_qoi_with(
  source : Bytes,
  budget? : @budget.Budget = qoi_decode_budget(),
  limits? : @codec.CodecLimits = qoi_probe_limits(),
  complete? : Bool = true,
) -> Result[@codec.DecodeResult, @error.CoreError] {
  ...
}
```

```moonbit
// modules/mb-image/qoi/decode_test.mbt:196-212
let failed = decode_qoi_scripted(source, fail_at=15).unwrap_err()
inspect(failed.category() == @error.ErrorCategory::Host, content="true")
inspect(
  failed.code() == @error.ErrorCode::HostOperationFailed,
  content="true",
)
inspect(failed.context() == Some("qoi-payload"), content="true")
```

```moonbit
// modules/mb-image/qoi/decode_test.mbt:245-297
let exact_budget = @budget.Budget::new(...)
ignore(decode_qoi_with(source, budget=exact_budget, limits=exact_limits).unwrap())
inspect(exact_budget.remaining().work(), content="0")
let rejected_budget = qoi_decode_budget()
let before = rejected_budget.remaining()
...
let after = rejected_budget.remaining()
inspect(after.bytes() == before.bytes(), content="true")
...
inspect(after.work() == before.work(), content="true")
```

**Copy:** local source/limit/budget factories, public-only calls, typed error-field assertions, exact/one-less boundary cases, and unchanged-budget assertions when a complete preflight is rejected.

**Adapt:** cover the full generated matrix: header/directory one-short cases; duplicate/overlap/alignment/checksum failures; every missing required table; unsupported profiles; long/short `loca`; `hmtx` tail bearings; empty glyphs; count mismatches; all `FontLimits` and budget boundaries; mutation, including mutate-back; exact integer metric facts. A failed `Font::open` must leave no queryable partial value.

---

### `modules/mb-font/font/font_wbtest.mbt` (test, transform)

**Analogs:** `modules/mb-image/qoi/decode_wbtest.mbt`; `modules/mb-image/png/stream_decode_wbtest.mbt`

```moonbit
// modules/mb-image/qoi/decode_wbtest.mbt:1-7
test "QOI arithmetic is checked before resource preflight" {
  inspect(
    @checked.checked_mul(18446744073709551615UL, 2UL) is Err(_),
    content="true",
  )
}
```

```moonbit
// modules/mb-image/qoi/decode_wbtest.mbt:63-90
test "generated QOI vectors cover every chunk family with exact bytes" {
  for item in _generated_qoi_cases() {
    let (id, source, expected, width, height, channels, colorspace) = item
    let decoded = match qoi_vector_decode(source) {
      Ok(value) => value
      Err(_) => fail(id)
    }
    ...
  }
}
```

**Copy** focused private-helper tests plus table-driven generated cases whose failure reports the vector ID. **Adapt** to cursor exact-fit/one-short reads, checked directory/hmtx/loca expressions, sort/overlap helpers, checksum zero-padding and `head` special handling, table-local window containment, and cross-table cardinality facts.

---

### `moon.work` (config, batch)

**Analog:** existing workspace member list.

```toml
# moon.work:1-7
members = [
  "./modules/mb-core",
  "./modules/mb-color",
  "./modules/mb-image",
  "./modules/mb-canvas",
  "./modules/mb-svg",
  ...
]
```

Add exactly `"./modules/mb-font"` among module members. Preserve all current modules/examples; do not use path dependencies in `moon.mod.json`.

---

### `policy/foundation.json` (config/policy inventory, batch)

**Analog:** module and package inventory for `tchivs/mb-image/png`.

```json
// policy/foundation.json:1123-1142
{
  "name": "tchivs/mb-image",
  "path": "modules/mb-image",
  "version": "0.1.0",
  ...
  "supported_targets": ["js", "wasm", "wasm-gc", "native"],
  "direct_dependencies": [
    "tchivs/mb-core",
    "tchivs/mb-color"
  ],
  "publication_files": [
    "CHANGELOG.md",
    "README.mbt.md",
    ...
  ]
}
```

```json
// policy/foundation.json:1707-1736
{
  "name": "tchivs/mb-image/png",
  "path": "png",
  "stability": "candidate",
  "allowed_imports": [
    "tchivs/mb-core/budget",
    "tchivs/mb-core/bytes",
    "tchivs/mb-core/checked",
    "tchivs/mb-core/error",
    ...
  ],
  "production_sources": [
    "moon.pkg",
    "png.mbt",
    "structural.mbt",
    ...
  ],
  "semantic_interface": [
    "package \"tchivs/mb-image/png\"",
    ...
  ]
}
```

**Copy:** module metadata, exact publication-file allowlist, one public-package entry, allowed imports, exact production source order, semantic `.mbti` allowlist, targets, and dependency edge shape.

**Adapt:** module dependency is only `tchivs/mb-core`; package imports are only the core packages actually declared in `moon.pkg`; publication inventory contains all production/test/doc files but no generated `.mbti`; semantic interface contains only opaque font/ID/limits/metric types and methods. Add exactly `tchivs/mb-font -> tchivs/mb-core` to `allowed_dependency_edges`.

---

### `scripts/quality/Assert-Policy.ps1` (utility/quality gate, batch)

**Analog:** generic module verification plus scoped PNG gate.

```powershell
# scripts/quality/Assert-Policy.ps1:802-850
$modulePath = Join-Path $repoRoot ([string]$module.path)
$manifest = Read-QualityJson -Path (Join-Path $modulePath 'moon.mod.json')
Assert-Condition ($manifest.name -ceq $module.name) "Manifest name drift ..."
...
Assert-ExactSet "Manifest dependencies ..." $manifestDeps @($module.direct_dependencies)
...
Assert-ExactSet "moon.pkg imports ..." $actualImports @($package.allowed_imports)
...
Assert-Condition ($readmeText -cmatch '\bcandidate\b') ...
foreach ($target in @($policy.required_targets)) {
  Assert-Condition ($readmeText -cmatch [regex]::Escape($target)) ...
}
```

```powershell
# scripts/quality/Assert-Policy.ps1:981-1007
$png = @($image.public_packages | Where-Object { $_.path -ceq 'png' })
Assert-ExactSet 'PNG public package selection' @($png.name) @('tchivs/mb-image/png')
...
Assert-ExactSequence 'PNG policy production source order' @($png.production_sources) $sources
...
Assert-ExactSet 'PNG directory contents' $actualFiles $files
...
& moon -C modules/mb-image info --target all --frozen
...
Assert-ExactSequence 'PNG generated semantic interface' $semanticLines @(...)
```

**Copy:** exact-set module/path/member selection, acyclic dependency check, exact package imports/targets/source order/directory contents, manifest-to-policy matching, candidate/target README checks, `moon info`, and exact generated-interface comparison.

**Adapt:** add a font-scoped selector that requires exactly `tchivs/mb-font/font`, the four core imports, the proposed production/test files, and no extra package/file. Add negative checks for extra imports/files and public leakage such as cursor/table/tag/raw-offset/cmap/kern/outline/path/host APIs. Update existing exact module/path/workspace arrays without dropping currently present modules or examples.

The currently hard-coded selectors at `Assert-Policy.ps1:714-722` must be updated together:

```powershell
$expectedModules = @(...)
$expectedPaths = @(...)
Assert-ExactSet 'Policy modules' @($policy.modules.name) $expectedModules
Assert-ExactSet 'Policy module paths' @($policy.modules.path) $expectedPaths
...
Assert-ExactSet 'moon.work members' $workMembers @($expectedPaths + @(...))
```

---

### `README.md` (config/docs, batch)

**Analog:** existing bilingual module inventory.

```markdown
<!-- README.md:38-48 -->
| Module | Responsibility | Direct dependencies |
| --- | --- | --- |
| [`tchivs/mb-core`](modules/mb-core/README.mbt.md) | ... | — |
| [`tchivs/mb-image`](modules/mb-image/README.mbt.md) | ... | `mb-core`, `mb-color` |
...

The dependency direction is deliberately downward: ...
```

Add `mb-font` to both the English table (`README.md:38-44`) and Chinese table (`README.md:131-137`), with `mb-core` as its only dependency. Update the dependency-direction prose and status text without advertising deferred font capabilities.

## Shared Patterns

### Retained Source and Mutation Revision

**Sources:** `modules/mb-core/bytes/views.mbt:150-217`; `modules/mb-image/png/stream_encode.mbt:960-990,1334-1353`  
**Apply to:** `font.mbt`, `directory.mbt`, `tables.mbt`, `metrics.mbt`, mutation tests

```moonbit
// modules/mb-image/png/stream_encode.mbt:973-990
Ok({
  source: Some(source),
  ...
  source_revision: source.mutation_revision(),
  ...
})
```

```moonbit
// modules/mb-image/png/stream_encode.mbt:1338-1353
fn PngEncodeMachine::validate_replay_revision(
  self : PngEncodeMachine,
) -> Result[Unit, @error.CoreError] {
  let source = match self.source {
    None => return Ok(())
    Some(value) => value
  }
  if source.mutation_revision() == self.source_revision { return Ok(()) }
  ...
}
```

Capture the revision before parsing, compare again immediately before publishing `Font`, and guard every public query. Font-specific drift errors should be `State` with stable operation/context fields; do not reuse PNG context tokens.

### Checked Widened Arithmetic and Table-Local Ranges

**Sources:** `modules/mb-core/checked/checked.mbt:29-85,118-146`; `modules/mb-core/checked/range.mbt:31-123`; `modules/mb-core/bytes/views.mbt:189-217`  
**Apply to:** `cursor.mbt`, `directory.mbt`, `tables.mbt`, `metrics.mbt`

```moonbit
pub fn checked_add(left : UInt64, right : UInt64)
  -> Result[UInt64, @error.CoreError]
pub fn checked_sub(left : UInt64, right : UInt64)
  -> Result[UInt64, @error.CoreError]
pub fn checked_mul(left : UInt64, right : UInt64)
  -> Result[UInt64, @error.CoreError]
pub fn checked_narrow_int(value : UInt64)
  -> Result[Int, @error.CoreError]
```

```moonbit
// modules/mb-core/checked/range.mbt:84-123
pub fn CheckedRange::subrange(
  self : CheckedRange,
  relative_start : UInt64,
  length : UInt64,
) -> Result[CheckedRange, @error.CoreError] {
  let parent_length = self.length()
  if relative_start > parent_length { ... }
  else if length > parent_length - relative_start { ... }
  else { ... }
}
```

Keep wire offsets/counts as `UInt64`; use checked math before loop bounds, slicing, checksum work, or allocations; narrow only at final backend indexing. Normalize root ranges once with `ByteView::subview`.

### Semantic Limits Plus Atomic Shared Budget

**Sources:** `modules/mb-image/codec/contracts.mbt:11-77`; `modules/mb-core/budget/budget.mbt:80-111,168-329`  
**Apply to:** `limits.mbt`, `font.mbt`, all parser admission paths, budget tests

```moonbit
// modules/mb-core/budget/budget.mbt:314-329
pub fn Budget::charge(
  self : Budget,
  charge : ResourceCharge,
) -> Result[Unit, @error.CoreError] {
  for window in self.windows {
    match window.preflight_charge(charge) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
  }
  for window in self.windows {
    window.commit_charge(charge)
  }
  Ok(())
}
```

Intersect declarations with `FontLimits` and `budget.remaining()`. Build one known `ResourceCharge` after all checked cost derivations when possible; attacker-driven scans/checksums must also charge bounded work. Never treat `maxp.numGlyphs` or `numTables` as permission to allocate or iterate.

### Structured Portable Errors

**Source:** `modules/mb-core/error/core_error.mbt:1-72,90-136`  
**Apply to:** every production file and public test

```moonbit
pub(all) enum ErrorCategory {
  InvalidInput
  Data
  State
  Resource
  Capability
  Host
}

pub(all) enum ErrorCode {
  InvalidRange
  InvalidEncoding
  ArithmeticOverflow
  ...
  BudgetExceeded
  CapabilityUnavailable
}

pub fn CoreError::new(
  category : ErrorCategory,
  code : ErrorCode,
  operation? : String,
  requested? : UInt64,
  completed? : UInt64,
  range_start? : UInt64,
  range_end? : UInt64,
  source_offset? : UInt64,
  limit? : UInt64,
  context? : String,
) -> CoreError
```

Use `Data/InvalidEncoding` for malformed supported SFNT, `Capability/CapabilityUnavailable` for well-formed unsupported containers/outlines/profiles, `Resource/BudgetExceeded` for ceilings, and `State` for revision drift. Tests assert category, code, bounded context token, offsets, requested, and limit—not rendered prose.

### Public Versus White-Box Test Split

**Sources:** `modules/mb-image/qoi/decode_test.mbt`; `modules/mb-image/qoi/decode_wbtest.mbt`  
**Apply to:** `font_test.mbt`, `font_wbtest.mbt`

- `font_test.mbt`: use only public `@font` behavior and stable core error facts.
- `font_wbtest.mbt`: call private cursor/checksum/table/cardinality helpers and consume generated builder cases.
- Binary results use exact bytes/digests plus semantic assertions; avoid opaque snapshots.
- The same semantic tests run on all targets.

## No Same-Format Analog Found

The planner must use the Phase 97 research/OpenType rules rather than copying a repository algorithm for these areas:

| Area / Owning File | Reason | Required adaptation |
|---|---|---|
| SFNT directory and search-helper validation (`directory.mbt`) | No existing SFNT/table-directory parser | Implement strict `0x00010000`, canonical helpers, sorted unique tags, aligned contained non-overlap |
| SFNT table/font checksums (`directory.mbt`) | Existing PNG CRC is a different algorithm | Big-endian 32-bit word sum, virtual zero padding, `head.checksumAdjustment` special handling |
| `head`/`hhea`/`maxp`/`OS/2` envelopes (`tables.mbt`) | No font-table decoders | Decode only Phase 97 fields and version-dependent structural lengths |
| `hmtx` tail and derived RSB (`metrics.mbt`) | No analogous repeated-final-record format | Repeat only advance, distinct tail LSB, checked signed widened derivation |
| `loca`/`glyf` relationship (`metrics.mbt`) | No analogous cross-table location index | Short/long cardinality, monotonic offsets, containment, empty equal offsets, header-only bounds |

## Verification Commands

Run from the repository root:

```powershell
# Fast implementation loop, including black-box and white-box package tests
moon -C modules/mb-font test --target native --frozen

# Required portable semantic gate
moon -C modules/mb-font test --target all --frozen

# Generate/review the exact public interface; private parser symbols must not appear
moon -C modules/mb-font info --target all --frozen

# Repository policy/workspace/publication gate
./scripts/quality.ps1 -Lane Required -EvidenceDirectory artifacts/release-qualification/local
```

Interface review must reject public cursor/table/tag/raw-offset APIs and all cmap, kern, outline, path, filesystem, FFI, host, shaping, and rasterization capabilities.

## Metadata

**Analog search scope:** `modules/mb-core`, `modules/mb-color/profile`, `modules/mb-image/{codec,qoi,png}`, `modules/mb-svg`, `moon.work`, `policy/foundation.json`, `scripts/quality/Assert-Policy.ps1`, `README.md`  
**Graph result:** codebase-memory was consulted first as required; the current graph contains documentation/file nodes but no indexed MoonBit functions or call edges, so targeted `rg` and read-only file inspection supplied exact source analogs.  
**Principal analog families:** 5 (`mb-image` module/package integration, QOI hostile decoder/tests, PNG generated binary builders, PNG retained-source revision guard, core checked/budget/error/bytes primitives)  
**Pattern extraction date:** 2026-07-26
