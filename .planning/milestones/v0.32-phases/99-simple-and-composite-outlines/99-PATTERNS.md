# Phase 99: Simple and Composite Outlines - Pattern Map

**Mapped:** 2026-07-27
**Files analyzed:** 16 new/modified files
**Analogs found:** 15 / 16
**Strong code analogs inspected:** 7

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `modules/mb-font/font/outline.mbt` | service / binary decoder / lowerer | file-I/O, transform, request-response | `modules/mb-font/font/kern.mbt` plus `modules/mb-core/math/path.mbt` | role + data-flow match |
| `modules/mb-font/font/font.mbt` | model / public facade | request-response | existing guarded `glyph_for_scalar_after_lookup` and `kerning_after_lookup` | exact |
| `modules/mb-font/font/metrics.mbt` | utility / retained binary index | file-I/O, request-response | existing `font_read_glyph_bounds` | exact |
| `modules/mb-font/font/tables.mbt` | model / table decoder | file-I/O, transform | existing `font_decode_maxp` | exact |
| `modules/mb-font/font/limits.mbt` | config / model | request-response | existing `FontLimits` fields, constructor, and accessors | exact |
| `modules/mb-font/font/cursor.mbt` | utility | file-I/O, transform | existing `read_u8` and `read_i16` | exact |
| `modules/mb-font/font/moon.pkg` | config | batch | existing package import/target block | exact |
| `modules/mb-font/font/font_test.mbt` | black-box test | batch, request-response | current glyph/kerning/metric and budget tests | exact |
| `modules/mb-font/font/font_wbtest.mbt` | white-box test | batch, transform, event-driven | current cursor, post-read mutation, and taxonomy tests | exact |
| `modules/mb-font/font/generated_fonts_wbtest.mbt` | test fixture utility | file-I/O, batch, transform | current table builders and checksum-correct SFNT assembler | exact |
| `modules/mb-font/font/pkg.generated.mbti` | generated interface | transform | current generated interface plus Phase 98 source surface | exact, but stale baseline |
| `policy/foundation.json` | config / policy | batch, transform | current `tchivs/mb-font` policy entry | exact |
| `scripts/quality/Assert-Policy.ps1` | policy test / config | batch, transform | current `Assert-FontDeferredCapabilitySurface` and `Assert-FontFoundationPolicy` | exact |
| `modules/mb-font/README.mbt.md` | documentation / executable example | request-response | current admission, query, and boundary sections | exact |
| `modules/mb-font/CHANGELOG.md` | documentation / release config | batch | current `0.1.0 candidate` entry | exact |
| `README.md` | bilingual documentation | batch | current English/Chinese `mb-font` status and responsibility rows | exact |

`cursor.mbt` is a planned modification only if the decoder factors a shared signed-byte reader; otherwise keep signed-byte interpretation private in `outline.mbt`. All other listed files are required by the locked public surface, limit-constructor migration, tests, generated interface, policy, or documentation gates.

## Pattern Assignments

### `modules/mb-font/font/outline.mbt` (service, file-I/O + transform + request-response)

**Primary analog:** `modules/mb-font/font/kern.mbt`

Use private compact facts and `Result[..., @error.CoreError]`, then stage declared work before attacker-controlled loops. Copy the local preflight/charge ordering from `kern.mbt:323-360`:

```moonbit
let subtable_count = prefix & 0xFFFFUL
if subtable_count > limits.max_kern_subtables() {
  return Err(
    font_limit_error(
      "max-kern-subtables",
      subtable_count,
      limits.max_kern_subtables(),
    ),
  )
}
let subtable_work = match @checked.checked_add(base_work, subtable_count) {
  Err(error) => return Err(error)
  Ok(value) => value
}
if subtable_work > limits.max_work() {
  return Err(font_limit_error("max-work", subtable_work, limits.max_work()))
}
match font_preflight_admission_work(
  budget,
  limits.max_work(),
  subtable_budget_work,
) {
  Err(error) => return Err(error)
  Ok(_) => ()
}
match font_charge_admission_work(budget, subtable_count) {
  Err(error) => return Err(error)
  Ok(_) => ()
}
```

For Phase 99, apply that ordering separately to contour endpoints, expanded points/flags, instruction bytes, component records, reachable descriptor records, scratch arrays, and the conservative output command bound. Query failure may leave already-attempted work charged; no temporary points or commands escape.

Copy checked envelope and strict-consumption mechanics from `kern.mbt:62-106`: compute each record end with checked arithmetic, compare it to the contained glyph view, and require the final cursor to equal the logical body end. The phase-specific padding rule is exact exhaustion or one zero byte that accounts for the next even `loca` offset; every other trailing payload is Data.

**Output analog:** `modules/mb-core/math/path.mbt:11-52` and `modules/mb-core/math/affine.mbt:17-28`

```moonbit
pub(all) enum PathCommand {
  MoveTo(Point2)
  LineTo(Point2)
  QuadTo(Point2, Point2)
  CubicTo(Point2, Point2, Point2)
  Close
}

pub fn Path2::new() -> Path2 {
  { commands: [] }
}

pub fn Path2::push(self : Path2, command : PathCommand) -> Unit {
  self.commands.push(command)
}

pub fn Point2::new(x : Double, y : Double) -> Point2 {
  { x_value: x, y_value: y }
}
```

Build one local `Path2`; local mutation through `push` is not publication. Convert private Q15 `Int64` values to `Double` only at `Point2::new`, then return the path only after the facade’s post-read guard.

Do not copy `Affine2::apply_to_path`: `affine.mbt:9-11` explicitly directs exact integer callers to checked arithmetic. Implement the research’s private signed-Q15 helpers and exact matrix order:

```moonbit
x_num = xscale_raw * x_q15 + scale10_raw * y_q15
y_num = scale01_raw * x_q15 + yscale_raw * y_q15
x_q15 = x_num / 16384L
y_q15 = y_num / 16384L
```

Each multiply, sum, midpoint, translation, and subtraction must detect overflow before evaluation and translate failure to an outline-specific Data error rather than leaking `@checked`’s InvalidInput taxonomy.

There is no exact local analog for the TrueType contour state machine or iterative tri-color composite graph. Take those algorithms from `99-RESEARCH.md`: preserve encoded real-point numbering separately from implied midpoint commands; classify the entire bounded reachable descriptor graph before returning Capability for deeper acyclic nesting; lower geometry only for a root whose direct children are simple/empty.

---

### `modules/mb-font/font/font.mbt` (public facade, request-response)

**Analog:** `font.mbt:250-280` and `font.mbt:354-401`

Copy the wrapper + private test seam + pre/post guard shape:

```moonbit
pub fn Font::kerning(
  self : Font,
  left : GlyphId,
  right : GlyphId,
) -> Result[Int, @error.CoreError] {
  self.kerning_after_lookup(left, right, fn() { () })
}

fn Font::kerning_after_lookup(
  self : Font,
  left : GlyphId,
  right : GlyphId,
  after_lookup : () -> Unit,
) -> Result[Int, @error.CoreError] {
  match self.require_revision("font-query") {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  // receiving-font validation, private lookup
  after_lookup()
  match self.require_revision("font-query") {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  Ok(adjustment)
}
```

For `Font::outline`, use an outline-specific operation string consistently, revalidate `glyph.value_value < self.metric_index.num_glyphs` before `glyf` access using `font_glyph_id_error` (`font.mbt:219-231`), pass the caller’s query `Budget` into the private decoder, invoke a private after-decode hook, then post-guard and publish exactly once. Empty paths use the same hook and second guard.

Add `priv limits : FontLimits` beside the retained index at `font.mbt:9-19`, assign the opening `limits` in the one atomic `Ok({...})` construction at `font.mbt:150-173`, and never store the caller’s admission or query budgets.

---

### `modules/mb-font/font/metrics.mbt` (retained index, file-I/O + request-response)

**Analog:** `metrics.mbt:360-419`

Factor the existing `loca` math and table containment into a reusable private `font_glyph_window`:

```moonbit
let start = index.loca_offsets[glyph_index]
let end = index.loca_offsets[next_glyph_index]
if start == end {
  return Ok(None)
}
let length = match @checked.checked_sub(end, start) {
  Err(error) => return Err(error)
  Ok(value) => value
}
let glyph_view = match index.glyf.view.subview(start, length) {
  Err(error) => return Err(error)
  Ok(value) => value
}
```

Return `None` for equal adjacent offsets and `Some(ByteView)` otherwise. Keep the existing common-header `< 10` validation in `font_read_glyph_bounds`, but make both metric bounds and the new outline decoder consume the same table-local view. Do not recompute SFNT root offsets.

The normalized index already owns the correct facts (`metrics.mbt:1-8`) and proves monotonic contained offsets at `metrics.mbt:90-155`; reuse them unchanged.

---

### `modules/mb-font/font/tables.mbt` (maxp model/decoder, file-I/O + transform)

**Analog:** existing `MaxpFacts` and `font_decode_maxp`

Expand the private struct at `tables.mbt:12-14` with the version-1 outline maxima, and decode them in the already exact 32-byte path at `tables.mbt:507-530`:

```moonbit
match font_table_exact_length(table, 32UL, "font-maxp") {
  Err(error) => return Err(error)
  Ok(_) => ()
}
let version = match read_u32(table.view, 0UL) {
  Err(error) => return Err(error)
  Ok(value) => value
}
let num_glyphs = match read_u16(table.view, 4UL) {
  Err(error) => return Err(error)
  Ok(value) => value
}
if version != 0x00010000UL || num_glyphs == 0UL {
  return Err(font_data_error("font-maxp", source_offset=table.offset))
}
```

Read `maxPoints`, `maxContours`, `maxCompositePoints`, `maxCompositeContours`, `maxSizeOfInstructions`, `maxComponentElements`, and `maxComponentDepth` from this same table. Do not create a second `maxp` read path. At query time compare actual glyph facts to these claims first (Data), then to retained `FontLimits` (Resource).

Keep the single admission/publication path at `tables.mbt:1792-1871`: `RequiredTableFacts.maxp` remains the one retained value passed to outline decoding.

---

### `modules/mb-font/font/limits.mbt` (config/model, request-response)

**Analog:** `limits.mbt:7-18`, `limits.mbt:34-88`, and `limits.mbt:90-138`

Add four private nonzero values:

- total expanded outline points;
- total outline contours;
- composite components / inspected descriptors;
- per-glyph instruction bytes.

Copy the constructor validation pattern exactly:

```moonbit
if max_kern_pairs == 0UL {
  return Err(invalid_font_limit("max-kern-pairs"))
}
// ...
Ok({
  max_kern_pairs_value: max_kern_pairs,
  max_work_value: max_work,
})
```

Add one public accessor per new ceiling, append named parameters to `FontLimits::new`, and preserve the stable `InvalidInput` / `InvalidRange` / `font-limits-new` error shape from `limits.mbt:20-30`. Update every explicit constructor call in the three test files, package README, policy interface, and independent selector in the same migration.

---

### `modules/mb-font/font/cursor.mbt` (binary utility, file-I/O + transform)

**Analog:** `cursor.mbt:19-44` and `cursor.mbt:70-84`

If shared `read_i8` is introduced, compose it from `read_u8` and apply the same two’s-complement shape as `read_i16`:

```moonbit
match read_u16(source, offset) {
  Err(error) => Err(error)
  Ok(value) =>
    if value >= 0x8000UL {
      Ok(value.to_int() - 0x10000)
    } else {
      Ok(value.to_int())
    }
}
```

Use an `0x80` / `0x100` threshold for a byte. Do not bypass `require_read_window`; exact-fit and one-short cases belong in `font_wbtest.mbt`.

---

### `modules/mb-font/font/moon.pkg` (package config)

**Analog:** `moon.pkg:1-10`

Add only the package-level math import:

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

MoonBit source files do not carry per-file imports. Keep the four-target string and sole module dependency unchanged.

---

### `modules/mb-font/font/font_test.mbt` (black-box test)

**Analog:** `font_test.mbt:1188-1223`, `font_test.mbt:1266-1292`, `font_test.mbt:1537-1651`, and `font_test.mbt:1968-2002`

Freeze public paths by command kind, order, and exact coordinates through `Path2::length/get`, including empty and degenerate glyphs. Reuse the receiving-font error oracle:

```moonbit
let error = result.unwrap_err()
inspect(error.category() == @error.ErrorCategory::InvalidInput, content="true")
inspect(error.code() == @error.ErrorCode::InvalidRange, content="true")
inspect(error.requested() == Some(3UL), content="true")
inspect(error.limit() == Some(2UL), content="true")
inspect(error.context() == Some("font-glyph-id-range"), content="true")
```

Reuse exact budget-delta assertions:

```moonbit
let before = budget.remaining()
let error = result.unwrap_err()
inspect(budget.remaining().bytes() == before.bytes(), content="true")
inspect(
  budget.remaining().work() == before.work() - expected_work,
  content="true",
)
```

Add paired exact-fit/one-short cases for semantic `max_work`, the caller budget, points, contours, components, instruction bytes, and output/scratch allocations. Preserve the Phase 98 pattern that earlier staged work remains consumed when a later preflight or malformed read fails.

Extend the constructor tests at `font_test.mbt:19-196`: assert every new accessor and reject zero for each new named parameter. Update the shared default at `font_test.mbt:927-939` and every explicit exact/narrow constructor.

Public generated micro-fonts must cover every D-21/D-22 command and taxonomy case; compare structured categories, codes, operation/context, requested/limit, and exact budget remainder rather than only `is Err`.

---

### `modules/mb-font/font/font_wbtest.mbt` (white-box test)

**Analog:** `font_wbtest.mbt:81-96`, `font_wbtest.mbt:313-353`, `font_wbtest.mbt:433-483`, and `font_wbtest.mbt:633-680`

Copy the exact-fit/one-short cursor test form for any new signed byte reader. Copy the after-read mutation seam:

```moonbit
let mut callback_count = 0
let result = font.kerning_after_lookup(glyph, glyph, fn() {
  callback_count = callback_count + 1
  font_wb_mutate_one_byte(owner, 0UL)
})
match result {
  Ok(_) => fail("post-read revision drift must not publish an adjustment")
  Err(error) => font_wb_assert_revision_drift(error)
}
inspect(callback_count, content="1")
```

Use the outline equivalent to prove even a fully decoded or empty private path is not published after revision drift.

Private tests should call helpers directly and freeze:

- flag cursor positions and `1 + repeat` expansion;
- strictly increasing contour endpoints;
- signed delta accumulation;
- exact Q15 midpoint and all matrix terms before `Double`;
- real-point numbering excluding implied points;
- transformed-child-then-attachment translation;
- tri-color stack transitions, self/multi-glyph cycles, and deeper-acyclic classification;
- Data/Capability/Resource/State separation and failure-path work deltas.

Update `font_wb_limits` at `font_wbtest.mbt:486-498` and expand `MaxpFacts` assertions near `font_wbtest.mbt:633-657`.

---

### `modules/mb-font/font/generated_fonts_wbtest.mbt` (fixture utility, file-I/O + batch + transform)

**Analog:** `generated_fonts_wbtest.mbt:15-72`, `generated_fonts_wbtest.mbt:130-143`, `generated_fonts_wbtest.mbt:204-209`, and `generated_fonts_wbtest.mbt:228-316`

Build glyph bodies from small semantic helpers, then reuse the checksum-correct assembler:

```moonbit
fn font_wb_table(tag : Bytes, payload : Bytes) -> GeneratedFontTable {
  { tag, payload }
}

fn font_wb_build_sfnt(tables : Array[GeneratedFontTable]) -> Bytes {
  // directory records use generated_checksum(table.payload)
  // payloads are padded to four-byte table alignment
  // head.checkSumAdjustment is repaired last
}
```

Parameterize `glyf`, normalized `loca`, glyph count, and the seven `maxp` outline maxima rather than embedding whole-font byte strings. Extend `generated_maxp_table` (`:204-209`) to accept or expose maxima fields. Keep top-level SFNT four-byte padding distinct from the outline decoder’s stricter `loca` glyph-body trailing-byte rule.

Use `generated_put_u16/i16/u32` for signed component arguments, flags, F2DOT14 raw coefficients, endpoints, and instruction lengths. Keep fixtures pure MoonBit, deterministic, checksum-correct, and license-free.

---

### `modules/mb-font/font/pkg.generated.mbti` (generated interface)

**Analog:** current generated file at `pkg.generated.mbti:1-70`

Never hand-edit. The tracked file is already stale: SHA-256 is `f26d91803070046fccc2032a3f4b3ad33b84adc32346494f6d2e57cc4005a2bd`, and it omits Phase 98’s `Font::glyph_for_scalar`, `Font::kerning`, `max_kern_subtables`, `max_kern_pairs`, and expanded constructor even though source and `policy/foundation.json:2242-2292` contain them.

Required two-baseline workflow:

1. Before any Phase 99 public-source edit, run:

   ```powershell
   moon -C modules/mb-font info --target all --frozen --target-dir <unique-phase98-baseline>
   ```

2. Inspect and preserve the Phase 98-only generated delta. It must add only the already-implemented Phase 98 queries/limits; do not attribute those lines to Phase 99.
3. After `Font::outline`, math import, and the four new limit accessors/constructor parameters compile, run `moon info` again with a fresh target directory.
4. Treat only the second delta as Phase 99: the `@math` public import, `Font::outline(Self, GlyphId, @budget.Budget) -> Result[@math.Path2, @error.CoreError]`, four accessors, and the newly expanded constructor.
5. Copy the final non-comment semantic lines verbatim into `policy/foundation.json`; do not type signatures from memory.

This ordering is a planning dependency, not an optional cleanup. Running the policy gate before repairing the Phase 98 baseline can misclassify old signatures or fail independently of the outline implementation.

---

### `policy/foundation.json` and `scripts/quality/Assert-Policy.ps1` (policy config/tests)

**Analogs:** `policy/foundation.json:2181-2300`; `Assert-Policy.ps1:981-1052` and `:1054-1197`

Update the coupled exact sets together:

- module description;
- `publication_files` with `font/outline.mbt`;
- package `allowed_imports` with `tchivs/mb-core/math`;
- `production_sources` with `outline.mbt` in actual accepted source order;
- final generated `semantic_interface`;
- PowerShell `$publicationFiles`, `$imports`, and `$productionSources` mirrors.

The independent selector currently calls every outline or `Path2` line a deferred Phase 99+ capability (`Assert-Policy.ps1:981-1051`) and explicitly injects `Font::outline_path` as a forbidden case (`:1150-1183`). Replace the Phase 98 allowlist with a Phase 99-reviewed allowlist that accepts only the locked direct `Font::outline(...Budget) -> Result[Path2, CoreError]` and four numeric limits while continuing to reject:

- any second public outline DTO;
- nested-composite/hint/raster APIs;
- host/file/FFI discovery;
- public cursor/table/descriptor/Q15 internals.

Preserve the fail-closed generated-interface comparison at `Assert-Policy.ps1:1186-1196`:

```powershell
& moon -C $fontModulePath info --target all --frozen
if ($LASTEXITCODE -ne 0) { throw "Font interface generation failed (exit $LASTEXITCODE)." }
$semanticLines = @(
  Get-Content -LiteralPath $interfacePath |
    ForEach-Object { $_.TrimEnd() } |
    Where-Object { $_ -ne '' -and -not $_.TrimStart().StartsWith('//') }
)
Assert-ExactSequence 'Font generated semantic interface' $semanticLines $interfaceText
```

Update Phase-number wording in assertions so the selector reports the post-Phase-99 deferred boundary accurately.

---

### Documentation files

**Files:** `modules/mb-font/README.mbt.md`, `modules/mb-font/CHANGELOG.md`, `README.md`

**Analogs:** the existing Phase 98 sections in the same files

For `modules/mb-font/README.mbt.md`:

- add `tchivs/mb-core/math` to literate frontmatter (`:1-10`);
- add the four new named limits to the executable constructor (`:71-91`);
- document direct `Font::outline(glyph, budget)`, query-owned budget, exact Q15-to-Double boundary, empty/simple/one-level-composite outcomes, and taxonomy;
- narrow the deliberate boundary (`:177-187`) to exclude nested composites, phantom attachment, grid rounding/hinting, rasterization, variable/CFF/color outlines, and Phase 100 real-font evidence.

For `modules/mb-font/CHANGELOG.md`, extend the current `0.1.0 candidate` Added list (`:10-30`) with the additive query and limits, then replace the Phase 98 outline exclusion (`:32-35`) with the remaining post-Phase-99 exclusions.

For root `README.md`, keep English and Chinese synchronized:

- English current-scope prose/row at `README.md:26-28` and `:48`;
- Chinese current-scope prose/row at `README.md:129-130` and `:147`.

The new descriptions should say complete unhinted simple and bounded one-level composite `Path2` outlines, without claiming Phase 100 licensed-real-font qualification.

## Shared Patterns

### Retained-Source Transaction

**Source:** `modules/mb-font/font/font.mbt:67-76`, `:250-280`, `:363-401`  
**Apply to:** `Font::outline`, including empty glyphs

Order is fixed: pre-guard → receiving-font glyph validation → private charged decode/lower → after-decode test hook → post-guard → one complete return. Never publish points, contours, component placements, or commands individually.

### Contained Binary Reads

**Source:** `modules/mb-font/font/cursor.mbt:19-108`; `metrics.mbt:360-419`  
**Apply to:** glyph header, simple body, composite descriptors, child lookups

Every read is relative to a `ByteView` already contained by normalized `loca` offsets. Use checked additions/multiplications for derived offsets and translate format arithmetic failures to the locked outline Data taxonomy.

### Limits and Budget Are Both Authoritative

**Source:** `modules/mb-font/font/kern.mbt:323-424`; `modules/mb-core/budget/budget.mbt:314-348`  
**Apply to:** every declared count and allocation stage

First enforce font consistency (`maxp`, Data), then retained semantic limits (Resource), then `Budget::preflight` and `Budget::charge` (Resource). `preflight` is non-consuming; `charge` atomically commits after rechecking. Charge discovery before traversal and allocation before allocation.

### Error Taxonomy

**Source:** `font_wbtest.mbt:433-483`; `font.mbt:219-231`; `kern.mbt:52-59`

| Condition | Category / code |
|---|---|
| foreign/out-of-range glyph or zero constructor limit | `InvalidInput` / `InvalidRange` |
| malformed bytes, flags, references, cycle, signed overflow, `maxp` inconsistency | `Data` / `InvalidEncoding` |
| valid deeper nesting, phantom attachment, grid rounding | `Capability` / `CapabilityUnavailable` |
| semantic ceiling or caller budget exhaustion | `Resource` / `BudgetExceeded` |
| retained-source revision drift | `State` / `InvalidRange` |

Keep stable outline-specific operation/context strings; do not propagate generic checked-arithmetic categories.

### Exact Geometry Boundary

**Source:** `modules/mb-core/math/affine.mbt:1-28`; `path.mbt:11-52`  
**Apply to:** path lowering only

All format arithmetic remains private signed `Int64` Q15. Create public `Point2(Double, Double)` only while appending final commands to a private `Path2`. Preserve source contour/component/point order and winding; never normalize, reverse, flatten, union, or drop degenerate contours.

### Test Oracles

**Source:** `font_test.mbt:1188-1292`, `:1537-1651`, `:1968-2039`; `font_wbtest.mbt:81-96`, `:313-483`

Tests assert exact command sequences, structured error fields, exact Q15 facts, exact cursor positions, exact-fit/one-short budgets, already-consumed failure work, repeatability, foreign glyph rejection, and deterministic mid-query revision drift.

## Verification Analogs and Gates

Use the established Phase 98 isolated-target pattern; do not run an unscoped parallel Windows test:

```powershell
# Fast production/private integration
moon -C modules/mb-font check --target native --frozen

# Focused native loop
moon -C modules/mb-font test font --target native --frozen --target-dir <unique-native-outline> --no-parallelize -f "*outline*"

# Full public + white-box package on every portable target
moon -C modules/mb-font test font --target native --frozen --target-dir <unique-native> --no-parallelize
moon -C modules/mb-font test font --target js --frozen --target-dir <unique-js> --no-parallelize
moon -C modules/mb-font test font --target wasm --frozen --target-dir <unique-wasm> --no-parallelize
moon -C modules/mb-font test font --target wasm-gc --frozen --target-dir <unique-wasm-gc> --no-parallelize

# Generated interface (after the separate Phase 98 baseline regeneration)
moon -C modules/mb-font info --target all --frozen --target-dir <unique-interface>

# Literate package docs on all targets
moon -C modules/mb-font check README.mbt.md --target native --frozen --target-dir <unique-doc-native> --serial
moon -C modules/mb-font check README.mbt.md --target js --frozen --target-dir <unique-doc-js> --serial
moon -C modules/mb-font check README.mbt.md --target wasm --frozen --target-dir <unique-doc-wasm> --serial
moon -C modules/mb-font check README.mbt.md --target wasm-gc --frozen --target-dir <unique-doc-wasm-gc> --serial

# Exact policy/source/import/interface classifier
pwsh -NoProfile -Command ". ./scripts/quality/Assert-Policy.ps1; Assert-FontFoundationPolicy -PolicyPath ./policy/foundation.json"
```

Verification evidence should map directly to:

- public command sequence and error tests in `font_test.mbt`;
- private decoder/Q15/graph/charging tests in `font_wbtest.mbt`;
- checksum-correct micro-font construction in `generated_fonts_wbtest.mbt`;
- generated interface exactness and no private leaks in `Assert-Policy.ps1`;
- English/Chinese scope equivalence and executable package docs.

## No Analog Found

| File / Concern | Role | Data Flow | Reason |
|---|---|---|---|
| `modules/mb-font/font/outline.mbt` TrueType semantic core | service / decoder / lowerer | file-I/O, transform | No existing outline decoder, implied-point contour lowerer, exact signed-Q15 transform layer, point-attachment implementation, or iterative composite graph classifier exists. Use `99-RESEARCH.md` algorithms while copying the local containment, staging, error, publication, and test patterns above. |

## Planner Notes

- Make the stale Phase 98 interface regeneration the first isolated task, before any Phase 99 public edit.
- Keep the costly `FontLimits::new` migration atomic across implementation, all explicit callers, docs, generated interface, JSON policy, and independent PowerShell selector.
- A useful implementation split is: retained windows/maxp/limits → simple decoder/Q15 lowering → composite graph/placement → facade/query tests → generated interface/policy/docs.
- `outline.mbt` is the only new production source. Do not add a second public outline model or a second module dependency.
- Modify `cursor.mbt` only if a shared signed-byte helper materially simplifies coordinate decoding; otherwise keep it unchanged and remove it from the execution plan.
- Policy/docs are the final integration task after the four-target package tests, except for the mandatory pre-implementation interface-baseline regeneration.

## Metadata

**Analog search scope:** `modules/mb-font/font`, `modules/mb-font`, `modules/mb-core/math`, `modules/mb-core/budget`, `policy/foundation.json`, `scripts/quality/Assert-Policy.ps1`, root `README.md`  
**Graph result:** codebase-memory indexed repository/file structure but exposed no current MoonBit function nodes; scoped `rg` and direct reads were used as the documented `AGENTS.md` fallback  
**Files scanned:** 26 relevant source/config/test/documentation files  
**Pattern extraction date:** 2026-07-27
