# Phase 98: Unicode Mapping and Kerning - Pattern Map

**Mapped:** 2026-07-27
**Files analyzed:** 14 new/modified files
**Analogs found:** 14 / 14
**Strong code analogs inspected:** 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `modules/mb-font/font/cmap.mbt` | utility / table decoder | file-I/O, transform, request-response | `modules/mb-font/font/tables.mbt` | role + data-flow match |
| `modules/mb-font/font/kern.mbt` | utility / table decoder | file-I/O, transform, request-response | `modules/mb-font/font/tables.mbt` | role + data-flow match |
| `modules/mb-font/font/tables.mbt` | service / admission coordinator | file-I/O, batch, transform | existing `modules/mb-font/font/tables.mbt` | exact |
| `modules/mb-font/font/directory.mbt` | utility | file-I/O, request-response | existing `modules/mb-font/font/directory.mbt` | exact |
| `modules/mb-font/font/font.mbt` | model / public facade | request-response | existing `modules/mb-font/font/font.mbt` | exact |
| `modules/mb-font/font/limits.mbt` | config / model | request-response | existing `modules/mb-font/font/limits.mbt` | exact |
| `modules/mb-font/font/font_test.mbt` | test | batch, request-response | existing `modules/mb-font/font/font_test.mbt` | exact |
| `modules/mb-font/font/font_wbtest.mbt` | test | batch, transform | `modules/mb-font/font/font_test.mbt` | role-match |
| `modules/mb-font/font/generated_fonts_wbtest.mbt` | test fixture utility | file-I/O, batch, transform | `modules/mb-font/font/font_test.mbt` | role + data-flow match |
| `modules/mb-font/font/pkg.generated.mbti` | generated config / interface | transform | existing `modules/mb-font/font/pkg.generated.mbti` | exact |
| `policy/foundation.json` | config / policy | batch, transform | existing `tchivs/mb-font` policy entry | exact |
| `modules/mb-font/README.mbt.md` | config / documentation | request-response | existing Phase 97 contract sections in the same file | exact |
| `modules/mb-font/CHANGELOG.md` | config / documentation | batch | existing `0.1.0 candidate` entry in the same file | exact |
| `README.md` | config / documentation | batch | existing English/Chinese `mb-font` responsibility rows | exact |

`modules/mb-font/font/moon.pkg` is a read-first dependency source, not an expected modification: it already imports only `mb-core` and declares all four required targets. MoonBit discovers package source files without an explicit list there; the explicit source inventory/order is enforced in `policy/foundation.json`.

## Pattern Assignments

### `modules/mb-font/font/cmap.mbt` (utility, file-I/O + transform + request-response)

**Analog:** `modules/mb-font/font/tables.mbt`

Use a private retained-facts value, table-local offsets, and `Result[..., @error.CoreError]`. Do not decode a Unicode map or expose offsets. The existing facts convention is at `tables.mbt:32-63`:

```moonbit
priv struct CmapSubtableFacts {
  format : UInt64
  length : UInt64
  language : UInt64
  body_records : UInt64
}

priv struct CmapAdmissionWork {
  body_records : UInt64
  format4_discovery_work : UInt64
  search_work : UInt64
  mapping_work : UInt64
}
```

Copy the checked envelope pattern from `tables.mbt:558-733`: calculate `remaining`, read the format, use `checked_add`/`checked_mul` for all offsets and lengths, reject inconsistent exact lengths with `font_data_error("font-cmap-envelope")`, and return compact facts only after every read is contained.

Copy format-4 offset derivation from `tables.mbt:1023-1053`:

```moonbit
let code_array_size = match @checked.checked_mul(facts.body_records, 2UL) {
  Err(error) => return Err(error)
  Ok(value) => value
}
let end_codes = match @checked.checked_add(offset, 14UL) {
  Err(error) => return Err(error)
  Ok(value) => value
}
let reserved = match @checked.checked_add(end_codes, code_array_size) {
  Err(error) => return Err(error)
  Ok(value) => value
}
let start_codes = match @checked.checked_add(reserved, 2UL) {
  Err(error) => return Err(error)
  Ok(value) => value
}
let id_deltas = match @checked.checked_add(start_codes, code_array_size) {
  Err(error) => return Err(error)
  Ok(value) => value
}
let id_range_offsets = match @checked.checked_add(id_deltas, code_array_size) {
  Err(error) => return Err(error)
  Ok(value) => value
}
```

Preserve the raw-zero rule from `tables.mbt:1138-1149`: for an indexed format-4 entry, return glyph zero before applying `idDelta`; apply modulo 65536 only to nonzero raw glyphs. Preserve format-12 sorted-group and glyph-cardinality proof from `tables.mbt:1157-1208`.

The canonical selector is new, but should follow the existing pure private-helper style. Encode the locked rank literally and return no rank for every other tuple:

1. `(platform=0, encoding=4, format=12)`
2. `(platform=3, encoding=10, format=12)`
3. `(platform=0, encoding=3, format=4)`
4. `(platform=3, encoding=1, format=4)`

Queries should derive binary-search bounds from admitted counts, never from stored search helper fields. A selected-table miss returns `0UL`; it must not consult another record.

**Validation/error pattern:** malformed bytes use `font_data_error`; no eligible Unicode record and conflicting canonical candidates use stable capability/data outcomes required by CONTEXT D-06/D-07a. Candidate scans and semantic consistency comparisons must be included in pre-loop work before iteration.

---

### `modules/mb-font/font/kern.mbt` (utility, file-I/O + transform + request-response)

**Analog:** `modules/mb-font/font/tables.mbt`, using the error/state seam in `directory.mbt`

No kern parser exists, so copy the same table-decoder mechanics rather than inventing a second parser architecture:

- private facts/state only;
- table-local `TableWindow`;
- checked exact lengths before reads;
- declared-count ceilings and work preflight before loops;
- strict sorted/unique validation at admission;
- allocation-free binary search at query time.

Use a private tri-state matching D-10a:

```moonbit
priv(all) enum KernState {
  Absent
  Supported(KernFormat0Facts)
  Unsupported
}
```

Copy the repository error taxonomy from `directory.mbt:34-74`:

```moonbit
fn font_data_error(...) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::Data,
    @error.ErrorCode::InvalidEncoding,
    operation="font-open",
    ...
  )
}

fn font_capability_error(context : String) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::Capability,
    @error.ErrorCode::CapabilityUnavailable,
    operation="font-open",
    context~,
  )
}
```

The supported profile must validate exact version-0/one-subtable/coverage-`0x0001`/format-0 facts, exact `14 + 6*nPairs` subtable length, exact table exhaustion, canonical search helper fields, strict pair-key order, glyph range, and signed `read_i16` values. Structurally readable out-of-profile data becomes `Unsupported`; malformed recognized version-0 data remains a `Data` error during `Font::open`.

The pair lookup should use the admitted `nPairs` count for binary search and construct keys only after both opaque glyph values have been revalidated by the receiving `Font`.

---

### `modules/mb-font/font/tables.mbt` (admission service, file-I/O + batch)

**Analog:** existing `tables.mbt`

Extend `RequiredTableFacts` at `tables.mbt:57-63`; do not create a second admission transaction:

```moonbit
priv struct RequiredTableFacts {
  head : HeadFacts
  maxp : MaxpFacts
  hhea : HheaFacts
  os2 : Os2Facts
  cmap : CmapEnvelope
}
```

Replace/extend `CmapEnvelope` with the selected lookup descriptor and add retained `KernState`. Keep `font_admit_required_tables` as the single integration point. Its current coordinator pattern is at `tables.mbt:1763-1830`: obtain normalized windows, decode dependent cardinalities first, admit cmap/name/post, then publish one `RequiredTableFacts`.

Copy the count-discovery-before-charge pattern from `tables.mbt:103-135`:

```moonbit
let cmap_records = match read_u16(cmap_table.view, 2UL) {
  Err(error) => return Err(error)
  Ok(value) => value
}
if cmap_records > limits.max_cmap_records() {
  return Err(font_limit_error(
    "max-cmap-records",
    cmap_records,
    limits.max_cmap_records(),
  ))
}
let cmap_work = match font_cmap_declared_work(
  cmap_table,
  cmap_records,
  budget,
  limits.max_work(),
  cmap_discovery_base_work,
) {
  Err(error) => return Err(error)
  Ok(value) => value
}
```

Every new cmap comparison, kern subtable, and kern pair count must be added to the checked aggregate list before the authoritative charge, following `tables.mbt:263-304`. Preserve the preflight helper at `tables.mbt:736-755`; it checks both `max_work` and the caller budget before attacker-driven loops.

Do not weaken the current format-4/12 structural validation at `tables.mbt:988-1213`. Narrow canonical eligibility separately from structural format admission: legacy supported-format records may be structurally checked but must never become the selected Unicode map.

---

### `modules/mb-font/font/directory.mbt` (utility, file-I/O + request-response)

**Analog:** existing `directory.mbt`

Keep required lookup unchanged and add a separate optional lookup. Current required lookup (`directory.mbt:613-623`) is:

```moonbit
fn font_table_window(
  directory : DirectoryFacts,
  tag : UInt64,
) -> Result[TableWindow, @error.CoreError] {
  for table in directory.tables {
    if table.tag == tag {
      return Ok(table)
    }
  }
  Err(font_data_error("font-required-table"))
}
```

The optional analog should perform the same normalized scan but return `TableWindow?` (`Some(table)`/`None`), not convert kern absence into `font-required-table`. Keep `TableWindow` private and normalized as at `directory.mbt:18-30`.

If optional lookup work changes the number of precharge scans, update both the discovery preflight and final aggregate rather than charging after the scan. The current discovery discipline is documented and implemented at `directory.mbt:266-293`.

---

### `modules/mb-font/font/font.mbt` (public facade, request-response)

**Analog:** `Font::horizontal_metrics` in `font.mbt:257-296`

Both new queries must use the exact guard sequence:

```moonbit
match self.require_revision("font-query") {
  Err(error) => return Err(error)
  Ok(_) => ()
}
// validate caller input
// perform lookup over admitted private facts
match self.require_revision("font-query") {
  Err(error) => return Err(error)
  Ok(_) => ()
}
// publish the immutable semantic result
```

For kerning, copy receiving-font glyph revalidation from `font.mbt:265-272` for both inputs:

```moonbit
if glyph.value_value >= self.metric_index.num_glyphs {
  return Err(
    font_glyph_id_error(
      "font-horizontal-metrics",
      glyph.value_value,
      self.metric_index.num_glyphs,
    ),
  )
}
```

Use a kern-specific operation string but preserve category/code/context semantics. For cmap, add a signed-`Int` scalar validator before converting to `UInt64`; reject negatives, surrogates, and values above `0x10FFFF` as `InvalidInput`. Valid misses publish `GlyphId { value_value: 0UL }`.

Keep the public surface minimal: two `Font` methods and no new public table/facts types. Add private state to `Font` only if it is not already carried through `RequiredTableFacts`.

---

### `modules/mb-font/font/limits.mbt` (config/model, request-response)

**Analog:** existing `FontLimits`

Add `max_kern_subtables_value` and `max_kern_pairs_value` beside the other private fields (`limits.mbt:7-16`), named constructor parameters beside `max_cmap_records`, nonzero checks using `invalid_font_limit`, initialization fields, and public accessors.

Copy the constructor validation pattern from `limits.mbt:32-75`:

```moonbit
if max_cmap_records == 0UL {
  return Err(invalid_font_limit("max-cmap-records"))
}
...
Ok({
  max_cmap_records_value: max_cmap_records,
  ...
})
```

Use stable contexts `max-kern-subtables` and `max-kern-pairs`. Update every `FontLimits::new` call site; do not add defaults that hide the costly public resource-contract change.

---

### `modules/mb-font/font/font_test.mbt` (public black-box tests)

**Analog:** existing `font_test.mbt`

Extend the byte builders; do not introduce external font tooling. Format-4/12 fixture style is at `font_test.mbt:252-344`. It pushes big-endian fields explicitly, returns immutable `Bytes`, and accepts structured groups:

```moonbit
fn font_test_cmap_format12(groups : Array[(UInt64, UInt64, UInt64)]) -> Bytes {
  let output : Array[Byte] = []
  ...
  font_test_push_u32(output, 16UL + groups.length().to_uint64() * 12UL)
  font_test_push_u32(output, groups.length().to_uint64())
  for group in groups {
    let (start_code, end_code, start_glyph) = group
    font_test_push_u32(output, start_code)
    font_test_push_u32(output, end_code)
    font_test_push_u32(output, start_glyph)
  }
  Bytes::from_array(output)
}
```

Add kern builders in the same style and add helpers to build a font with an optional `kern` table. Public outcomes should use exact `inspect` assertions, including category, code, operation, requested/limit, and context where stable. Receiving-font checks follow `font_test.mbt:960-998`.

Exact-fit/one-short resource tests must recompute the complete work formula and prove atomic failure. Copy `font_test.mbt:1124-1211`: admit exact limits/budget, inspect zero remaining resources, then use `exact_work - 1UL` and assert the budget is unchanged after rejection.

Extend the all-query mutation helper at `font_test.mbt:2086-2096` with both new queries so every retained-source mutation case proves pre/post guard coverage.

---

### `modules/mb-font/font/font_wbtest.mbt` (private white-box tests)

**Analog:** `font_test.mbt` assertion/error style plus existing private symbol visibility

Use direct private helper calls for rank values, format-4 array-base math, format-12 lower-bound edges, kern exact-length/search-helper validation, signed FWORD decoding, pair-key order, and error taxonomy. Keep tests deterministic and table-driven. Reuse the exact `inspect(..., content="...")` style shown at `font_test.mbt:923-1016`; do not snapshot opaque binary blobs.

White-box boundary tests should cover zero/one/non-power-of-two/power-of-two pair counts and first/middle/last/miss binary-search positions. They should test derived navigation from counts even when helper fields are validated.

---

### `modules/mb-font/font/generated_fonts_wbtest.mbt` (test fixture utility)

**Analog:** generated builders in `font_test.mbt:252-365`

If shared white-box admission cases need cmap/kern variants, extend the existing generated table/builder layer instead of embedding duplicate full SFNT byte arrays in tests. Preserve the pattern of small table payload builders, a generic `tag + payload` table value, and checksum repair. Keep fixtures generated and deterministic; no licensed font is introduced in Phase 98.

If all new fixtures remain local to public `font_test.mbt`, leave this file unchanged rather than moving builders merely for symmetry.

---

### `modules/mb-font/font/pkg.generated.mbti` (generated interface)

**Analog:** existing generated interface at `pkg.generated.mbti:15-65`

Regenerate with `moon -C modules/mb-font info --target all --frozen`; never hand-edit. Expected delta:

- two public `Font` query signatures;
- `FontLimits::max_kern_subtables`;
- `FontLimits::max_kern_pairs`;
- the expanded `FontLimits::new` signature.

No private cmap/kern facts or raw table APIs may appear.

---

### `policy/foundation.json` (policy config)

**Analog:** current `tchivs/mb-font` entry at `policy/foundation.json:2181-2293`

Update all coupled allowlists in one change:

- package description to include deterministic Unicode mapping and basic legacy horizontal kerning;
- `publication_files` with `font/cmap.mbt` and `font/kern.mbt`;
- `production_sources` with `cmap.mbt`/`kern.mbt` in the actual accepted MoonBit source order;
- `semantic_interface` to exactly match regenerated `pkg.generated.mbti`.

Keep `allowed_imports` and four `supported_targets` unchanged. The policy’s exact interface format is line-oriented; copy generated signatures verbatim rather than retyping from memory.

---

### `modules/mb-font/README.mbt.md`, `modules/mb-font/CHANGELOG.md`, and `README.md`

**Analogs:** existing Phase 97 contract text in the same files

For `README.mbt.md`, update the contract/boundary sections at lines 14-34 and 103-133, the literate `FontLimits::new` example at lines 70-81, and document:

- one valid signed Unicode scalar query, invalid scalar error, and glyph-zero miss;
- deterministic format-12/format-4 selection;
- optional basic version-0 horizontal format-0 kern query and its absent/miss/unsupported/malformed distinctions;
- retained-source guards and allocation-free admitted lookups;
- continued exclusions for shaping, GPOS/GSUB, outlines, discovery, rasterization, and real-font qualification.

For `CHANGELOG.md`, extend the existing `0.1.0 candidate` “Added” list at lines 10-22 and replace the Phase 97 “does not claim cmap/kerning” sentence at lines 24-27 with the narrowed post-Phase-98 boundary.

For root `README.md`, update both English and Chinese `mb-font` responsibility rows (`README.md:46` and `README.md:142`) and matching status prose (`README.md:28`, `README.md:127-128`) so the two languages remain equivalent.

## Shared Patterns

### Package Imports and Portability

**Source:** `modules/mb-font/font/moon.pkg:1-10`  
**Apply to:** all production `.mbt` files

```moonbit
import {
  "tchivs/mb-core/budget",
  "tchivs/mb-core/bytes",
  "tchivs/mb-core/checked",
  "tchivs/mb-core/error",
}

supported_targets = "+js+wasm+wasm-gc+native"
```

MoonBit imports are package-level here; new source files should not add per-file import blocks or foreign dependencies.

### Retained-Source Guard

**Source:** `modules/mb-font/font/font.mbt:67-76`, `257-296`  
**Apply to:** both public queries

Check revision before caller validation/table reads and again immediately before publishing any table-derived result. Queries never charge or mutate the opening `Budget`.

### Error Taxonomy

**Source:** `modules/mb-font/font/directory.mbt:34-74`, `font.mbt:217-230`  
**Apply to:** cmap/kern admission and queries

| Condition | Category / code pattern |
|---|---|
| malformed supported bytes | `Data` / `InvalidEncoding`, operation `font-open` |
| recognized out-of-profile capability | `Capability` / `CapabilityUnavailable` |
| invalid scalar or receiving-font glyph | `InvalidInput` / `InvalidRange` |
| source revision drift | `State` / `InvalidRange` |
| semantic ceiling or budget | `Resource` / `BudgetExceeded` |

Do not collapse unsupported kern, absent kern, and pair miss into one result.

### Checked Arithmetic and Exact Envelopes

**Source:** `modules/mb-font/font/tables.mbt:558-733`, `988-1213`  
**Apply to:** `cmap.mbt`, `kern.mbt`, and admission integration

All attacker-derived offsets and lengths use `@checked`; reads are contained in the admitted `TableWindow`; declared lengths must be exact where the profile requires exact exhaustion. Validate sorted/unique/cardinality invariants during opening, not lazily in public queries.

### Preflight Before Attacker-Driven Loops

**Source:** `modules/mb-font/font/tables.mbt:736-755`, `859-972`, `263-304`  
**Apply to:** record, candidate-comparison, group, segment, subtable, and pair scans

Discover counts, checked-add them into cumulative work, preflight `max_work` and budget before the loop, then include the same work exactly once in the aggregate authoritative charge.

### Test Oracles

**Source:** `modules/mb-font/font/font_test.mbt:19-146`, `923-1016`, `1124-1269`, `2086-2120`  
**Apply to:** public and white-box tests

- exact semantic values through `inspect`;
- full structured-error field assertions;
- exact-fit and one-short semantic/budget cases;
- unchanged budget on atomic rejection and after successful queries;
- repeatability/order independence;
- mutation drift across every public query.

## No Analog Found

No scoped file lacks a close role/data-flow analog. However, there is no exact existing kern parser or canonical cmap-candidate consistency comparator. For those two algorithms, planner actions must take byte-layout specifics from `98-RESEARCH.md` and the locked CONTEXT decisions while preserving the local table-decoder, admission, error, and resource patterns above.

## Planner Notes

- Keep one production-quality tracer slice first: admit/select cmap facts, expose one guarded scalar query, and prove format-4/12 hit/miss plus mutation behavior before expanding to kern.
- The costly public `FontLimits::new` change should be isolated in a plan/task that updates all call sites, docs, generated interface, and policy together.
- Do not assign `pkg.generated.mbti` before production code compiles; regenerate it after the public surface is final.
- Policy/docs should be the final integration task after all four-target tests pass.
- `generated_fonts_wbtest.mbt` is conditional: modify it only when its shared fixture layer is used; otherwise all required generated public fixtures can remain in `font_test.mbt`.

## Metadata

**Analog search scope:** `modules/mb-font/font`, `modules/mb-font`, `policy/foundation.json`, root `README.md`  
**Graph result:** repository/file structure indexed; no MoonBit function nodes or matches, so scoped `rg` and direct reads were used per `AGENTS.md` fallback policy  
**Files scanned:** 20 relevant code/config/documentation files; 5 strong code analogs read for excerpts  
**Pattern extraction date:** 2026-07-27
