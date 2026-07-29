# Phase 108: Public Contract and Transaction Skeleton - Context

**Gathered:** 2026-07-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 108 freezes the public, format-neutral `mb-text` shaping call and
immutable positioned-run semantics, then establishes the opaque cross-module
transaction skeleton needed to stage and publish one complete result under one
combined budget commit. It does not parse or execute GSUB, GPOS, GDEF, or
legacy `kern`; those behaviors begin in Phases 109-111.

</domain>

<decisions>
## Implementation Decisions

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

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone Scope and Requirements

- `.planning/PROJECT.md` — v0.35 active goal, project constraints, and explicit
  milestone boundary.
- `.planning/MILESTONE-CONTEXT.md` — selected vertical slice, exclusions, and
  carried-forward portability/safety constraints.
- `.planning/REQUIREMENTS.md` — normative TXT-01 and TXT-02 requirements and
  v0.35 traceability.
- `.planning/ROADMAP.md` — Phase 108 goal, success criteria, dependencies, and
  research flag.

### Research Decisions

- `.planning/research/SUMMARY.md` — synthesized closed profile, public contract,
  six-phase sequence, risk decisions, and Phase 108 research gaps.
- `.planning/research/ARCHITECTURE.md` — opaque transaction closure, ownership
  boundary, numeric/direction model, and likely file map.
- `.planning/research/FEATURES.md` — user-visible input/output, empty-run,
  direction, cluster, atomicity, and feature-policy behavior.
- `.planning/research/PITFALLS.md` — ordering, source authority, budget,
  mutation, and false-success risks that the skeleton must structurally
  prevent.

### Architectural Charters

- `docs/rfcs/0004-mb-font.md` — font-binary ownership and opaque `Font`
  boundary.
- `docs/rfcs/0005-mb-text.md` — proposed `mb-text` ownership and allowed
  dependency direction; its broader paragraph-layout scope remains deferred
  by the narrower v0.35 requirements.

### Existing Implementation Authorities

- `modules/mb-core/budget/budget.mbt` — hierarchical `Budget`,
  `ResourceCharge`, atomic ancestor preflight, and single-charge patterns.
- `modules/mb-font/font/font.mbt` — opaque `Font`, private retained source
  revision, same-font `GlyphId`, query guards, and final-guard publication
  patterns.
- `modules/mb-font/font/limits.mbt` — explicit semantic-limit value pattern
  intersecting, not replacing, caller budget authority.
- `modules/mb-font/font/kern.mbt` — existing format-neutral legacy-kerning
  boundary that later run-level authority must preserve.
- `modules/mb-core/moon.mod.json` and `modules/mb-font/moon.mod.json` — current
  four-target module identities and dependency floor.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `ResourceCharge` and hierarchical `Budget`: already provide immutable charge
  values, ancestor-aware preflight, and atomic mutation of budget windows.
  Phase 108 needs checked immutable charge composition rather than a second
  charging path.
- Opaque `Font` and `GlyphId`: already hide numeric glyph identity, retain the
  opening source revision, and reject cross-font or mutated-source queries.
- `FontLimits`: demonstrates private fields, validated construction, and
  semantic ceilings that remain separate from caller budget authority.
- Existing font open/outline transactions: provide final revision guard and
  publish-after-charge patterns for the new cross-module skeleton.

### Established Patterns

- Public structs keep representation private and expose named value accessors.
- Retained `ByteView` mutation is detected by comparing its current revision
  with the opening revision at operation boundaries.
- Resource work is staged, preflighted against every budget ancestor, and
  committed only after semantic validation and the final mutation guard.
- Portable modules declare the same `+js+wasm+wasm-gc+native` target set and
  avoid runtime FFI.

### Integration Points

- Add checked `ResourceCharge` composition in `mb-core/budget`.
- Add the smallest opaque request-scoped transaction seam beside `Font` in
  `mb-font/font`; it must not depend on `mb-text`.
- Create `tchivs/mb-text@0.1.0` with direct dependencies on `mb-font@0.1.0`
  and `mb-core@0.1.0`, plus a public package for the closed shaping contract.
- Extend `moon.work` only through the tracked new module member and keep all
  four supported targets.

</code_context>

<specifics>
## Specific Ideas

- Treat RTL as a final pen-order and signed-delta projection, never as
  pre-shaping input reversal.
- Make empty-run behavior executable and charged so it cannot become a hidden
  bypass around option validation, font mutation authority, or budget rules.
- Keep the Phase 108 implementation capable of generated contract fixtures,
  but use placeholder/private normalized layout outcomes rather than
  prematurely parsing GSUB/GPOS.

</specifics>

<deferred>
## Deferred Ideas

- GSUB/GPOS/GDEF table admission and selected-capability resolution — Phase 109.
- Substitution, ligature matching, and real cluster propagation — Phase 110.
- Pair positioning and GPOS-versus-legacy authority — Phase 111.
- Complete loop-derived charge ledger and mutation matrix — Phase 112.
- Licensed fonts, host oracle, and four-target release evidence — Phase 113.
- Normalization, paragraph bidi, fallback, line layout, complex scripts,
  arbitrary features, vertical text, variables, rasterization, and persistent
  caches — future milestones.

</deferred>

---

*Phase: 108-public-contract-and-transaction-skeleton*
*Context gathered: 2026-07-30*
