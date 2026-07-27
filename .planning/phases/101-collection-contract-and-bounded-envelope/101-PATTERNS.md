# Phase 101: Collection Contract and Bounded Envelope - Pattern Map

**Mapped:** 2026-07-28  
**Files analyzed:** 6 new, generated, or verification artifacts  
**Analogs found:** 6 / 6 file-level matches; no existing TTC/DSIG parser exists  
**Requirement:** TTC-01 only

## Scope Guard

Phase 101 opens and inspects a complete TTC/OTC collection. It does not select
a face, construct a `Font`, validate table payload checksums, enforce the
standalone required-table set, or decode cmap/metrics/kern/glyf/CFF/variation
semantics. Those are Phase 102 or later.

Do not modify `Font::open` behavior or route `ttcf` through
`parse_font_directory`. `font.mbt`, `directory.mbt`, and `limits.mbt` are
analogs to copy from, not Phase 101 refactor targets.

## Expected Files and Symbols

| File | Expected Phase 101 symbols/responsibility |
|---|---|
| `modules/mb-font/font/collection_limits.mbt` | Public opaque `FontCollectionLimits`; `new`; eight getters; private zero-limit error helper |
| `modules/mb-font/font/collection_parser.mbt` | Private compact face/protected/DSIG facts; TTC v1/v2 declaration and structural passes; root-relative directory/table range helpers; profile classification; protected-range and exact-alias validation; DSIG traversal; retained-byte/work/charge helpers |
| `modules/mb-font/font/collection.mbt` | Public `FontFaceProfile`, `FontCollectionDsigStatus`, opaque `FontCollection`; `FontCollection::open`; `face_count`; `face_profile`; `dsig_status`; private revision/index/error helpers |
| `modules/mb-font/font/collection_test.mbt` | Black-box public API, error precedence, exact limits/budget charge, atomicity, revision, generated TTC v1/v2 and interface-leak cases |
| `modules/mb-font/font/collection_wbtest.mbt` | White-box range-origin, search facts, profile, sharing, protected-range, DSIG, exact formula, traversal order, and final-revision seam tests |
| `modules/mb-font/font/pkg.generated.mbti` | Generated interface evidence after `moon info`; never hand-edit |

Internal helper names and compact-fact layouts are discretionary. Preserve the
observable public symbols and error/category behavior from `101-CONTEXT.md`.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `collection_limits.mbt` | config / authority model | request-response | `limits.mbt` | exact role |
| `collection_parser.mbt` | service / parser | transform + bounded batch over caller bytes | `directory.mbt` | role-match; collection traversal is new |
| `collection.mbt` | model + provider facade | request-response | `font.mbt` | exact facade/lifecycle |
| `collection_test.mbt` | black-box test | request-response + mutation events | `font_test.mbt` | exact test tier |
| `collection_wbtest.mbt` | white-box test | transform + adversarial batch | `font_wbtest.mbt` | exact test tier |
| `pkg.generated.mbti` | generated public interface | transform | existing `pkg.generated.mbti` | exact generated artifact |

## Pattern Assignments

### `collection_limits.mbt` (config, request-response)

**Analog:** `modules/mb-font/font/limits.mbt`

**Opaque storage pattern** (`limits.mbt:7-22`):

```moonbit
pub struct FontLimits {
  priv max_source_bytes_value : UInt64
  priv max_tables_value : UInt64
  // ...
  priv max_work_value : UInt64
}
```

Mirror this with private `UInt64` fields for:

```text
max_source_bytes
max_faces
max_tables_per_face
max_table_records
max_dsig_records
max_dsig_bytes
max_retained_bookkeeping_bytes
max_work
```

**Stable constructor-error pattern** (`limits.mbt:25-34`):

```moonbit
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
```

Copy the category/code/requested/limit shape. Use collection-specific operation
`font-collection-limits-new` and kebab-case field contexts.

**Argument-order validation pattern** (`limits.mbt:38-60`):

```moonbit
pub fn FontLimits::new(
  max_source_bytes~ : UInt64,
  max_tables~ : UInt64,
  // ...
) -> Result[FontLimits, @error.CoreError] {
  if max_source_bytes == 0UL {
    return Err(invalid_font_limit("max-source-bytes"))
  }
  if max_tables == 0UL {
    return Err(invalid_font_limit("max-tables"))
  }
  // ...
}
```

Validate all eight collection fields in the public constructor's argument
order, then preserve their values verbatim.

**Getter pattern** (`limits.mbt:114-122`):

```moonbit
pub fn FontLimits::max_source_bytes(self : FontLimits) -> UInt64 {
  self.max_source_bytes_value
}

pub fn FontLimits::max_tables(self : FontLimits) -> UInt64 {
  self.max_tables_value
}
```

Provide one direct getter per constructor field. Do not widen `FontLimits`.

---

### `collection_parser.mbt` (service/parser, transform + bounded batch)

**Analog:** `modules/mb-font/font/directory.mbt`

This is a role match, not a parser that can be called unchanged. Reuse the
checked/error/search idioms; replace the standalone origin, overlap, profile,
checksum, and resource formulas.

**Private retained-fact pattern** (`directory.mbt:18-31`):

```moonbit
priv struct TableWindow {
  tag : UInt64
  checksum : UInt64
  offset : UInt64
  length_value : UInt64
  view : @bytes.ByteView
}

priv struct DirectoryFacts {
  source : @bytes.ByteView
  tables : Array[TableWindow]
  work : UInt64
}
```

Keep collection parser facts `priv`. Retain only compact face facts and
protected ranges required by the facade and Phase 102. Raw offsets, tags,
checksums, ranges, and views may exist only as private parser/retained facts;
never expose them or model them as public `TableWindow`-style values.

**Error taxonomy pattern** (`directory.mbt:34-75`):

```moonbit
fn font_data_error(...) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::Data,
    @error.ErrorCode::InvalidEncoding,
    operation="font-open",
    // ...
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

fn font_limit_error(...) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::Resource,
    @error.ErrorCode::BudgetExceeded,
    operation="font-open",
    requested~,
    limit~,
    context~,
  )
}
```

Create collection equivalents using `operation="font-collection-open"`.
Malformed wire arithmetic must be caught and remapped to
`Data/InvalidEncoding`; do not leak checked-primitive `InvalidInput` errors.

**Reusable search-fact helper** (`directory.mbt:117-143`):

```moonbit
fn font_directory_search_facts(
  num_tables : UInt64,
) -> Result[(UInt64, UInt64, UInt64), @error.CoreError] {
  let (power, selector) = font_directory_search_power_and_selector(num_tables)
  let search_range = @checked.checked_mul(power, 16UL)
  // ...
  let range_shift = @checked.checked_sub(table_bytes, search_range)
  // ...
}
```

Call this pure helper for every face and compare all three stored search facts.
The directory envelope must be computed as
`directory_offset + 12 + 16 * num_tables`, with checked `UInt64` arithmetic.

**Checked root-range pattern** (`directory.mbt:299-314`):

```moonbit
let source_range = match
  @checked.CheckedRange::from_start_length(0UL, source.length()) {
  Err(error) => return Err(error)
  Ok(value) => value
}
let table_range = match source_range.subrange(offset, length) {
  Err(error) => return Err(error)
  Ok(value) => value
}
```

Apply this in root coordinates to the TTC header/offset array, every directory,
every table record, the optional DSIG, and every DSIG block. Directory-field
locations add the face directory base; table-record offsets do not.

**Wire-order traversal pattern** (`directory.mbt:433-579`):

```moonbit
let (expected_search, expected_selector, expected_shift) =
  font_directory_search_facts(num_tables).unwrap()
let mut previous_tag : UInt64? = None
let mut index = 0UL
while index < num_tables {
  let record_delta = @checked.checked_mul(index, 16UL).unwrap()
  let record_offset = @checked.checked_add(12UL, record_delta).unwrap()
  let tag = read_u32(source, record_offset).unwrap()
  match previous_tag {
    Some(previous) =>
      if tag <= previous {
        return Err(font_data_error("font-directory-tag-order"))
      }
    None => ()
  }
  // read checksum, root-relative offset, and length in field order
  previous_tag = Some(tag)
  index = @checked.checked_add(index, 1UL).unwrap()
}
```

Preserve face-offset order, then record order within each face. Use a
declaration/count pass before allocating, a complete structural pass, then a
retained-normalization pass.

**Do not copy these standalone assumptions:**

- `directory.mbt:228-233` rejects anything except standalone
  `0x00010000`; collection open must require `ttcf` and accept exact TTC v1/v2.
- `directory.mbt:463` assumes the directory starts at byte zero; add the face
  directory offset only to directory-field locations.
- `directory.mbt:471-473` rejects unsupported outline tags; collection parsing
  must classify them without failing.
- `directory.mbt:541-561` protects only the current standalone directory and
  rejects every overlap; Phase 101 protects the complete header, all face
  directories, and DSIG, while allowing only exact cross-face aliases with
  matching tag/length/checksum metadata.
- `directory.mbt:640-713` scans payload and whole-font checksums; Phase 101 must
  not call these helpers or charge that work.
- `directory.mbt:286-294` charges the full source length as retained bytes;
  collection admission charges compact bookkeeping only.

**Collection-specific new logic with no existing exact analog:**

- TTC v2 all-zero DSIG tuple versus malformed partial-zero tuple.
- DSIG version-1/format-1 header, record, block, reserved-field, containment,
  non-overlap, and exact inner/outer-length checks while leaving payload opaque.
- Exact cross-face alias metadata comparison.
- Full protected-set comparisons and the Phase 101 exact work formula.

Use the research formula from one helper so implementation and exact-one-short
tests cannot drift:

```text
P = 1 + F + S
retained_bytes = 96 + F*40 + P*24
allocations = 2
allocation_size = max(F*40, P*24)

exact_work =
  declaration_reads + structural_reads + R
  + C2(P) + R*P + C2(R)
  + S*(3 + 6*N + C2(N))
  + 1 + F + P
```

All products/sums are checked after their controlling semantic ceiling.

---

### `collection.mbt` (opaque model/provider, request-response)

**Analog:** `modules/mb-font/font/font.mbt`

**Opaque retained-source facade** (`font.mbt:9-20`):

```moonbit
pub struct Font {
  priv source : @bytes.ByteView
  priv opening_revision : UInt64
  // private admitted facts
  priv limits : FontLimits
}
```

`FontCollection` should retain the original root `ByteView`, captured revision,
compact face facts, protected ranges, and closed DSIG status. Keep every field
private.

**Closed public enum shape:**

```moonbit
pub(all) enum FontFaceProfile {
  StaticGlyf
  Cff
  Cff2
  Variable
  OtherUnsupported
} derive(Eq)

pub(all) enum FontCollectionDsigStatus {
  Absent
  PresentUnverified
} derive(Eq)
```

Do not add `Valid`, `Trusted`, raw tag/offset/range accessors, or selected-face
methods.

**Shared revision guard** (`font.mbt:58-77`):

```moonbit
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

Copy with collection-specific context
`font-collection-source-revision-drift`; open uses
`font-collection-open`, queries use `font-collection-query`.

**Admission orchestration pattern** (`font.mbt:99-125`, `148-175`):

```moonbit
pub fn Font::open(
  source : @bytes.ByteView,
  limits : FontLimits,
  budget : @budget.Budget,
) -> Result[Font, @error.CoreError] {
  let opening_revision = source.mutation_revision()
  // discover, preflight, parse/validate, normalize
  if source.mutation_revision() != opening_revision {
    return Err(font_revision_error("font-open"))
  }
  Ok({ source, opening_revision, /* private facts */ })
}
```

For collection opening, preflight the one final compact `ResourceCharge`,
normalize retained facts, perform the final revision guard, charge once, then
publish. Any malformed/capability/limit/budget/state failure publishes nothing
and leaves the transaction uncommitted.

Do not copy `Font::open`'s current placement of `budget.charge` at
`font.mbt:122-125`: it precedes later standalone semantic validation. D-12 and
D-14 require the collection's single charge after all collection validation,
normalization, and the final revision guard.

**Revision-first query pattern** (`font.mbt:182-186`):

```moonbit
pub fn Font::units_per_em(self : Font) -> Result[UInt64, @error.CoreError] {
  match self.require_revision("font-query") {
    Err(error) => Err(error)
    Ok(_) => Ok(self.units_per_em_value)
  }
}
```

Apply to `face_count` and `dsig_status`. `face_profile` must also guard revision
before validating the index.

**Index error pattern** (`font.mbt:220-233`, `287-301`):

```moonbit
fn font_glyph_id_error(
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
    context="font-glyph-id-range",
  )
}
```

Use `requested=index`, `limit=face_count`, collection query operation, and a
stable collection face-index context. Narrow to `Int` only after the `UInt64`
range check.

---

### `collection_test.mbt` (black-box test, request-response + mutation)

**Analog:** `modules/mb-font/font/font_test.mbt`

**Full observable error assertion** (`font_test.mbt:1-16`):

```moonbit
fn assert_invalid_font_limit(
  result : Result[FontLimits, @error.CoreError],
  context : String,
) -> Unit raise {
  let error = result.unwrap_err()
  inspect(error.category() == @error.ErrorCategory::InvalidInput, content="true")
  inspect(error.code() == @error.ErrorCode::InvalidRange, content="true")
  inspect(error.operation() == Some("font-limits-new"), content="true")
  inspect(error.requested() == Some(0UL), content="true")
  inspect(error.limit() == Some(1UL), content="true")
  inspect(error.context() == Some(context), content="true")
}
```

Create a collection equivalent and test every zero field in constructor order,
plus exact preservation through all eight getters.

**Exact-fit and one-short budget pattern** (`font_test.mbt:3752-3865`):

```moonbit
let exact_budget = font_test_budget_with_dimensions(
  source_length,
  allocations=3UL,
  allocation_size=directory_allocation_size,
  exact_work,
)
ignore(Font::open(owner.view(), exact_limits, exact_budget).unwrap())
inspect(exact_budget.remaining().bytes(), content="0")
inspect(exact_budget.remaining().allocations(), content="0")
inspect(exact_budget.remaining().work(), content="0")

let size_before = size_budget.remaining()
let size_error = Font::open(owner.view(), exact_limits, size_budget).unwrap_err()
inspect(size_error.context() == Some("allocation_size"), content="true")
inspect(
  size_budget.remaining().allocation_size() == size_before.allocation_size(),
  content="true",
)
```

For collection tests, assert all budget dimensions remain unchanged for every
rejected open. Success must charge exactly compact retained bytes, two
allocations, maximum retained-array size, and exact work; source length is not
charged as copied bytes.

**Mutate-back and every-query pattern** (`font_test.mbt:4847-4896`):

```moonbit
fn font_test_assert_every_query_drift(font : Font, glyph : GlyphId) -> Unit raise {
  font_test_assert_revision_drift(font.units_per_em().unwrap_err())
  // every other query
}

let original = restored_owner.view().get(offset).unwrap()
font_test_mutate_bytes(restored_owner, offset, b"\xff")
font_test_mutate_bytes(restored_owner, offset, Bytes::from_array([original]))
font_test_assert_every_query_drift(restored, glyph)
```

Exercise `face_count`, `face_profile`, and `dsig_status` after relevant,
unrelated, and mutate-restore changes. Add revision-before-index precedence and
independent-collection isolation.

Build deterministic TTC bytes in test code. Include a non-zero directory offset
and a table offset that stays in bounds under an incorrect rebase. Separate
exactly shared ranges from same-sized distinct ranges and equal-content
distinct ranges.

---

### `collection_wbtest.mbt` (white-box test, transform + adversarial batch)

**Analog:** `modules/mb-font/font/font_wbtest.mbt`

**Caller-owned view helper** (`font_wbtest.mbt:1-21`):

```moonbit
fn font_wb_view(source : Bytes) -> @bytes.ByteView {
  let length = source.length().to_uint64()
  @bytes.OwnedBytes::from_bytes(
    source,
    @budget.Budget::new(
      @budget.ResourceLimits::new(
        bytes=length,
        allocations=1UL,
        allocation_size=length,
        // ...
      ),
    ),
  )
  .unwrap()
  .view()
}
```

Reuse this ownership pattern for private parser helpers; retain an
`OwnedBytes` helper when mutation tests need the owner.

**Exact-one-short private accounting pattern** (`font_wbtest.mbt:287-345`):

```moonbit
let exact = @budget.Budget::new(
  @budget.ResourceLimits::new(
    allocations=3UL,
    allocation_size=88UL,
    // ...
  ),
)
// exact helper succeeds

let one_short = @budget.Budget::new(
  @budget.ResourceLimits::new(
    allocations=3UL,
    allocation_size=87UL,
    // ...
  ),
)
let error = private_helper(/* ... */, one_short).unwrap_err()
inspect(error.category() == @error.ErrorCategory::Resource, content="true")
inspect(error.code() == @error.ErrorCode::BudgetExceeded, content="true")
inspect(error.context() == Some("allocation_size"), content="true")
inspect(one_short.remaining().allocations(), content="3")
```

Test every retained/work formula at exact fit and one short, including checked
overflow remapped to the correct collection `Resource` ceiling.

**Private matrix pattern** (`font_wbtest.mbt:993-1068`):

```moonbit
let facts = font_parse_directory(font_wb_view(valid), font_wb_limits()).unwrap()
for offset in [6, 8, 10] {
  let malformed = font_wb_put_u16_at_copy(valid, offset, 0UL)
  inspect(
    font_parse_directory(font_wb_view(malformed), font_wb_limits()) is Err(_),
    content="true",
  )
}
```

Use table-driven mutation matrices for header versions, search facts, tag
order, root-relative ranges, protected intersections, alias relations, profile
classification, DSIG tuple/body/records/blocks, and traversal precedence.

**Taxonomy matrix pattern** (`font_wbtest.mbt:920-969`):

```moonbit
let data = font_data_error("font-kern-format0")
inspect(data.category() == @error.ErrorCategory::Data, content="true")
inspect(data.code() == @error.ErrorCode::InvalidEncoding, content="true")

let state = font_revision_error("font-query")
inspect(state.category() == @error.ErrorCategory::State, content="true")
inspect(state.code() == @error.ErrorCode::InvalidRange, content="true")

let resource = font_limit_error("max-kern-pairs", 2UL, 1UL)
inspect(resource.category() == @error.ErrorCategory::Resource, content="true")
inspect(resource.code() == @error.ErrorCode::BudgetExceeded, content="true")
```

Freeze all five Phase 101 outcomes: invalid index/limits, malformed bytes,
recognized unsupported version/DSIG format, resource exhaustion, and revision
drift.

---

### `pkg.generated.mbti` (generated interface, transform)

**Analog:** `modules/mb-font/font/pkg.generated.mbti`

**Opaque generated type pattern** (`pkg.generated.mbti:16-28`):

```moonbit
pub struct Font {
  // private fields
}
pub fn Font::open(
  @bytes.ByteView,
  FontLimits,
  @budget.Budget,
) -> Result[Self, @error.CoreError]
pub fn Font::units_per_em(Self) -> Result[UInt64, @error.CoreError]
```

**Opaque limits + getter pattern** (`pkg.generated.mbti:38-55`):

```moonbit
pub struct FontLimits {
  // private fields
}
pub fn FontLimits::max_source_bytes(Self) -> UInt64
pub fn FontLimits::max_work(Self) -> UInt64
pub fn FontLimits::new(/* named UInt64 ceilings */) -> Result[Self, @error.CoreError]
```

After `moon info`, assert the generated interface adds only:

- `FontFaceProfile` with the five closed variants;
- `FontCollectionDsigStatus::{Absent, PresentUnverified}`;
- opaque `FontCollectionLimits`, its constructor, and eight getters;
- opaque `FontCollection`;
- `FontCollection::{open, face_count, face_profile, dsig_status}`.

Reject any generated exposure of root/source views, revisions, offsets, tags,
records, checksums, ranges, compact parser facts, DSIG payloads, selected
`Font`, or Phase 102 admission methods. Never edit this generated file by hand.

## Shared Patterns

### Package Imports and Portability

**Source:** `modules/mb-font/font/moon.pkg:1-9`  
**Apply to:** all Phase 101 production and tests

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

MoonBit source files in this package do not carry per-file import blocks.
Phase 101 needs no new dependency, module, FFI, or target restriction.

### Atomic Resource Publication

**Source:** `modules/mb-font/font/font.mbt:99-175` (lifecycle analog; charge
placement must be changed as noted above)  
**Apply to:** `FontCollection::open`

Capture the root revision first; establish semantic authority; preflight the
one final charge; validate and normalize private facts; final-guard revision;
charge once; then construct the opaque value. Never publish or commit on an
error.

### Checked Half-Open Ranges

**Source:** `modules/mb-font/font/directory.mbt:299-314`  
**Apply to:** all TTC header, directory, table, protected, DSIG, and block ranges

Keep `UInt64` root coordinates through validation and narrow only after the
range/count authority check. Empty ranges do not overlap; touching endpoints
are permitted.

### Stable Error Pairs

**Sources:** `directory.mbt:34-75`, `font.mbt:58-77`,
`font_wbtest.mbt:920-969`

| Condition | Category | Code |
|---|---|---|
| Zero limit or face index | `InvalidInput` | `InvalidRange` |
| Malformed/truncated/inconsistent wire data | `Data` | `InvalidEncoding` |
| Complete unsupported TTC/DSIG version or DSIG format | `Capability` | `CapabilityUnavailable` |
| Semantic ceiling/formula overflow/caller budget | `Resource` | `BudgetExceeded` |
| Root revision drift | `State` | `InvalidRange` |

Unsupported face profiles are informative enum values, not open failures.

### Test Layers

- `collection_test.mbt` is black-box: use only exported collection API and
  assert externally observable categories, codes, fields, budgets, revision,
  opacity, and standalone compatibility.
- `collection_wbtest.mbt` is white-box: call private formulas/parsers and assert
  exact ranges, counts, work terms, fail order, and retained fact layout.
- Preserve the existing standalone suite unchanged and run all four targets
  with distinct target directories.

## No Exact Analog Found

| Symbol/Seam | Role | Data Flow | Planner Direction |
|---|---|---|---|
| TTC v1/v2 multi-face structural passes | parser service | bounded batch/transform | Adapt `directory.mbt` cursor/search/range idioms; do not call the standalone parser |
| Exact cross-face alias validation | parser utility | pairwise batch | Implement from D-08 and the exact `C2(R)` work term |
| Structural DSIG traversal | parser service | bounded batch/transform | Implement the research v1/format-1 envelope; payload stays opaque |
| Collection compact retained charge | accounting utility | transform | Use the research 96/40/24-byte model or a deliberately equivalent documented model with exact-one-short tests |
| Deterministic mid-open revision hook | white-box test seam | event-driven | Mirror post-read callback seams in `font_wbtest.mbt`; keep it private |

## Discovery Notes

The project-required `codebase-memory-mcp` was queried first. Its
`mnf-phase100-exec` graph reports zero nodes under `modules/mb-font/font`, and
symbol search returns planning/document nodes rather than MoonBit functions.
Consequently, MoonBit function/source extraction used the allowed fallback:
targeted repository reads (`rg` only to locate ranges in the 5,210-line
black-box test file, then single-pass or non-overlapping reads).

No `.codex/skills/` or `.agents/skills/` project skill directories exist in
this worktree.

## Metadata

**Analog search scope:** `modules/mb-font/font`, plus existing package manifest  
**Strong analog files:** 5 (`limits.mbt`, `font.mbt`, `directory.mbt`,
`font_test.mbt`, `font_wbtest.mbt`)  
**Generated interface reference:** `pkg.generated.mbti`  
**Pattern extraction date:** 2026-07-28  
**Out of scope:** selected-face admission, `Font` construction from a
collection, checksum mode, WOFF, CFF/CFF2 outline execution, variation
execution, DSIG cryptographic trust, discovery, shaping, rendering, authoring,
and Phase 103 qualification infrastructure
