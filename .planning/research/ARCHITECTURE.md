# Architecture Research

**Domain:** v0.34 bounded static OpenType CFF1 admission and Type 2 cubic outlines
**Project:** MoonBit Native Foundation / `tchivs/mb-font`
**Researched:** 2026-07-28
**Confidence:** MEDIUM overall; HIGH for repository integration seams, MEDIUM for obscure Type 2 compatibility operators and licensed-CID fixture selection

## Executive Recommendation

Extend the existing `tchivs/mb-font/font` package with a private CFF1 parser and
a private, bounded Type 2 interpreter. Do not add another public font type and
do not route through FreeType, HarfBuzz, fontTools, or native FFI. Both
standalone `OTTO` fonts and collection faces already classified as
`FontFaceProfile::Cff` should publish the existing opaque `Font`. The current
public mapping, glyph identity, global metrics, horizontal metrics, kerning,
and `Font::outline` methods remain the consumer contract.

The key internal change is to replace glyf-specific retained state with one
closed private outline-source sum:

```moonbit
priv enum FontOutlineSource {
  Glyf(GlyfOutlineFacts)
  Cff1(CffOutlineFacts)
}
```

Common SFNT facts (`cmap`, `head`, `hhea`, `hmtx`, `maxp`, `name`, `OS/2`,
`post`, and optional `kern`) remain admitted once. Profile-specific admission
then retains either `glyf`/`loca` facts or bounded CFF1 facts. Dispatch occurs
only at admission, per-glyph bounds lookup, and outline extraction. This
prevents CFF work from changing the already-qualified glyf decoder.

CFF admission must execute every glyph once with a validation/bounds sink
before a `Font` is published. This is not optional: the existing
`Font::horizontal_metrics` method has no budget argument but returns bounds and
right-side bearing. Retaining a conservatively rounded integer CFF glyph bound
per GID preserves that method without hidden query-time work. The same Type 2
VM then runs a selected glyph again under the caller's outline budget with a
path sink, producing `MoveTo`, `LineTo`, `CubicTo`, and `Close` commands. There
must be one interpreter, not separate validator and renderer implementations.

Keep Type 2 hinting non-rendering. Stem operators, `hintmask`, and `cntrmask`
are parsed and validated because they affect byte synchronization, stack
interpretation, and hostile-input safety. They never adjust points, invoke a
grid fitter, or rasterize. CFF2, variations, WOFF, shaping, hint execution, and
rasterization remain rejected at the existing capability boundaries.

## Standard Architecture

### System Overview

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│ Public package: tchivs/mb-font/font                                        │
│ Font::open │ FontCollection::open_face │ Font queries │ Font::outline      │
└───────────────┬───────────────────────────────────────────────┬─────────────┘
                │                                               │
                v                                               v
┌──────────────────────────────────────┐       ┌──────────────────────────────┐
│ Shared SFNT / TTC authority          │       │ Per-glyph outline authority  │
│ retained ByteView + revision         │       │ caller Budget + final guard  │
│ directory/checksum/profile           │       └───────────────┬──────────────┘
│ common table admission               │                       │
└───────────────┬──────────────────────┘                       │
                │                                               │
          ┌─────┴─────┐                                  ┌──────┴──────┐
          v           v                                  v             v
┌────────────────┐  ┌──────────────────────────┐  ┌──────────────┐ ┌──────────┐
│ Static glyf    │  │ Static CFF1              │  │ glyf decoder │ │ Type 2 VM│
│ existing facts │  │ Header/INDEX/DICT facts  │  │ unchanged    │ │ path sink│
│ loca + glyf    │  │ name/CID keying          │  └──────┬───────┘ └────┬─────┘
└───────┬────────┘  │ CharStrings + subrs      │         │              │
        │           │ retained glyph bounds    │         └──────┬───────┘
        │           └─────────────┬────────────┘                v
        │                         │                    ┌──────────────────┐
        │                         v                    │ @math.Path2      │
        │              ┌──────────────────────┐       │ Quad for glyf    │
        │              │ Type 2 VM            │       │ Cubic for CFF1   │
        │              │ validation/bounds    │       └──────────────────┘
        │              │ sink during admission│
        │              └──────────────────────┘
        │
        └── existing glyf behavior and evidence remain frozen
```

### Component Responsibilities

| Component | Responsibility | Recommended implementation |
|---|---|---|
| Public `Font` facade | Preserve opaque font identity and all existing query signatures | Add private `outline_source : FontOutlineSource`; do not expose raw CFF offsets, SIDs, CIDs, DICTs, or subroutines |
| SFNT directory/profile layer | Accept exactly static glyf (`0x00010000`) or static CFF1 (`OTTO`) and reject mixed/variable/CFF2 profiles | Refactor signature/profile validation into closed branches; leave directory range, sorting, overlap, checksum, and TTC root-relative rules shared |
| Common table admission | Admit mapping and metrics tables used by both outline formats | Split current `RequiredTableFacts` into common facts plus profile-specific facts; keep `cmap`, `hmtx`, `kern`, and line/global metrics unchanged |
| CFF cursor/range layer | Make every CFF-relative offset a checked subview of the `'CFF '` `TableWindow` | Reuse `ByteView` and `CheckedRange`; never treat a CFF offset as a root-SFNT or TTC offset |
| CFF INDEX parser | Validate count, `offSize`, `count + 1` offsets, first offset `1`, monotonicity, final range, and object count ceilings | Retain compact object windows or offset arrays; empty INDEX is exactly a two-byte zero count |
| CFF DICT parser | Decode bounded integer/real operands and exact operator arity without executing PostScript | Separate Top, Font, and Private DICT schemas; reject duplicate singleton structural operators and unsupported synthetic/variation constructs |
| CFF keying adapter | Normalize name-keyed and CID-keyed data into one per-GID execution selection | `CffKeying::NameKeyed` or `CffKeying::CidKeyed`; return charset identity plus selected Private DICT/local-subr environment for a GID |
| CFF admission transaction | Validate the full CFF envelope and every glyph, compute exact resource facts, and retain integer glyph bounds | Use the Type 2 VM with a bounds sink; perform the final source-revision guard and budget commit before publishing `Font` |
| Type 2 frame machine | Decode numbers/operators, share stack and execution state across subroutine frames, and enforce hard plus caller limits | Iterative frame stack, not host recursion; frame identity includes global/local scope and subroutine index |
| Type 2 geometry sink | Close contours, append relative line/cubic geometry, lower flex operators, and calculate bounds | One fixed-point command stream with `ValidateBounds` and `BuildPath` sink modes |
| Qualification generator | Produce generated valid, hostile, licensed-oracle, TTC, compatibility, and target evidence | Extend the existing generator/lane rather than create a parallel CFF-only release system |

## Recommended Project Structure

Keep all runtime files in the existing `font` package so private facts remain
private and no new publishable package or dependency edge appears.

```text
modules/mb-font/font/
├── font.mbt                         # Public facade; closed outline dispatch
├── directory.mbt                    # SFNT signature/profile and shared directory rules
├── tables.mbt                       # Common required-table admission
├── metrics.mbt                      # Shared hmtx + profile-specific retained bounds
├── outline.mbt                      # Existing glyf decoder; compatibility-frozen
├── collection.mbt                   # Cff face becomes selectable; Cff2/Variable stay rejected
├── collection_parser.mbt            # Existing all-face classification remains authoritative
├── limits.mbt                       # Existing public constructor; private CFF-derived ceilings
├── cff_cursor.mbt                   # Checked CFF-relative reads and subviews
├── cff_index.mbt                    # Generic bounded CFF1 INDEX parsing
├── cff_dict.mbt                     # Number/DICT decoding and typed operator schemas
├── cff_keying.mbt                   # charset, Encoding, ROS, FDArray, FDSelect
├── cff_admission.mbt                # CFF1 envelope, common-table cross-checks, bounds pass
├── type2_vm.mbt                     # Iterative interpreter and operator semantics
├── type2_geometry.mbt               # Fixed-point bounds/path sinks and contour lifecycle
├── cff_wbtest.mbt                   # Private parser/VM unit and adversarial tests
├── cff_test.mbt                     # Public black-box standalone/TTC tests
├── cff_qualification_test.mbt       # Focused generated/licensed semantic facts
└── generated_cff_qualification_test.mbt

fixtures/font/
├── qualification-cases.json         # Existing glyf baseline, unchanged
├── collection-qualification-cases.json
├── cff-qualification-cases.json     # Closed CFF valid/hostile/resource matrix
└── cff/
    ├── LICENSE-or-NOTICE
    ├── licensed-name-keyed.otf
    ├── licensed-cid-keyed.otf-or-derived-subset.otf
    ├── oracle.json                   # Tool-produced facts, never runtime oracle
    └── provenance.json               # Source URL/revision, hashes, derivative recipe

scripts/fixtures/
└── Generate-FontQualification.ps1   # Extend one canonical generator/check seam

scripts/quality/
├── Invoke-FontQualification.ps1     # Upgrade evidence schema and four-target payload
└── Test-FontQualificationEvidenceBoundary.ps1
```

### Structure Rationale

- **`cff_*` versus `type2_*`:** CFF is a container/data-model parser; Type 2 is
  an execution engine. Keeping the boundary explicit prevents CFF offsets,
  FDSelect policy, or DICT defaults from leaking into operator execution.
- **Same MoonBit package:** `priv` facts remain inaccessible to consumers while
  avoiding a new module/package dependency. The public edge stays exactly
  `mb-font -> mb-core`.
- **Existing `outline.mbt` remains glyf-only:** modifying the qualified
  quadratic/composite decoder to accommodate a stack VM would create needless
  compatibility risk.
- **One generator and one qualification lane:** target comparison, evidence
  path ownership, toolchain identity, interface facts, and dependency facts are
  already solved. CFF should add semantic payload, not duplicate release
  machinery.

## Architectural Patterns

### Pattern 1: Closed Outline-Profile Dispatch

**What:** Retain common font facts once and place only outline-format-specific
facts behind a private enum.

```moonbit
priv enum FontOutlineSource {
  Glyf(GlyfOutlineFacts)
  Cff1(CffOutlineFacts)
}

fn font_decode_selected_outline(
  source : FontOutlineSource,
  glyph : UInt64,
  limits : FontLimits,
  budget : @budget.Budget,
) -> Result[@math.Path2, @error.CoreError] {
  match source {
    Glyf(facts) => font_decode_glyf_outline(facts, glyph, limits, budget)
    Cff1(facts) => cff_decode_outline(facts, glyph, limits, budget)
  }
}
```

**When to use:** At admission, horizontal-metric bounds lookup, and
`Font::outline`.

**Trade-offs:** Adds a small internal dispatch but prevents a combinatorial set
of optional `glyf`, `loca`, `CFF`, FDArray, and FDSelect fields. It also makes
the CFF2/variable prohibition explicit and reviewable.

The common required-table set for both profiles is `cmap`, `head`, `hhea`,
`hmtx`, `maxp`, `name`, `OS/2`, and `post`. Static glyf additionally requires
`glyf` and `loca`; static CFF1 requires exactly `'CFF '` and prohibits `CFF2`,
`glyf`, `loca`, and recognized variation tables in the selected executable
profile. `OTTO` alone is not sufficient evidence of a supported face.

### Pattern 2: Parse → Validate → Commit → Publish

**What:** Keep budget authority and publication transactional even though the
parser retains views into caller-owned bytes.

```text
capture source revision
  → directory discovery preflight
  → checked directory/profile parse
  → common table validation
  → CFF envelope validation
  → all-glyph Type 2 validation + retained bounds
  → exact cumulative charge preflight
  → final source-revision guard
  → one budget charge
  → publish opaque Font
```

**When to use:** Standalone CFF `Font::open` and CFF
`FontCollection::open_face`.

**Trade-offs:** The all-glyph pass makes opening CFF fonts more expensive than
lazy parsing, but it is required for honest atomic admission and budgetless
metric queries. Work stays bounded by `max_glyphs`, table/charstring ceilings,
the execution ledger, and the authoritative `Budget`.

Do not change the qualified glyf charge order merely to share this machinery.
Give CFF admission a deferred transaction mode, analogous to the collection
selected-face ledger, and freeze glyf counters/precedence in compatibility
tests.

### Pattern 3: One VM, Two Geometry Sinks

**What:** Execute exactly the same operator, stack, subroutine, hint, arithmetic,
and contour state machine in two modes.

| Mode | Used when | Retains | Publishes |
|---|---|---|---|
| `ValidateBounds` | CFF admission, once for every glyph | Conservative integer bound and validation facts | Nothing until the whole font commits |
| `BuildPath` | `Font::outline(glyph, budget)` | Fixed-point commands for one glyph | One complete `Path2` after final guard/commit |

The VM should store coordinates in checked fixed-point form through all
relative arithmetic and FontMatrix application. Convert to `Double` only while
emitting `Point2`. For public integer glyph bounds, use `floor(min)` and
`ceil(max)` over every line endpoint and cubic control point after effective
FontMatrix-to-font-unit normalization. This matches the existing control-point
enclosure semantics and avoids truncating fractional CFF coordinates.

**Trade-offs:** A sink-aware VM is more stateful than a direct `Path2` builder,
but it eliminates validator/decoder drift and makes partial-path publication
impossible.

### Pattern 4: Iterative Type 2 Call Frames

**What:** Model the glyph charstring, global subroutines, and the selected local
subroutine INDEX as frames over one shared VM state.

```text
Type2State
├── operand stack[48]
├── transient array[32] + initialized bits
├── return frames[10]
├── active subroutine identities
├── current point / open contour
├── width-seen and path-phase state
├── stem count / mask state
├── selected local environment (name Private DICT or CID FD)
├── deterministic random state
└── work, byte, call, command, and arithmetic ledgers
```

A subroutine identity is not just an integer. It is
`Global(index)` or `Local(private_environment, index)`. This distinction is
required for CID fonts and for cycle detection. Global subroutines execute
with the calling glyph's local environment, so a `callsubr` reached from a
global subroutine still resolves against the glyph-selected Private DICT.

**Trade-offs:** An explicit frame machine is more verbose than recursive
functions but makes depth, return position, cycle, byte, and call accounting
auditable on all four targets.

### Pattern 5: Keying Adapter Before Execution

**What:** Normalize name-keyed and CID-keyed selection before the VM sees a
charstring.

```moonbit
priv enum CffKeying {
  NameKeyed(
    charset : CffCharsetFacts,
    encoding : CffEncodingFacts,
    private : CffPrivateFacts,
  )
  CidKeyed(
    ros : CffRosFacts,
    charset : CffCidCharsetFacts,
    fd_select : CffFdSelectFacts,
    font_dicts : Array[CffFontDictFacts],
  )
}
```

For name-keyed fonts, validate the custom/predefined charset and Encoding even
though public Unicode mapping continues to come exclusively from SFNT `cmap`.
Retain SID-to-GID lookup only where required by the deprecated non-nested
`endchar` seac compatibility form. CFF Name INDEX data is not a public font
name; the SFNT `name` table remains authoritative.

For CID-keyed fonts, a leading `ROS` selects CID processing. Encoding must be
absent, predefined charsets are forbidden, charset entries are CIDs, FDArray
and FDSelect are required, every GID must resolve to an in-range FD, and each
FD must resolve a required (possibly zero-length) Private DICT plus optional
local Subrs INDEX.

**Trade-offs:** Admission stores more compact routing facts, but the VM receives
one unambiguous local-subroutine and private-width/hint environment per glyph.

## Data Flow

### Standalone Admission Flow

```text
Font::open(ByteView, FontLimits, Budget)
  → capture mutation_revision
  → accept 0x00010000 or OTTO, reject TTC/WOFF/unknown
  → parse checked SFNT directory and checksums
  → classify exact profile
      ├── StaticGlyf → existing required tables + metric index
      └── StaticCff1
          → common required tables
          → CFF Header + five fixed-position structures
          → typed Top DICT and CFF-relative windows
          → name/CID keying structures + Private DICT(s)
          → CharStrings count == maxp.numGlyphs
          → validate every GID with Type2 ValidateBounds
          → retain CffOutlineFacts + glyph bounds
  → budget preflight
  → final revision guard
  → charge
  → Font { common facts, outline_source }
```

### Collection Selected-Face Flow

```text
FontCollection::open_face(index, FontLimits, Budget)
  → existing collection revision/index guards
  → existing cached FontFaceProfile
      ├── StaticGlyf → existing selected-face adapter unchanged
      ├── Cff        → same CFF admission from root-relative TableWindows
      └── Cff2 / Variable / OtherUnsupported → CapabilityUnavailable
  → final collection-source revision guard
  → publish existing opaque Font
```

The CFF table record offset in a TTC/OTC remains root-file-relative, as required
by the existing collection adapter. Once the `'CFF '` `TableWindow` is made,
all internal CFF `(0)` offsets are relative to the beginning of that table.
Never add the selected face directory base to a CFF-internal offset.

### Query and Outline Flow

```text
Font::glyph_for_scalar
  → unchanged cmap lookup → GlyphId

Font::horizontal_metrics
  → unchanged hmtx lookup
  → glyf: existing glyph-header bounds
  → CFF1: retained admission-time integer bounds
  → unchanged public GlyphHorizontalMetrics

Font::outline(glyph, Budget)
  → revision + glyph ownership/range guard
  → outline-source dispatch
      ├── glyf → existing quadratic decoder
      └── CFF1 → select Private/FD → Type2 BuildPath → cubic commands
  → mutation test hook / final revision guard
  → complete Path2 only
```

### Type 2 Geometry Rules

1. Maintain a current point in checked fixed-point font units.
2. Any moveto closes the prior open contour, then emits `MoveTo`.
3. `rlineto`, `hlineto`, and `vlineto` emit `LineTo`.
4. `rrcurveto`, `rcurveline`, `rlinecurve`, `vvcurveto`, `hhcurveto`,
   `vhcurveto`, and `hvcurveto` emit one or more `CubicTo` commands.
5. `hflex`, `flex`, `hflex1`, and `flex1` always preserve their two cubic
   curves. Device-pixel flex flattening is hint/raster behavior and is out of
   scope.
6. `endchar` closes the final contour. Missing or misplaced `endchar`, invalid
   `return`, trailing executable bytes, and reserved operators fail.
7. The deprecated four-argument `endchar` form may compose only name-keyed
   StandardEncoding components, must be bounded, and may not nest. Reject it
   for CID-keyed fonts or unresolved component names.

## Limits, Budgets, and Failure Atomicity

### Hard Format and Interpreter Limits

The implementation should enforce the Type 2 specification ceilings even when
the caller supplies larger general limits:

| Dimension | Hard ceiling | Additional MNF rule |
|---|---:|---|
| DICT operands before an operator | 48 | Exact arity/type per typed DICT schema |
| Type 2 operand stack | 48 | Check before every push and after every operator |
| H/V stems total | 96 | Includes implicit vstem operands before a mask |
| Subroutine nesting | 10 | Iterative frames; active-frame cycle rejection |
| Charstring bytes per object | 65,535 | Also bounded by CFF/table and caller outline-instruction ceilings |
| Global or local subr count | 65,536 VM limit; 65,535 representable in a CFF1 Card16 INDEX | INDEX count/range validated before lookup |
| Transient array | 32 | Track initialization; reject out-of-range/undefined reads |
| CFF INDEX `offSize` | 1–4 | First offset exactly 1; offsets monotonic and in-range |

### Caller Semantic Limits

Preserve the signature of `FontLimits::new`. Derive private CFF ceilings from
the existing fields instead of making every existing caller pass new
arguments:

| Existing limit | CFF use |
|---|---|
| `max_source_bytes` | Entire standalone/TTC source authority |
| `max_tables`, `max_table_bytes` | SFNT records and `'CFF '` table/window ceiling |
| `max_glyphs` | CharStrings count and retained bounds count |
| `max_name_records` | SFNT name admission; CFF Name INDEX is independently fixed to exactly one |
| `max_cmap_records` | Existing Unicode mapping |
| `max_kern_subtables`, `max_kern_pairs` | Existing optional `kern` behavior |
| `max_outline_points` | Maximum emitted fixed-point endpoints/control points per glyph |
| `max_outline_contours` | Maximum moveto/closed contour count per glyph |
| `max_outline_components` | Deprecated seac component expansion (maximum two, non-nested); do not misuse it as subroutine depth |
| `max_outline_instruction_bytes` | Per-glyph cumulative executed charstring/subroutine bytes, capped again at format limits |
| `max_post_name_bytes` | Existing `post` validation |
| `max_work` | Admission-wide and outline-call work, including INDEX/DICT scans, all-glyph execution, subroutine calls, masks, operators, and command lowering |

The fixed stack/depth/stem/transient limits are explicit format invariants.
Total subroutine calls and repeated-subroutine work are not safely bounded by
nesting alone; charge every call, executed byte/token, emitted point/command,
FDSelect range traversal, and charset/INDEX entry against `max_work` and the
caller `Budget`.

### Hint and Mask Handling

Hints are validated data, not geometry:

- Recognize `hstem`, `vstem`, `hstemhm`, and `vstemhm`; handle the optional
  width before determining operand-pair parity.
- Track stem count across the glyph and all called subroutines.
- Immediately before `hintmask` or `cntrmask`, pending even operand pairs are
  the omitted vstem declaration allowed by Type 2.
- Require at least one declared stem before a mask.
- Consume exactly `(stem_count + 7) / 8` inline bytes. A subroutine boundary
  cannot split an operator from mask bytes.
- Require unused low bits in the last byte to be zero.
- Validate the ordering/phase rules and the 96-stem ceiling.
- Do not retain masks after validation and do not move the current point.

### Atomic Failure Contract

| Failure point | Published state | Budget effect |
|---|---|---|
| CFF directory/INDEX/DICT/keying failure | No `Font` | No committed CFF admission charge |
| Any malformed/resource-exhausting glyph during all-glyph admission | No `Font`, no retained bounds exposed | No committed CFF admission charge |
| Source mutation before final admission guard | No `Font` | No committed CFF admission charge |
| Selected outline stack/subr/mask/path failure | Existing `Font` remains valid; no `Path2` returned | No committed CFF outline transaction |
| Source mutation before outline publication | Existing `Font` only; no `Path2` returned | No committed CFF outline transaction |
| Successful CFF admission/outline | One complete value | Exactly one declared cumulative commit |

Use preflight checks before every attacker-controlled loop or allocation, but
accumulate CFF charges in a private ledger until the final commit. Arrays and
scratch state must remain unreachable until success. Structured error
precedence should stay: state/revision guard, caller input/range, resource
limit, data encoding, then capability where the input is structurally
recognized but deliberately unsupported.

## Scaling Considerations

This library scales by input complexity, not user count.

| Scale | Architecture behavior |
|---|---|
| Small Latin OTF, hundreds of glyphs | Full admission validation and retained bounds are inexpensive; direct array facts are preferred |
| Large CJK CID OTF, tens of thousands of glyphs | Bounds pass dominates; use compact INDEX offsets, range-coded charset/FDSelect facts, no copied charstrings, and exact cumulative work preflight |
| Hostile maximum-count font | Fail before attacker-sized traversal/allocation when count/range/work preflight cannot be authorized; never rely on the Type 2 depth limit alone |

### Scaling Priorities

1. **First bottleneck — all-glyph VM work:** Keep charstrings and subroutines as
   retained views, store only offsets, per-FD private facts, and one integer
   bounds record per GID. Do not retain a `Path2` for every glyph.
2. **Second bottleneck — repeated subroutine expansion:** Count every executed
   token/call. Do not memoize subroutine geometry because results depend on
   caller stack, current point, hint state, local environment, and transient
   array.
3. **Third bottleneck — qualification source size:** Generate MoonBit literals
   from immutable fixtures in bounded chunks and keep licensed payload/oracle
   provenance separate from target-produced evidence.

## Anti-Patterns

### Anti-Pattern 1: Make `Font` Fields Optional for Every Format

**What people do:** Add `glyf?`, `loca?`, `cff?`, `fd_array?`, and
`fd_select?` fields and test combinations throughout queries.

**Why it is wrong:** Invalid combinations become representable and every query
must re-prove the profile.

**Do this instead:** Use `FontOutlineSource::Glyf`/`Cff1` after one admission
proof.

### Anti-Pattern 2: Lazy First Validation in `Font::outline`

**What people do:** Accept CFF structure at open and discover malformed
charstrings only when a glyph is requested.

**Why it is wrong:** It violates atomic font admission and cannot preserve
budgetless `horizontal_metrics` bounds.

**Do this instead:** Validate every glyph and retain bounds during admission;
decode only the requested path later.

### Anti-Pattern 3: Reuse `loca`/`glyf` Metric Logic for CFF

**What people do:** Fabricate pseudo-loca offsets or return `None` bounds for
all CFF glyphs.

**Why it is wrong:** It couples unrelated formats or silently weakens the
existing metrics contract.

**Do this instead:** Let `MetricIndexFacts` own shared hmtx cardinality and
delegate bounds to glyf headers or retained CFF admission bounds.

### Anti-Pattern 4: Recursive Host-Language Subroutine Calls

**What people do:** Implement `callsubr` by recursive MoonBit calls.

**Why it is wrong:** Host stack behavior differs by target and hides cycle,
return, and work accounting.

**Do this instead:** Use an explicit maximum-10 return-frame stack and active
subroutine identities.

### Anti-Pattern 5: Skip Hints Because Hinting Is Out of Scope

**What people do:** Treat stem/mask operators as no-ops without consuming or
validating their operands and inline bytes.

**Why it is wrong:** Mask length depends on cumulative stem count; one missed
byte desynchronizes the entire charstring and creates parser ambiguity.

**Do this instead:** Fully validate hint syntax and masks, then discard their
rendering effect.

### Anti-Pattern 6: Apply CFF Offsets in the Wrong Coordinate Space

**What people do:** Add the TTC face directory base to a CFF-internal offset or
apply an INDEX offset from the beginning of the INDEX.

**Why it is wrong:** SFNT/TTC table offsets, CFF `(0)` offsets, Private DICT
relative Subrs offsets, and INDEX 1-based object offsets have different bases.

**Do this instead:** Convert each authority into a checked `TableWindow` or
`ByteView` at the boundary and name the base in the helper/API.

### Anti-Pattern 7: Let Charstring Width Replace `hmtx`

**What people do:** Publish Type 2 `defaultWidthX`/`nominalWidthX` results as
the existing horizontal metric.

**Why it is wrong:** OpenType retains duplicated CFF widths, but the public
MNF contract already reads `hmtx`; changing authority would create
profile-dependent metrics.

**Do this instead:** Validate Type 2 width placement/value arithmetic for
well-formed execution and keep `hmtx` authoritative.

### Anti-Pattern 8: Use Floating Point Throughout the VM

**What people do:** Decode DICT reals and Type 2 fixed values directly to
`Double`, then accumulate relative coordinates.

**Why it is wrong:** Long arithmetic/subroutine chains can drift across
targets, undermining exact semantic comparison.

**Do this instead:** Parse into checked fixed/rational forms, apply the
effective FontMatrix deterministically, and convert only when emitting
`Point2`.

### Anti-Pattern 9: Refactor the Glyf Decoder Alongside CFF

**What people do:** Generalize every outline function before CFF evidence
exists.

**Why it is wrong:** It widens the regression surface and makes frozen glyf
failures, budget counters, and path fingerprints harder to attribute.

**Do this instead:** Share only the public dispatch and common metric boundary;
leave `outline.mbt` behavior frozen.

## Integration Points

### Internal Boundaries

| Boundary | Communication | Contract |
|---|---|---|
| `directory.mbt` ↔ `cff_admission.mbt` | Checked `'CFF '` `TableWindow` plus common table facts | No raw unchecked offsets; exact static CFF1 profile only |
| `cff_admission.mbt` ↔ `cff_index.mbt` | Bounded object windows/offset facts | INDEX base semantics owned entirely by INDEX layer |
| `cff_admission.mbt` ↔ `cff_keying.mbt` | Typed Top/Private/Font DICT facts | One execution environment per GID |
| `cff_keying.mbt` ↔ `type2_vm.mbt` | CharString view, Global Subrs, selected Local Subrs, widths/hint defaults | VM does not parse FDSelect or choose a font dict |
| `type2_vm.mbt` ↔ `type2_geometry.mbt` | Validated fixed-point move/line/cubic/close operations | Sink does not read source bytes or manage subroutine frames |
| `font.mbt` ↔ `metrics.mbt` | Closed profile-specific bounds provider | Public metric type and hmtx authority unchanged |
| `font.mbt` ↔ `@math.Path2` | Complete path only | CFF curves are `CubicTo`; no canvas/raster dependency |
| `FontCollection` ↔ selected CFF admission | Retained root `ByteView`, cached face directory facts | No copying/materializing a standalone font |

### External Services

There are no runtime external services. Production parsing uses caller-owned
bytes, explicit limits, and caller budgets only.

| Service/tool | Integration pattern | Notes |
|---|---|---|
| Offline oracle tooling | Qualification-only fixture inspection | May use mature external tooling to generate expected facts; target output must never be its own oracle |
| PowerShell fixture generator | Deterministic source/oracle and hostile-case generation | Check mode must detect byte/source/manifest drift |
| MoonBit four-target runner | Independent `js`, `wasm`, `wasm-gc`, `native` package execution | Use isolated target directories and compare normalized semantic payloads |

## Qualification Architecture

### Test Layers

1. **Private white-box parser tests**
   - Header version/hdrSize; empty and non-empty INDEX rules; every `offSize`.
   - DICT integer/real encodings, stack 48, exact typed arity, defaults,
     duplicate structural operators, and checked offsets.
   - Name INDEX/Top DICT count one; CharstringType two; CharStrings/maxp
     cardinality.
   - Custom/predefined charset and Encoding forms/supplements.
   - ROS, FDArray, FDSelect formats 0/3, Private DICT, and per-FD Subrs.
   - Fixed-point arithmetic, contour closure, all line/curve/flex operators,
     widths, subr bias thresholds, storage/conditional/arithmetic operators,
     deterministic random state, and seac compatibility.

2. **Public black-box tests**
   - Standalone name-keyed CFF opens through `Font::open`.
   - Standalone CID-keyed CFF opens through the same opaque `Font`.
   - `glyph_for_scalar`, `glyph_id`, global/line/horizontal metrics, `kerning`,
     and cubic `outline` agree with independent oracle facts.
   - `FontCollection::face_profile` remains `Cff`; `open_face` now succeeds for
     valid static CFF while Cff2/Variable still fail.
   - Existing glyf literals, errors, budget facts, and path fingerprints remain
     byte-for-byte frozen.

3. **Generated hostile/resource matrix**
   - Truncated/overlapping CFF ranges; invalid INDEX first/descending/final
     offsets; object/count/table limits.
   - Invalid Top/Private/Font DICT operand types/counts, offsets, and keying
     combinations.
   - Charset/Encoding/FDSelect range exhaustion, duplicate/invalid entries, and
     out-of-range FD/GID/SID/CID references.
   - Type 2 truncated numbers/operators, stack under/overflow, transient
     misuse, arithmetic failure, reserved operators, missing `return`/`endchar`,
     recursion, depth 11, subr/call/work exhaustion, stem 97, malformed masks,
     path/contour/point exhaustion, and nested seac.
   - Exact/one-short semantic limits and budgets.
   - Mutation before admission commit, during all-glyph validation, during
     selected outline decode, and immediately before publication.

4. **Licensed interoperability**
   - One immutable name-keyed static CFF1 OTF with Latin/non-BMP mapping where
     available.
   - One immutable CID-keyed CFF1 OTF or license-compliant deterministic
     derivative/subset exercising FDArray/FDSelect and multiple local
     environments.
   - Provenance URL/revision, original and derivative SHA-256, license/notice,
     generator identity, and offline oracle version recorded in the fixture
     manifest.

5. **Four-target evidence**
   - Upgrade the closed font evidence schema rather than append ad-hoc files.
   - Exactly four ordered records: `js`, `wasm`, `wasm-gc`, `native`.
   - Semantic payload includes CFF fixture identities, name/CID workflows,
     cubic command fingerprints, integer bounds, hostile/resource outcomes,
     mutation atomicity, frozen glyf compatibility, public-interface baseline,
     sole dependency, and toolchain identity.
   - Normalize only target/runner fields; all CFF facts remain byte-visible.
   - Keep evidence-directory ownership/link defenses and negative probes.

### Phase Ordering Recommendation

1. **CFF profile and bounded data model**
   - Refactor common versus profile-specific table requirements.
   - Accept standalone `OTTO` and selected `FontFaceProfile::Cff`.
   - Implement checked CFF Header/INDEX/DICT/charset/Encoding/Private,
     name-keyed and CID-keyed FDArray/FDSelect facts.
   - Freeze `FontLimits` derivation, error precedence, retained representation,
     and exact admission charge formula.
   - Rationale: the interpreter cannot safely run until each GID has an
     unambiguous charstring and local environment.

2. **Bounded Type 2 validation and retained metrics**
   - Implement the iterative VM, hard limits, work ledger, hints/masks,
     subroutines, arithmetic/storage/conditionals, deterministic random policy,
     width handling, fixed-point geometry, and all-glyph bounds pass.
   - Publish CFF `Font` only after the all-glyph transaction commits.
   - Route `horizontal_metrics` to retained bounds while preserving `hmtx`.
   - Rationale: this closes the atomic admission and existing metrics contract
     before any public outline success is claimed.

3. **Cubic `Path2` extraction and public/TTC integration**
   - Add the path sink to the same VM.
   - Preserve contour closure and lower all curve/flex forms to `CubicTo`.
   - Wire `Font::outline` and CFF collection selected-face admission.
   - Freeze existing glyf semantic and budget evidence.
   - Rationale: the public path is now a thin, reviewable reuse of already
     qualified execution semantics.

4. **Hostile, licensed, and four-target qualification**
   - Finalize generated matrices, immutable licensed name/CID fixtures,
     independent oracles, mutation tests, evidence schema, target comparison,
     complete package runs, and Required lane.
   - Rationale: fixture provenance and cross-target equality should qualify the
     completed public slice, not drive parser design through target-produced
     expectations.

Do not combine phases 1 and 2 into a single parser/VM task: INDEX/DICT/keying
error precedence and Type 2 execution limits are independently large hostile
surfaces. Do not start licensed qualification before the supported operator,
FontMatrix, seac, and deterministic-random policies are frozen.

## Open Research Flags

- **Type 2 `random`:** TN #5177 defines the operator and CFF defines
  `initialRandomSeed`, but portable cross-implementation exactness needs a
  documented deterministic PRNG policy and oracle agreement. Freeze this
  before interpreter implementation.
- **Effective FontMatrix:** CFF1 permits Top and CID Font DICT matrices more
  broadly than the narrowed CFF2 OpenType rules. Freeze matrix composition,
  normalization to `head.unitsPerEm`, fixed-point precision, and overflow
  errors with licensed fixtures.
- **Deprecated seac:** The specification recommends support and forbids
  nesting. Confirm the intended v0.34 compatibility promise and generated
  coverage; if deliberately rejected, classify it as a recognized capability
  boundary rather than malformed data.
- **Licensed CID fixture:** Select an immutable, redistributable CFF1 CID font
  or a reproducible licensed derivative after verifying notice and derivative
  terms. This is phase-specific fixture research, not a runtime architecture
  blocker.

## Sources

### Repository Sources

- `modules/mb-font/font/font.mbt` — opaque `Font`, revision guards, public
  query/outline flow, retained glyf-specific state.
- `modules/mb-font/font/directory.mbt` — current standalone signature/profile,
  directory/checksum, checked table-window, and budget seams.
- `modules/mb-font/font/metrics.mbt` — current hmtx/loca/glyf coupling and
  budgetless public metric lookup.
- `modules/mb-font/font/outline.mbt` — qualified glyf fixed-point decoder,
  work/allocation charging, transactional `Path2`, and composite boundaries.
- `modules/mb-font/font/collection.mbt` and `collection_parser.mbt` — existing
  `Cff`/`Cff2` classification, root-relative selected-face adapter, and current
  CFF selection prohibition.
- `modules/mb-core/math/path.mbt` — shared `Path2` and `CubicTo` consumer
  contract.
- `scripts/quality/Invoke-FontQualification.ps1`,
  `scripts/quality/Test-FontQualificationEvidenceBoundary.ps1`, and
  `scripts/fixtures/Generate-FontQualification.ps1` — current four-target,
  fixture, oracle, interface, dependency, and evidence architecture.
- `docs/rfcs/0004-mb-font.md` and `.planning/PROJECT.md` — module boundary and
  v0.34 scope.
  **Confidence:** HIGH (direct repository inspection).

### Authoritative External Sources

- [OpenType 1.9.1 — The OpenType Font File](https://learn.microsoft.com/en-us/typography/opentype/spec/otff)
  — `OTTO`, common required tables, CFF versus glyf/loca, and TTC directory
  rules.
- [OpenType 1.9.1 — CFF table](https://learn.microsoft.com/en-us/typography/opentype/spec/cff)
  — one-entry Name INDEX, Type 2 requirement, CFF/OpenType GID identity,
  CharStrings/`maxp` cardinality, and collection sharing.
- [Adobe Technical Note #5176 — The Compact Font Format Specification](https://adobe-type-tools.github.io/font-tech-notes/pdfs/5176.CFF.pdf)
  — CFF Header/INDEX/DICT layout, charset, Encoding, Private DICT, local/global
  Subrs, CID ROS/FDArray/FDSelect, and offset bases.
- [Adobe Technical Note #5177 — The Type 2 Charstring Format](https://adobe-type-tools.github.io/font-tech-notes/pdfs/5177.Type2.pdf)
  — operator semantics, widths, hints/masks, subroutines, seac compatibility,
  and implementation limits.
- [OpenType 1.9.1 — CFF2 table](https://learn.microsoft.com/en-us/typography/opentype/spec/cff2)
  — used only to confirm the CFF2/variation boundary and FontMatrix/UPEM
  contrast; CFF2 execution is out of scope.
  **Confidence:** MEDIUM (official Microsoft/Adobe sources cross-checked; the
  research seam classifies verified Brave-backed web findings as MEDIUM).

---
*Architecture research for: MoonBit Native Foundation v0.34 CFF Outline Foundation*
*Researched: 2026-07-28*
