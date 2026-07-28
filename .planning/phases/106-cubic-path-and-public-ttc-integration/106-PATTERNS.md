# Phase 106: Cubic Path and Public/TTC Integration - Pattern Map

**Mapped:** 2026-07-29
**Files analyzed:** 19 likely new/modified files
**Analogs found:** 19 / 19 (two use a composite analog)

## Scope Summary

Phase 106 should integrate already-admitted CFF1 facts into the existing public
`Font`, `FontCollection`, metrics, and `Path2` workflows. It should not create a
second Type 2 interpreter, expose CFF-specific public APIs, copy collection
faces, or alter the existing glyf lowering and charge formulas.

The five primary analog families are:

1. `modules/mb-core/math/path.mbt` plus `Type2Vm::new` for exact-capacity arrays.
2. `cff_type2_bounds.mbt` plus `outline.mbt` for shared exact geometry and public
   path command lowering.
3. `cff_admission.mbt`, `tables.mbt`, and `budget.mbt` for preflight, final
   revision guard, one commit, and no partial publication.
4. `font.mbt` plus `metrics.mbt` for opaque, format-neutral query dispatch.
5. `collection_parser.mbt`, `collection.mbt`, and collection tests for retained
   root-relative selected-face routing and glyf compatibility.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `modules/mb-core/math/path.mbt` | model / utility | transform | Same file's `Path2::new`; capacity construction in `cff_type2.mbt:1355-1360` | exact seam |
| `modules/mb-core/math/path_wbtest.mbt` | test | transform | Same file's push/length and cubic tests | exact |
| `modules/mb-font/font/cff_type2_bounds.mbt` | service / model | streaming transform | Existing `Type2BoundsSink` | exact |
| `modules/mb-font/font/cff_type2_path.mbt` (new, recommended) | service / sink | streaming transform | Composite: `cff_type2_bounds.mbt` geometry + `outline.mbt` path lowering | composite |
| `modules/mb-font/font/cff_type2.mbt` | service / VM | streaming transform, batch admission, request-response query | Existing sole `Type2Vm` and all-glyph staging | exact |
| `modules/mb-font/font/cff_admission.mbt` | service / retained model | batch, request-response | Existing combined structural + Type 2 admission | exact |
| `modules/mb-font/font/tables.mbt` | service / model | batch admission | `font_admit_required_tables_impl` and `FontAdmissionLedger` | exact role |
| `modules/mb-font/font/kern.mbt` | service / model | batch admission, request-response query | `font_admit_kern_bounded` / `KernState` | exact |
| `modules/mb-font/font/metrics.mbt` | service | request-response | glyf horizontal metric lookup plus `cff_read_hmtx_metric` | exact |
| `modules/mb-font/font/font.mbt` | provider / public facade | request-response | Existing `Font` construction and guarded query methods | exact |
| `modules/mb-font/font/collection.mbt` | provider / route | request-response | Existing `StaticGlyf` selected-face route | exact |
| `modules/mb-font/font/cff_type2_bounds_wbtest.mbt` | test | streaming transform | Existing cubic, contour, bounds, and flex goldens | exact |
| `modules/mb-font/font/cff_type2_path_wbtest.mbt` (new, recommended) | test | streaming transform | Composite: bounds goldens + `path_wbtest.mbt` command assertions | composite |
| `modules/mb-font/font/cff_type2_wbtest.mbt` | test | streaming transform | Existing VM/operator tests | exact |
| `modules/mb-font/font/cff_admission_wbtest.mbt` | test | batch, atomic transaction | Existing all-glyph, revision, exact-charge, and hmtx-authority tests | exact |
| `modules/mb-font/font/font_wbtest.mbt` | test | request-response, mutation injection | Existing private `Font` guard/probe tests | role match |
| `modules/mb-font/font/font_test.mbt` | test | request-response | Existing public standalone glyf fingerprint | exact |
| `modules/mb-font/font/collection_wbtest.mbt` | test / fixture | batch, request-response | Existing shared-CFF TTC fixture and atomic selected admission | exact |
| `modules/mb-font/font/collection_test.mbt` | test | request-response | Existing selected-face public fingerprint/equivalence tests | exact |

### Reference-only file

`modules/mb-font/font/collection_parser.mbt` already retains
`directory_start`, `table_count`, `sfnt_version`, and `profile`, and already
classifies `FontFaceProfile::Cff`. Phase 106 should consume these facts without
redesigning or rebasing the parser.

## Pattern Assignments

### Capacity-aware `Path2`

**Apply to:** `path.mbt`, `path_wbtest.mbt`, `cff_type2_path.mbt`

**Primary analog:** `modules/mb-core/math/path.mbt`

**Public model and append-only storage pattern** (`path.mbt:13-52`):

```moonbit
pub(all) enum PathCommand {
  MoveTo(Point2)
  LineTo(Point2)
  QuadTo(Point2, Point2)
  CubicTo(Point2, Point2, Point2)
  Close
}

pub struct Path2 {
  commands : Array[PathCommand]
}

pub fn Path2::new() -> Path2 {
  { commands: [] }
}

pub fn Path2::push(self : Path2, command : PathCommand) -> Unit {
  self.commands.push(command)
}
```

Add only a format-neutral constructor beside `new`, preserving private storage
and all existing methods. Copy the fixed-capacity syntax used by the Type 2 VM
(`cff_type2.mbt:1355-1360`):

```moonbit
let stack : Array[Type2Fixed] = Array::new(
  capacity=limits.max_operand_stack.to_int(),
)
let frames : Array[Type2Frame] = Array::new(
  capacity=limits.frame_capacity,
)
```

The planned constructor should therefore follow:

```moonbit
pub fn Path2::with_capacity(capacity : Int) -> Path2 {
  { commands: Array::new(capacity~) }
}
```

Do not add a capacity getter or expose `commands`. Validate negative/zero/exact
capacity behavior in `path_wbtest.mbt` while retaining the established test
style (`path_wbtest.mbt:4-12`):

```moonbit
test "path2 push and length track command count" {
  let path = Path2::new()
  inspect(path.length(), content="0")
  path.push(MoveTo(Point2::new(0.0, 0.0)))
  path.push(LineTo(Point2::new(10.0, 0.0)))
  path.push(LineTo(Point2::new(10.0, 10.0)))
  path.push(Close)
  inspect(path.length(), content="4")
}
```

**Important compatibility fact:** `Path2::bounds` treats `MoveTo` as a point
(`path.mbt:76-104`). The CFF path sink must defer `MoveTo` until the first
segment so a move-only glyph remains an empty path with `None` bounds.

---

### Shared Type 2 geometry core and native cubic path sink

**Apply to:** `cff_type2_bounds.mbt`, new `cff_type2_path.mbt`,
`cff_type2.mbt`, and their white-box tests.

**Primary analog:** `modules/mb-font/font/cff_type2_bounds.mbt`

**Shared state to extract, not duplicate** (`cff_type2_bounds.mbt:21-42`):

```moonbit
priv struct Type2BoundsSink {
  mut current_x : Type2Fixed
  mut current_y : Type2Fixed
  mut contour_start_x : Type2Fixed
  mut contour_start_y : Type2Fixed
  mut contour_open : Bool
  mut contour_has_segments : Bool
  mut points : UInt64
  mut contours : UInt64
  mut commands : UInt64
  mut has_segments : Bool
  // bounds accumulator fields...
  matrix : Type2Matrix
  limits : Type2Limits
}
```

The extracted shared geometry state should continue to own current point,
contour lifecycle, limits, exact relative additions, and exact matrix
application. Bounds and path publication are outputs of the same state
transitions.

**Relative cubic accumulation pattern** (`cff_type2_bounds.mbt:325-378`):

```moonbit
let control1_x = type2_geometry_coordinate_add(start_x, dx1)?
let control1_y = type2_geometry_coordinate_add(start_y, dy1)?
let control2_x = type2_geometry_coordinate_add(control1_x, dx2)?
let control2_y = type2_geometry_coordinate_add(control1_y, dy2)?
let end_x = type2_geometry_coordinate_add(control2_x, dx3)?
let end_y = type2_geometry_coordinate_add(control2_y, dy3)?
// include contour start and all three cubic hull points
self.current_x = end_x
self.current_y = end_y
```

MoonBit source uses explicit `match` propagation rather than `?`; preserve that
local error-handling convention in implementation. The path sink must receive
these exact absolute points, transform with the same `Type2Matrix`, perform one
checked deterministic rational-to-`Double` conversion at the `Point2`
boundary, and emit:

```moonbit
path.push(@math.PathCommand::CubicTo(control1, control2, end))
```

**Public command lowering analog** (`outline.mbt:433-446,463-504`):

```moonbit
let path = @math.Path2::new()
path.push(@math.PathCommand::MoveTo(font_outline_point(start)))
path.push(@math.PathCommand::LineTo(font_outline_point(point)))
path.push(
  @math.PathCommand::QuadTo(
    font_outline_point(value),
    font_outline_point(point),
  ),
)
path.push(@math.PathCommand::Close)
```

Copy only the typed `PathCommand` lowering style. Do not copy glyf's immediate
moveto behavior or its incremental budget charging into the CFF query.

**Contour rule to preserve/generalize** (`cff_type2_bounds.mbt:281-292`):

```moonbit
fn Type2BoundsSink::include_contour_start(
  self : Type2BoundsSink,
) -> Result[Unit, @error.CoreError] {
  if self.contour_has_segments {
    return Ok(())
  }
  match self.include_point(self.contour_start_x, self.contour_start_y) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  self.contour_has_segments = true
  Ok(())
}
```

For path publication, the analogous first-segment hook flushes one pending
`MoveTo`, then emits the segment. `close` emits `Close` only if the contour has
segments. A new moveto closes only the prior geometric contour. Admission must
retain an exact *publishable* command count, not blindly reuse the current
geometry-limit `commands` counter, because current `move_relative` and `close`
charge commands even for move-only contours (`cff_type2_bounds.mbt:231-258,
382-394`).

**One VM authority** (`cff_type2.mbt:71-89,1345-1388`):

```moonbit
priv struct Type2Vm {
  stack : Array[Type2Fixed]
  transient : Array[Type2Fixed]
  transient_initialized : Array[Bool]
  frames : Array[Type2Frame]
  local_subrs : CffIndex
  global_subrs : CffIndex
  // width, PRNG, limits, ledger...
  geometry : Type2BoundsSink
}

fn Type2Vm::new(/* retained execution facts */) -> Type2Vm {
  // fixed-capacity fresh stack/transient/frame/PRNG state
  {
    // ...
    geometry: Type2BoundsSink::new(matrix, limits),
    prng: Type2Prng::new(seed),
    // ...
  }
}
```

Replace only the concrete bounds-only geometry field with a private sink mode
or shared protocol. Keep the existing operator loop, width handling, frames,
subroutines, hint masks, arithmetic, and PRNG in one implementation.

**Fresh selected-glyph execution facts** (`cff_type2.mbt:1698-1740`):

```moonbit
fn type2_execute_glyph(
  descriptor : CffGlyphDescriptor,
  global_subrs : CffIndex,
  units_per_em : UInt64,
  limits : Type2Limits,
  opening_revision : UInt64,
) -> Result[Type2VmResult, @error.CoreError] {
  // decode retained widths only for VM validation
  let matrix = type2_matrix_compose(
    descriptor.environment.top_font_matrix,
    descriptor.environment.fd_font_matrix,
    units_per_em,
  )?
  type2_execute_program_with_matrix_unretained(
    descriptor.charstring.view,
    descriptor.environment.local_subrs,
    global_subrs,
    // fresh seed/state and retained matrix...
  )
}
```

Add a path-mode selected-glyph entry around this existing execution authority;
do not reparse CFF and do not create a renderer-only operator switch.

**Tests to copy:** retain the explicit-vs-flex equivalence loop from
`cff_type2_bounds_wbtest.mbt:187-220`, and extend it to compare exact
`CubicTo` sequences. Preserve the empty/move-only invariant from
`cff_type2_bounds_wbtest.mbt:312-317`:

```moonbit
inspect(type2_vm_wb_run(b"\x0E").unwrap().geometry.bounds is None, content="true")
inspect(
  type2_vm_wb_run(b"\x95\x9F\x15\x0E").unwrap().geometry.bounds is None,
  content="true",
)
```

Add path assertions that both produce `Path2.length() == 0` and
`Path2::bounds() is None`.

---

### Atomic outline query: preflight, stage, final revision guard, one commit

**Apply to:** `cff_type2.mbt`, `cff_type2_path.mbt`, `font.mbt`,
`cff_admission.mbt`, `font_wbtest.mbt`, `cff_admission_wbtest.mbt`.

**Primary analogs:** `cff_admission.mbt` and `tables.mbt`

**Admission transaction pattern** (`cff_admission.mbt:1689-1748`):

```moonbit
let executed = type2_stage_all_glyphs_with_probe(
  staged.glyphs,
  staged.global_subrs,
  staged.metrics.units_per_em,
  vm_limits,
  budget,
  source,
  staged.opening_revision,
  glyph_visit_probe,
)?
let combined = cff_combine_staged_charge(staged.charge, executed.charge)?
let ledger = FontAdmissionLedger::new(
  budget,
  FontAdmissionCommitMode::CollectionDeferred,
)
ledger.preflight_atomic(limits.max_work(), combined.work, combined.resource)?
before_final_guard()
if source.mutation_revision() != staged.opening_revision {
  return Err(/* State / font-cff-source-revision-drift */)
}
ledger.commit_atomic(combined.resource)?
Ok(/* complete aggregate only */)
```

Again, production code uses explicit `match`; the shortened excerpt shows the
ordering to copy. The CFF outline query should mirror this exact transaction:

1. initial `Font` revision guard;
2. receiving-font GID range check;
3. read retained descriptor, subroutine views, matrix/limits, and exact
   publishable command capacity;
4. preflight fixed scratch and path backing-store authority before allocation;
5. execute only the selected GID into a private exact-capacity `Path2`;
6. verify emitted count equals retained count;
7. form and preflight the exact combined VM/path `ResourceCharge`;
8. final source revision guard;
9. one `budget.charge`;
10. publish the path.

No sink or VM helper should call `Budget::charge`.

**Ancestor-aware budget primitive** (`modules/mb-core/budget/budget.mbt:314-347`):

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

Use these public primitives; do not implement a CFF-specific ancestor walker.

**Largest-allocation pattern** (`cff_type2.mbt:1831-1859`):

```moonbit
let allocation_size = if bytes > limits.scratch_allocation_size {
  bytes
} else {
  limits.scratch_allocation_size
}
let fixed_authority = @budget.ResourceCharge::new(
  bytes~,
  allocations=base_allocations,
  allocation_size~,
  width=0UL,
  height=0UL,
  pixels=0UL,
  work=0UL,
)
budget.preflight(fixed_authority)?
let bounds : Array[GlyphBoundsFacts?] = Array::new(
  capacity=descriptors.length(),
)
```

The path query should derive allocation count and `allocation_size` from real
VM scratch plus the exact `PathCommand` backing store. Freeze the conservative
per-command capacity unit in tests. Do not change the existing glyf
`command_bound * 32UL` formula (`outline.mbt:420-433`) in this phase.

**Failure test pattern** (`cff_admission_wbtest.mbt:425-462`): inject mutation
immediately before the final guard, assert `State` with the stable revision
context, then compare every budget dimension to its pre-query value. Add
equivalent exact/one-short caller and ancestor tests for selected-glyph path
queries.

---

### Retained CFF common facts and outline-neutral table admission

**Apply to:** `cff_admission.mbt`, `tables.mbt`, `kern.mbt`, `metrics.mbt`.

**Primary analog:** `RequiredTableFacts` plus the current CFF metric retention.

**Common public facts shape** (`tables.mbt:73-80`):

```moonbit
priv struct RequiredTableFacts {
  head : HeadFacts
  maxp : MaxpFacts
  hhea : HheaFacts
  os2 : Os2Facts
  cmap : CmapEnvelope
  kern : KernState
}
```

**Current CFF retention gap** (`cff_admission.mbt:3-28`):

```moonbit
priv struct AdmittedCff1 {
  // CFF structure and glyph descriptors...
  bounds : Array[GlyphBoundsFacts?]
  metrics : CffMetricFacts
  num_glyphs : UInt64
  // exact charges and revision/coordinate authority...
}

priv struct CffMetricFacts {
  hmtx : TableWindow
  units_per_em : UInt64
  num_glyphs : UInt64
  number_of_h_metrics : UInt64
}
```

Extend `AdmittedCff1` with the selected `DirectoryFacts`, complete
outline-neutral `RequiredTableFacts`, retained `KernState`, and compact
per-GID execution facts (bound plus exact publishable command count). Public
`Font` construction must be a non-fallible projection of this post-ledger
aggregate.

**Common decode pattern to extract** (`tables.mbt:2092-2171`):

```moonbit
let head = font_decode_head(head_table)?
let maxp = font_decode_maxp(maxp_table, limits)?
let hhea = font_decode_hhea(hhea_table, maxp)?
let os2 = font_decode_os2(os2_table)?
let cmap = font_admit_cmap_envelope(cmap_table, maxp, limits)?
let kern = match retained_kern {
  Some(value) => value
  None => font_admit_kern(font_optional_table_window(directory, KERN), maxp.num_glyphs)?
}
Ok({ head, maxp, hhea, os2, cmap, kern })
```

Extract an outline-neutral helper accepting an already-decoded
outline-specific `MaxpFacts` and presence policy. Keep the current glyf wrapper
and its work/charge formulas stable. Do not call the current helper unchanged
for CFF because it explicitly requires `glyf` and `loca`
(`tables.mbt:2125-2129`).

**Bounded kern pattern** (`kern.mbt:291-313`):

```moonbit
fn font_admit_kern(
  table : TableWindow?,
  num_glyphs : UInt64,
) -> Result[KernState, @error.CoreError] {
  match table {
    None => Ok(Absent)
    Some(value) => font_kern_classify(value, num_glyphs)
  }
}

fn font_admit_kern_bounded(
  table : TableWindow?,
  num_glyphs : UInt64,
  limits : FontLimits,
  ledger : FontAdmissionLedger,
  base_work : UInt64,
  base_budget_work : UInt64,
) -> Result[KernAdmissionFacts, @error.CoreError] {
  // ...
}
```

Use the bounded variant so CFF kern discovery joins the same combined admission
ledger and commit.

---

### CFF horizontal metrics from face-local `hmtx` plus retained bounds

**Apply to:** `metrics.mbt`, `font.mbt`, `cff_admission_wbtest.mbt`,
`font_test.mbt`, `collection_test.mbt`.

**Primary analog:** glyf `font_lookup_horizontal_metrics`

**Shared hmtx reader** (`metrics.mbt:298-395`):

```moonbit
fn font_read_hmtx_values(
  hmtx : TableWindow,
  num_glyphs : UInt64,
  number_of_h_metrics : UInt64,
  glyph : UInt64,
) -> Result[(UInt64, Int), @error.CoreError] {
  // direct long metric or trailing-bearing lookup
}

fn cff_read_hmtx_metric(
  metrics : CffMetricFacts,
  glyph : UInt64,
) -> Result[(UInt64, Int), @error.CoreError] {
  font_read_hmtx_values(
    metrics.hmtx,
    metrics.num_glyphs,
    metrics.number_of_h_metrics,
    glyph,
  )
}
```

**Bounds/RSB composition pattern** (`metrics.mbt:496-522`):

```moonbit
let (advance_width, left_side_bearing) =
  font_read_hmtx_metric(index, glyph)?
let bounds = font_read_glyph_bounds(index, glyph)?
let extent = match bounds {
  None => 0UL
  Some(value) => font_signed_extent(value.x_min, value.x_max)?
}
let right_side_bearing =
  font_right_side_bearing(advance_width, left_side_bearing, extent)?
Ok({ advance_width, left_side_bearing, bounds, right_side_bearing })
```

Add a closed CFF equivalent using `cff_read_hmtx_metric` and
`admitted.bounds[gid]`; reuse `font_signed_extent` and
`font_right_side_bearing` unchanged. Type 2 width is validation-only.

**Existing authority test** (`cff_admission_wbtest.mbt:508-532`):

```moonbit
let first = cff_read_hmtx_metric(admitted.metrics, 0UL).unwrap()
let second = cff_read_hmtx_metric(admitted.metrics, 1UL).unwrap()
let third = cff_read_hmtx_metric(admitted.metrics, 2UL).unwrap()
inspect(first.0, content="500")
inspect(first.1, content="-20")
inspect(second.0, content="500")
inspect(second.1, content="30")
inspect(third.0, content="500")
inspect(third.1, content="-40")
```

Promote this mismatch fixture through public `Font::horizontal_metrics` and add
non-empty/empty retained-bound cases to prove RSB calculation.

---

### Opaque `Font` construction and closed query dispatch

**Apply to:** `font.mbt`, `font_wbtest.mbt`, `font_test.mbt`.

**Primary analog:** current `Font` facade.

**Closed private source boundary** (`font.mbt:1-17`):

```moonbit
priv enum FontOutlineSource {
  Glyf
  Cff1(AdmittedCff1)
}

fn font_outline_source_from_cff(admitted : AdmittedCff1) -> FontOutlineSource {
  FontOutlineSource::Cff1(admitted)
}
```

Keep this enum private and closed. Move glyph cardinality, horizontal metrics,
and outline decode behind private helpers matching `Glyf` and `Cff1`. Do not
add CFF public types or accessors.

**Common public projection** (`font.mbt:133-166`):

```moonbit
fn font_from_admitted_facts(
  source : @bytes.ByteView,
  opening_revision : UInt64,
  directory : DirectoryFacts,
  tables : RequiredTableFacts,
  metric_index : MetricIndexFacts,
  limits : FontLimits,
) -> Font {
  {
    source,
    opening_revision,
    units_per_em_value: tables.head.units_per_em,
    global_bounds_value: { /* head bounds */ },
    hhea_line_metrics_value: { /* hhea */ },
    typographic_line_metrics_value: { /* OS/2 */ },
    directory,
    tables,
    metric_index,
    limits,
    outline_source: FontOutlineSource::Glyf,
  }
}
```

Add a private CFF constructor that projects the same common fields from the
complete `AdmittedCff1` and sets `FontOutlineSource::Cff1(admitted)`. It should
not parse, allocate, preflight, or fail after CFF admission commits.

**Guard/validation/publication ordering** (`font.mbt:608-643`):

```moonbit
match self.require_revision("font-outline") {
  Err(error) => return Err(error)
  Ok(_) => ()
}
if glyph.value_value >= self.metric_index.num_glyphs {
  return Err(font_glyph_id_error(/* font-outline */))
}
let path = font_decode_outline(/* glyf facts */)?
after_decode(path)
match self.require_revision("font-outline") {
  Err(error) => return Err(error)
  Ok(_) => ()
}
Ok(path)
```

Preserve this public ordering and stable operation/context values. Replace the
hard-coded glyf cardinality/decode with private closed helpers:

```moonbit
match self.outline_source {
  Glyf => font_decode_outline(/* existing byte-for-byte glyf arm */)
  Cff1(admitted) => cff_decode_outline_atomic(/* retained facts */)
}
```

The CFF helper owns its exact one-commit budget transaction. The outer method
still performs the final `Font` revision guard immediately before return.

**Standalone routing:** branch after bounded directory/profile classification
and before the existing glyf semantic commit. A supported `OTTO` static CFF1
profile calls `admit_cff1_structure`; the glyf branch from `font.mbt:315-363`
must remain behaviorally unchanged.

---

### Standalone and collection route convergence without rebasing

**Apply to:** `collection.mbt`, `font.mbt`, `collection_wbtest.mbt`,
`collection_test.mbt`.

**Primary analog:** current retained-face routing plus selected CFF admission.

**Already-retained authority** (`collection_parser.mbt:3-9`):

```moonbit
priv struct CollectionFaceFacts {
  directory_start : UInt64
  directory_end : UInt64
  table_count : UInt64
  sfnt_version : UInt64
  profile : FontFaceProfile
}
```

**Existing CFF classification** (`collection_parser.mbt:1737-1769`):

```moonbit
let profile = if has_variation {
  FontFaceProfile::Variable
} else if sfnt_version == 0x4F54544FUL && has_cff2 /* ... */ {
  FontFaceProfile::Cff2
} else if sfnt_version == 0x4F54544FUL && has_cff /* no mixed outlines */ {
  FontFaceProfile::Cff
} else if sfnt_version == 0x00010000UL && has_glyf && has_loca /* ... */ {
  FontFaceProfile::StaticGlyf
} else {
  FontFaceProfile::OtherUnsupported
}
Ok({ directory_start, directory_end, table_count, sfnt_version, profile })
```

No parser change is needed. Table-record offsets remain root-relative because
`font_collection_scan_face` reads `table_offset` directly against the retained
root (`collection_parser.mbt:1657-1700`).

**Current route to extend** (`collection.mbt:187-214`):

```moonbit
match self.require_revision("font-collection-open-face") {
  Err(error) => return Err(error)
  Ok(_) => ()
}
// index validation...
let face = self.faces[narrowed]
if face.profile != FontFaceProfile::StaticGlyf {
  return Err(font_collection_profile_error())
}
font_open_collection_face(
  self.source,
  self.opening_revision,
  face,
  limits,
  budget,
  before_selected_loop,
  before_final_guard,
)
```

Replace the final profile check with a closed match:

```moonbit
match face.profile {
  StaticGlyf => font_open_collection_face(/* existing arm unchanged */)
  Cff => admit/promote selected CFF using:
    self.source,
    self.opening_revision,
    face.directory_start,
    face.table_count,
    FontChecksumMode::Collection
  _ => Err(font_collection_profile_error())
}
```

The selected CFF admission seam currently captures a fresh revision internally
(`cff_admission.mbt:1157`). Adjust it to accept the collection's retained
`opening_revision` as the authoritative revision rather than recapturing a new
identity. Preserve the same root `ByteView`; never create a face subview/copy.

**Selected CFF admission analog** (`cff_admission.mbt:1806-1827`):

```moonbit
admit_cff1_structure_at_after_preflight(
  source,
  directory_start,
  Some(expected_table_count),
  FontChecksumMode::Collection,
  true,
  limits,
  budget,
  gid,
  before_final_guard,
  fn() { () },
  fn() { () },
)
```

Promote the complete result to `Font` without another parsing or charging pass.

---

### Compatibility and fixture patterns

**Apply to:** all test files listed in the classification table.

**Glyf standalone fingerprint** (`font_test.mbt:1374-1396`):

```moonbit
let font = Font::open(owner.view(), font_test_limits(), budget).unwrap()
let glyph = font.glyph_id(0UL).unwrap()
inspect(font.units_per_em().unwrap(), content="1000")
inspect(font.glyph_for_scalar(65).unwrap().value(), content="0")
let metrics = font.horizontal_metrics(glyph).unwrap()
inspect(metrics.advance_width(), content="500")
inspect(metrics.left_side_bearing(), content="0")
inspect(font.kerning(glyph, glyph).unwrap(), content="0")
inspect(font.outline(glyph, font_test_outline_budget()).unwrap().length(), content="0")
```

Extend this fingerprint to freeze exact path commands, error
category/code/operation/context, and every budget dimension. Do not replace it
with only CFF-positive tests.

**Glyf collection fingerprint** (`collection_test.mbt:810-845`) already covers
face count/profile, common queries, metrics, kerning, outline, and budget
consumption. Preserve it unchanged and add parallel public CFF cases.

**Shared-CFF TTC fixture pattern** (`collection_wbtest.mbt:1154-1199`):

```moonbit
fn font_collection_wb_shared_cff_ttc() -> Bytes {
  let standalone = cff_wb_otf(cff_name_wb_table(), num_glyphs=3UL)
  // build two face directories
  // copy table records but convert each offset to retained-root coordinates
  font_collection_wb_put_u32(
    output,
    directory + record + 8,
    payload.to_uint64() + old_offset,
  )
  Bytes::from_array(output)
}
```

Extend this fixture so two faces share the CFF table but have distinct
face-local `cmap`, `hmtx`, and `kern` records. Assert:

- both faces use the shared CFF charstrings;
- each face returns its own mapping/metrics/kerning;
- standalone and selected forms of the same face return identical public
  commands and query facts;
- directory/table offsets remain correct internally;
- exact and every one-short budget fail atomically;
- mutation before/during/final guard publishes and charges nothing.

**Existing exact/one-short selected-CFF test style**
(`collection_wbtest.mbt:1224-1324`): obtain one successful aggregate, run one
exact budget, then loop over bytes/allocations/allocation-size/work one-short
cases and compare all remaining counters. Reuse that structure for public
`open_face` and `Font::outline`.

## Shared Patterns

### Error propagation

Use explicit `match` on `Result`, returning the original `CoreError` unless the
existing seam deliberately remaps a low-level error to a stable font context.
Keep the established precedence:

1. retained source `State` drift;
2. caller/ancestor `Resource` authority;
3. unsupported `Capability`;
4. malformed `Data`;
5. public invalid GID/scalar checks in their existing operation order.

Do not add a public CFF error enum.

### Imports and package qualification

These MoonBit files do not use per-file import blocks. Same-package private
symbols are referenced directly; cross-package APIs use established aliases:

```moonbit
@bytes.ByteView
@budget.Budget
@budget.ResourceCharge
@checked.checked_add
@error.CoreError
@math.Path2
@math.PathCommand::CubicTo
@math.Point2
```

Use the existing aliases from the package manifest; do not add dependencies.

### Revision authority

- Standalone `Font::open` captures one revision and CFF admission must use it
  through the final commit.
- `FontCollection::open_face` must pass `self.opening_revision` into selected
  CFF admission.
- A selected query guards before execution and again immediately before commit
  and public return.
- Mutation restoration still counts as drift because `mutation_revision`
  changes.

### Resource authority

- Preflight all fixed capacities before allocation.
- Track real scratch arrays, path backing-store capacity, total allocations,
  largest single allocation, and stable work.
- Preflight caller and every ancestor through `Budget::preflight`.
- Commit once through `Budget::charge`.
- Failed queries return no `Path2` and leave every budget counter unchanged.
- Keep existing glyf incremental charge behavior and constants unchanged.

### Public format neutrality

All common queries continue through `Font`:

- `glyph_for_scalar` uses retained `cmap`;
- `GlyphId` remains a numeric GID validated by the receiving font;
- `horizontal_metrics` uses face-local `hmtx` plus outline-specific bounds;
- `kerning` uses retained face-local `KernState`;
- `outline` privately dispatches `Glyf | Cff1`;
- all returned geometry is the existing `Path2`.

## Composite Analog / No Single Exact Analog

| File | Role | Data Flow | Composite Sources | Planner Guidance |
|---|---|---|---|---|
| `modules/mb-font/font/cff_type2_path.mbt` | service / sink | streaming transform | `cff_type2_bounds.mbt:21-42,231-395` + `outline.mbt:408-507` + `path.mbt:13-52` | Share exact geometry state with bounds; copy only typed path lowering; add deferred moveto and atomic staging. |
| `modules/mb-font/font/cff_type2_path_wbtest.mbt` | test | streaming transform | `cff_type2_bounds_wbtest.mbt:76-220,287-317` + `path_wbtest.mbt:4-25,102-119` | Assert exact native `CubicTo` sequences, flex equivalence, transformed coordinates, empty/move-only paths, and exact counts. |

There are no files with no usable codebase analog. The two new path-sink files
need a deliberate composite rather than copying one existing file wholesale.

## Planner Guardrails

- Treat `collection_parser.mbt` as reference-only unless implementation proves
  a missing retained fact; current research says no structural change is
  needed.
- Do not generalize or rewrite `outline.mbt`; use it only as the typed
  `PathCommand` lowering and compatibility analog.
- Do not retain admission-time path commands. Retain only compact per-GID
  bounds and exact publishable command capacity.
- Do not use retained bounds to reconstruct paths.
- Do not use Type 2 width for public metrics.
- Do not call the glyf-only common-table helper unchanged for CFF.
- Do not recapture a collection revision inside selected CFF admission.
- Do not perform fallible common-table work after the combined CFF ledger
  commits.

## Metadata

**Analog search scope:**

- `modules/mb-core/math`
- `modules/mb-core/budget`
- `modules/mb-font/font`

**Primary source files read:** 18 production/test files plus phase context and
research.

**Knowledge graph result:** the required `codebase-memory-mcp` graph was queried
first. The workspace index exposed file/section nodes but no MoonBit
function/type nodes for the requested symbols, so discovery fell back to
targeted `rg` symbol searches and non-overlapping line-numbered source reads.

**Pattern extraction date:** 2026-07-29
