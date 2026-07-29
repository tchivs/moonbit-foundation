# Phase 108: Public Contract and Transaction Skeleton - Research

**Researched:** 2026-07-30
**Domain:** MoonBit format-neutral text shaping contract, opaque cross-module transaction authority, checked resource accounting
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)

The following constraints are copied verbatim from `108-CONTEXT.md`. [VERIFIED: `.planning/phases/108-public-contract-and-transaction-skeleton/108-CONTEXT.md`]

### Locked Decisions

### Public Call and Immutable Run

- **D-01:** Publish one closed operation equivalent to
  `shape(font, scalars, options, limits, budget) -> Result[ShapedRun, CoreError]`.
  The exact MoonBit namespace or receiver syntax may follow established module
  ergonomics, but there is no builder, ambient session, or incremental public
  mutation surface.
- **D-02:** The text input is an ordered scalar-value array, not a UTF-8 byte
  offset contract or a host `String` normalization contract. Validate the
  complete array, then retain a request-owned scalar snapshot before font
  work so later stages do not borrow mutable caller storage.
- **D-03:** `ShapedRun` and its glyph records are opaque immutable value
  contracts. Expose metadata, length, and indexed value accessors; do not
  return mutable internal arrays, raw OpenType records, lookup indices,
  offsets, table bytes, or a persistent layout profile.
- **D-04:** Each positioned record contains a same-font opaque `GlyphId`, a
  zero-based scalar-origin cluster, checked signed `Int64` advance,
  `x_offset`, and `y_offset`. The run also exposes `units_per_em`, explicit
  direction, and checked signed `total_advance`.

### Direction, Clusters, and Numeric Projection

- **D-05:** Execute shaping over logical input order for both directions.
  Publish LTR records in logical pen order; for RTL, reverse only the final
  positioned records into pen order.
- **D-06:** Final record advances are signed pen deltas: positive for ordinary
  LTR progression and negative for ordinary RTL progression. Compute base
  metrics and admitted positioning adjustments in checked design-unit
  arithmetic before the final direction projection. `total_advance` is the
  checked signed sum of published record advances.
- **D-07:** `x_offset` and `y_offset` remain signed OpenType design-space
  placement coordinates and are not converted to pixels or renderer screen
  axes. Phase 108 fixtures must make the RTL sign/projection rule executable
  before public API freeze.
- **D-08:** A one-to-one glyph retains its source scalar index. A ligature
  receives the minimum source scalar index of its consumed components.
  Positioning never changes clusters. Clusters do not claim UTF-8 byte
  offsets, grapheme boundaries, caret stops, bidi levels, or fallback spans.

### Tags, Features, and Empty Input

- **D-09:** Use checked four-byte `ScriptTag` and `LanguageTag` value types,
  `LanguageChoice::Default | Exact(LanguageTag)`, and explicit
  `Direction::LeftToRight | RightToLeft`. No automatic script, language, or
  direction inference participates.
- **D-10:** Public feature selection is closed: caller booleans control
  `liga` and `kern`; a supported required LangSys feature and supported
  `rlig` behavior are non-disableable. Do not expose arbitrary feature tags,
  numeric feature values, ranges, or variation coordinates in v0.35.
- **D-11:** A valid empty scalar array succeeds without selecting or parsing
  layout tables. It still validates all public options and limits, guards the
  font revision, reads stable font metadata needed by the run, preflights and
  commits the exact fixed text-side operation charge once, and returns an
  empty immutable run.
- **D-12:** Invalid scalars, malformed tags, duplicate or nonsensical closed
  choices, zero/invalid required limits, and foreign-font glyph construction
  attempts remain observable caller-contract failures rather than capability
  fallbacks.

### Transaction Authority and Error Precedence

- **D-13:** `mb-font` retains caller bytes, opening revision, normalized
  selected layout facts, glyph ownership, and the guarded request-scoped
  continuation. `mb-text` owns scalar policy, clusters, direction, feature
  choices, public run staging, and text-side charge facts. The dependency
  remains `mb-text -> mb-font -> mb-core`.
- **D-14:** One private harness composes immutable font-side and text-side
  `ResourceCharge` values, preflights the complete charge against caller and
  ancestors, performs the final font-source revision guard, charges once, and
  publishes one immutable run. There is no separately committable font stage,
  second text charge, public prepared transaction, or persistent cache.
- **D-15:** Freeze stage precedence as follows: validate caller
  `InvalidInput`; guard entry `State`; validate selected structural `Data`;
  reject selected semantic `Capability`; perform exact `Resource` limit and
  budget preflight after semantic staging. At every named mutation probe,
  observed revision drift returns `State` immediately, and the final `State`
  guard precedes the sole budget commit.
- **D-16:** Public errors continue using `CoreError` categories/codes with
  stable operation and context strings. Phase 108 owns the stage matrix and
  generic contract contexts; table- and lookup-specific diagnostics remain
  for the phases that introduce those structures.

### the agent's Discretion

- Choose the exact MoonBit function/receiver spelling and private generic or
  continuation encoding that preserves D-13 through D-15 without widening
  the public API.
- Choose internal immutable record storage and accessors, provided callers
  cannot mutate retained run state and exact allocation/charge facts remain
  derivable.
- Choose concise type and context-string names consistent with existing
  `mb-core` and `mb-font` conventions; the semantic meanings above are locked.

### Deferred Ideas (OUT OF SCOPE)

- GSUB/GPOS/GDEF table admission and selected-capability resolution — Phase 109.
- Substitution, ligature matching, and real cluster propagation — Phase 110.
- Pair positioning and GPOS-versus-legacy authority — Phase 111.
- Complete loop-derived charge ledger and mutation matrix — Phase 112.
- Licensed fonts, host oracle, and four-target release evidence — Phase 113.
- Normalization, paragraph bidi, fallback, line layout, complex scripts,
  arbitrary features, vertical text, variables, rasterization, and persistent
  caches — future milestones.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TXT-01 | Library authors can shape one bounded array of Unicode scalar values with one admitted static `Font` through an explicit deterministic horizontal API that requires script, default-or-exact language choice, `LeftToRight` or `RightToLeft` direction, a closed `rlig`/`liga`/`kern` feature policy, shaping limits, and one caller-owned budget, without ambient locale, normalization, bidi analysis, fallback, host font lookup, or I/O. | The recommended top-level `shape` API, opaque callback-scoped font transaction, validated tags/options/limits, full scalar snapshot, fixed empty charge, fail-closed nonempty skeleton, and single combined commit directly establish this contract. [VERIFIED: `.planning/REQUIREMENTS.md`; VERIFIED: phase context and codebase inspection] |
| TXT-02 | A successful immutable shaped run exposes only same-font opaque glyph identities, zero-based scalar-origin clusters, checked signed design-unit advances and x/y offsets, `units_per_em`, explicit direction, and checked total advance; LTR records are in logical pen order, RTL records are reversed only for final pen order, and a ligature carries the minimum source scalar index of its consumed components. | The recommended `PositionedGlyph`/`ShapedRun` value APIs, strengthened `GlyphId` owner check, checked `Int64` helpers, final-only RTL projection, and generated fixture matrix make every stated invariant executable. [VERIFIED: `.planning/REQUIREMENTS.md`; VERIFIED: phase context and codebase inspection] |

</phase_requirements>

## Summary

Phase 108 should freeze a small top-level `@text.shape` API and immutable run value model, then implement the minimum transaction mechanism needed to keep `mb-font` authoritative over retained font bytes while allowing `mb-text` to stage the public result. MoonBit makes top-level declarations package-private by default, forbids public signatures from mentioning private types, and only allows the package that owns a type to define its public methods. Therefore `mb-text` cannot add `Font::shape`, and a cross-module private transaction type is not expressible; the seam must be a public abstract type whose representation and useful lifetime remain controlled by `mb-font`. [CITED: https://docs.moonbitlang.com/en/latest/language/packages.html]

Use a generic continuation on `Font` that lends an opaque `FontShapeScope` to a callback. The scope contains the opening font authority and hidden font-side charge ledger, becomes unusable when the callback ends, and never exposes bytes, offsets, tables, or a persistent prepared layout. `mb-text` returns its privately staged value plus an immutable text-side charge to the harness; `mb-font` combines charges, checks the final revision, charges the caller budget once, and only then returns the value. The existing callback-scoped `BudgetScope::with_depth[T]`, shared `active` flag, ancestor-aware `Budget::preflight`, and atomic `Budget::charge` are direct in-repository precedents. [VERIFIED: `modules/mb-core/budget/budget.mbt`]

Two existing gaps must be resolved before the public contract freezes. First, `ResourceCharge` has no checked composition operation, so a single authoritative charge cannot yet be built without exposing fields. Second, current `GlyphId` stores only a numeric value; it cannot distinguish a glyph from another admitted `Font` with the same glyph range. Add checked charge composition in `mb-core` and bind each `GlyphId` to its owning `Font` (or an equally private identity token) in `mb-font`. [VERIFIED: `modules/mb-core/budget/budget.mbt`; VERIFIED: `modules/mb-font/font/font.mbt`]

**Primary recommendation:** Implement a public-abstract, callback-scoped `FontShapeScope` with one generic commit authority; keep nonempty real-font shaping fail-closed until Phase 109, but use private generated prepared fixtures to freeze run, direction, cluster, charge, mutation, and error-precedence behavior now.

## Project Constraints (from AGENTS.md)

- Core algorithms and shared models must be MoonBit implementations; this phase must not wrap a foreign shaping stack. [VERIFIED: `AGENTS.md`]
- Native remains the primary system target, while portable behavior must be maintained through explicit boundaries and conformance across `js`, `wasm`, `wasm-gc`, and `native`. [VERIFIED: `AGENTS.md`; VERIFIED: module manifests]
- Any native FFI must be small, isolated, documented, and replaceable; Phase 108 needs no FFI. [VERIFIED: `AGENTS.md`; VERIFIED: phase boundary]
- Public package dependencies must remain acyclic and explicit: `mb-text -> mb-font -> mb-core`. [VERIFIED: `AGENTS.md`; VERIFIED: D-13]
- Stable public APIs follow Semantic Versioning once declared stable, and experimental APIs must be visibly marked. [VERIFIED: `AGENTS.md`]
- Public operations must be deterministic and usable without GUI state; CLI, agent, and MCP callers are first-class. [VERIFIED: `AGENTS.md`]
- Performance claims require declared workloads and reproducible baselines; this phase should specify operation charges and correctness fixtures, not unmeasured performance claims. [VERIFIED: `AGENTS.md`]
- New modules and breaking architectural changes require RFC governance; RFC 0005 already charters `mb-text`, while the narrower v0.35 contract remains governed by the phase decisions. [VERIFIED: `AGENTS.md`; VERIFIED: `docs/rfcs/0005-mb-text.md`]
- Code discovery should prefer the codebase knowledge graph, then fall back to text/source inspection where the graph lacks MoonBit symbols. The graph reported files/modules but no MoonBit functions or call edges, so exact API research used direct source inspection. [VERIFIED: `AGENTS.md`; VERIFIED: codebase-memory architecture/search results]
- Repository edits must run through a GSD workflow; this research was initialized through the phase operation and changes only the requested research artifact. [VERIFIED: `AGENTS.md`; VERIFIED: GSD init output]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Scalar validation, tags, direction, features, clusters, and shaped-run values | `mb-text` public library API | `mb-core` errors/checked arithmetic | These are text policy and result semantics, while shared errors and arithmetic remain foundational. [VERIFIED: D-02 through D-10, D-13] |
| Retained font bytes, revision authority, normalized font facts, and glyph ownership | `mb-font` domain layer | `mb-core` bytes/errors | RFC 0004 and existing `Font` already own the retained source and revision guard. [VERIFIED: `docs/rfcs/0004-mb-font.md`; VERIFIED: `modules/mb-font/font/font.mbt`] |
| Cross-module staging and sole publication authority | `mb-font` transaction harness | `mb-text` continuation body | Only `mb-font` can guarantee the retained source has not changed immediately before the commit; `mb-text` supplies the staged public value and text charge. [VERIFIED: D-13 through D-15] |
| Checked charge composition and signed arithmetic | `mb-core` foundation | `mb-font`/`mb-text` stage-specific error rebinding | These operations are format-neutral reusable safety primitives. [VERIFIED: existing `mb-core/budget` and `mb-core/checked` boundaries] |
| Workspace membership, dependency policy, release lanes, and interface policy | Repository governance | Individual module manifests | Current policy scripts and `foundation.json` explicitly enumerate modules and allowed edges. [VERIFIED: `moon.work`; VERIFIED: `policy/foundation.json`; VERIFIED: `scripts/quality/Assert-Policy.ps1`] |

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| MoonBit `moon` | `0.1.20260713` (`75c7e1f`, 2026-07-13) | Workspace build, check, test, info, and package commands | This is the installed and project-pinned v0.1 toolchain. [VERIFIED: local `moon version`; VERIFIED: `.planning/research/STACK.md`] |
| `moonc` | `v0.10.4+2cc641edf` (2026-07-15) | Compile MoonBit source for all supported backends | It ships with the verified `moon` toolchain. [VERIFIED: local `moonc -v`; VERIFIED: `.planning/research/STACK.md`] |
| `tchivs/mb-core` | `0.1.0` | Budget, resource charge, checked arithmetic, and stable errors | Existing shared foundation; no new external dependency is needed. [VERIFIED: `modules/mb-core/moon.mod.json`] |
| `tchivs/mb-font` | `0.1.0` | Opaque admitted font, glyph identity, metadata, source revision, and transaction scope | Existing font-domain authority required by D-13. [VERIFIED: `modules/mb-font/moon.mod.json`; VERIFIED: `modules/mb-font/font/font.mbt`] |
| `tchivs/mb-text` | `0.1.0` (new) | Closed shaping contract and immutable shaped-run values | RFC 0005 and the v0.35 roadmap assign this public boundary to a separately publishable module. [VERIFIED: `docs/rfcs/0005-mb-text.md`; VERIFIED: `.planning/ROADMAP.md`] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| `moon.work` workspace resolution | Current project file | Coordinate local independent modules without path dependencies | Add `./modules/mb-text` so local `mb-core` and `mb-font` versions resolve while publication units stay separate. [VERIFIED: `moon.work`; CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/workspace.html] |
| Existing `CoreError` model | `mb-core@0.1.0` | Stable category, code, operation, and bounded context | Reuse for all caller, state, data, capability, and resource outcomes; do not add a text-only error hierarchy. [VERIFIED: `modules/mb-core/error/error.mbt`; VERIFIED: D-16] |
| Generated contract fixtures | Test-only, repository-owned | Exercise transaction and run invariants without real OpenType layout parsing | Use in Phase 108 for LTR/RTL, ligature cluster, mutation, precedence, and charge tests. [VERIFIED: phase boundary; VERIFIED: `108-CONTEXT.md` Specific Ideas] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Generic callback-scoped `FontShapeScope` | Public `PreparedLayout` or transaction object | Rejected: a persistent or separately committable object violates D-03 and D-14 and can outlive revision authority. [VERIFIED: D-03, D-14] |
| Top-level `@text.shape` | `Font::shape` implemented in `mb-text` | Not legal as the public method owner: MoonBit permits public methods only in the package that defines the type. [CITED: https://docs.moonbitlang.com/en/latest/language/packages.html] |
| Request-owned `Array[Int]` copy | Borrowed caller array or `ArrayView` | Rejected: MoonBit arrays are shared and mutable, and an `ArrayView` observes mutations of its underlying array. [CITED: https://docs.moonbitlang.com/en/latest/language/fundamentals.html] |
| Direct owner reference inside opaque `GlyphId` | Process-global numeric font identity | A direct private reference uses MoonBit object identity, remains portable, and avoids global mutable identity state. [VERIFIED: local `moon ide doc physical_equal`; VERIFIED: project portability constraint] |
| `moon.mod.json` for the new module | Immediate migration to `moon.mod` | Current official docs prefer the newer format, but project policy deliberately retains `moon.mod.json` until its compatibility floor is revisited. Do not mix manifest migrations into Phase 108. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html; VERIFIED: `.planning/research/STACK.md`] |

**Installation:** No third-party package installation is required. Add a local workspace module with declared `mb-core@0.1.0` and `mb-font@0.1.0` dependencies. [VERIFIED: project module model]

## Package Legitimacy Audit

Not applicable: Phase 108 installs no external npm, PyPI, crates.io, or MoonBit registry package. It adds one repository-owned MoonBit module and depends only on the two repository modules already governed by the workspace. [VERIFIED: phase scope and recommended stack]

## Architecture Patterns

### System Architecture Diagram

```text
Caller
  |
  | shape(font, scalar_array, options, limits, budget)
  v
mb-text public boundary
  |-- validate every scalar/tag/choice/limit --------> InvalidInput
  |-- copy request-owned scalar snapshot
  |
  v
Font::with_shape_transaction<T>  (mb-font authority)
  |-- entry source-revision guard -------------------> State
  |-- lend opaque active FontShapeScope to callback
  |       |
  |       +--> selected structural stage ------------> Data
  |       +--> selected semantic stage --------------> Capability
  |       +--> logical record staging in mb-text
  |       +--> return (private staged run, text charge)
  |
  |-- checked combine(font charge, text charge)
  |-- exact semantic limits + full budget preflight -> Resource
  |-- final source-revision guard -------------------> State
  |-- Budget::charge(combined) exactly once
  |-- close scope; publish T
  v
Opaque immutable ShapedRun
  |-- metadata/len/indexed value access only
  `-- LTR logical pen order OR final-only RTL reversal
```

This flow preserves the locked error order and gives `mb-font` the last source-state check without creating a reverse dependency on `mb-text`. [VERIFIED: D-13 through D-16]

### Recommended Project Structure

```text
modules/
├── mb-core/
│   ├── budget/
│   │   ├── budget.mbt                 # checked ResourceCharge composition
│   │   ├── budget_test.mbt            # public composition and budget tests
│   │   └── budget_wbtest.mbt          # overflow/dimension invariants
│   └── checked/
│       ├── checked.mbt                # checked signed Int64 helpers
│       ├── checked_test.mbt
│       └── checked_wbtest.mbt
├── mb-font/
│   └── font/
│       ├── font.mbt                   # same-Font GlyphId ownership
│       ├── shape_transaction.mbt      # opaque callback-scoped authority
│       ├── shape_transaction_test.mbt
│       └── shape_transaction_wbtest.mbt
└── mb-text/
    ├── moon.mod.json
    ├── README.mbt.md
    ├── CHANGELOG.md
    └── text/
        ├── moon.pkg
        ├── tags.mbt                   # checked ScriptTag/LanguageTag
        ├── options.mbt                # direction/language/features/options
        ├── limits.mbt                 # validated semantic ceilings
        ├── run.mbt                    # opaque records and run accessors
        ├── shape.mbt                  # public call + private staging
        ├── contract_test.mbt           # black-box frozen behavior
        └── contract_wbtest.mbt         # private probes/generated facts
moon.work
policy/foundation.json
scripts/quality/Assert-Policy.ps1
scripts/quality/Invoke-MoonQuality.ps1
```

These filenames follow current package organization, black-box `*_test.mbt`, white-box `*_wbtest.mbt`, and module publication-file conventions. [VERIFIED: repository source tree; VERIFIED: `.planning/research/STACK.md`]

### Pattern 1: Public-Abstract, Callback-Scoped Font Authority

**What:** Define `FontShapeScope` as a public type with private fields and expose one generic continuation on `Font`. A public type with private representation is abstract to consumers; a public signature cannot mention a private type. [CITED: https://docs.moonbitlang.com/en/latest/language/packages.html]

**When to use:** Use only for one request-scoped cross-module shaping transaction. Do not expose a constructor, persistent layout profile, raw source/table accessor, or commit method.

**Recommended signature:**

```moonbit
// Source pattern: existing BudgetScope::with_depth[T] plus MoonBit package docs.
pub fn[T] Font::with_shape_transaction(
  self : Font,
  budget : @budget.Budget,
  body : (FontShapeScope) ->
    Result[(T, @budget.ResourceCharge), @error.CoreError],
) -> Result[T, @error.CoreError]
```

The concrete tuple spelling should receive an immediate compile proof in the first implementation task; generic functions, closures, and higher-order function types are documented language features, and the repository already compiles the analogous `BudgetScope::with_depth[T]`. [CITED: https://docs.moonbitlang.com/en/latest/language/fundamentals.html; VERIFIED: `modules/mb-core/budget/budget.mbt`]

Implementation rules:

1. The scope owns a shared private `active` flag, the `Font`, and a private font-side charge ledger. [VERIFIED: analogous `BudgetScope` pattern]
2. Every scope operation first checks `active`, then checks the retained-source revision. [VERIFIED: D-15]
3. `defer` closes the scope on success or error; an escaped scope value can exist but all later operations return `State` with context `font-shape-scope-closed`. [VERIFIED: analogous `BudgetScope` invalidation behavior; recommended stable context]
4. The callback returns a private staged `T` and text charge. The harness combines it with the hidden font charge, preflights caller and ancestors, invokes the final mutation probe, guards the revision, calls `Budget::charge` once, then returns `T`. [VERIFIED: D-14, D-15]
5. No callback or fallible publication work occurs after `Budget::charge`. [VERIFIED: atomicity requirement D-14]

### Pattern 2: Checked Immutable ResourceCharge Composition

**What:** Add `ResourceCharge::checked_add` without exposing or mutating its private fields. [VERIFIED: `ResourceCharge` currently has private fields and no composition API in `modules/mb-core/budget/budget.mbt`]

**Recommended semantics:**

| Dimension | Composition |
|-----------|-------------|
| `bytes`, `allocations`, `pixels`, `work` | Checked `UInt64` addition |
| `allocation_size`, `width`, `height` | Maximum of the two per-operation ceilings |

The distinction matches current `Budget::preflight`: bytes/allocations/pixels/work consume remaining allowance, whereas allocation size/width/height are per-operation maxima. [VERIFIED: `modules/mb-core/budget/budget.mbt`]

```moonbit
// Recommended API; implement with @checked.checked_add_uint64.
pub fn ResourceCharge::checked_add(
  self : ResourceCharge,
  other : ResourceCharge,
) -> Result[ResourceCharge, @error.CoreError]
```

Bind overflow to category `Resource`, code `ArithmeticOverflow`, operation `resource-charge-add`, and the exact failing dimension as context. This is a phase recommendation consistent with existing `CoreError` conventions. [VERIFIED: `modules/mb-core/error/error.mbt`; recommended context contract]

### Pattern 3: Same-Font Glyph Identity

**What:** Strengthen opaque `GlyphId` with a private owner reference:

```moonbit
pub struct GlyphId {
  priv owner : Font
  priv value_value : UInt64
}
```

Current `GlyphId` contains only `value_value : UInt64`, and current glyph-consuming methods validate only the numeric range. Two different admitted fonts with equal glyph counts can therefore pass a foreign glyph numerically. [VERIFIED: `modules/mb-font/font/font.mbt`]

Construct glyphs only through `Font` methods and compare the private owner with `physical_equal` before any range or table work. Return `InvalidInput`/`InvalidRange`, operation rebound to the caller method, context `font-glyph-owner` on mismatch. MoonBit exposes physical identity comparison, and keeping the owner private preserves opaque value semantics. [VERIFIED: local `moon ide doc physical_equal`; recommended error context]

### Pattern 4: Closed Public mb-text Values

**What:** Publish a top-level function, checked tags/options/limits, and opaque immutable output values.

```moonbit
pub fn shape(
  font : @font.Font,
  scalars : Array[Int],
  options : ShapingOptions,
  limits : ShapeLimits,
  budget : @budget.Budget,
) -> Result[ShapedRun, @error.CoreError]
```

`shape` must be top-level because `mb-text` does not own `Font`. [CITED: https://docs.moonbitlang.com/en/latest/language/packages.html]

Recommended value contracts:

- `ScriptTag` and `LanguageTag` are abstract four-byte values. Constructors require exactly four bytes, each in OpenType Tag range `0x20..0x7E`; `ScriptTag` may represent `DFLT`, while `LanguageTag` rejects reserved `dflt` and `DFLT` spellings because default language selection is represented only by `LanguageChoice::Default`. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/otff; CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/scripttags; CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/languagetags]
- `pub(all) enum LanguageChoice { Default; Exact(LanguageTag) }` and `pub(all) enum Direction { LeftToRight; RightToLeft }` expose only closed choices. [VERIFIED: D-09]
- `FeaturePolicy` has private `liga` and `kern` booleans; no field or constructor permits disabling required LangSys or supported `rlig`. [VERIFIED: D-10]
- `PositionedGlyph` privately stores `GlyphId`, scalar-index cluster, signed advance, and signed x/y offsets; named accessors return values. [VERIFIED: D-04]
- `ShapedRun` privately stores a copied record array, `units_per_em`, direction, and checked total; expose only `len`, `glyph_at`, and named metadata accessors. [VERIFIED: D-03, D-04]
- `glyph_at` should return `InvalidInput`/`InvalidRange` with operation `text-shaped-run-glyph-at` and context `run-index`. This is a recommended stable generic contract context. [VERIFIED: existing indexed-access error style; recommended context]

MoonBit arrays are mutable shared references, so private construction must copy the fully validated scalar input before font work and copy any staging array before run publication. Returning an `ArrayView` is insufficient because the underlying array remains mutable. [CITED: https://docs.moonbitlang.com/en/latest/language/fundamentals.html]

### Pattern 5: Semantic Limits Separate from Budget

**What:** Follow `FontLimits`: private fields, a checked constructor that rejects zero required ceilings, named accessors, and no mutable setters. `ShapeLimits` constrains structural/semantic work; caller `Budget` independently constrains resource consumption. [VERIFIED: `modules/mb-font/font/limits.mbt`; VERIFIED: D-12, D-15]

Freeze these Phase 108 public limit groups so later phases do not need to widen the constructor:

| Limit group | Required ceilings |
|-------------|-------------------|
| Input/output | input scalars, final glyphs |
| Selected layout bytes | GSUB bytes, GPOS bytes, GDEF bytes, legacy kern bytes |
| Selection graph | scripts, language systems, features, feature-to-lookup references |
| Lookup graph | lookups, subtables, lookup applications, subtable probes |
| Coverage/class data | coverage entries/ranges, class ranges/counts, class-pair cells |
| Substitution | pair sets/records, ligature sets/ligatures/components, substitutions, consumed components |
| Positioning | pair probes, applied adjustments |
| Retained staging | normalized bytes, private allocations, output allocations, maximum allocation size, total work |
| Numeric bounds | maximum absolute advance, maximum absolute x/y offset |

The exact field names may stay concise, but every group above should have a nonzero ceiling and accessor now; Phases 109–112 will consume them rather than alter the public contract. This is a prescriptive design choice within the agent’s discretion, derived from the already enumerated future layout structures and charge loops. [VERIFIED: `.planning/research/ARCHITECTURE.md`; VERIFIED: `.planning/research/PITFALLS.md`]

### Pattern 6: Logical Staging, Final-Only RTL Projection

**What:** Compute base metrics and admitted adjustments in logical order using checked signed arithmetic. For RTL, negate each final advance and reverse only the finished record array. Never negate offsets or rewrite clusters. [VERIFIED: D-05 through D-08]

Add format-neutral `mb-core/checked` helpers for signed addition, signed negation, and checked `UInt64` to `Int64` conversion. Existing checked helpers cover only `UInt64` add/subtract/multiply and narrowing to `Int`; the local standard library exposes ordinary `Int64` arithmetic but no checked `Result` operation. `UInt64::reinterpret_as_int64` is a bit reinterpretation and must not be used as a numeric range check. [VERIFIED: `modules/mb-core/checked/checked.mbt`; VERIFIED: local `moon ide doc Int64`; VERIFIED: local `moon ide doc UInt64::reinterpret_as_int64`]

Recommended helper set:

```moonbit
pub fn checked_add_int64(lhs : Int64, rhs : Int64)
  -> Result[Int64, @error.CoreError]

pub fn checked_neg_int64(value : Int64)
  -> Result[Int64, @error.CoreError]

pub fn checked_uint64_to_int64(value : UInt64)
  -> Result[Int64, @error.CoreError]
```

Rebind generic arithmetic failures at the text boundary to stable operation/context values such as `text-shape-project` plus `advance`, `x-offset`, `y-offset`, or `total-advance`. [VERIFIED: D-16; recommended contexts]

### Pattern 7: Empty Success, Nonempty Fail-Closed Skeleton

**What:** Empty input uses the full validation and transaction path but bypasses layout selection and parsing. Choose this exact Phase 108 fixed text charge:

```moonbit
ResourceCharge::new(
  bytes=0,
  allocations=0,
  allocation_size=0,
  width=0,
  height=0,
  pixels=0,
  work=1,
)
```

This prescriptive charge records one deterministic text operation while avoiding claims about retained payload allocation for a zero-length run. A budget with `work=1` must succeed and end at zero; `work=0` must fail unchanged. The font-side charge is `ResourceCharge::none()`, and the combined charge is committed once through the same harness used by nonempty requests. [VERIFIED: D-11, D-14; recommended exact charge]

For nonempty input in Phase 108, do not report successful real-font shaping as a `cmap` + horizontal-metrics approximation: required feature and `rlig` authority cannot be established before layout admission. The public nonempty path should fail closed with `Capability` until Phase 109 supplies selected normalized layout facts. Private generated fixtures should feed prepared logical glyph facts into the transaction skeleton to test public run semantics without parsing GSUB, GPOS, GDEF, or `kern`. [VERIFIED: phase boundary; VERIFIED: D-10; VERIFIED: `.planning/research/PITFALLS.md`]

### Pattern 8: Frozen Stage and Mutation Matrix

**What:** Implement the following order literally. D-15 supersedes the earlier research draft that placed entry `State` before caller `InvalidInput`. [VERIFIED: D-15; VERIFIED: `.planning/research/ARCHITECTURE.md`]

1. Validate all public scalar/tag/choice/limit input and scan the complete scalar array — `InvalidInput`.
2. Copy the scalar snapshot.
3. Guard the font revision at entry — `State`.
4. Validate selected structural facts — `Data`.
5. Guard at the named post-structure mutation probe — `State`.
6. Validate selected semantic support — `Capability`.
7. Guard at the named post-capability mutation probe — `State`.
8. Stage the private logical run and combine font/text charges with checked arithmetic.
9. Guard after complete private staging — `State`.
10. Enforce exact semantic limits and call `Budget::preflight` on the combined charge — `Resource`.
11. Invoke the private `before_final_guard` mutation probe.
12. Perform the final font revision guard — `State`.
13. Call `Budget::charge(combined)` exactly once.
14. Close the scope and publish the staged value; perform no further fallible work.

Existing private callbacks such as `_after_lookup`, `_after_decode`, and `before_final_guard` establish the repository convention for deterministic mutation injection. Add a private probe bundle/wrapper for tests; the public wrapper always supplies no-op probes. [VERIFIED: `modules/mb-font/font/font.mbt`; VERIFIED: font outline/collection transaction sources]

### Anti-Patterns to Avoid

- **Private type in a public cross-module signature:** MoonBit rejects public entities that mention private types. Use a public abstract type with private fields. [CITED: https://docs.moonbitlang.com/en/latest/language/packages.html]
- **An `internal` friend package shared across `mb-font` and `mb-text`:** internal packages are usable only inside the same module prefix, so they cannot create a private bridge between separately publishable modules. [CITED: https://docs.moonbitlang.com/en/latest/language/packages.html]
- **Public prepared transaction or commit handle:** It widens the lifetime and permits stale or separately committed state, violating D-03/D-14. [VERIFIED: D-03, D-14]
- **Incremental font charge followed by text charge:** It makes failure partially consume the caller budget. Compose immutable facts and commit once. [VERIFIED: D-14; VERIFIED: current `Budget` semantics]
- **Borrowing `Array` or returning `ArrayView`:** Both retain access to mutable backing storage. Copy before font work and before publication. [CITED: https://docs.moonbitlang.com/en/latest/language/fundamentals.html]
- **Numeric-only glyph range checks:** Equal numeric glyph ranges do not prove common font ownership. Bind opaque glyphs to their owner. [VERIFIED: `modules/mb-font/font/font.mbt`]
- **Reversing input for RTL:** It changes logical lookup and cluster semantics. Reverse final records only. [VERIFIED: D-05]
- **Negating RTL offsets:** Offsets remain OpenType design-space placement coordinates; only pen deltas change sign. [VERIFIED: D-06, D-07]
- **Using `reinterpret_as_int64` for checked conversion:** It reinterprets bits and can produce a negative value for an out-of-range `UInt64`. [VERIFIED: local MoonBit standard-library documentation]
- **Returning nonempty false success before layout admission:** `cmap` plus metrics cannot establish required-feature/`rlig` policy. Fail closed until Phase 109. [VERIFIED: D-10 and phase boundary]
- **Updating `moon.work` without policy/quality enumeration:** The repository’s module policy and required-lane script currently hard-code known modules, so a workspace-only addition would leave governance incomplete. [VERIFIED: `policy/foundation.json`; VERIFIED: `scripts/quality/Assert-Policy.ps1`; VERIFIED: `scripts/quality/Invoke-MoonQuality.ps1`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Hierarchical resource authority | A text-specific counter or rollback log | Existing `Budget::preflight` + one `Budget::charge` | Existing code already checks all ancestors before mutating any window. [VERIFIED: `modules/mb-core/budget/budget.mbt`] |
| Error hierarchy | New shaping exceptions or string-only failures | Existing `CoreError` category/code/operation/context | D-16 requires stable shared errors and current accessors already support contract testing. [VERIFIED: D-16; VERIFIED: `modules/mb-core/error/error.mbt`] |
| Scope lifetime system | Global transaction registry or persistent token table | Shared private `active` flag with `defer` invalidation | The repository already uses this callback-scoped pattern for `BudgetScope`. [VERIFIED: `modules/mb-core/budget/budget.mbt`] |
| Font identity registry | Global incrementing IDs | Private owner `Font` reference + `physical_equal` | Avoids ambient state and remains portable. [VERIFIED: local MoonBit API; VERIFIED: project constraints] |
| Tag parser | General string normalization or locale resolver | Exact four-byte checked value constructors | OpenType Tags have a fixed byte representation, and automatic locale/script behavior is out of scope. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/otff; VERIFIED: D-09] |
| Layout parser/executor | Early GSUB/GPOS/GDEF/`kern` implementation | Private generated prepared fixtures | Real admission and execution belong to Phases 109–111. [VERIFIED: phase boundary and Deferred Ideas] |
| Bidi or grapheme machinery | Host bidi/normalization libraries | Explicit direction and scalar-index clusters | Bidi analysis, normalization, and grapheme semantics are explicitly excluded. [VERIFIED: TXT-01; VERIFIED: D-08] |

**Key insight:** Phase 108 is about freezing authority, ownership, value semantics, and error order. Implementing format machinery now would hide contract flaws beneath parser complexity and violate the milestone decomposition. [VERIFIED: phase boundary and roadmap]

## Common Pitfalls

### Pitfall 1: A Scope That Can Be Escaped and Reused

**What goes wrong:** A generic callback can return the lent scope as `T`, apparently extending its lifetime.

**Why it happens:** MoonBit documents lexical closures and generics but does not provide a public lifetime type system for this API shape. [CITED: https://docs.moonbitlang.com/en/latest/language/fundamentals.html]

**How to avoid:** Put a shared private `active` cell in the scope, invalidate it with `defer`, and make every method reject inactive use before touching font state. [VERIFIED: existing `BudgetScope` pattern]

**Warning signs:** A public scope constructor, a public `commit`, or a scope method that omits the active/revision guard.

### Pitfall 2: Partial Budget Consumption

**What goes wrong:** Font work charges successfully, then text staging or publication fails, leaving a consumed budget and no run.

**Why it happens:** Existing font operations often own their entire transaction and can charge independently; that pattern cannot be nested unchanged across two module authorities. [VERIFIED: current font transaction sources; VERIFIED: D-14]

**How to avoid:** Return immutable charge facts from both sides, combine with checked arithmetic, preflight once, perform the final revision guard, and call `Budget::charge` once. [VERIFIED: D-14]

**Warning signs:** More than one `charge` call in the shaping call graph, a charge inside the continuation body, or any fallible step after the sole charge.

### Pitfall 3: Foreign Glyphs Passing by Numeric Coincidence

**What goes wrong:** A glyph created by Font A is accepted by Font B because both contain that numeric glyph ID.

**Why it happens:** Current `GlyphId` carries only the numeric value and consuming methods range-check against the receiving font. [VERIFIED: `modules/mb-font/font/font.mbt`]

**How to avoid:** Add private owner identity and reject owner mismatch before table access. Test two distinct fonts with the same glyph count. [VERIFIED: codebase gap; recommended remedy]

**Warning signs:** Any public/internal construction from a naked integer, or validation that checks only `< glyph_count`.

### Pitfall 4: Wrong Error Wins in a Multi-Fault Request

**What goes wrong:** A short budget or unsupported feature masks malformed input, structural corruption, or a mutation that occurred at a named probe.

**Why it happens:** Convenient early preflight or delayed revision checks change observable precedence. [VERIFIED: D-15]

**How to avoid:** Implement the frozen pipeline and a cross-product matrix of deliberately simultaneous faults. [VERIFIED: D-15]

**Warning signs:** Budget checks before semantic staging, entry font access before the complete public validation scan, or a probe without an immediate revision guard.

### Pitfall 5: Overflow During Projection

**What goes wrong:** Negating `Int64::MIN_VALUE`, adding an adjustment to a base advance, or summing total advance wraps before an error is raised.

**Why it happens:** Ordinary `Int64` operators do not return a checked result, and bit reinterpretation is not numeric narrowing. [VERIFIED: local MoonBit standard-library documentation]

**How to avoid:** Use explicit checked signed helpers for every conversion, adjustment, negation, and total accumulation. [VERIFIED: D-06]

**Warning signs:** Bare `+` in final advance/total code, bare unary negation of admitted data, or `reinterpret_as_int64`.

### Pitfall 6: Empty Input Becomes a Validation or Charging Bypass

**What goes wrong:** Empty input returns immediately without validating tags/limits, guarding the font, or committing the fixed work charge.

**Why it happens:** An intuitive `if scalars.is_empty() return empty` shortcut is placed before the transaction.

**How to avoid:** Validate all public values first, then use the normal transaction with no layout selection, stable metadata read, exact `work=1` text charge, final guard, and one commit. [VERIFIED: D-11; recommended exact charge]

**Warning signs:** Empty-path return before `Font::with_shape_transaction`, any selected-layout method call for empty input, or no budget delta on success.

### Pitfall 7: Accidental Public Surface Growth

**What goes wrong:** Generated `.mbti` reveals constructors, mutable arrays, raw table facts, probe callbacks, or transaction internals.

**Why it happens:** MoonBit’s `pub`, `pub(all)`, and default abstract type visibility have materially different export behavior. [CITED: https://docs.moonbitlang.com/en/latest/language/packages.html]

**How to avoid:** Keep representations private, expose only named value accessors, run `moon info --target all`, and extend the repository’s public-interface policy for the new package. [VERIFIED: repository policy scripts]

**Warning signs:** `pub(all)` on run structs, public raw-array access, or probe names in generated interface output.

## Code Examples

Verified and recommended patterns for the planner:

### Immutable Input Snapshot

```moonbit
// Source: MoonBit Array docs and existing repository .copy() usage.
fn validate_and_snapshot(
  scalars : Array[Int],
) -> Result[Array[Int], @error.CoreError] {
  for scalar in scalars {
    guard is_unicode_scalar(scalar) else {
      return Err(invalid_scalar_error())
    }
  }
  Ok(scalars.copy())
}
```

MoonBit arrays are shared mutable references; `.copy()` creates a distinct shallow array, which is sufficient for scalar values. [CITED: https://docs.moonbitlang.com/en/latest/language/fundamentals.html; VERIFIED: local `moon ide doc Array::copy`; VERIFIED: repository `.copy()` usage]

### Executable RTL Projection Fixture

Logical staging before direction projection:

| Logical record | Cluster | Base + adjustment | x offset | y offset |
|----------------|---------|-------------------|----------|----------|
| A | 0 | `600 + (-50) = 550` | `+20` | `-10` |
| B | 1 | `500 + 0 = 500` | `-30` | `+15` |

Expected publication:

| Direction | Published records | Advances | Offsets | Total |
|-----------|-------------------|----------|---------|-------|
| LTR | A, B | `+550`, `+500` | unchanged | `+1050` |
| RTL | B, A | `-500`, `-550` | unchanged | `-1050` |

This fixture proves final-only reversal, signed pen-delta projection, unchanged design-space offsets, unchanged clusters, and checked total. [VERIFIED: D-05 through D-08]

Add a ligature fixture consuming scalar indices `1, 2, 3`; its cluster is `1` in logical staging and remains `1` after RTL record reversal. [VERIFIED: D-08]

### Multi-Fault Precedence Matrix

| Injected faults | Expected winner | Budget mutation |
|-----------------|-----------------|-----------------|
| Invalid scalar + already drifted font | `InvalidInput` | none |
| Valid caller + already drifted font | `State` | none |
| Malformed selected structure + unsupported capability + short budget | `Data` | none |
| Structurally valid + unsupported capability + short budget | `Capability` | none |
| Valid semantic stage + exceeded limit/short budget | `Resource` | none |
| Revision drift at any named stage probe + later fault | `State` immediately | none |
| Exact budget + mutation after preflight/before final guard | `State` | none |
| Exact valid request | success | one combined decrement in caller and every ancestor |

This matrix is a direct executable form of D-15 and D-14. [VERIFIED: D-14, D-15]

### Same-Font Ownership Test Shape

```moonbit
// Recommended black-box behavior.
let glyph_a = font_a.glyph_id(3U64).unwrap()
assert_true(font_a.horizontal_metrics(glyph_a).is_ok())
assert_true(font_b.horizontal_metrics(glyph_a).is_err())
```

Use two distinct admitted fonts whose glyph count includes ID 3; copied aliases of the same `Font` must remain accepted because the owner object is physically identical. [VERIFIED: current Font/GlyphId API; recommended ownership regression]

## State of the Art

| Old / Existing Approach | Current Phase 108 Approach | When Changed | Impact |
|-------------------------|----------------------------|--------------|--------|
| Module-private top-level implementation or same-package method | Public abstract callback-scoped cross-module scope | Phase 108 | Respects MoonBit visibility while keeping bytes/layout facts opaque. [CITED: MoonBit package docs; VERIFIED: D-13] |
| Numeric-only `GlyphId` | Opaque glyph bound to owning `Font` | Phase 108 | Enforces TXT-02 same-font identity rather than numeric coincidence. [VERIFIED: current code gap; VERIFIED: TXT-02] |
| No `ResourceCharge` composition | Checked immutable combined charge | Phase 108 | Enables one caller/ancestor preflight and one commit. [VERIFIED: current code gap; VERIFIED: D-14] |
| Unsigned-only shared checked arithmetic | Shared signed add/negate/narrow helpers | Phase 108 | Makes final LTR/RTL projection and total advance overflow-safe. [VERIFIED: current checked API; VERIFIED: D-06] |
| Earlier research ordering `State` before `InvalidInput` | Locked `InvalidInput` before entry `State` | Context decision D-15, 2026-07-30 | Planner and tests must follow D-15, not the older draft. [VERIFIED: `108-CONTEXT.md`; VERIFIED: `.planning/research/ARCHITECTURE.md`] |
| Official docs’ newer `moon.mod` examples | Project-retained `moon.mod.json` compatibility floor | Existing project policy | Phase 108 avoids an unrelated manifest migration. [CITED: MoonBit module docs; VERIFIED: `.planning/research/STACK.md`] |

**Deprecated/outdated for this phase:**

- A public `PreparedLayout[T]` or separately committable font result is superseded by D-14’s no-public-prepared-transaction decision. [VERIFIED: D-14]
- A statement that current `GlyphId` already enforces same-font ownership is inaccurate for the inspected code; it stores only a numeric value. [VERIFIED: `modules/mb-font/font/font.mbt`]
- Treating `moon test --target all` alone as sufficient semantic evidence is incomplete; the repository’s release posture requires explicit target lanes and policy/qualification evidence. [VERIFIED: `.planning/research/STACK.md`; VERIFIED: quality scripts]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | No claims are tagged `[ASSUMED]`; unresolved design points are stated as recommendations or open questions and should be compile-proven during implementation. | All | — |

## Open Questions

1. **Will the exact proposed nested callback tuple signature compile unchanged on the pinned toolchain?**
   - What we know: Generic functions, closures, and higher-order function types are documented, and `BudgetScope::with_depth[T]` already compiles in this repository. [CITED: https://docs.moonbitlang.com/en/latest/language/fundamentals.html; VERIFIED: `modules/mb-core/budget/budget.mbt`]
   - What is unclear: The exact formatting/spelling of `Result[(T, ResourceCharge), CoreError]` was not compiled during this documentation-only research task.
   - Recommendation: Make a minimal compile proof the first task in the font-transaction plan; if tuple syntax is awkward, replace only the private callback return carrier with a public-abstract generic result type while preserving the same opacity and lifetime rules.

2. **How many individual fields should the frozen `ShapeLimits` constructor expose?**
   - What we know: D-12 requires valid nonzero limits, and future phases require ceilings across selection, lookup, coverage/class, substitution, positioning, staging, and numeric dimensions. [VERIFIED: D-12; VERIFIED: research architecture/pitfalls]
   - What is unclear: Context locks semantics but delegates concise type naming and representation.
   - Recommendation: Freeze every limit group listed in Pattern 5 now, use private fields and named accessors, and allow internal constructors/helpers to group arguments without dropping a public ceiling.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| `moon` | Module creation, check, test, info, package | ✓ | `0.1.20260713` (`75c7e1f`, 2026-07-13) | — [VERIFIED: local command] |
| `moonc` | Four-target compilation | ✓ | `v0.10.4+2cc641edf` (2026-07-15) | — [VERIFIED: local command] |
| `moonrun` | Native test execution | ✓ | `0.1.20260713` (`75c7e1f`, 2026-07-13) | — [VERIFIED: local command] |
| PowerShell quality entry point | Policy and qualification lanes | ✓ | Repository scripts | Direct `moon` commands provide local focused fallback, but release evidence still requires the scripts. [VERIFIED: `scripts/quality.ps1`] |
| External shaping/font library | None | not required | — | Generated MoonBit fixtures; real layout parsing is deferred. [VERIFIED: phase boundary] |

**Missing dependencies with no fallback:** None. [VERIFIED: environment probe]

**Missing dependencies with fallback:** None. [VERIFIED: environment probe]

## Verification Strategy (Nyquist Validation Disabled)

The formal `Validation Architecture`/Wave 0 section is intentionally omitted because `.planning/config.json` explicitly sets `workflow.nyquist_validation` to `false`. The phase still needs executable contract tests and the following exact commands. [VERIFIED: `.planning/config.json`]

### Focused Commands

```powershell
moon -C modules/mb-core test budget --target native --frozen
moon -C modules/mb-core test checked --target native --frozen
moon -C modules/mb-font test font --target native --frozen
moon -C modules/mb-text check --target native --deny-warn --frozen
moon -C modules/mb-text test text --target native --frozen
```

Package-filtered `moon test` accepts a package path argument, and `--frozen` prevents dependency-lock mutation. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html]

### Four-Target Contract Loop

Run affected packages explicitly on every production target:

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

The documented `all` target expands to `wasm`, `wasm-gc`, `js`, and `native`; explicit per-target execution gives clearer backend-specific failure evidence. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html]

### Workspace, Interface, and Governance Gates

```powershell
moon -C modules/mb-text info --target all --frozen
moon check --target all --deny-warn --frozen
moon test --target all --frozen
./scripts/quality.ps1 -Lane Required -EvidenceDirectory artifacts/release-qualification/phase108
./scripts/quality.ps1 -Lane FontQualification -EvidenceDirectory artifacts/release-qualification/phase108-font
```

`moon info` is required to inspect the actual public surface; the quality scripts enforce module metadata, dependency edges, interface policy, and the repository’s font regression lane. [VERIFIED: `scripts/quality/Assert-Policy.ps1`; VERIFIED: `scripts/quality/Invoke-MoonQuality.ps1`]

### Required Test Matrix

| Contract | Test Type | Focus |
|----------|-----------|-------|
| Full scalar/tag/choice/limit validation before font access | Black-box + private mutation probe | InvalidInput precedence and request-owned copy |
| Empty request exact success/failure charge | Black-box | `work=1` exact fit, one-short failure, no layout selection |
| Scope escape/invalidation | White-box | Escaped scope returns `State`; no retained usable authority |
| Combined charge arithmetic | Core unit | additive dimensions, max ceilings, overflow per dimension |
| Caller + ancestor atomicity | Core/font integration | exact fit, one-short, no partial mutation |
| Same-font glyph identity | Font black-box | alias accepted; distinct same-range font rejected |
| LTR/RTL projection | Generated contract fixture | record order, advance sign, unchanged offsets/clusters, checked total |
| Ligature cluster | Generated contract fixture | minimum consumed scalar index, preserved through RTL reversal |
| Stage/error precedence | White-box matrix | InvalidInput → State → Data → Capability → Resource |
| Named mutation probes | White-box matrix | immediate State and zero budget delta at every seam |
| Public interface | `moon info` + policy | no raw arrays, table facts, probes, constructors, or commit handles |

### Planning Decomposition

1. **Core safety primitives:** implement/test checked `ResourceCharge` composition and checked signed `Int64` helpers.
2. **Font authority:** strengthen `GlyphId` ownership, compile-proof and implement the opaque transaction scope, and add escape/mutation/atomicity tests.
3. **Text contract:** add the module and public values, limits, immutable run, empty path, fail-closed nonempty path, private generated fixture seam, RTL/cluster/precedence tests.
4. **Repository integration:** add workspace membership, module/dependency/interface policy, required-lane enumeration, docs/changelog, and four-target evidence.

This split keeps dependencies one-directional and makes each plan independently verifiable before the next layer consumes it. [VERIFIED: D-13; VERIFIED: current module graph]

## Security Domain

Security enforcement is enabled because `.planning/config.json` does not set `security_enforcement` to `false`. [VERIFIED: `.planning/config.json`]

### Applicable ASVS Categories

ASVS 5.0.0 is an application-security verification standard; this library phase adapts only categories relevant to untrusted structured input and resource authority. [CITED: https://github.com/OWASP/ASVS/releases]

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No identity/authentication surface in this pure library phase. [VERIFIED: phase scope] |
| V3 Session Management | no | The callback scope is a local capability lifetime, not an authenticated session. [VERIFIED: recommended architecture] |
| V4 Access Control | no | No user/role authorization boundary; owner checks are type/domain integrity. [VERIFIED: phase scope] |
| V5 Validation, Sanitization and Encoding | yes | Complete scalar/tag/choice/limit validation before font access; checked table-independent value constructors. [VERIFIED: D-02, D-09, D-12, D-15] |
| V6 Stored Cryptography | no | No secrets or cryptographic persistence. [VERIFIED: phase scope] |
| Architecture / Business Logic | yes | Opaque authority, deterministic stage order, same-font ownership, one combined commit. [VERIFIED: D-13 through D-16] |
| Files / Resources | yes | Retained source revision guard, semantic ceilings, hierarchical budget preflight, checked arithmetic. [VERIFIED: existing `ByteView`/`Budget`; VERIFIED: D-11 through D-15] |

### Known Threat Patterns for the MoonBit Library Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Caller mutates retained scalar array after validation | Tampering | Copy the fully validated array before font work. [CITED: MoonBit array semantics; VERIFIED: D-02] |
| Retained font bytes mutate between stages | Tampering | Revision guard at entry, every named probe, after staging, and immediately before commit. [VERIFIED: D-15; VERIFIED: existing Font guards] |
| Huge input or prepared facts exhaust work/memory | Denial of Service | Nonzero semantic ceilings plus caller/ancestor `Budget` and checked charge composition. [VERIFIED: D-12, D-14, D-15] |
| Foreign glyph crosses font authority | Spoofing / Tampering | Private owner identity checked before range/table access. [VERIFIED: identified code gap; VERIFIED: D-12] |
| Raw normalized facts escape transaction | Information Disclosure / Integrity | Public abstract scope, no byte/table accessors, scope invalidation, opaque run values. [VERIFIED: D-03, D-13, D-14] |
| Multi-fault request yields nondeterministic error | Repudiation / Integrity | Frozen stage precedence and stable operation/context strings. [VERIFIED: D-15, D-16] |
| Signed arithmetic wraps | Tampering / Denial of Service | Checked add, negate, narrowing, and total accumulation. [VERIFIED: D-06] |

## Sources

### Primary (HIGH confidence)

- `modules/mb-core/budget/budget.mbt` — `ResourceCharge`, hierarchical preflight/charge, `BudgetScope::with_depth[T]`, active-scope invalidation.
- `modules/mb-core/checked/checked.mbt` — existing unsigned checked arithmetic and missing signed helpers.
- `modules/mb-core/error/error.mbt` — stable categories, codes, operations, and bounded contexts.
- `modules/mb-font/font/font.mbt` — retained revision authority, current numeric-only `GlyphId`, metadata/glyph query guards, mutation probes.
- `modules/mb-font/font/limits.mbt` — validated private semantic-limit pattern.
- `moon.work`, module manifests, `policy/foundation.json`, `scripts/quality/Assert-Policy.ps1`, `scripts/quality/Invoke-MoonQuality.ps1` — workspace and governance integration.
- `.planning/phases/108-public-contract-and-transaction-skeleton/108-CONTEXT.md` — locked phase decisions.
- `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md` — TXT-01/TXT-02 and phase boundary.
- `docs/rfcs/0004-mb-font.md`, `docs/rfcs/0005-mb-text.md` — module ownership charters.
- Local pinned `moon ide doc` output — `Array::copy`, `physical_equal`, `Int64` bounds/API, and `UInt64::reinterpret_as_int64`.

### Secondary (MEDIUM confidence)

- https://docs.moonbitlang.com/en/latest/language/packages.html — package visibility, public abstract types, public-signature constraints, method ownership, internal packages.
- https://docs.moonbitlang.com/en/latest/language/fundamentals.html — generics, closures, higher-order function types, shared mutable arrays/views.
- https://docs.moonbitlang.com/en/latest/toolchain/moon/workspace.html — workspace member behavior.
- https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html — targets, `--target all`, test/check/info, and `--frozen`.
- https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html — current manifest documentation.
- https://learn.microsoft.com/en-us/typography/opentype/spec/otff — OpenType Tag representation.
- https://learn.microsoft.com/en-us/typography/opentype/spec/scripttags — script tag conventions and `DFLT`.
- https://learn.microsoft.com/en-us/typography/opentype/spec/languagetags — language tags and reserved default tags.
- https://github.com/OWASP/ASVS/releases — ASVS 5.0.0 security category reference.

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — versions and module dependencies were verified locally and in manifests.
- Architecture: MEDIUM — visibility and existing callback patterns are verified, but the exact proposed cross-module generic signature still needs a pinned-toolchain compile proof.
- Pitfalls: HIGH — derived from locked decisions, exact source gaps, and official language semantics.
- Numeric/direction contract: HIGH — locked by context and backed by checked-API inspection.
- Governance/test commands: HIGH — derived from current manifests, official commands, and repository quality scripts.

**Research date:** 2026-07-30
**Valid until:** 2026-08-06 — MoonBit’s v0.1 toolchain and manifest guidance are fast-moving; recheck official docs/tool versions after seven days.
