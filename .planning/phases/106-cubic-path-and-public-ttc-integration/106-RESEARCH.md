# Phase 106: Cubic Path and Public/TTC Integration - Research

**Researched:** 2026-07-29
**Domain:** Static OpenType CFF1 publication through format-neutral MoonBit font and cubic-path APIs
**Confidence:** HIGH for repository seams and locked behavior; MEDIUM for the final capacity-byte constant and rational-to-`Double` policy

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Existing Public Contract and Private Dispatch
- **D-01:** Keep `Font::open`, `FontCollection::open_face`, and `Font::outline(GlyphId, Budget) -> Result[Path2, CoreError]` as the sole public workflows. Do not add a CFF-specific font, glyph, metric, or outline API.
- **D-02:** Dispatch privately through the existing closed `FontOutlineSource::Glyf | Cff1(AdmittedCff1)` boundary. Public callers must not observe CFF INDEX, DICT, FDSelect, subroutine, width, or execution-environment types.
- **D-03:** A `GlyphId` remains an opaque numeric GID owned by the receiving `Font`; Unicode mapping, glyph range checks, and kerning lookup use the same public operations and ordering for glyf and CFF1.

### Cubic Path Fidelity
- **D-04:** Reuse the Phase 105 Type 2 interpreter and operator/frame semantics through a path-capable geometry sink. Do not create a second interpreter and do not retain or replay an admission-time command stream.
- **D-05:** Emit native `PathCommand::MoveTo`, `LineTo`, `CubicTo(control1, control2, end)`, and `Close` commands. Never approximate Type 2 cubics as quadratics and never flatten curves.
- **D-06:** Apply the effective exact Top/FD FontMatrix and design-unit normalization before emission, keep coordinates exact through VM/sink arithmetic, and convert to `Point2` `Double` values only at the `Path2` boundary using one deterministic checked conversion rule.
- **D-07:** Preserve Phase 105 contour semantics: a new moveto closes the prior geometric contour and legal endchar closes the final geometric contour. A glyph with no drawing segments returns an empty `Path2`; move-only contours must not create misleading public bounds.

### Atomic Query and Resource Authority
- **D-08:** A CFF outline query executes only the selected admitted glyph with fresh operand, transient, frame, PRNG, and path state. Admission still retains compact bounds and immutable execution facts, never full paths.
- **D-09:** Guard the retained source revision before execution and before return. Stage the complete path and its exact named VM/path charge, preflight caller and ancestor authority, perform the final revision guard, then commit once and publish; any failure returns no `Path2` and leaves the query transaction uncommitted.
- **D-10:** Account for real path-command storage and any sink scratch allocation, including largest single allocation and backing-store capacity. Hidden `Array` growth must not exceed charged authority; a minimal format-neutral capacity-aware `Path2` construction seam is allowed if required.
- **D-11:** Reuse the admitted glyph descriptor, global/local subroutine views, matrix, limits, and deterministic initial state. Query execution must not reparse CFF structure, change admission results, or use retained bounds as a substitute for emitting geometry.

### Standalone and TTC/OTC Admission
- **D-12:** Route a supported standalone `OTTO` + static CFF1 profile into the existing complete CFF admission transaction before any glyf-only semantic commit. Construct the public `Font` only from the complete post-ledger `AdmittedCff1`.
- **D-13:** Extend `FontCollection::open_face` to accept the already-classified static `FontFaceProfile::Cff` case and call the same selected-face CFF admission using the retained collection root, face directory start, and expected table count.
- **D-14:** Preserve root-relative TTC/OTC table-record authority and table-local CFF offsets without copying the selected face. Shared CFF bytes may coexist with face-local common tables; CFF2, variable, mixed, and other unsupported profiles remain rejected.

### Format-Neutral Metrics, Errors, and Compatibility
- **D-15:** CFF-backed `Font` retains the same common `head`, `hhea`, `OS/2`, `cmap`, `hmtx`, and `kern` facts as glyf-backed fonts. Horizontal metrics use face-local `hmtx` plus the retained CFF bounds slot; Type 2 width remains validation-only.
- **D-16:** Preserve public operation names, `CoreError` category/code behavior, mutation precedence, and glyph-range behavior. Stable CFF-specific diagnostic contexts may remain internal details, but no new public error enum or CFF inspection surface is introduced.
- **D-17:** Existing static-glyf standalone and collection admission, metrics, mappings, kerning, outline commands, error ordering, and exact resource charges stay on their current branch and must be frozen by compatibility tests.
- **D-18:** Reuse existing `FontLimits` and `Budget`; do not add public CFF or Type 2 limit types in this phase.

### the agent's Discretion
- Exact private sink/protocol type names, file boundaries, and whether path capacity is provided by a small `mb-core` constructor or a private staged-command assembler.
- Exact fixed work-unit constants for path emission, provided they are stable, independently testable, and charge real execution/allocation.
- Test fixture organization between standalone CFF, collection CFF, public integration, and frozen glyf compatibility suites.

### Deferred Ideas (OUT OF SCOPE)
- Phase 107 owns licensed Latin/CJK assets, generated/hostile matrix completion, performance baselines, independent oracles, and exact four-target qualification.
- CFF2/variation execution, deprecated seac composition, WOFF, shaping/bidi, hint rendering, rasterization, color/bitmap glyphs, authoring, discovery, and ambient I/O remain outside v0.34.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CFF-04 | A successfully admitted standalone static CFF1 font is returned as the existing opaque `Font`; mapping, glyph identity, metrics, kerning, errors, and atomic cubic paths remain format-neutral. | The public-construction, common-facts, metric-dispatch, single-VM/two-sink, capacity, and atomic-query seams below map directly to this requirement. [VERIFIED: REQUIREMENTS.md + codebase inspection] |
| CFF-05 | A supported selected TTC/OTC CFF1 face uses the same implementation, preserves root/table coordinate spaces and face-local common tables, and leaves static-glyf behavior unchanged. | The selected-face routing, retained-root revision authority, shared-CFF/face-local-facts tests, and frozen-glyf gates below map directly to this requirement. [VERIFIED: REQUIREMENTS.md + codebase inspection] |
</phase_requirements>

## Summary

Phase 106 is an integration/refactor phase, not a new parser or VM. The verified Phase 105 interpreter already owns all operator, frame, fixed-point, matrix, contour, mutation, and geometry-limit semantics, but `Type2Vm.geometry` is concretely typed as `Type2BoundsSink`; the correct first task is to separate shared absolute-geometry state from sink-specific accumulation and add a path sink without duplicating the operator switch. [VERIFIED: `cff_type2.mbt`, `cff_type2_bounds.mbt`, 105-VERIFICATION.md]

There is a second, less visible prerequisite: `AdmittedCff1` retains CFF structure, per-GID descriptors, bounds, and a narrow `CffMetricFacts`, but it does not retain the parsed `DirectoryFacts` or `RequiredTableFacts`; `cff_validate_common_tables` validates and then discards `head`, `hhea`, `OS/2`, `cmap`, `name`, and `post`, and it does not admit/retain `kern`. Public CFF construction therefore must be preceded by a CFF common-facts refactor inside the existing admission transaction, including exact work/allocation authority for `kern`; reparsing these tables after the CFF ledger commits would violate the locked atomic/no-reparse boundary. [VERIFIED: `cff_admission.mbt:3-28,322-405`, `tables.mbt:73-80,2092-2171`]

**Primary recommendation:** implement in four dependency-ordered plans: (1) capacity-aware `Path2` plus one shared geometry core and two sinks, (2) retain full CFF common/query facts and add CFF metric/outline dispatch, (3) route standalone and selected collection admission through complete CFF transactions, and (4) close exact resource/mutation/error and frozen-glyf compatibility matrices. [VERIFIED: CONTEXT.md + codebase inspection]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Type 2 relative-to-absolute geometry and contour lifecycle | Font library / VM | — | The existing VM and bounds sink already own the authoritative current point, control-point arithmetic, transform, and contour limits. [VERIFIED: `cff_type2.mbt`, `cff_type2_bounds.mbt`] |
| Cubic `Path2` storage | Shared `mb-core` geometry | Font library / path sink | `Path2` owns the private command array; `mb-font` should request exact capacity and emit only public format-neutral commands. [VERIFIED: `modules/mb-core/math/path.mbt:13-52`] |
| Standalone CFF profile routing | Font facade | CFF admission | `Font::open` is the public entry point; the CFF admission transaction must finish before a `Font` is constructed. [VERIFIED: CONTEXT.md D-12 + `font.mbt:297-364`] |
| TTC/OTC selected-face routing | Collection facade | CFF admission | `FontCollection` owns face identity/root revision while CFF admission owns the selected face directory and table-local CFF view. [VERIFIED: `collection.mbt:152-216`, `collection_parser.mbt:3-9`] |
| Format-neutral mapping/kerning/metrics | Font common-facts layer | Closed outline source | `cmap` and `kern` remain common; only glyph bounds and outline decoding branch by outline source. [VERIFIED: `font.mbt:440-643`, CONTEXT.md D-15] |
| Query budget/revision transaction | Font outline facade | VM/path sink | The facade owns caller/ancestor `Budget` and final publication; the VM/sink reports a complete named charge without committing it. [VERIFIED: CONTEXT.md D-09 + `font.mbt:608-643`] |

## Project Constraints (from AGENTS.md)

- Core algorithms and shared data models must remain pure MoonBit; no foreign font stack or FFI implementation is appropriate for this phase. [VERIFIED: AGENTS.md]
- Native remains the primary target while portable behavior must stay deterministic behind capability boundaries. [VERIFIED: AGENTS.md]
- Public-package dependencies must remain acyclic and explicit; the existing `mb-font -> mb-core` direction must not be reversed. [VERIFIED: AGENTS.md + module inspection]
- Public API compatibility follows Semantic Versioning; CFF details must remain private and experimental internals must not leak. [VERIFIED: AGENTS.md + CONTEXT.md]
- Public operations must be deterministic and GUI/ambient-I/O independent; benchmarks require declared reproducible workloads. [VERIFIED: AGENTS.md]
- Code discovery used the required codebase-memory graph first; the graph exposed only file/section nodes for MoonBit, so targeted source inspection was the permitted fallback. [VERIFIED: codebase-memory-mcp result + AGENTS.md]

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| MoonBit `moon` / `moonrun` | `0.1.20260713` (`75c7e1f`) | Build and test the existing four-target codebase. | Present locally and matches the project pin. [VERIFIED: local CLI + AGENTS.md] |
| `moonc` | `v0.10.4+2cc641edf` | Compile MoonBit source. | Present locally and matches the project pin. [VERIFIED: local CLI + AGENTS.md] |
| `tchivs/mb-core` | workspace `0.1.0` | `ByteView`, `Budget`, checked errors, `Point2`, `Path2`, and `PathCommand`. | It is the existing sole runtime foundation; no new dependency is needed. [VERIFIED: codebase inspection] |
| `tchivs/mb-font` | workspace `0.1.0` | Existing opaque font/collection public API and private CFF implementation. | All required seams already live in this package. [VERIFIED: codebase inspection] |

### Supporting

| Source | Version | Purpose | When to Use |
|--------|---------|---------|-------------|
| OpenType specification | 1.9.1 | CFF/OpenType GID identity, required common tables, `hmtx`, and TTC offsets. | Use for public integration and collection-coordinate tests. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/cff] |
| Adobe Technical Note #5177 | 16 Mar 2000 revision | Type 2 cubic, moveto, flex, and endchar behavior. | Use only to verify already-locked path semantics, not to reopen Phase 105 decisions. [CITED: https://adobe-type-tools.github.io/font-tech-notes/pdfs/5177.Type2.pdf] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| One VM with private sink dispatch | A second renderer/interpreter | Forbidden by D-04 and would permit validator/renderer drift. [VERIFIED: CONTEXT.md] |
| Exact-capacity `Path2` construction | Append to `Path2::new()` and charge a guessed final size | Hidden growth can exceed caller authority and violates D-10. [VERIFIED: `path.mbt:38-52` + CONTEXT.md] |
| Retained common facts | Reparse common tables when wrapping `AdmittedCff1` | Creates fallible work after the admission commit and violates D-11/D-12. [VERIFIED: CONTEXT.md + codebase inspection] |

**Installation:** none. This phase must add no external package, runtime dependency, FFI library, or host tool. [VERIFIED: AGENTS.md + CONTEXT.md]

## Architecture Patterns

### System Architecture Diagram

```text
caller ByteView + FontLimits + Budget
            |
            v
      public entry profile branch
       /                         \
static glyf (frozen)        OTTO static CFF1
       |                         |
existing glyf admission      complete CFF admission
                             structure + all-glyph VM
                             + retained common facts
                             + compact per-GID execution facts
       \                         /
        \                       /
         closed FontOutlineSource
          Glyf | Cff1(AdmittedCff1)
                    |
         public format-neutral queries
         cmap / GID / kern / metrics
                    |
        Font::outline(selected GID, Budget)
                    |
    opening revision guard + capacity preflight
                    |
          sole Type 2 VM/operator switch
                    |
          shared absolute geometry core
             /                 \
     admission bounds sink   query path sink
                                  |
                     exact transformed rational points
                                  |
                    checked rational -> Double boundary
                                  |
                      staged native cubic Path2
                                  |
              exact charge preflight -> final guard
                                  |
                       one commit -> publish

FontCollection retained root
  -> face profile Cff
  -> same CFF admission(directory_start, expected_table_count,
                        collection checksum mode, retained opening revision)
```

This flow preserves the existing glyf branch and makes the same admitted CFF state serve standalone and selected collection workflows. [VERIFIED: CONTEXT.md + codebase inspection]

### Recommended Project Structure

```text
modules/mb-core/math/
├── path.mbt                     # add exact-capacity constructor only
└── path_wbtest.mbt              # freeze capacity/length behavior

modules/mb-font/font/
├── cff_type2.mbt                # sole VM, sink-neutral dispatch, query result/charge
├── cff_type2_bounds.mbt         # shared geometry core + admission bounds accumulator
├── cff_type2_path.mbt           # new private Path2 accumulator/conversion/charge
├── cff_admission.mbt            # retained common and compact per-GID execution facts
├── tables.mbt / kern.mbt        # reusable CFF common-facts + bounded kern admission
├── metrics.mbt                  # CFF hmtx + retained-bound metric lookup
├── font.mbt                     # standalone construction and closed query dispatch
├── collection.mbt               # Cff selected-face route
└── *_test.mbt / *_wbtest.mbt    # public, hostile, exact-charge, and compatibility gates
```

The exact new file name is discretionary; keeping path-only logic separate avoids inflating the already large VM file. [VERIFIED: CONTEXT.md discretion + codebase inspection]

### Pattern 1: Shared geometry core with deferred contour publication

**What:** move current point, contour start/open/has-segments, point/contour/command limits, relative coordinate addition, and matrix application into one sink-neutral geometry state. Bounds and path accumulators receive the same absolute exact points. [VERIFIED: `cff_type2_bounds.mbt:21-42,231-395`]

**When to use:** every moveto, line, cubic, flex-lowered cubic, and endchar path event. [VERIFIED: `cff_type2.mbt:565-739,839-1130`]

**Critical rule:** stage a moveto as pending; append `MoveTo` only when the contour emits its first line/cubic, append `Close` only for a non-empty contour, and discard a move-only contour. This is required because current `Path2::bounds` counts `MoveTo` points, while D-07 requires move-only glyphs to return an empty path with no misleading bounds. [VERIFIED: `path.mbt:76-180`, CONTEXT.md D-07]

### Pattern 2: Retain compact path-capacity facts, never command streams

Admission should retain at least an exact publishable-path command count per GID beside the existing optional bound. That count is an immutable execution fact, not a command replay stream, and lets the query preflight and allocate an exact-capacity `Path2` before executing the selected glyph once. [VERIFIED: CONTEXT.md D-08/D-10 + current all-glyph execution in `cff_type2.mbt:1766-2106`]

Recommended private shape:

```moonbit
// Recommended shape; names are discretionary.
priv struct CffGlyphExecutionFacts {
  bounds : GlyphBoundsFacts?
  path_commands : UInt64
}

pub fn Path2::with_capacity(capacity : Int) -> Path2 {
  { commands: Array::new(capacity~) }
}
```

`Array::new(capacity=...)` is an official MoonBit construction form, but the project must freeze the exact capacity/charge contract with tests because the documentation does not expose a portable capacity introspector. [CITED: https://docs.moonbitlang.com/ja/latest/language/fundamentals.html]

### Pattern 3: One post-ledger CFF aggregate owns all public query facts

Refactor `cff_validate_common_tables` into a retained common-facts admission that returns the CFF-compatible `MaxpFacts`, `HeadFacts`, `HheaFacts`, `Os2Facts`, selected `CmapEnvelope`, `KernState`, `CffMetricFacts`, and `DirectoryFacts` inside `AdmittedCff1`. The exact bounded `kern` discovery/admission work must join the same combined CFF charge before commit. [VERIFIED: current discard gap in `cff_admission.mbt:322-405`; reusable logic in `tables.mbt:255-601,2092-2171`]

Do not call the existing `font_admit_required_tables_impl` unchanged: it requires `glyf`/`loca` and decodes TrueType `maxp` 1.0 fields. Extract a common helper that accepts already-decoded outline-specific `MaxpFacts` and an outline-profile presence policy, leaving the glyf wrapper and its charge path unchanged. [VERIFIED: `tables.mbt:2101-2139,2125-2129`; `cff_admission.mbt:294-318`]

### Pattern 4: Closed source dispatch owns glyph cardinality, bounds, and outlines

The least disruptive facade refactor is to make the closed outline source carry the glyf metric index as well as the CFF aggregate:

```moonbit
priv enum FontOutlineSource {
  Glyf(MetricIndexFacts)
  Cff1(AdmittedCff1)
}
```

Then add private helpers for `num_glyphs`, horizontal metrics, and outline decode. The glyf arms call the existing functions byte-for-byte; the CFF metric arm uses face-local `hmtx` plus the retained bound and existing `font_right_side_bearing`; the CFF outline arm executes the retained descriptor through the path sink. [VERIFIED: `font.mbt:8-16,483-535,618-643`; `metrics.mbt:275-395,496-523`]

### Pattern 5: Preflight before allocation, commit only after complete staging

For a CFF outline query:

1. guard `Font.opening_revision`;
2. validate GID with the same current ordering;
3. obtain retained exact path-command capacity and derive scratch/path allocation authority;
4. non-consumingly preflight caller and ancestors before allocating;
5. execute the selected descriptor once with fresh VM/path state;
6. verify emitted command count equals retained capacity;
7. form one exact query charge from executed VM work plus path work and all allocations;
8. preflight the exact charge, perform the final source revision guard, call `budget.charge` once, and return the staged path. [VERIFIED: CONTEXT.md D-08–D-11 + existing admission preflight pattern in `cff_type2.mbt:1836-1859,2063-2106`]

The path sink must never call `Budget::charge`; only the public outline transaction commits. [VERIFIED: CONTEXT.md D-09]

### Anti-Patterns to Avoid

- **Genericizing `outline.mbt`:** keep the glyf decoder and its incremental charge behavior unchanged; dispatch above it. [VERIFIED: CONTEXT.md D-17]
- **Immediate `MoveTo` append:** a move-only program would create a non-empty path and public point bound. [VERIFIED: `path.mbt:84-104`, CONTEXT.md D-07]
- **Retained-bounds replay:** bounds do not contain cubic controls or contour order and cannot produce a path. [VERIFIED: `GlyphBoundsFacts` + CONTEXT.md D-11]
- **Post-commit common-table parsing:** creates new failure/mutation/resource states after CFF admission has committed. [VERIFIED: CONTEXT.md D-11/D-12]
- **Collection subview/copy:** selected CFF admission already accepts root, directory start, expected count, and collection checksum mode; copying would lose root-relative authority. [VERIFIED: `cff_admission.mbt:1806-1849`]
- **Recapturing collection revision inside selected admission:** the selected CFF route should accept/validate the `FontCollection.opening_revision` so a race cannot establish a new root identity between `open_face`'s guard and CFF staging. [VERIFIED: current gap across `collection.mbt:187-216` and `cff_admission.mbt:1157-1171`]

## Concrete File and Function Seams

| File | Existing seam | Required Phase 106 change |
|------|---------------|---------------------------|
| `modules/mb-core/math/path.mbt` | `Path2::new`, private `commands`, `push` | Add one format-neutral exact-capacity constructor; keep existing methods and behavior unchanged. [VERIFIED: codebase inspection] |
| `cff_type2_bounds.mbt` | `Type2BoundsSink::{move_relative,preflight_segments,line_relative_unchecked,cubic_relative_unchecked,close,facts}` | Extract shared state/event math; preserve admission counts/bounds goldens and add exact publishable command count. [VERIFIED: codebase inspection] |
| `cff_type2.mbt` | `Type2Vm.geometry : Type2BoundsSink`, `Type2Vm::new`, `type2_execute_program_with_matrix_and_read_probe`, `type2_execute_glyph` | Parameterize private sink mode without duplicating the loop; return path/query ledger facts for one selected GID. [VERIFIED: codebase inspection] |
| `cff_admission.mbt` | `AdmittedCff1`, `cff_validate_common_tables`, `type2_stage_all_glyphs_with_probe`, `admit_cff1_structure*` | Retain directory/full common query facts, compact per-GID path capacity, and exact kern/common charges; allow selected admission to validate the collection's retained revision. [VERIFIED: codebase inspection] |
| `tables.mbt` / `kern.mbt` | glyf-oriented `font_admission_charge*`, `font_admit_required_tables_impl`, bounded kern helpers | Extract outline-neutral common-facts/kern admission helpers; do not change the glyf wrappers or formulas. [VERIFIED: codebase inspection] |
| `metrics.mbt` | `cff_read_hmtx_metric`, existing bound/RSB helpers | Add CFF metric lookup from retained bound array; preserve common glyph-range and RSB arithmetic. [VERIFIED: codebase inspection] |
| `font.mbt` | `FontOutlineSource`, `font_from_admitted_facts`, `Font::open`, common queries, `outline_after_decode` | Add CFF constructor/standalone branch and closed helpers; maintain operation names, validation order, and glyf arms. [VERIFIED: codebase inspection] |
| `collection.mbt` | `open_face_after_preflights` accepts only `StaticGlyf` | Match `StaticGlyf` to the current function, `Cff` to selected CFF admission, and all other profiles to the existing capability error. [VERIFIED: `collection.mbt:204-216`] |
| `collection_parser.mbt` | retains `directory_start`, `table_count`, `sfnt_version`, `profile`; table records are root-relative | No structural redesign; consume the already-retained CFF face facts. [VERIFIED: `collection_parser.mbt:3-9,1492-1769`] |

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Type 2 execution | A renderer-only interpreter | Existing `Type2Vm` loop/operator/frame implementation | Phase 105 has verified arithmetic, calls, hints, random, limits, and errors. [VERIFIED: 105-VERIFICATION.md] |
| Matrix/coordinate arithmetic | Floating-point transform inside operators | `type2_matrix_compose` and `type2_matrix_apply` exact rationals | Prevents bounds/path divergence and early target-dependent rounding. [VERIFIED: `cff_type2_fixed.mbt:625-681`] |
| Collection offsets | A selected-face copied buffer or rebased directory | Existing root `ByteView` plus `directory_start` and `expected_table_count` | OpenType table offsets in TTC directories are root-relative. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/otff#ttc-header] |
| Horizontal metrics | Type 2 width as advance | Existing `hmtx` readers and RSB helper | `hmtx` records are indexed by GID and define advance/LSB; Type 2 width remains validation-only by decision. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/hmtx] |
| Path capacity | Unbounded append/growth | Exact retained command count plus capacity-aware `Path2` | Required for truthful allocation-size and ancestor authority. [VERIFIED: CONTEXT.md D-10] |
| Common queries | CFF-specific public accessors | Existing `Font` common facts and operations | CFF GID is the OpenType glyph index and public workflows are locked format-neutral. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/cff] |

**Key insight:** the phase succeeds by reusing already-verified authorities and moving the format branch inward; every parallel parser, interpreter, public type, or collection adapter would create a second semantic authority. [VERIFIED: CONTEXT.md + codebase inspection]

## Common Pitfalls

### Pitfall 1: Public CFF font is built without retained `cmap`/`kern`
**What goes wrong:** `glyph_for_scalar` or `kerning` cannot use the same common query path, or common tables are reparsed after the CFF commit. [VERIFIED: current `AdmittedCff1` fields and `Font` fields]
**How to avoid:** retain complete CFF-compatible `RequiredTableFacts` and directory facts inside the admission result; include bounded kern work before commit. [VERIFIED: recommended from code gap + CONTEXT.md D-15]

### Pitfall 2: Move-only contours leak as public geometry
**What goes wrong:** immediate `MoveTo` emission makes `Path2.length() > 0` and `Path2::bounds()` return a point for a glyph Phase 105 treats as boundless. [VERIFIED: `path.mbt:76-180`, `cff_type2_bounds_wbtest.mbt`]
**How to avoid:** pending moveto, flush on first segment, close only non-empty contours. [VERIFIED: CONTEXT.md D-07]

### Pitfall 3: Path allocation is charged after hidden growth
**What goes wrong:** `Path2::new().push(...)` may grow its private array before final authority is known. [VERIFIED: `path.mbt:32-52`]
**How to avoid:** retain exact publishable command count during admission, preflight it, and construct the query path with that exact capacity. [VERIFIED: CONTEXT.md D-08–D-10]

### Pitfall 4: CFF public open double-charges or commits then performs fallible work
**What goes wrong:** wrapping `AdmittedCff1` through glyf admission helpers reparses tables, charges twice, or can fail after CFF has committed. [VERIFIED: current separate admission paths]
**How to avoid:** make public construction a non-fallible projection of the complete post-ledger aggregate; any needed common facts and allocations belong inside CFF admission. [VERIFIED: CONTEXT.md D-12]

### Pitfall 5: Selected collection admission captures a new revision
**What goes wrong:** a mutation between the collection guard and CFF admission capture can establish a revision different from the retained collection identity. [VERIFIED: current call sequence]
**How to avoid:** pass the collection's opening revision into selected CFF staging and make it authoritative from the first CFF check through the final commit. [VERIFIED: CONTEXT.md D-13/D-14]

### Pitfall 6: Shared CFF table incorrectly supplies common facts
**What goes wrong:** two collection faces sharing CFF bytes accidentally share `cmap`, `hmtx`, or `kern` state that belongs to their separate directories. [VERIFIED: existing shared-CFF/face-local-hmtx fixture]
**How to avoid:** parse every common table from the selected face directory while CFF internal offsets remain local to the shared CFF `TableWindow`. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/otff#ttc-header]

### Pitfall 7: Glyf behavior changes during facade cleanup
**What goes wrong:** changed enum/metric plumbing alters current incremental charge, error precedence, or quadratic commands. [VERIFIED: `outline.mbt` and existing Phase 105 fingerprints]
**How to avoid:** keep current glyf functions untouched, add closed dispatch helpers around them, and assert exact before/after budget dimensions in standalone and collection tests. [VERIFIED: CONTEXT.md D-17]

## Code Examples

### Deterministic rational-to-Point2 boundary

```moonbit
// Recommended deterministic rule; freeze exact positive/negative,
// integral, fractional, and large-cancellation cases in white-box tests.
fn type2_rational_to_double(value : Type2Rational) -> Result[Double, CoreError] {
  if value.denominator <= 0L {
    return Err(type2_data_error("font-cff-type2-path-coordinate"))
  }
  let whole = value.numerator / value.denominator
  let remainder = value.numerator % value.denominator
  Ok(
    whole.to_double() +
    remainder.to_double() / value.denominator.to_double()
  )
}
```

This quotient-plus-remainder rule avoids first rounding a potentially large unreduced numerator; MoonBit documents `Double` as IEEE-754 binary64 and explicit `to_double()` conversions, but the exact project rule still needs golden tests. [CITED: https://docs.moonbitlang.com/ja/latest/language/fundamentals.html] [ASSUMED]

### Closed outline dispatch

```moonbit
match self.outline_source {
  FontOutlineSource::Glyf(index) =>
    font_decode_outline(index, self.tables.maxp, self.limits, gid, budget)
  FontOutlineSource::Cff1(admitted) =>
    cff_decode_outline_atomic(
      self.source,
      self.opening_revision,
      admitted,
      gid,
      self.limits,
      budget,
    )
}
```

The dispatch location is recommended from the existing `Font::outline_after_decode` seam and D-02; exact helper names are discretionary. [VERIFIED: `font.mbt:608-643` + CONTEXT.md]

## Recommended Plan Decomposition

### Plan 106-01 — Capacity-aware path construction and shared geometry sink

- Add `Path2::with_capacity` plus direct unit tests.
- Extract shared exact geometry/contour state from `Type2BoundsSink`.
- Add pending-moveto/non-empty-close semantics and retain exact publishable command count per GID.
- Add `Type2PathSink` that emits native line/cubic commands after exact transform and checked final conversion.
- Prove explicit `rrcurveto` and all flex forms produce identical cubic command sequences; preserve every Phase 105 bounds/VM golden. [VERIFIED: codebase seams + CONTEXT.md]

### Plan 106-02 — Retained common facts and atomic CFF query dispatch

- Refactor CFF common-table validation to retain directory, head/hhea/OS2/cmap/hmtx/kern/maxp facts inside `AdmittedCff1`.
- Reuse bounded kern discovery/admission inside the combined CFF ledger.
- Add CFF horizontal-metric lookup from face-local `hmtx` plus retained bound.
- Add exact query charge, preflight, revision, one-commit, and no-partial-path behavior.
- Refactor the private outline source so glyph count, metrics, and outline dispatch remain closed and format-neutral. [VERIFIED: codebase seams + CONTEXT.md]

### Plan 106-03 — Standalone and selected TTC/OTC public routing

- Branch `Font::open` to the complete standalone CFF transaction before the glyf semantic/charge branch.
- Construct the public CFF `Font` only from the complete aggregate with no post-commit reparsing.
- Route `FontCollection::open_face` `Cff` faces through selected admission using retained root revision, directory start, expected table count, and collection checksum mode.
- Cover a shared CFF table with distinct face-local cmap/hmtx/kern facts and standalone/collection semantic equality. [VERIFIED: codebase seams + OpenType collection specification]

### Plan 106-04 — Compatibility, exact authority, errors, and phase gate

- Freeze public standalone and collection glyf fingerprints for mapping, metrics, kerning, command sequence, error precedence, and every budget dimension.
- Add CFF exact/one-short scratch/path allocation, work, caller/ancestor, final-mutation, invalid-GID, empty, move-only, cubic, and common-table error cases.
- Run focused package native tests, full native suite, and `moon check --target all`; Phase 107 remains responsible for licensed/performance/exact four-target runtime evidence. [VERIFIED: CONTEXT.md + existing test conventions]

## State of the Art

| Old / Current Approach | Required Current Approach | Impact |
|------------------------|---------------------------|--------|
| `Type2Vm` contains `Type2BoundsSink` directly. | One VM with shared geometry state and bounds/path sink modes. | Prevents validator/renderer semantic drift. [VERIFIED: codebase inspection] |
| `Path2::new()` always starts with `[]`. | Exact-capacity format-neutral construction for bounded CFF output. | Makes backing-store authority explicit. [VERIFIED: codebase inspection + CONTEXT.md] |
| CFF common tables are validated then discarded. | Retain common query facts and kern inside `AdmittedCff1`. | Enables non-fallible opaque `Font` promotion. [VERIFIED: codebase inspection] |
| `Font::open` and selected `open_face` are glyf-only. | Private profile branch converges on the same public `Font`. | Satisfies CFF-04/CFF-05 without public API growth. [VERIFIED: codebase inspection + REQUIREMENTS.md] |

**Deprecated/outdated:** no external API is deprecated. The only implementation pattern to retire is the bounds-specific VM field; all Phase 105 semantics and tests remain authoritative. [VERIFIED: codebase inspection]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Quotient-plus-remainder rational-to-`Double` is the chosen deterministic publication rule. | Code Examples | Coordinate goldens differ; planner should lock the rule in the first path-sink task. |
| A2 | A conservative fixed per-`PathCommand` capacity byte unit can represent real backing-store authority across all targets. | Open Questions | Exact budget goldens or D-10 fail; planner must verify/freeze the unit before coding query charges. |

## Open Questions

1. **Exact path-command capacity byte unit**
   - What we know: current glyf lowering charges `command_bound * 32`, but CFF `CubicTo` has the largest payload and MoonBit does not document a stable public enum layout. [VERIFIED: `outline.mbt:415-433`; official MoonBit FFI docs describe payload layout as unstable]
   - Recommendation: define one conservative format-neutral authority unit in `mb-core` (recommended starting value: 64 bytes per command) and freeze exact/one-short budgets; do not change the existing glyf `32`-byte formula in this phase. [ASSUMED]

2. **Exact public capacity seam name**
   - What we know: `Path2` owns the private array and D-10 explicitly permits a minimal capacity-aware seam. [VERIFIED: `path.mbt` + CONTEXT.md]
   - Recommendation: use `Path2::with_capacity(Int)`; do not expose the array, a capacity getter, or CFF-specific constructor. [VERIFIED: design recommendation under CONTEXT.md discretion]

3. **CFF common-facts extraction boundary**
   - What we know: the current common helper is glyf-specific and CFF validation omits retained kern. [VERIFIED: codebase inspection]
   - Recommendation: extract an outline-neutral common decoder/admitter parameterized by already-decoded `MaxpFacts`; keep both existing glyf wrappers and formulas stable. [VERIFIED: design recommendation from code seam]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| `moon` | package/full tests | ✓ | `0.1.20260713` | — [VERIFIED: local CLI] |
| `moonrun` | target execution helpers | ✓ | `0.1.20260713` | — [VERIFIED: local CLI] |
| `moonc` | compilation | ✓ | `v0.10.4+2cc641edf` | — [VERIFIED: local CLI] |

**Missing dependencies with no fallback:** none. [VERIFIED: local CLI]

## Security Domain

Security enforcement is enabled because `.planning/config.json` does not set `security_enforcement` to `false`. Nyquist validation is explicitly disabled, so this research intentionally omits the `Validation Architecture` section. [VERIFIED: `.planning/config.json`]

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Pure in-process font library has no identity boundary. [VERIFIED: phase scope] |
| V3 Session Management | no | No session state or ambient service exists. [VERIFIED: phase scope] |
| V4 Access Control | yes, resource authority only | Existing caller/ancestor `Budget` preflight and one commit; no allocation or work beyond authorized dimensions. [VERIFIED: CONTEXT.md D-09/D-10] |
| V5 Input Validation | yes | Checked `ByteView` windows, retained profile classification, glyph-range checks, exact limits, and revision guards. [VERIFIED: codebase inspection] |
| V6 Cryptography | no | No cryptographic operation is introduced; collection DSIG remains structurally present/unverified. [VERIFIED: phase scope + collection API] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malicious CharString causes path/allocation amplification | Denial of Service | Exact retained command capacity, semantic limits, cumulative work, scratch/path allocation preflights, one commit. [VERIFIED: CONTEXT.md] |
| Retained source mutates during query/selected admission | Tampering | Opening revision authority, loop/error revision preference, final guard immediately before commit. [VERIFIED: Phase 105 + CONTEXT.md] |
| TTC table offset is rebased to face directory | Tampering / data confusion | Root-relative table records and table-local CFF subviews only. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/otff#ttc-header] |
| Validator and renderer interpret operators differently | Integrity | One operator switch and shared geometry core, with bounds/path equality tests. [VERIFIED: CONTEXT.md D-04] |
| Partial path escapes after late failure | Integrity | Private staged path; no callback/public return before exact preflight, final guard, and one commit. [VERIFIED: CONTEXT.md D-09] |

OWASP ASVS 5.0 is primarily a web-application standard; its safe untrusted-input and bounded-file-handling principles are applicable here only by analogy, while the repository's stricter `ByteView`/budget/revision contracts are the actual controls. [CITED: https://github.com/OWASP/ASVS]

## Sources

### Primary (HIGH confidence)

- `106-CONTEXT.md`, `REQUIREMENTS.md`, `ROADMAP.md`, `STATE.md` — locked scope and acceptance.
- `104-CONTEXT.md`, `104-VERIFICATION.md`, `104-04-SUMMARY.md` — verified structure/keying/root-coordinate handoff.
- `105-CONTEXT.md`, `105-VERIFICATION.md`, `105-REVIEW-FINAL.md`, `105-05-SUMMARY.md` — verified VM, bounds, matrix, resource, and mutation handoff.
- `modules/mb-core/math/path.mbt` and the listed `modules/mb-font/font/*.mbt` files — concrete implementation seams.

### Secondary (MEDIUM confidence)

- [OpenType 1.9.1 CFF table](https://learn.microsoft.com/en-us/typography/opentype/spec/cff) — GID/CharStrings identity, one-font CFF FontSet, shared collection CFF.
- [OpenType 1.9.1 font collection structure](https://learn.microsoft.com/en-us/typography/opentype/spec/otff#ttc-header) — root-relative directory/table offsets and shared/face-local tables.
- [OpenType 1.9.1 hmtx](https://learn.microsoft.com/en-us/typography/opentype/spec/hmtx) — GID-indexed advance/LSB and trailing-bearing rule.
- [Adobe Technical Note #5177](https://adobe-type-tools.github.io/font-tech-notes/pdfs/5177.Type2.pdf) — relative cubic and contour/endchar behavior.
- [MoonBit fundamentals](https://docs.moonbitlang.com/ja/latest/language/fundamentals.html) — `Array::new(capacity=...)`, `Double`, and explicit numeric conversions.

### Tertiary (LOW confidence)

- Exact 64-byte conservative capacity unit and quotient-plus-remainder conversion choice; both are explicitly logged as assumptions and must be frozen by direct tests.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependency; local versions match the project pin.
- Architecture: HIGH — derived from locked decisions and direct source inspection.
- Public/common-facts integration: HIGH — current missing retained facts and kern are directly visible.
- Capacity byte constant: LOW until the first implementation task freezes it.
- Rational-to-`Double` rule: MEDIUM as a deterministic recommendation, pending golden tests.
- Pitfalls: HIGH — each maps to a current concrete seam or locked invariant.

**Research date:** 2026-07-29
**Valid until:** 2026-08-28, or earlier if Phase 105 internals or the pinned MoonBit toolchain change.
