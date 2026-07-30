# Phase 109: Bounded Layout Admission - Pattern Map

**Mapped:** 2026-07-30  
**Canonical files classified:** 29  
**Additional proposal collisions resolved:** 3  
**Strong analog families:** 5  
**Graph status:** insufficient for current MoonBit symbols; source fallback used

## Discovery Note

Project instructions require codebase-memory graph discovery before text search.
`search_graph` was queried for cursor/window/limits/charge/transaction/revision/
error/fixture/layout symbols and returned zero current MoonBit function or call
nodes. A regex graph query returned only planning-document sections, not live
MoonBit definitions. The graph therefore could not supply callable symbol
analogs or line excerpts.

The permitted fallback inspected the live source under `modules/mb-font`,
`modules/mb-text`, and `modules/mb-core`, plus `policy/foundation.json`,
`scripts/quality/Assert-Policy.ps1`, module documentation, and RFCs. No project
skill directories were present. The checked branch is
`codex/v0.34-cff-outlines`; the pre-existing `.planning/config.json` change was
left untouched.

The five strongest reusable families are:

1. `cursor.mbt` + `directory.mbt`: checked `UInt64` reads, ranges, and
   table-local windows.
2. `cff_admission.mbt` + `cff_type2.mbt`: exact retained/work/allocation
   ledgers, preflight-before-allocation, revision probes, and atomic staging.
3. `limits.mbt` + `mb-text/text/limits.mbt`: private nonzero limit fields,
   deterministic validation order, and compatibility-preserving construction.
4. `font.mbt` + `shape_transaction.mbt` + `mb-text/text/shape.mbt`: source
   revision authority, request-scoped lifetime, one combined commit, and error
   operation rebinding.
5. CFF/shape/text tests plus `foundation.json`/`Assert-Policy.ps1`: generated
   byte fixtures, exact/one-short atomicity, private probes, exact interface
   inventories, and documentation/no-leakage gates.

There is no authentication or middleware pattern in this library phase.

## File Classification

### Canonical implementation, test, policy, and documentation targets

| New/Modified File | Action | Role | Data Flow | Closest Live Analog | Match Quality | Adaptation |
|---|---|---|---|---|---|---|
| `modules/mb-font/font/layout_limits.mbt` | add | config/model | transform | `modules/mb-font/font/limits.mbt` | exact role | Copy private fields, ordered zero rejection, stable `InvalidInput` errors; expose the constructor but no raw fields or Phase-109 profile accessors. |
| `modules/mb-font/font/layout_model.mbt` | add | model/store | transform | `cff_admission.mbt`; `cff_type2.mbt`; `mb-text/text/run.mbt` | composite exact | Retain owned primitive arrays and exact charge counters. Unlike `cmap`/`kern`, retain no `ByteView`, source offset, or unchecked index. |
| `modules/mb-font/font/layout_common.mbt` | add | utility/service | request-response transform | `cursor.mbt`; `directory.mbt`; `kern.mbt` | exact logic | Centralize table-local targets, offset-base ledger, list envelopes, selection, Coverage/ClassDef, flags, work, and stable errors. |
| `modules/mb-font/font/layout_gsub.mbt` | add | service/parser | request-response transform | `kern.mbt`; `cff_admission.mbt` | role/data-flow match | Deep-normalize only selected GSUB 1/4 and one-hop 7; preserve lookup order and every subtable occurrence; do not execute. |
| `modules/mb-font/font/layout_gpos.mbt` | add | service/parser | request-response transform | `kern.mbt`; `cff_admission.mbt` | role/data-flow match | Deep-normalize GPOS 2 and one-hop 9, checked ValueRecord widths and matrices; do not position. |
| `modules/mb-font/font/layout_gdef.mbt` | add | service/parser | request-response transform | optional-table path in `kern.mbt`; version/envelope parsing in `directory.mbt` | role match | Parse only when ignore-class flags require it; exact GDEF 1.0 plus normalized GlyphClassDef; richer unselected GDEF remains neutral. |
| `modules/mb-font/font/layout_admission.mbt` | add | provider/service | request-response transaction | `cff_admission.mbt`; `shape_transaction.mbt` | exact composite | Orchestrate entry/table/profile guards, global then selected deep validation, deferred capability, exact charge staging, and single-use scope mutation. |
| `modules/mb-font/font/shape_transaction.mbt` | modify | provider/service | callback transaction | same file | exact | Preserve public `with_shape_transaction` signature and one final commit. Make private `font_charge` mutable, add `layout_admitted`, and share active/revision authority. |
| `modules/mb-text/text/limits.mbt` | modify | config/model | transform | same file; `mb-font/font/limits.mbt` | exact | Keep the two-argument constructor exactly; embed the sealed default `FontLayoutLimits`; add only `with_layout_limits`. |
| `modules/mb-text/text/shape.mbt` | modify | controller/service | request-response transaction | same file | exact | Validate caller input first, project semantic tags/toggles into `scope.admit_layout`, sanitize/rebind errors to `text-shape`, retain empty success and nonempty `layout-unavailable`. |
| `modules/mb-font/font/layout_fixture_wbtest.mbt` | add | test utility | file-I/O-like byte generation | `cff_admission_wbtest.mbt`; `generated_fonts_wbtest.mbt` | exact role | Build generated table bytes with labelled bases and patch helpers; cover exact end, one-short, overflow, aliasing, and noncontiguous targets; no licensed bytes. |
| `modules/mb-font/font/layout_common_wbtest.mbt` | add | white-box test | batch | `cff_admission_wbtest.mbt`; `kern` tests | role match | Table-drive every header/list/selection/Coverage/ClassDef boundary and selected-vs-unselected depth rule. |
| `modules/mb-font/font/layout_gsub_wbtest.mbt` | add | white-box test | batch | `cff_type2_fixture_wbtest.mbt`; `cff_admission_wbtest.mbt` | role match | Generated hostile body matrices, exact normalized summaries, type-7 offset above `0xFFFF`, recursive/unsupported capability cases. |
| `modules/mb-font/font/layout_gpos_wbtest.mbt` | add | white-box test | batch | `cff_type2_bounds_wbtest.mbt`; `cff_admission_wbtest.mbt` | role match | PairSet order/cardinality, class product/extent, every ValueFormat bit and complete record window, type-9 matrix. |
| `modules/mb-font/font/layout_gdef_wbtest.mbt` | add | white-box test | batch | optional/unsupported tests in `kern.mbt`; CFF profile tests | role match | Cover dependency absent/null/malformed, exact 1.0, richer capability, class bounds 0-4, and ignore masks. |
| `modules/mb-font/font/layout_admission_wbtest.mbt` | add | white-box test | event-driven/batch | `cff_admission_wbtest.mbt`; `shape_transaction_wbtest.mbt` | exact composite | Probe every named revision seam; inspect private summaries; prove deferred capability ordering, exact charges, limits, and unchanged budgets on failure. |
| `modules/mb-font/font/layout_admission_test.mbt` | add | black-box test | batch/request-response | `shape_transaction_test.mbt`; `font_test.mbt` | exact public role | Test public constructor, abstract profile/scope surface, direct tag validation, scope closure, and second-admission State failure without private facts. |
| `modules/mb-font/font/shape_transaction_test.mbt` | modify | black-box test | batch/transaction | same file | exact | Extend existing exact/one-short, scope escape, and error-close cases with admission charge composition; preserve all Phase 108 regressions. |
| `modules/mb-font/font/shape_transaction_wbtest.mbt` | modify | white-box test | event-driven/batch | same file | exact | Add layout-stage mutations and mutable font-charge composition while retaining final guard/overflow/ancestor atomicity. |
| `modules/mb-text/text/contract_test.mbt` | modify | black-box test | batch/request-response | same file | exact | Freeze old constructor, new customization, empty behavior, valid nonempty fail-closed result, sanitized errors, and InvalidInput precedence. |
| `modules/mb-text/text/contract_wbtest.mbt` | modify | white-box test | event-driven/batch | same file | exact | Exercise semantic projection, error rebinding, admitted private profile path, stage matrix, mutations, and zero committed charge. |
| `modules/mb-font/README.mbt.md` | modify | docs/test | static/doc-check | current “Glyph ownership and shaping transaction seam” section | exact | Add public-abstract admission surface, subset, lifetime, charge/work semantics, and explicit no-execution/no-cache/no-raw-facts boundary. |
| `modules/mb-font/CHANGELOG.md` | modify | docs/config | static | current Phase 108 additive entry | exact | Record additive candidate admission surface and closed subset; do not claim layout execution or qualification. |
| `modules/mb-text/README.mbt.md` | modify | docs/test | static/doc-check | current closed limits/transaction/nonempty sections | exact | Document exact defaults/customization and continued nonempty failure after private admission. |
| `modules/mb-text/CHANGELOG.md` | modify | docs/config | static | current candidate entry | exact | Record additive `ShapeLimits` customization without shaping-success language. |
| `docs/rfcs/0004-mb-font.md` | modify | governance docs | static | Sections 3.2, 6, and 8 in same RFC | exact | State request-scoped normalized layout authority, font-owned parsing, no raw inspection/cache, and no executor. |
| `docs/rfcs/0005-mb-text.md` | modify | governance docs | static | Sections 3.1, 6.1/6.2, and 7 in same RFC | exact | State semantic projection, text-owned execution boundary, layout-limit ownership, and Phase 109 nonempty closure. |
| `policy/foundation.json` | modify | config/policy | batch/governance | existing mb-font and mb-text entries | exact | Update exact publication/source/test arrays and semantic interfaces; refresh relevant hashes/counts only after final source/docs. Preserve DAG. |
| `scripts/quality/Assert-Policy.ps1` | modify | policy utility | batch | `Assert-FontPhase108Surface`; `Assert-TextFoundationPolicy` | exact | Replace the Phase 108 one-operation assumption with the exact additive surface; add context/inventory/docs/no-leakage/no-execution gates and negative fixtures. |

### Proposal collision resolution

The research contains three names in the illustrative project tree that are not
in its exact implementation/test matrices. The planner should resolve them
before assigning tasks:

| Proposed Name | Canonical Resolution | Reason |
|---|---|---|
| `modules/mb-font/font/layout_cursor.mbt` | Prefer merging into `layout_common.mbt` unless a compile-proved private-visibility split is useful. | The exact implementation matrix assigns the table-local offset helper to `layout_common.mbt`, and the research explicitly permits this merge. Do not plan both files with duplicate target/window logic. |
| `modules/mb-text/text/limits_test.mbt` | Do not add; extend `contract_test.mbt`. | The exact test matrix assigns old/new constructor compatibility to the existing public contract test, and exact policy currently seals the two-test inventory. |
| `modules/mb-text/text/shape_test.mbt` | Do not add; extend `contract_test.mbt` and `contract_wbtest.mbt`. | The exact test matrix assigns public closure to the former and semantic/probe internals to the latter. A third file would collide with policy inventory and duplicate fixtures. |

`modules/mb-font/font/moon.pkg` and `modules/mb-text/text/moon.pkg` require no
new import: all Phase 109 source stays inside existing packages. Their exact
imports already enforce `mb-text -> mb-font -> mb-core`.

## Pattern Assignments

### 1. `layout_common.mbt`: checked table-local target and offset ledger

**Primary analogs:** `modules/mb-font/font/cursor.mbt`,
`modules/mb-font/font/directory.mbt`

MoonBit imports are package-wide, not per source file. Keep the existing
`mb-font/font/moon.pkg` import set:

```moonbit
// modules/mb-font/font/moon.pkg:1-7
import {
  "tchivs/mb-core/budget",
  "tchivs/mb-core/bytes",
  "tchivs/mb-core/checked",
  "tchivs/mb-core/error",
  "tchivs/mb-core/math",
}
```

Copy the checked-add-before-read shape:

```moonbit
// modules/mb-font/font/cursor.mbt:19-33
fn require_read_window(
  source : @bytes.ByteView,
  offset : UInt64,
  width : UInt64,
) -> Result[Unit, @error.CoreError] {
  let end = match @checked.checked_add(offset, width) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if end > source.length() {
    Err(font_read_error(offset, width, source.length()))
  } else {
    Ok(())
  }
}
```

Copy `read_u16`/`read_u32` from `cursor.mbt:47-68` and `87-108`; do not narrow
an Offset16/32 merely because its encoded width is 16/32 bits. Resolve and keep
all arithmetic as `UInt64`.

Copy the subrange proof, adapted to a table-local view:

```moonbit
// modules/mb-font/font/directory.mbt:346-360
let source_range =
  @checked.CheckedRange::from_start_length(0UL, source.length())
let table_range = source_range.subrange(offset, length)
source.subview(table_range.start(), table_range.length())
```

Adaptation rules:

- First reduce GSUB/GPOS/GDEF to `TableWindow.view`; all later offsets resolve
  inside that local view.
- The target helper takes an explicit base supplied by the field ledger. Never
  use “current cursor” or table start as an implicit universal base.
- Prove `base + offset`, `target + minimum`, and the complete count-derived
  extent separately with checked arithmetic.
- Zero is handled by the field schema before addition; it is legal only for
  the locked nullable fields.
- A target subview extends from resolved target to the end of the owning table,
  not to the next sibling. Aliasing/non-monotonic siblings are legal.
- Map arithmetic/window failures to
  `Data/InvalidEncoding`, operation `font-layout-admit`, and a sealed semantic
  context. Do not forward `font-read` with `source_offset` to the text API.

The exact base assignments that tests must name are:

| Field family | Base |
|---|---|
| ScriptList/FeatureList/LookupList offsets | layout table start |
| ScriptRecord | ScriptList start |
| LangSys | selected Script start |
| FeatureRecord | FeatureList start |
| FeatureParams | selected Feature start |
| lookup offsets | LookupList start |
| subtable offsets | selected Lookup start |
| Coverage/ClassDef/PairSet/LigatureSet | owning selected subtable |
| Ligature offsets | owning LigatureSet |
| GDEF GlyphClassDef | GDEF start |
| extension target | extension-subtable start |

### 2. `layout_model.mbt`: owned normalized facts and exact ledgers

**Primary analogs:** `cff_admission.mbt`, `cff_type2.mbt`,
`mb-text/text/run.mbt`

Copy the explicit parallel charge facts:

```moonbit
// modules/mb-font/font/cff_admission.mbt:54-84
priv struct CffCombinedCharge {
  resource : @budget.ResourceCharge
  bytes : UInt64
  allocations : UInt64
  allocation_size : UInt64
  work : UInt64
}

priv struct CffStructuralCharge {
  resource : @budget.ResourceCharge
  bytes : UInt64
  allocations : UInt64
  allocation_size : UInt64
  retained_bytes : UInt64
  // named semantic/work counters follow
}
```

Copy checked sum for consumable dimensions and maximum for
`allocation_size`:

```moonbit
// modules/mb-font/font/cff_admission.mbt:1632-1669
let bytes = @checked.checked_add(structural.bytes, type2.bytes)
let allocations =
  @checked.checked_add(structural.allocations, type2.allocations)
let allocation_size =
  if structural.allocation_size > type2.allocation_size {
    structural.allocation_size
  } else {
    type2.allocation_size
  }
let work = @checked.checked_add(structural.work, type2.work)
@budget.ResourceCharge::new(
  bytes~,
  allocations~,
  allocation_size~,
  width=0UL,
  height=0UL,
  pixels=0UL,
  work~,
)
```

This agrees with the core contract in
`modules/mb-core/budget/budget.mbt:171-217`: `bytes`, `allocations`, and `work`
add, while per-operation ceilings take the maximum.

For exact allocation preflight, copy the two-pass/staged pattern:

```moonbit
// modules/mb-font/font/cff_type2.mbt:2008-2129
let bounds_bytes = @checked.checked_mul(bounds_slots, 24UL)
let path_count_bytes = @checked.checked_mul(bounds_slots, 8UL)
let path_work_bytes = @checked.checked_mul(bounds_slots, 8UL)
let bytes = @checked.checked_add(
  bounds_bytes,
  @checked.checked_add(path_count_bytes, path_work_bytes),
)
let fixed_authority = @budget.ResourceCharge::new(
  bytes~,
  allocations=base_allocations,
  allocation_size~,
  width=0UL,
  height=0UL,
  pixels=0UL,
  work=0UL,
)
budget.preflight(fixed_authority)
```

Then allocate exact arrays only after preflight, as at
`cff_type2.mbt:2143-2151`.

Phase 109 adaptation:

- Profile header is 64 logical retained bytes.
- Selected lookup arrays use `8 * count`; lookup descriptor planes use
  `32 * count`; occurrence planes use `16 * count`.
- Coverage 1 is an owned GID array; Coverage 2 is owned start/end/start-index
  planes plus cardinality.
- ClassDef 1/2, substitutions, ligatures, pairs, and dense value planes follow
  the exact coefficients sealed in `109-RESEARCH.md:378-393`.
- `bytes` counts only final normalized facts, never GSUB/GPOS/GDEF source table
  bytes.
- `allocations` counts every explicit scratch and retained array, including
  empty arrays.
- `allocation_size` is the maximum logical payload of any single scratch or
  retained array.
- Build exact-size arrays and move them into the profile. If any `.copy()` is
  added, charge its allocation, bytes where retained, and copy work.
- Work increments for reads, resolves, visits, comparisons, dispatches,
  unsupported probes, copies, and named stages. It contains no execution or
  output work.

The immutable-copy pattern in `mb-text/text/run.mbt:55-76` is useful for
public values, but Phase 109 should avoid an unnecessary final copy by moving
private exact-size arrays into the profile.

### 3. `layout_limits.mbt` and `mb-text/text/limits.mbt`

**Primary analogs:** `modules/mb-font/font/limits.mbt`,
`modules/mb-text/text/limits.mbt`

Copy private fields and deterministic first-zero validation:

```moonbit
// modules/mb-font/font/limits.mbt:25-33, 38-61
fn invalid_font_limit(context : String) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::InvalidInput,
    @error.ErrorCode::InvalidRange,
    operation="font-limits-new",
    requested=0UL,
    limit=1UL,
    context~,
  )
}

pub fn FontLimits::new(/* named UInt64 ceilings */)
  -> Result[FontLimits, @error.CoreError] {
  if max_source_bytes == 0UL {
    return Err(invalid_font_limit("max-source-bytes"))
  }
  // Continue in constructor argument order.
}
```

Use operation `font-layout-limits-new` and each exact kebab-case limit field as
context. `FontLayoutLimits` is public-abstract: public constructor, private
fields, and no raw/table/profile accessor.

Preserve this signature exactly:

```moonbit
// modules/mb-text/text/limits.mbt:21-35
pub fn ShapeLimits::new(
  max_input_scalars~ : UInt64,
  max_output_glyphs~ : UInt64,
) -> Result[ShapeLimits, @error.CoreError]
```

The constructor embeds the sealed defaults:

| Field | Default |
|---|---:|
| `max_gsub_bytes` | 1,048,576 |
| `max_gpos_bytes` | 1,048,576 |
| `max_gdef_bytes` | 262,144 |
| `max_scripts` | 256 |
| `max_language_systems` | 512 |
| `max_features` | 2,048 |
| `max_feature_references` | 8,192 |
| `max_lookups` | 2,048 |
| `max_subtables` | 4,096 |
| `max_coverage_glyphs` | 65,535 |
| `max_coverage_ranges` | 8,192 |
| `max_classdef_glyphs` | 65,535 |
| `max_classdef_ranges` | 8,192 |
| `max_substitution_rules` | 65,535 |
| `max_ligature_sets` | 16,384 |
| `max_ligatures` | 65,535 |
| `max_ligature_components` | 262,144 |
| `max_pair_sets` | 16,384 |
| `max_pair_records` | 262,144 |
| `max_classes` | 1,024 |
| `max_class_cells` | 262,144 |
| `max_record_extent` | 8,388,608 |
| `max_cross_product` | 262,144 |
| `max_retained_bytes` | 16,777,216 |
| `max_allocations` | 32,768 |
| `max_allocation_size` | 8,388,608 |
| `max_parser_work` | 10,000,000 |

Add:

```moonbit
pub fn ShapeLimits::with_layout_limits(
  self : ShapeLimits,
  layout_limits : @font.FontLayoutLimits,
) -> ShapeLimits
```

It replaces only the embedded bundle. It must not alter
`max_input_scalars_value` or `max_output_glyphs_value`, and must not add a new
required argument or a public `ShapeLimits::default`.

### 4. `layout_gsub.mbt`, `layout_gpos.mbt`, and `layout_gdef.mbt`

**Primary analog:** `modules/mb-font/font/kern.mbt`

The closest parser shape is “global envelope, semantic/resource preflight,
selected deep validation, compact facts.” Copy:

```moonbit
// modules/mb-font/font/kern.mbt:176-256
let pair_bytes = @checked.checked_mul(pair_count, 6UL)
let expected_length = @checked.checked_add(14UL, pair_bytes)
if profile.subtable_length != expected_length {
  return Err(font_data_error("font-kern-format0"))
}
for index = 0UL; index < pair_count; index = index + 1UL {
  pair_probe()
  let record_offset = @checked.checked_mul(index, 6UL)
  let offset = @checked.checked_add(pairs_start, record_offset)
  // read, range-check, and require strict order
}
```

Also copy declared-count preflight before traversal:

```moonbit
// modules/mb-font/font/kern.mbt:363-390
if subtable_count > limits.max_kern_subtables() {
  return Err(font_limit_error(
    "max-kern-subtables",
    subtable_count,
    limits.max_kern_subtables(),
  ))
}
let subtable_work = @checked.checked_add(base_work, subtable_count)
ledger.admit_stage(
  limits.max_work(),
  subtable_work,
  base_budget_work,
  subtable_count,
)
```

Adaptation:

- Validate the fixed envelope first. Truncation is `Data`.
- Once fixed fields are valid, declared count/product/extent ceilings can
  return `Resource` before attacker-sized loops.
- Global Script/Feature/Lookup records validate array extents, strict tag
  ordering/uniqueness, and immediate child envelopes even when unselected.
- Do not capability-check valid unselected rich bodies.
- Deep-decode every selected occurrence. Defer only `Capability`; State, Data,
  and Resource remain immediate.
- Union/de-duplicate lookup indices and emit them ascending. Preserve every
  selected subtable occurrence in source order; never de-duplicate occurrences.
- Coverage/ClassDef ranges require ordered, non-overlapping endpoints and exact
  cardinality/index progression.
- PairPos 2 checks `class1Count * class2Count` independently of each factor and
  before matrix traversal/allocation.
- Extensions allow one Offset32 hop only. Never narrow it to 16 bits.
- GDEF is parsed only for selected class-ignore flags.

Do not copy `font_lookup_kern` (`kern.mbt:505-566`): it executes a binary lookup.
Phase 109 admission may use binary search for selection internally, but must not
apply substitution, kerning, or positioning.

### 5. `layout_admission.mbt` and `shape_transaction.mbt`

**Primary analogs:** `modules/mb-font/font/font.mbt`,
`modules/mb-font/font/shape_transaction.mbt`,
`modules/mb-font/font/cff_admission.mbt`

Reuse the retained source guard:

```moonbit
// modules/mb-font/font/font.mbt:77-114
fn font_revision_error(operation : String) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::State,
    @error.ErrorCode::InvalidRange,
    operation~,
    context="font-source-revision-drift",
  )
}

fn Font::require_revision(
  self : Font,
  operation : String,
) -> Result[Unit, @error.CoreError] {
  if self.source.mutation_revision() != self.opening_revision {
    Err(font_revision_error(operation))
  } else {
    Ok(())
  }
}
```

Keep the existing callback lifetime:

```moonbit
// modules/mb-font/font/shape_transaction.mbt:42-64, 98-104
fn FontShapeScope::require_active(self : FontShapeScope)
  -> Result[Unit, @error.CoreError] {
  if !self.active {
    return Err(font_shape_scope_closed_error())
  }
  self.font.require_revision("font-shape-scope")
}

let scope = FontShapeScope::{ font: self, active: true, font_charge }
defer scope.close()
```

Keep the one-commit tail exactly:

```moonbit
// modules/mb-font/font/shape_transaction.mbt:118-140
(probes.post_complete_staging)()
self.require_revision("font-shape-transaction")
let combined = scope.font_charge.checked_add(text_charge)
budget.preflight(combined)
(probes.before_final_guard)()
self.require_revision("font-shape-transaction")
budget.charge(combined)
Ok(value)
```

Admission adaptation:

1. Entry guard.
2. Before/after selected GSUB.
3. Before/after selected GPOS.
4. Before/after selected GDEF binding.
5. After complete profile staging.
6. Existing final pre-commit transaction guard.

`FontShapeScope::admit_layout` first requires active state and rejects a second
successful admission with
`State/InvalidRange`, operation `font-layout-admit`, context
`layout-already-admitted`.

Only after the complete-profile guard succeeds should it:

- checked-add the exact admission charge into `scope.font_charge`;
- set `scope.layout_admitted = true`; and
- return the abstract profile.

Every error before that point leaves both fields unchanged. The admission
method must not call `Budget::charge`; the transaction remains the sole commit.

`FontLayoutProfile` shares the admitting scope's active/revision identity. It
may escape nominally, but exposes no Phase 109 methods and becomes unusable
when the callback closes. Do not add a persistent constructor or cache.

### 6. `mb-text/text/shape.mbt`: semantic projection and sanitized rebinding

**Primary analog:** same file plus `tags.mbt`/`options.mbt`

Input validation already occurs before font authority:

```moonbit
// modules/mb-text/text/shape.mbt:386-394
match options.validate() {
  Err(error) => return Err(error)
  Ok(_) => ()
}
let snapshot = match validate_and_snapshot_scalars(scalars) {
  Err(error) => return Err(error)
  Ok(value) => value
}
font.with_shape_transaction(budget, fn(scope) {
  // request-scoped font work
})
```

Project only semantic values:

- `options.script().bytes()`;
- `LanguageChoice::Default -> None`;
- `LanguageChoice::Exact(tag) -> Some(tag.bytes())`;
- `options.features().liga()`;
- `options.features().kern()`;
- `limits`' private layout bundle.

`tags.mbt:24-43` is the reusable direct-caller validation/copy pattern: exact
length four, printable ASCII, and owned bytes. Never include the selected tag
bytes in an error context.

The existing public capability remains:

```moonbit
// modules/mb-text/text/shape.mbt:13-20
@error.CoreError::new(
  @error.ErrorCategory::Capability,
  @error.ErrorCode::CapabilityUnavailable,
  operation="text-shape",
  context="layout-unavailable",
)
```

After successful private admission, nonempty Phase 109 still returns this
error from the callback; therefore neither layout admission charge nor the
text charge commits.

Do not copy `text_shape_project_error` verbatim: at
`shape.mbt:132-147` it forwards `source_offset`. Layout rebinding must preserve
category/code and only allowed named semantic `requested/limit` fields, set
operation `text-shape`, retain the sealed context, and strip source offset,
record ordinal, lookup index, and tag payload.

### 7. Stable `CoreError` construction

**Primary analog:** `modules/mb-core/error/core_error.mbt`

Use structured facts:

```moonbit
// modules/mb-core/error/core_error.mbt:49-72
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

Internal operation is always `font-layout-admit`; the public text boundary
rebinds it to `text-shape`.

Seal this context vocabulary:

- Headers/lists: `gsub-header`, `gpos-header`, `gdef-header`, `script-list`,
  `feature-list`, `lookup-list`, `feature-variations`.
- Selection: `script-record-order`, `script-record-offset`,
  `language-record-order`, `language-record-offset`, `language-selection`,
  `lookup-order`, `feature-index`, `required-feature-index`, `feature-params`,
  `feature-record-order`, `feature-record-offset`, `lookup-index`,
  `lookup-record-offset`, `lookup-subtable-offset`,
  `layout-already-admitted`.
- Common: `coverage-format`, `coverage-order`, `coverage-cardinality`,
  `classdef-format`, `classdef-range`, `classdef-class`, `lookup-flags`,
  `value-format`, `value-record`.
- GSUB: `single-format`, `single-cardinality`, `single-substitute`,
  `ligature-format`, `ligature-set-cardinality`, `ligature-offset`,
  `ligature-component`.
- GPOS: `pair-format`, `pairset-cardinality`, `pair-second-order`,
  `pair-class-count`, `pair-class-cell-extent`.
- GDEF/extensions: `gdef-glyph-class`, `extension-format`, `extension-type`,
  `extension-target`.
- Limits: exact kebab-case constructor/ceiling names.

Canonical rendering order is already fixed at `core_error.mbt:217-239`; no new
error type or host prose is needed.

## Test Pattern Assignments

### Generated fixture builders

Copy local array builders, patch helpers, and checksum repair from
`cff_admission_wbtest.mbt:2-116`. The key pattern is that a builder returns
owned `Bytes`, and a later helper wraps it into a generated SFNT while patching
checksums deterministically:

```moonbit
fn cff_wb_otf_tables(tables : Array[GeneratedFontTable]) -> Bytes {
  let sfnt = font_wb_build_sfnt(tables)
  let patched = font_wb_put_u32_at_copy(sfnt, 0, 0x4F54544FUL)
  let output = font_wb_bytes_array(patched)
  // patch head.checkSumAdjustment
  Bytes::from_array(output)
}
```

Phase 109 fixture builders should expose private labelled bases rather than
magic offsets, for example `layout_start`, `script_list_start`,
`selected_script_start`, `lookup_start`, `subtable_start`, and
`ligature_set_start`. Provide private helpers to patch Offset16/32 relative to
the intended base and to truncate at an exact byte boundary.

Do not place fixtures in public source or expose a fixture builder through the
generated interface.

### Exact charge and one-short atomicity

Copy the assertions in `cff_admission_wbtest.mbt:334-388`:

- compare named combined charge dimensions with component sums;
- construct a budget from the exact measured charge;
- rerun admission;
- assert consumable remaining dimensions are zero.

Copy the failure invariant from `cff_admission_wbtest.mbt:72-97`: snapshot all
budget dimensions, force the error, assert category/context, and compare the
unchanged snapshot.

For each semantic limit and each of `bytes`, `allocations`,
`allocation_size`, and `work`, generate an exact-fit case and a one-short case.
For `allocation_size`, exact/one-short compares the maximum, not a sum.

### Revision probes and transaction lifetime

Copy private probe injection from `cff_admission_wbtest.mbt:425-505` and
`contract_wbtest.mbt:1122-1165`: production probes are no-ops, tests inject a
mutation at one named seam, and every case asserts `State` plus unchanged
budget.

Copy public scope lifetime tests from `shape_transaction_test.mbt:142-184`:

- captured scope is closed after success;
- generic-returned scope is closed;
- captured scope closes after callback error.

Extend the pattern to an escaped abstract profile only through behavior
available inside white-box tests; do not add a public profile accessor merely
to test it.

### Stage precedence

Use `contract_wbtest.mbt:1027-1119` as the matrix structure, but apply the Phase
109 order:

`InvalidInput -> State -> Data -> Capability -> Resource`.

The one exception is count/resource preflight after a valid fixed envelope and
before attacker-sized traversal. A malformed fixed envelope remains Data.
Defer Capability across all selected occurrences so a later Data error wins;
do not defer State/Data/Resource.

### Black-box versus white-box split

- `layout_admission_test.mbt` and `contract_test.mbt` import only public API and
  assert abstractness through what cannot be called or observed.
- `*_wbtest.mbt` may inspect private normalized counts, kinds, order hashes,
  charge coefficients, and probe seams.
- No white-box summary may be added to `pkg.generated.mbti`.
- Preserve existing Phase 108 tests; add cases rather than replacing them.

## Policy and Documentation Patterns

### Exact policy inventories and interfaces

`policy/foundation.json:2190-2410` currently seals:

- mb-font direct dependency `tchivs/mb-core`;
- exact publication files;
- exact production/test source arrays;
- exact semantic interface;
- the abstract `FontShapeScope` and its current operation.

Add the seven canonical production files and seven new test files to all
applicable mb-font inventories. Add exact semantic lines for:

```text
pub struct FontLayoutLimits {
}
pub fn FontLayoutLimits::new(/* exact 27 named UInt64 fields */) -> Result[Self, @error.CoreError]
pub struct FontLayoutProfile {
}
pub fn FontShapeScope::admit_layout(Self, Bytes, Bytes?, Bool, Bool, FontLayoutLimits) -> Result[FontLayoutProfile, @error.CoreError]
```

Do not add profile methods or limit-field accessors unless a later locked
decision explicitly requires them.

`policy/foundation.json:2557-2714` seals the text module's exact two
dependencies and one-way edges. Add only
`ShapeLimits::with_layout_limits(Self, @font.FontLayoutLimits) -> ShapeLimits`
and any compile-proved abstract type import effect. Keep:

```text
pub fn ShapeLimits::new(max_input_scalars~ : UInt64, max_output_glyphs~ : UInt64) -> Result[Self, @error.CoreError]
pub fn shape(@font.Font, Array[Int], ShapingOptions, ShapeLimits, @budget.Budget) -> Result[ShapedRun, @error.CoreError]
```

`scripts/quality/Assert-Policy.ps1:4346-4577` is the exact pattern for:

- dependency/DAG assertions;
- production/test/publication inventories;
- exact generated interface sequence;
- required evidence test names;
- documentation facts;
- forbidden interface negative fixtures;
- `moon info --target all --frozen`.

Update `Assert-FontPhase108Surface` rather than stacking a contradictory second
allowlist. Its current assertion at `Assert-Policy.ps1:1113-1118` says
`units_per_em` is the scope's only operation; Phase 109 must replace that with
the exact two-operation shape.

Add negative interface fixtures for:

- `FontLayoutProfile::lookups`, `tables`, `offsets`, `source`, `bytes`,
  `indices`, `charge`, `commit`, or `execute`;
- `FontShapeScope::layout_profile`, cache constructors, or mutation probes;
- text-side `FontShapeScope`, `FontLayoutProfile`, raw `ByteView`, table facts,
  lookup indices, or prepared/commit handles.

Add source scans that forbid Phase 109 production from calling layout
execution, public `Font::kerning`, final metrics, cmap seeds, legacy-kern
selection, FFI, filesystem/network/UI, or qualification oracles.

Refresh source/doc hashes only after source, tests, READMEs, changelogs, and
RFC wording are final. Never hand-edit `pkg.generated.mbti`; regenerate and
compare it.

### Quality lanes

Phase 109 structural admission belongs to the existing Required policy/test
lane. No new lane or workflow file is proposed.

Planner verification should use:

```powershell
moon -C modules/mb-font test font --target all --frozen
moon -C modules/mb-text test text --target all --frozen
moon -C modules/mb-font info --target all --frozen
moon -C modules/mb-text info --target all --frozen
moon test --target all --frozen --outline
./scripts/quality/Assert-Policy.ps1
./scripts/quality.ps1 -Lane Required -EvidenceDirectory artifacts/release-qualification/phase109-required
```

The existing `FontQualification` lane may remain green as a regression lane,
but Phase 109 must not add layout cases to its licensed/oracle evidence or use
it to claim semantic shaping qualification. Phase 113 owns that claim.

### Documentation placement

- Extend `mb-font/README.mbt.md` near lines 414-446, the existing glyph
  ownership and transaction seam.
- Preserve the explicit boundary near lines 594-608 that mb-font does not shape
  text and that qualification does not widen the API.
- Extend `mb-text/README.mbt.md` near lines 41-55 for limits and lines 152-206
  for nonempty closure, transaction, and no-parser/no-cache boundary.
- Append candidate-compatible entries to the current `0.1.0 candidate
  (unpublished)` changelog sections.
- Update RFC 0004 Sections 3.2, 6, and 8; update RFC 0005 Sections 3.1, 6, and
  7. Do not silently widen the full contextual shaping scope.

Documentation must say “MNF closed-profile policy” for duplicate
FeatureRecords, selected FeatureParams, and recursive extensions when the
locked result intentionally differs from broad OpenType permissiveness. It
must not label every such case generically “invalid OpenType.”

## Cross-Module and Integration Constraints

1. Dependency direction remains:

   ```text
   mb-text -> mb-font -> mb-core
   ```

   `mb-font` must not import `mb-text`; semantic script/language/toggle values
   cross as `Bytes`, `Bytes?`, and booleans.

2. Public `shape` signature remains unchanged. The only text API addition is
   additive limit customization.

3. Public `Font::with_shape_transaction` signature remains unchanged. The only
   font additions are the public-abstract limits/profile types and the scoped
   admission method.

4. Empty input still reads guarded UPEM and commits exact text `work=1`; it need
   not admit layout.

5. Nonempty Phase 109 may privately admit a profile but returns
   `layout-unavailable`, so no admission/text charge commits and no run is
   published.

6. No GSUB/GPOS execution, cmap seed, final metrics, legacy kern choice,
   ligature cluster consumption, or positioning enters this phase.

7. No source table byte is recharged. Charges cover normalized retained bytes,
   actual arrays, maximum single allocation, and parser work.

8. No raw source view, table window, source offset, public lookup index,
   mutable source state, cache handle, commit method, or plan accessor escapes.

## Files and Patterns That Must Not Be Copied

| Source Pattern | Why It Must Not Be Copied Verbatim | Safe Part to Reuse |
|---|---|---|
| `cmap.mbt:3-18` compact facts containing `ByteView` and source offsets | D-29 requires fully owned normalized layout facts with no raw views or unchecked offsets. | Selection/rank logic, checked extents, strict ordering, and binary-search shape only. |
| `kern.mbt:3-7` facts containing `ByteView`/`pairs_start` | Phase 109 cannot retain font-source pair views as its normalized layout profile. | Envelope/count/order/GID validation and declared-count preflight. |
| `kern.mbt:505-566` lookup execution | It applies legacy kerning and is Phase 111/out of scope. | None beyond generic allocation-free binary-search mechanics for internal tag selection. |
| `cff_admission.mbt:1739-1753` direct `commit_atomic` | Layout admission must stage into `FontShapeScope`; only `with_shape_transaction` commits. | Final revision-guard placement and unchanged-budget tests. |
| `cff_type2.mbt` VM/execution paths | Phase 109 admits only; no GSUB/GPOS execution or output work. | Exact allocation/work/charge accounting and revision-error dominance. |
| Licensed CFF/real-font qualification fixtures and oracle scripts | D-45 reserves licensed/oracle/cross-target semantic layout claims for Phase 113. | Generated hostile fixture coding style only. |
| `text_shape_project_error` forwarding `source_offset` | Phase 109 public diagnostics must strip raw offsets/indices/tags. | Preserve category/code and allowed named semantic limit fields. |
| Phase 108 policy assertion that `units_per_em` is the scope's only operation | It would reject the required `admit_layout` addition. | Exact-sequence allowlist and negative-fixture framework. |
| Any manually edited `pkg.generated.mbti` | Generated interfaces are evidence, not source. | Run `moon info`, then update policy to the exact generated lines. |

## Collision and Review Risks

| Risk | Required Resolution |
|---|---|
| `layout_cursor.mbt` versus `layout_common.mbt` duplicates target logic | Choose one implementation owner. The exact matrix favors `layout_common.mbt`; tests should call one helper only. |
| Separate `limits_test.mbt`/`shape_test.mbt` versus existing contract tests | Follow the exact test matrix and extend existing files unless policy/test inventory is deliberately revised. |
| Old `ShapeLimits::new` gains a third argument or new semantics | Keep its exact two-argument interface and values; defaults are embedded privately. |
| Public limit accessors accidentally expose 27 fields | Research's proposed interface shows constructor only. Keep fields package-private unless compile needs prove a private helper. |
| Profile owns an independent `active` boolean | Share the same scope authority; otherwise an escaped profile could remain usable after callback close. |
| Admission charge is added before final profile guard | Mutate `font_charge` and `layout_admitted` only after complete staging and revision guard. |
| Layout parser commits its own budget | Forbidden; stage charge only and preserve transaction's single `Budget::charge`. |
| Capability returned on first unsupported selected occurrence | Defer Capability so later selected Data is still discovered; never allow a later supported occurrence to hide an earlier unsupported one. |
| Lookup references and subtable occurrences both de-duplicated | De-duplicate lookup indices only; retain every subtable occurrence in source order. |
| Factor limits used as product proof | Check `class1 * class2`, record byte extents, and aggregate counters independently. |
| GDEF parsed eagerly | Parse only if selected lookup flags need its classifier; rich unused GDEF is neutral. |
| Layout source bytes included in `ResourceCharge.bytes` | Charge normalized retained facts only; source belongs to the already-open font. |
| Public rebind leaks source offset, index, or tag | Reconstruct `CoreError` with the sealed context and allowed limit fields only. |
| Policy hashes refreshed before final docs/source | Make hashes the final policy step or later edits will invalidate the lane. |
| Existing `.planning/config.json` dirty state overwritten | Preserve it; it predates this mapping task and is outside Phase 109 source scope. |

## No Exact Analog Found

| Target | Missing Exact Precedent | Planner Guidance |
|---|---|---|
| `layout_common.mbt` full OpenType offset-base ledger | Existing font parsers use several local bases but do not implement the full Script/LangSys/Feature/Lookup/Coverage/ClassDef ledger. | Use the locked ledger in `109-RESEARCH.md`; reuse only checked window/arithmetic mechanics. |
| `layout_model.mbt` fully owned GSUB/GPOS normalized profile | Existing `cmap` and `kern` compact facts retain source views; CFF owns some arrays but also source descriptors. | Follow the normative coefficients/data shapes in research and the CFF exact ledger, with stricter no-view ownership. |
| Deferred Capability across all selected occurrences | Existing code often returns Capability immediately after a profile classification. | Implement the Phase 109 local deferred-capability accumulator exactly; only Capability is deferred. |
| `FontLayoutProfile` sharing scope lifetime while exposing no operations | `FontShapeScope` supplies the lifetime precedent, but no second abstract value currently aliases it. | Keep construction private, share active/revision authority, add no public accessor, and prove closure white-box. |
| Full GSUB 1/4/7, GPOS 2/9, GDEF 1.0 admission | No current layout parser exists. | Use official layouts already distilled in `109-RESEARCH.md`; do not infer field bases from unrelated CFF/cmap formats. |

## Metadata

**Graph search:** codebase-memory MCP project `moonbit-foundation`; no current
MoonBit symbol/call results for the requested domains  
**Fallback scope:** `modules/mb-core`, `modules/mb-font`, `modules/mb-text`,
`policy/foundation.json`, `scripts/quality/Assert-Policy.ps1`, quality-lane
entry points, module READMEs/changelogs, RFC 0004/0005  
**Canonical targets:** 29  
**Proposal-only names resolved:** 3  
**Pattern extraction date:** 2026-07-30

