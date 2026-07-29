# Phase 108: Public Contract and Transaction Skeleton - Pattern Map

**Mapped:** 2026-07-30
**Files analyzed:** 29 likely new/modified files
**Analogs found:** 27 / 29 (2 have only structural, not semantic, analogs)
**UI applicability:** none; `108-UI-SPEC.md` forbids UI/frontend/styling/screenshot work

## Discovery Note

The repository requires codebase-memory MCP graph discovery before source search.
The graph was queried first for `ResourceCharge`, `BudgetScope`, `GlyphId`,
`FontLimits`, and `horizontal_metrics`; every symbol query returned zero results.
`get_architecture` reported only `Section`, `Variable`, `File`, `Module`, and
`Folder` nodes from an older repository state, with no MoonBit
function/method/call-edge nodes and no current `mb-font` source tree. Exact
patterns therefore come from the live orchestrator worktree source, using
targeted source reads after the graph proved insufficient.

## File Classification

| New/Modified File | Likely Symbols / Responsibility | Role | Data Flow | Closest Analog | Match |
|---|---|---|---|---|---|
| `modules/mb-core/budget/budget.mbt` | `ResourceCharge::checked_add`; private per-dimension overflow rebinding | utility/model | transform | same file: `Budget::preflight`/`charge` | exact |
| `modules/mb-core/budget/budget_test.mbt` | public composition, exact-fit, ancestor atomicity tests | test | batch | existing exact/one-short budget tests | exact |
| `modules/mb-core/budget/budget_wbtest.mbt` | per-dimension overflow and max-ceiling invariants | test | batch | existing private maximum/atomicity tests | exact |
| `modules/mb-core/checked/checked.mbt` | `checked_add_int64`, `checked_neg_int64`, `checked_uint64_to_int64` | utility | transform | `outline_checked_add` plus existing checked API | exact logic / role match |
| `modules/mb-core/checked/checked_test.mbt` | public signed-boundary and conversion tests | test | batch | unsigned checked-boundary tests | role match |
| `modules/mb-core/checked/checked_wbtest.mbt` | private constants/guard invariants | test | batch | existing private guard tests | role match |
| `modules/mb-core/README.mbt.md` | document new public checked/charge operations | config/docs | static | current module literate README | role match |
| `modules/mb-core/CHANGELOG.md` | record candidate-compatible public additions | config/docs | static | current changelog entries | role match |
| `modules/mb-font/font/font.mbt` | add private `GlyphId.owner`; preserve constructors/accessors/consumers | model/service | request-response | current `Font`, `GlyphId`, guarded queries | exact |
| `modules/mb-font/font/shape_transaction.mbt` | public-abstract `FontShapeScope`; `Font::with_shape_transaction[T]`; private active/revision/charge state | provider/service | request-response callback transaction | `BudgetScope::with_depth[T]` + guarded font publication | role/data-flow composite |
| `modules/mb-font/font/shape_transaction_test.mbt` | black-box scope, same-font alias, distinct-font, exact-fit/one-short tests | test | batch | `font_test.mbt` public contract tests | role match |
| `modules/mb-font/font/shape_transaction_wbtest.mbt` | escaped-scope invalidation, named probes, combined-charge atomicity | test | event-driven/batch | `font_wbtest.mbt` mutation callback tests | exact probe pattern |
| `modules/mb-font/README.mbt.md` | document owner-bound glyphs and opaque shaping scope without exposing internals | config/docs | static | existing retained-source/glyph sections | exact docs role |
| `modules/mb-font/CHANGELOG.md` | record behavior-compatible glyph strengthening and new seam | config/docs | static | current candidate changelog | exact docs role |
| `modules/mb-text/moon.mod.json` | module identity `tchivs/mb-text@0.1.0`, four targets, direct `mb-core` + `mb-font` deps | config | batch/build | `modules/mb-font/moon.mod.json`, `modules/mb-svg/moon.mod.json` | exact |
| `modules/mb-text/README.mbt.md` | literate public contract and no-layout-parser boundary | config/docs | static/check | other module `README.mbt.md` files | role match |
| `modules/mb-text/CHANGELOG.md` | `0.1.0 candidate` scope and explicit deferrals | config/docs | static | `modules/mb-font/CHANGELOG.md` | exact |
| `modules/mb-text/text/moon.pkg` | imports font/budget/checked/error; four targets | config | batch/build | `modules/mb-font/font/moon.pkg` | exact |
| `modules/mb-text/text/tags.mbt` | `ScriptTag`, `LanguageTag`, checked four-byte construction | model | transform | `FontLimits` private validated value | structural only |
| `modules/mb-text/text/options.mbt` | `LanguageChoice`, `Direction`, `FeaturePolicy`, `ShapingOptions` | model | transform | `FontFaceProfile` closed enum + private values | role match |
| `modules/mb-text/text/limits.mbt` | `ShapeLimits` private fields, nonzero constructor, named accessors | model/config | transform | `modules/mb-font/font/limits.mbt` | exact |
| `modules/mb-text/text/run.mbt` | `PositionedGlyph`, `ShapedRun`, `len`, `glyph_at`, metadata accessors | model | transform/indexed access | `FontCollection::face_profile` | exact access / role match |
| `modules/mb-text/text/shape.mbt` | top-level `shape`; scalar snapshot; empty transaction; nonempty fail-closed; private projection/staging helpers | service/controller | request-response/transform | guarded Font/collection transactions | structural only |
| `modules/mb-text/text/contract_test.mbt` | black-box public scalar/tag/limit/empty/run/same-font tests | test | batch | `font_test.mbt`, `budget_test.mbt` | role match |
| `modules/mb-text/text/contract_wbtest.mbt` | private generated logical facts, RTL/cluster/precedence/mutation matrices | test | event-driven/batch | `generated_fonts_wbtest.mbt` + font mutation probes | role match |
| `moon.work` | add only `./modules/mb-text` as a workspace member | config | batch/build | existing ordered member list | exact |
| `policy/foundation.json` | module/package inventory, deps, publication files, semantic interface, targets | config | batch/governance | existing `mb-font` policy entry | exact |
| `scripts/quality/Assert-Policy.ps1` | include mb-text in expected module/path/workspace/interface assertions | utility/config | batch | current hard-coded module policy checks | exact |
| `scripts/quality/Invoke-MoonQuality.ps1` | include mb-text in independent fmt/check/test/doc/info/package and README checks | utility/config | batch | current `$modules`/four-target loops | exact |

`modules/mb-text/text/contract_wbtest.mbt` may be split into a separate
`generated_contract_wbtest.mbt` only if the generated fixture table becomes too
large. If split, add that exact filename to `policy/foundation.json`
`test_sources` and `publication_files`; do not create an untracked test-only
package or expose the fixture seam publicly.

## Pattern Assignments

### 1. `modules/mb-core/budget/budget.mbt` — checked immutable charge composition

**Analog:** the existing opaque `ResourceCharge` and the split
preflight/commit implementation in the same file.

**Private representation pattern** (`modules/mb-core/budget/budget.mbt:80`):

```moonbit
/// A complete pre-work charge. All fields are validated before any consumable
/// counter changes.
pub struct ResourceCharge {
  priv bytes_value : UInt64
  priv allocations_value : UInt64
  priv allocation_size_value : UInt64
  priv width_value : UInt64
  priv height_value : UInt64
  priv pixels_value : UInt64
  priv work_value : UInt64
}
```

Keep composition inside this package so no field accessor or mutable setter is
needed. Add:

```moonbit
pub fn ResourceCharge::checked_add(
  self : ResourceCharge,
  other : ResourceCharge,
) -> Result[ResourceCharge, @error.CoreError]
```

Composition is locked as:

| Dimension | Operation |
|---|---|
| `bytes`, `allocations`, `pixels`, `work` | checked `UInt64` addition |
| `allocation_size`, `width`, `height` | maximum, because these are per-operation ceilings |

**Why maxima are required** (`modules/mb-core/budget/budget.mbt:185`):

```moonbit
if @checked.checked_sub(self.bytes_remaining, charge.bytes_value) is Err(_) {
  return Err(budget_exceeded("budget_charge", "bytes", ...))
}
if charge.allocation_size_value > self.allocation_size_limit {
  return Err(budget_exceeded("budget_charge", "allocation_size", ...))
}
```

Consumables are subtracted; allocation size and dimensions are compared as
ceilings. Adding ceiling dimensions would overcharge and conflict with current
budget semantics.

**Atomic hierarchy pattern** (`modules/mb-core/budget/budget.mbt:314`):

```moonbit
pub fn Budget::preflight(
  self : Budget,
  charge : ResourceCharge,
) -> Result[Unit, @error.CoreError] {
  for window in self.windows {
    match window.preflight_charge(charge) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
  }
  Ok(())
}

pub fn Budget::charge(
  self : Budget,
  charge : ResourceCharge,
) -> Result[Unit, @error.CoreError] {
  match self.preflight(charge) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  for window in self.windows {
    window.commit_charge(charge)
  }
  Ok(())
}
```

`checked_add` must return a fresh value and never charge. On additive overflow,
rebind to `Resource` / `ArithmeticOverflow`, operation
`resource-charge-add`, and the exact dimension (`bytes`, `allocations`,
`pixels`, or `work`) as context. Do not leak the generic
`checked_add` operation/category unchanged.

**Tests to copy** (`modules/mb-core/budget/budget_test.mbt:16`,
`:100`):

```moonbit
test "exact remaining charge succeeds and the next unit fails unchanged" {
  let budget = @budget.Budget::new(generous_limits())
  // exact succeeds; next unit fails; remaining stays unchanged
}

test "preflight checks every hierarchy window without consuming counters" {
  let parent_before = parent.remaining()
  let child_before = child.remaining()
  child.preflight(charge).unwrap()
  inspect(parent.remaining().bytes() == parent_before.bytes(), content="true")
  inspect(child.remaining().bytes() == child_before.bytes(), content="true")
}
```

Add public tests for all seven result dimensions and private tests that make
each additive dimension overflow independently. Verify max-ceiling behavior by
charging the composed value against a budget with an exact maximum, not by
adding public `ResourceCharge` accessors.

---

### 2. `modules/mb-core/checked/checked.mbt` — shared checked `Int64` helpers

**Closest exact algorithm:** `modules/mb-font/font/outline.mbt:105`.

```moonbit
fn outline_checked_add(
  left : Int64,
  right : Int64,
) -> Result[Int64, @error.CoreError] {
  let max = 9223372036854775807L
  let min = -9223372036854775807L - 1L
  if (right > 0L && left > max - right) || (right < 0L && left < min - right) {
    Err(font_outline_data_error("font-outline-arithmetic"))
  } else {
    Ok(left + right)
  }
}
```

Promote the guard logic, not the font-specific `Data` error. The public helper
set is:

```moonbit
pub fn checked_add_int64(lhs : Int64, rhs : Int64)
  -> Result[Int64, @error.CoreError]

pub fn checked_neg_int64(value : Int64)
  -> Result[Int64, @error.CoreError]

pub fn checked_uint64_to_int64(value : UInt64)
  -> Result[Int64, @error.CoreError]
```

**Negation edge pattern** (`modules/mb-font/font/outline.mbt:150`):

```moonbit
let min = -9223372036854775807L - 1L
if right == min {
  // cannot form -right
} else {
  outline_checked_add(left, -right)
}
```

`checked_neg_int64` rejects only `Int64::MIN`. Conversion must first prove
`value <= 9223372036854775807UL`; a later
`reinterpret_as_int64` is acceptable only after that numeric guard.
`reinterpret_as_int64` itself is never the range check.

**Existing public error style** (`modules/mb-core/checked/checked.mbt:13`):

```moonbit
fn arithmetic_error(
  code : @error.ErrorCode,
  operation : String,
  requested : UInt64,
  limit : UInt64,
) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::InvalidInput,
    code,
    operation~,
    requested~,
    limit~,
  )
}
```

Keep generic checked helpers in this style, then let `mb-text` rebind errors to
its stable operation/context at the shaping boundary.

**Boundary-test style** (`modules/mb-font/font/font_wbtest.mbt:148`,
`modules/mb-core/checked/checked_test.mbt:22`):

```moonbit
let overflow = outline_checked_add(9223372036854775807L, 1L).unwrap_err()
inspect(overflow.code() == @error.ErrorCode::InvalidEncoding, content="true")

match @checked.checked_add(18446744073709551615UL, 1UL) {
  Err(error) =>
    inspect(error.code() == @error.ErrorCode::ArithmeticOverflow, content="true")
  Ok(_) => fail("addition overflow must fail")
}
```

Cover `MAX + 0`, `MAX + 1`, `MIN + 0`, `MIN + (-1)`, `-MIN`,
`UInt64(Int64::MAX)`, and one-over. Keep private constant/guard assertions in
`checked_wbtest.mbt`; public behavior belongs in `checked_test.mbt`.

---

### 3. `modules/mb-font/font/font.mbt` — owner-bound `GlyphId` without public API drift

**Current representation and compatibility surface**
(`modules/mb-font/font/font.mbt:58`, `:585`, `:620`, `:818`):

```moonbit
pub struct GlyphId {
  priv value_value : UInt64
}

pub fn Font::glyph_for_scalar(
  self : Font,
  scalar : Int,
) -> Result[GlyphId, @error.CoreError]

pub fn Font::glyph_id(
  self : Font,
  value : UInt64,
) -> Result[GlyphId, @error.CoreError]

pub fn GlyphId::value(self : GlyphId) -> UInt64 {
  self.value_value
}
```

The v0.34-compatible public behavior is represented by the policy allowlist at
`policy/foundation.json:2309-2320` and `:2384-2386`. Preserve every existing
signature and `GlyphId::value`; add only a private owner:

```moonbit
pub struct GlyphId {
  priv owner : Font
  priv value_value : UInt64
}
```

Every construction site (`glyph_id`, `glyph_for_scalar`, and any private
fixture constructor) must set `owner: self`. Every consumer
(`horizontal_metrics`, both operands of `kerning`, and `outline`) must call one
private owner validator before numeric range checks or table access.

Use physical object identity so a copied alias of the same `Font` is accepted,
while a separately opened `Font` with the same bytes and glyph count is
rejected. There is no global font-ID registry.

**Current gap** (`modules/mb-font/font/font.mbt:648`):

```moonbit
match self.require_revision("font-query") {
  Err(error) => return Err(error)
  Ok(_) => ()
}
let num_glyphs = self.num_glyphs()
if glyph.value_value >= num_glyphs {
  return Err(font_glyph_id_error("font-horizontal-metrics", ...))
}
```

Insert the owner check after the entry revision guard and before
`num_glyphs`/table work. Owner mismatch is
`InvalidInput` / `InvalidRange`, operation rebound to the consuming method, and
context `font-glyph-owner`. Do not reuse `font-glyph-id-range`; same-range
foreign glyphs must be distinguishable.

**Regression test shape:** existing tests at
`modules/mb-font/font/font_test.mbt:4224` and `:3260` only reject a foreign
numeric ID because it exceeds the receiving font's count. Add the missing
same-range case:

```moonbit
let font_a = open_same_shape_font()
let alias_a = font_a
let font_b = open_same_shape_font()
let glyph_a = font_a.glyph_id(0UL).unwrap()

inspect(alias_a.horizontal_metrics(glyph_a) is Ok(_), content="true")
let error = font_b.horizontal_metrics(glyph_a).unwrap_err()
inspect(error.context() == Some("font-glyph-owner"), content="true")
```

Repeat owner rejection for both `kerning` operands and `outline`, asserting no
budget delta for the latter.

---

### 4. `modules/mb-font/font/shape_transaction.mbt` — opaque callback-scoped authority

This file has no single semantic analog. Compose two established patterns:
`BudgetScope::with_depth[T]` for scoped invalidation and the collection/font
publication path for final guard + one charge.

**Generic callback/defer pattern**
(`modules/mb-core/budget/budget.mbt:405`, `:448`):

```moonbit
pub struct BudgetScope {
  priv budget_value : Budget
  priv mut active : Bool
}

pub fn[T] with_depth(
  budget : Budget,
  body : (BudgetScope) -> Result[T, @error.CoreError],
) -> Result[T, @error.CoreError] {
  match budget.enter_depth() {
    Err(error) => Err(error)
    Ok(scope) => {
      defer scope.leave()
      body(scope)
    }
  }
}
```

**Final publication pattern** (`modules/mb-font/font/font.mbt:367`):

```moonbit
match budget.preflight(admission.charge) {
  Err(error) => return Err(error)
  Ok(_) => ()
}
before_final_guard()
if source.mutation_revision() != opening_revision {
  return Err(font_collection_revision_error("font-collection-open-face"))
}
match budget.charge(admission.charge) {
  Err(error) => return Err(error)
  Ok(_) => ()
}
Ok(font_from_admitted_facts(...))
```

Implement a public-abstract type (public name, private fields) because a private
type cannot occur in a cross-module public signature:

```moonbit
pub fn[T] Font::with_shape_transaction(
  self : Font,
  budget : @budget.Budget,
  body : (FontShapeScope) ->
    Result[(T, @budget.ResourceCharge), @error.CoreError],
) -> Result[T, @error.CoreError]
```

The first implementation task must compile-proof the exact tuple/generic
syntax with the pinned toolchain. If the tuple spelling is rejected, replace
only the private callback carrier; do not widen lifetime or add public
`prepare`/`commit`.

Required private state and order:

1. Shared private `active` state, `Font`, opening revision authority, and
   immutable font-side charge facts.
2. Every scope method checks active state first, then font revision.
3. Entry revision guard occurs only after `mb-text` validates and snapshots all
   public input.
4. Callback returns staged `T` plus text-side charge; it never charges.
5. Harness uses `ResourceCharge::checked_add`, enforces semantic limits and
   `Budget::preflight`, invokes `before_final_guard`, checks revision, calls
   `Budget::charge` once, closes the scope, and returns `T`.
6. No fallible callback/publication work after the sole charge.

An escaped scope may exist as a value but every later operation returns
`State`, operation tied to the scope method, context
`font-shape-scope-closed`. Expose no constructor, source bytes, table offsets,
raw tables, layout profile, probe bundle, charge mutator, or commit method.
`mb-font` must not import `mb-text`.

**Mutation test pattern** (`modules/mb-font/font/font_wbtest.mbt:836`):

```moonbit
let result = font.glyph_for_scalar_after_lookup(0x0041, fn() {
  callback_count = callback_count + 1
  font_wb_mutate_one_byte(owner, 0UL)
})
match result {
  Ok(_) => fail("post-read revision drift must not publish a GlyphId")
  Err(error) => font_wb_assert_revision_drift(error)
}
```

Use private named callbacks at post-structure, post-capability,
post-complete-staging, and before-final-guard seams. Each callback is followed
immediately by a revision check. The public wrapper always supplies no-op
callbacks.

---

### 5. `modules/mb-text/text/tags.mbt`, `options.mbt`, and `limits.mbt` — closed validated values

**Private-field validation pattern:** `modules/mb-font/font/limits.mbt:7`.

```moonbit
pub struct FontLimits {
  priv max_source_bytes_value : UInt64
  // ...
  priv max_work_value : UInt64
}

pub fn FontLimits::new(...) -> Result[FontLimits, @error.CoreError] {
  if max_source_bytes == 0UL {
    return Err(invalid_font_limit("max-source-bytes"))
  }
  // validate every field before constructing
  Ok({ ... })
}
```

**Closed-enum pattern:** `modules/mb-font/font/collection.mbt:1`.

```moonbit
pub(all) enum FontFaceProfile {
  StaticGlyf
  Cff
  Cff2
  Variable
  OtherUnsupported
} derive(Eq)
```

Apply as follows:

- `ScriptTag` and `LanguageTag` are public structs with private four-byte
  representation and checked constructors. Require exactly four bytes, each
  in `0x20..0x7E`. Do not retain a mutable caller array/view.
- `LanguageTag` rejects reserved `dflt` and `DFLT`; default is represented
  only by `LanguageChoice::Default`.
- `LanguageChoice` is
  `Default | Exact(LanguageTag)` and `Direction` is
  `LeftToRight | RightToLeft`; both are closed `pub(all)` enums.
- `FeaturePolicy` privately stores only caller choices for `liga` and `kern`.
  There is no boolean for required LangSys behavior or supported `rlig`.
- `ShapingOptions` privately composes script, language, direction, and feature
  policy, with named value accessors and no mutable setters/default inference.
- `ShapeLimits` follows `FontLimits`: validate every required ceiling as
  nonzero, return stable `InvalidInput`/`InvalidRange` with operation
  `text-shape-limits-new` and per-field context, then expose named value
  accessors.

Freeze `ShapeLimits` groups now: input scalars; output glyphs; selected
GSUB/GPOS/GDEF/legacy-kern bytes; script/LangSys/feature/reference counts;
lookup/subtable/application/probe counts; coverage/class/range/cell counts;
pair/ligature/component/substitution counts; positioning probes/adjustments;
normalized/staging bytes; private/output allocation counts and maximum
allocation size; total work; maximum absolute advance and x/y offset.

These are ceilings only. Do not add parsers, table models, or execution code
for those groups in Phase 108.

**Test style** (`modules/mb-font/font/font_test.mbt:19`):

```moonbit
let limits = FontLimits::new(...).unwrap()
inspect(limits.max_source_bytes(), content="1024")
// assert every accessor
```

Use one preservation test for every field and table-driven zero rejection for
every required field. Test malformed tags, reserved language tags, and all
closed enum choices in `contract_test.mbt`.

---

### 6. `modules/mb-text/text/run.mbt` — immutable copied storage and indexed value access

**Closest indexed-access analog:**
`modules/mb-font/font/collection.mbt:19`, `:40`, `:117`.

```moonbit
pub struct FontCollection {
  priv source : @bytes.ByteView
  priv opening_revision : UInt64
  priv faces : Array[CollectionFaceFacts]
  // ...
}

fn font_collection_index_error(
  operation : String,
  requested : UInt64,
  limit : UInt64,
) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::InvalidInput,
    @error.ErrorCode::InvalidRange,
    operation~,
    requested~,
    limit~,
    context="font-collection-face-index",
  )
}

pub fn FontCollection::face_profile(
  self : FontCollection,
  index : UInt64,
) -> Result[FontFaceProfile, @error.CoreError] {
  let count = self.faces.length().to_uint64()
  if index >= count {
    return Err(font_collection_index_error("font-collection-query", index, count))
  }
  let narrowed = match @checked.checked_narrow_int(index) {
    Ok(value) => value
    Err(_) => return Err(font_collection_index_error(...))
  }
  Ok(self.faces[narrowed].profile)
}
```

`PositionedGlyph` privately stores same-font `@font.GlyphId`, `UInt64` scalar
cluster, and signed `Int64` advance/x-offset/y-offset. `ShapedRun` privately
stores a copied `Array[PositionedGlyph]`, units-per-em, explicit direction, and
checked signed total advance.

Expose only named value accessors, `len`, and:

```moonbit
pub fn ShapedRun::glyph_at(
  self : ShapedRun,
  index : UInt64,
) -> Result[PositionedGlyph, @error.CoreError]
```

Follow the checked bounds/narrowing pattern with operation
`text-shaped-run-glyph-at` and context `run-index`. Return the record value,
never the backing array, `ArrayView`, mutable iterator/lease, table fact,
lookup index, or raw layout bytes. Private construction copies the staged
array before publication.

---

### 7. `modules/mb-text/text/shape.mbt` — closed call and one transaction

There is no existing text shaper to copy. Use the public top-level style
required by MoonBit ownership and the font transaction sequence:

```moonbit
pub fn shape(
  font : @font.Font,
  scalars : Array[Int],
  options : ShapingOptions,
  limits : ShapeLimits,
  budget : @budget.Budget,
) -> Result[ShapedRun, @error.CoreError]
```

The implementation order is part of the public contract:

1. Validate every scalar (`0..0x10FFFF`, excluding surrogates), tag, choice,
   and limit; continue scanning the complete scalar array before font access.
2. Copy the validated scalar array into request-owned storage.
3. Enter `Font::with_shape_transaction`; entry drift returns `State`.
4. Selected structural validation returns `Data`.
5. Guard immediately after the structure probe.
6. Selected semantic support returns `Capability`.
7. Guard immediately after the capability probe.
8. Stage logical records and checked charge facts.
9. Guard after complete private staging.
10. Enforce semantic ceilings and preflight the combined charge; failures are
    `Resource`.
11. Invoke the final probe and perform the final revision guard (`State`).
12. Charge once and publish with no later fallible work.

For valid empty input, skip all layout selection/parsing but still read guarded
stable `units_per_em`, validate everything, enter the transaction, combine the
font-side `none()` charge with exactly:

```moonbit
@budget.ResourceCharge::new(
  bytes=0UL,
  allocations=0UL,
  allocation_size=0UL,
  width=0UL,
  height=0UL,
  pixels=0UL,
  work=1UL,
)
```

An exact `work=1` budget succeeds and reaches zero; `work=0` fails unchanged.

For nonempty real-font input in Phase 108, fail closed with `Capability` after
the required preceding validation/revision/structural stages. Do not report
`cmap + metrics` as successful shaping because required feature/`rlig`
authority is not yet available.

Private generated logical facts may exercise projection:

- stage in logical scalar order for both directions;
- apply checked base advance + admitted adjustment before projection;
- LTR publishes logical order with signed advances unchanged;
- RTL negates advances using `checked_neg_int64`, then reverses only the final
  positioned records;
- never negate x/y offsets or rewrite clusters;
- accumulate `total_advance` with `checked_add_int64`;
- a ligature cluster is the minimum consumed scalar index and survives final
  reversal unchanged.

Rebind generic arithmetic errors to stable text operation/context strings such
as operation `text-shape-project` and contexts `advance`, `x-offset`,
`y-offset`, and `total-advance`.

---

### 8. Public and white-box contract tests

Use `_test.mbt` for public API only and `_wbtest.mbt` for private stage/probe
fixtures.

**Public exact-fit/no-mutation pattern**
(`modules/mb-core/budget/budget_test.mbt:37`):

```moonbit
match budget.charge(rejected) {
  Err(error) => {
    inspect(error.code() == @error.ErrorCode::BudgetExceeded, content="true")
    inspect(error.context() == Some("work"), content="true")
  }
  Ok(_) => fail("work overflow must reject the complete charge")
}
let remaining = budget.remaining()
inspect(remaining.bytes(), content="100")
inspect(remaining.work(), content="1000")
```

**Generated-table pattern**
(`modules/mb-image/ops/reference_vectors_wbtest.mbt:1`, `:144`):

```moonbit
// Generated by scripts/fixtures/Generate-ImageVectors.ps1. Do not edit.

fn generated_ops_case_ids() -> Array[String] { ... }

test "generated operation vector tables are complete" {
  inspect(generated_ops_case_ids().length(), content="14")
  inspect(generated_orientation_vectors().length(), content="8")
}
```

Phase 108 generated facts must be repository-owned, deterministic, and
table-only; they must not embed or parse GSUB/GPOS/GDEF/`kern` bytes. At
minimum, freeze:

- LTR records A/B: advances `550, 500`, offsets `(+20,-10),(-30,+15)`,
  clusters `0,1`, total `1050`;
- RTL publication B/A: advances `-500,-550`, identical offsets/clusters,
  total `-1050`;
- ligature consuming indices `1,2,3` has cluster `1` before and after RTL
  reversal;
- immutable `glyph_at` exact first/last and one-past error;
- caller scalar mutation after validation cannot affect the retained snapshot.

White-box precedence matrix:

| Simultaneous faults | Required winner | Budget delta |
|---|---|---|
| invalid scalar + already drifted font | `InvalidInput` | none |
| valid caller + already drifted font | `State` | none |
| malformed selected structure + unsupported feature + short budget | `Data` | none |
| valid structure + unsupported feature + short budget | `Capability` | none |
| valid semantic stage + exceeded limit/short budget | `Resource` | none |
| drift at any named probe + later fault | immediate `State` | none |
| exact budget + drift before final guard | `State` | none |
| exact valid generated request | success | one combined decrement in caller and every ancestor |

---

### 9. Module, package, workspace, and governance files

**Module manifest analog** (`modules/mb-font/moon.mod.json:1`):

```json
{
  "name": "tchivs/mb-font",
  "version": "0.1.0",
  "license": "Apache-2.0",
  "repository": "https://github.com/tchivs/moonbit-foundation",
  "readme": "README.mbt.md",
  "preferred-target": "native",
  "supported-targets": "+js+wasm+wasm-gc+native",
  "deps": {
    "tchivs/mb-core": "0.1.0"
  }
}
```

Create `mb-text` with the same metadata shape and direct pinned dependencies:

```json
"deps": {
  "tchivs/mb-core": "0.1.0",
  "tchivs/mb-font": "0.1.0"
}
```

Do not add path dependencies or migrate to `moon.mod`.

**Package import analog** (`modules/mb-font/font/moon.pkg:1`):

```moonbit
import {
  "tchivs/mb-core/budget",
  "tchivs/mb-core/bytes",
  "tchivs/mb-core/checked",
  "tchivs/mb-core/error",
  "tchivs/mb-core/math",
}

supported_targets = "+js+wasm+wasm-gc+native"
```

`mb-text/text/moon.pkg` should import only
`tchivs/mb-font/font`, `tchivs/mb-core/budget`,
`tchivs/mb-core/checked`, and `tchivs/mb-core/error` unless a concrete
implementation requires another already-approved foundational package. It
must not import bytes, host, canvas, image, UI, or native FFI packages.

**Workspace analog** (`moon.work:1`):

```moonbit
members = [
  "./modules/mb-core",
  // ...
  "./modules/mb-font",
  // examples follow
]
```

Add `./modules/mb-text` adjacent to `mb-font`; do not reorder unrelated members.

**Policy analog** (`policy/foundation.json:2181`):

```json
{
  "name": "tchivs/mb-font",
  "path": "modules/mb-font",
  "version": "0.1.0",
  "stability": "candidate",
  "preferred_target": "native",
  "supported_targets": ["js", "wasm", "wasm-gc", "native"],
  "direct_dependencies": ["tchivs/mb-core"],
  "publication_files": [ ... ],
  "public_packages": [ ... ]
}
```

Add a complete `mb-text` entry, exact publication/test source inventories, one
public `text` package, allowed imports, and the generated semantic interface.
Add dependency edges `mb-text -> mb-font` and `mb-text -> mb-core`; keep
`mb-font -> mb-core` and forbid reverse edges.

Update the existing `mb-core` semantic interface for
`ResourceCharge::checked_add` and the three signed checked helpers. Update the
`mb-font` semantic interface by addition only: keep the existing signatures at
`policy/foundation.json:2309-2320` and `:2384-2386` byte-for-byte while adding
the public-abstract scope and generic continuation surface.

**Hard-coded policy enumeration**
(`scripts/quality/Assert-Policy.ps1:714`):

```powershell
$expectedModules = @(
  'tchivs/mb-core',
  'tchivs/mb-color',
  'tchivs/mb-image',
  'tchivs/mb-canvas',
  'tchivs/mb-font'
)
$expectedPaths = @(
  'modules/mb-core',
  'modules/mb-color',
  'modules/mb-image',
  'modules/mb-canvas',
  'modules/mb-font'
)
```

Add text to both lists and to the exact `moon.work` expected set. Generic
manifest/package checks already enforce version, targets, deps, allowed
imports, `moon.pkg`, interface allowlist, and publication inventory at
`Assert-Policy.ps1:802-845`; add text-specific exact package/import/interface
assertions only where generic checks cannot express the closed surface.

**Required-lane enumeration and four-target loop**
(`scripts/quality/Invoke-MoonQuality.ps1:1003`, `:1078`):

```powershell
$requiredTargets = @('js', 'wasm', 'wasm-gc', 'native')
$modules = @('mb-core', 'mb-color', 'mb-image')

foreach ($target in $requiredTargets) {
  Invoke-MoonCommand ... @('check', '--target', $target, '--deny-warn', '--frozen')
  Invoke-MoonCommand ... @('test', '--target', $target, '--frozen')
  foreach ($module in $modules) {
    Invoke-MoonCommand ... @('-C', "modules/$module", 'check', '--target', $target, '--deny-warn', '--frozen')
    Invoke-MoonCommand ... @('-C', "modules/$module", 'test', '--target', $target, '--frozen')
  }
}
```

Add `mb-text` to the independently checked module list and add its literate
README check. Preserve explicit per-target execution for diagnostic evidence.
The existing `.github/workflows/quality.yml` already invokes the Required lane
and does not need a new UI or shaping-specific job unless policy enforcement
later demonstrates a missing CI entry point.

## Shared Patterns

### Error construction and operation rebinding

**Source:** `modules/mb-font/font/font.mbt:76`, `:85`
**Apply to:** checked composition, font scope, tags/options/limits, run access,
and shape staging.

```moonbit
fn font_revision_error(operation : String) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::State,
    @error.ErrorCode::InvalidRange,
    operation~,
    context="font-source-revision-drift",
  )
}

fn font_rebind_operation(
  error : @error.CoreError,
  operation : String,
) -> @error.CoreError {
  @error.CoreError::new(
    error.category(),
    error.code(),
    operation~,
    requested?=error.requested(),
    // preserve every optional diagnostic field
    context?=error.context(),
  )
}
```

Use stable category/code/operation/context tuples. Rebinding must preserve all
optional diagnostic fields. Do not create an `mb-text`-specific error type.

### Retained-source revision guard

**Source:** `modules/mb-font/font/font.mbt:105`
**Apply to:** every `FontShapeScope` operation, entry, named mutation seams,
and immediately before the sole commit.

```moonbit
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

Mutation followed by restoration still fails because the revision, not byte
equality, is authoritative.

### Immutable snapshots

**Source:** `modules/mb-core/budget/budget.mbt:399`; current repository array
copy usage.

```moonbit
let windows = self.windows.copy()
windows.push(BudgetWindow::new(limits))
```

Validate the complete scalar array, then call `.copy()` before any font work.
Copy staged positioned records again at private run publication. Never use
`ArrayView` as an immutability boundary.

### Preflight, final guard, one commit

**Sources:** `modules/mb-core/budget/budget.mbt:320-347`,
`modules/mb-font/font/font.mbt:367-388`
**Apply to:** the only shaping transaction harness.

Preflight every caller/ancestor with the fully composed charge, run the last
mutation probe, guard source revision, call `Budget::charge` once, then publish.
There must be no charge inside the `mb-text` continuation and no fallible work
after commit.

### Public versus private tests

- `*_test.mbt`: only public API, including interface-compatible glyph behavior,
  empty shaping, immutable access, and error tuples.
- `*_wbtest.mbt`: private scope escape, mutation probes, generated logical
  facts, precedence cross-products, arithmetic implementation invariants.
- Generated fixture tables stay deterministic and test-only; production code
  must not read test sources or embed layout-table specimens.

## Integration and Anti-Pattern Constraints

1. Dependency direction remains `mb-text -> mb-font -> mb-core`, with the
   explicit direct `mb-text -> mb-core` edge. No `mb-font -> mb-text`.
2. Preserve the existing `Font`, `GlyphId`, `GlyphId::value`,
   `glyph_for_scalar`, `glyph_id`, `horizontal_metrics`, `kerning`, and
   `outline` public signatures; same-font ownership is a private strengthening.
3. Do not expose a prepared transaction, public commit, persistent layout
   profile/cache, source bytes, tables, offsets, lookups, probes, or raw arrays.
4. Do not charge font and text stages separately. Compose immutable charges,
   preflight once, final-guard, and commit once.
5. Do not reverse scalar input for RTL. Reverse final positioned records only;
   negate advances only; keep offsets and clusters unchanged.
6. Do not use bare `Int64 +`, bare negation of admitted values, or
   `reinterpret_as_int64` without an explicit numeric range guard.
7. Do not allow a numeric glyph range check to stand in for font ownership.
8. Do not return early for empty input before option/limit validation, source
   guard, stable metadata read, exact fixed charge, and one commit.
9. Do not return successful nonempty real-font shaping before layout
   admission; fail closed with `Capability`.
10. Do not design or implement GSUB, GPOS, GDEF, or legacy `kern` selection,
    parsing, normalization, or execution in Phase 108. Counts in `ShapeLimits`
    are future ceilings, not permission to add format code.
11. Do not add normalization, bidi analysis, grapheme/caret semantics,
    fallback, variation coordinates, arbitrary feature tags/values/ranges,
    vertical text, pixels, screen-axis conversion, UI, FFI, I/O, or registry
    code.
12. Do not migrate manifests to `moon.mod`, add path dependencies, omit
    `--frozen`, or collapse four-target evidence to native-only execution.

## No Exact Analog Found

| File | Reason | Planner Direction |
|---|---|---|
| `modules/mb-text/text/tags.mbt` | Existing font code represents table tags internally as numeric constants; there is no checked public four-byte tag value. | Copy private-field/validated-constructor/error patterns from `FontLimits`, not raw internal tag constants. |
| `modules/mb-text/text/shape.mbt` | No existing cross-module text shaping contract or run projection exists. | Assemble only the verified scope, guard, charge, snapshot, and indexed-value patterns above; use `108-RESEARCH.md` for the locked stage machine and generated projection facts. |

There is intentionally no analog search or assignment for GSUB/GPOS parsing or
execution because those files and behaviors are out of Phase 108 scope.

## Verification Commands

Focused implementation feedback:

```powershell
moon -C modules/mb-core test budget --target native --frozen
moon -C modules/mb-core test checked --target native --frozen
moon -C modules/mb-font test font --target native --frozen
moon -C modules/mb-text check --target native --deny-warn --frozen
moon -C modules/mb-text test text --target native --frozen
```

Explicit four-target contract loop:

```powershell
foreach ($target in 'js', 'wasm', 'wasm-gc', 'native') {
  moon -C modules/mb-core check --target $target --deny-warn --frozen
  moon -C modules/mb-core test budget --target $target --frozen
  moon -C modules/mb-core test checked --target $target --frozen
  moon -C modules/mb-font check --target $target --deny-warn --frozen
  moon -C modules/mb-font test font --target $target --frozen
  moon -C modules/mb-text check --target $target --deny-warn --frozen
  moon -C modules/mb-text test text --target $target --frozen
}
```

Workspace/interface/governance gates:

```powershell
moon -C modules/mb-text info --target all --frozen
moon check --target all --deny-warn --frozen
moon test --target all --frozen
./scripts/quality.ps1 -Lane Required -EvidenceDirectory artifacts/release-qualification/phase108
./scripts/quality.ps1 -Lane FontQualification -EvidenceDirectory artifacts/release-qualification/phase108-font
```

`moon info` must show opaque structs, closed enums, named accessors, and the
single closed `shape` call—never raw arrays, table facts, probes, scope
constructors, or commit handles.

## Metadata

**Graph search:** codebase-memory MCP project `moonbit-foundation`; insufficient
for current MoonBit symbols (zero symbol hits, no function/call nodes)
**Fallback search scope:** `modules/mb-core`, `modules/mb-font`, module
manifests, `moon.work`, `policy/foundation.json`, quality scripts, generated and
public tests
**Strong analogs used:** 5 primary implementation families (`budget.mbt`,
`checked.mbt`/private outline arithmetic, `font.mbt`, `limits.mbt`,
`collection.mbt`) plus manifests/governance scripts
**Pattern extraction date:** 2026-07-30
