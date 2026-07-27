# Phase 98: Unicode Mapping and Kerning - Context

**Gathered:** 2026-07-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Extend the admitted portable `tchivs/mb-font/font` value with two deterministic public queries: map one valid Unicode scalar through the font's canonical format-12-or-format-4 `cmap`, and query one pair of admitted glyph IDs through the basic OpenType version-0 horizontal format-0 `kern` profile. Outline extraction, text shaping, GPOS, normalization of strings, font discovery, and portable real-font qualification remain owned by later phases.

</domain>

<decisions>
## Implementation Decisions

### Unicode Query Contract
- **D-01:** Expose one signed-integer scalar-to-opaque-`GlyphId` query so negative values are testable caller errors. A scalar is valid only in `U+0000..U+10FFFF` excluding `U+D800..U+DFFF`; invalid input returns a structured invalid-input error, while a valid unmapped scalar returns glyph zero.
- **D-02:** A mapped glyph must already be proven within the receiving font's glyph cardinality. The public result reuses Phase 97's opaque `GlyphId`; no raw table offset, encoding record, or integer-only bypass becomes public.
- **D-03:** Every cmap query uses Phase 97's pre-read and post-read retained-source revision guards. Mutation drift fails before publishing a glyph result.

### Deterministic Cmap Selection
- **D-04:** Admit one canonical Unicode mapping for queries: prefer an eligible format 12 subtable over every format 4 subtable, matching the OpenType rule that a 32-bit mapping supersedes a 16-bit compatibility mapping.
- **D-05:** Use the research-frozen rank exactly: `(platform 0, encoding 4, format 12)`, `(3, 10, 12)`, `(0, 3, 4)`, then `(3, 1, 4)`. Legacy Macintosh, ISO, custom, or symbol records may be structurally admitted when they use the supported formats, but they never become the Unicode mapping.
- **D-06:** Aliased encoding records may share one checked subtable. Distinct equally eligible records must resolve to the same admitted mapping facts or opening fails deterministically; do not merge records or fall back to a lower-priority table on a per-scalar miss.
- **D-07:** Preserve the Phase 97 format-4 and format-12 structural validation, sorted-range checks, glyph-range proof, checked arithmetic, and charged work. Planning may narrow the previously broad encoding-domain admission so it matches the canonical Unicode selection policy.
- **D-07a:** A well-formed admitted font with no eligible Unicode record fails `Font::open` with a capability error. A supplementary scalar queried through the selected format 4 mapping is a valid miss and returns glyph zero.

### Legacy Horizontal Kerning
- **D-08:** Support the interoperable basic profile: an optional OpenType `kern` table with version 0 and exactly one version-0, horizontal kerning-value, format-0 subtable whose coverage is exactly `0x0001`. Multiple supported subtables, format 2, Apple extensions, vertical/minimum/cross-stream/override/variation behavior, and reserved coverage bits are present-but-unsupported capabilities.
- **D-09:** The public pair query accepts two opaque `GlyphId` values, revalidates both against the receiving `Font`, and returns an exact signed font-unit adjustment. Table absence and a supported pair miss both return neutral zero.
- **D-10:** Classify recognized but out-of-profile kern data as a capability error and structurally invalid supported-profile bytes as a data error, with stable distinct contexts. Neither may be confused with successful neutral zero.
- **D-10a:** A well-formed out-of-profile kern table does not block metrics or cmap use: `Font::open` retains an unsupported-capability state and only the kerning query returns the capability error. A malformed kern envelope fails atomic opening as data.
- **D-11:** Format-0 pair keys must be strictly sorted and unique, both glyph IDs must be in range, search helper fields must be canonical, lengths must be exact, and lookup uses deterministic binary search.

### Admission and Resource Semantics
- **D-12:** Select and validate cmap and optional kern facts during the existing atomic `Font::open` admission transaction. Retain only compact table-local lookup facts; do not allocate a decoded Unicode map or kerning dictionary.
- **D-13:** Charge every attacker-declared record, group, segment, subtable, and pair scan before the loop that consumes it. Add explicit non-zero `max_kern_subtables` and `max_kern_pairs` semantic ceilings to `FontLimits` alongside the authoritative shared budget and `max_work`. — **Reversibility:** costly — removing these limits later would change the public constructor and weaken a published resource contract.
- **D-14:** Successful queries are bounded, allocation-free binary searches over already admitted facts and do not mutate the caller's opening budget. Exact-fit/one-short admission tests remain the resource oracle.

### Verification and Compatibility
- **D-15:** Generated micro-fonts must cover BMP and supplementary mappings, format-12 precedence, valid misses, invalid scalars, format-4 direct and glyph-array paths, aliased/conflicting records, glyph-range failures, kern absence/miss/hit, negative adjustments, unsupported profiles, malformed pairs, mutation drift, and exact limit/budget edges.
- **D-16:** Public black-box tests freeze stable semantic outcomes; private white-box tests cover offset math, selection ranking, binary-search boundaries, and error taxonomy. The phase must preserve the four-target package contract and minimal generated `.mbti` surface.

### the agent's Discretion
- Exact public method names and private source-file split are flexible if the generated interface exposes only the two scoped queries and the established opaque values.
- Exact stable error context strings and the internal representation of selected subtable offsets are flexible, provided invalid input, malformed data, unsupported capability, mutation, and resource exhaustion remain distinguishable.
- Exact internal encodings for selected/absent/unsupported table states are flexible if they preserve the locked public outcomes.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope and Requirements
- `.planning/ROADMAP.md` — Phase 98 goal, dependencies, and four success criteria.
- `.planning/REQUIREMENTS.md` — `FONT-02` Unicode mapping and `FONT-04` kerning contracts.
- `.planning/PROJECT.md` — v0.32 milestone boundary, pure-MoonBit portability, deterministic automation, and resource constraints.
- `.planning/research/STACK.md` — frozen four-step canonical cmap platform/encoding/format priority.

### Architecture and Prior Decisions
- `docs/rfcs/0004-mb-font.md` — font/text boundary, cmap ownership, TrueType/OpenType subset, format 4/12, and horizontal format-0 kern scope.
- `.planning/phases/97-font-admission-and-metrics/97-CONTEXT.md` — locked opaque value, retained-source, atomic admission, limits, budget, error, and dependency decisions inherited by this phase.
- `.planning/phases/97-font-admission-and-metrics/97-02-SUMMARY.md` — retained directory/required-table facts and strict cmap envelope admission.
- `.planning/phases/97-font-admission-and-metrics/97-03-SUMMARY.md` — receiving-font glyph revalidation and public interface policy.

### Existing Implementation Seams
- `modules/mb-font/font/font.mbt` — opaque `Font`/`GlyphId`, revision guard, atomic open coordinator, and public metric-query pattern.
- `modules/mb-font/font/tables.mbt` — retained `CmapEnvelope`, format-4/12 validation, work preflights, and required-table facts.
- `modules/mb-font/font/directory.mbt` — checked normalized `TableWindow` lookup for required and optional tables.
- `modules/mb-font/font/limits.mbt` — explicit semantic-limit constructor and accessors.
- `modules/mb-font/font/font_test.mbt` — generated public font builders and current cmap/resource regression corpus.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `CmapEnvelope` and `CmapSubtableFacts` already retain/count admitted format-4/12 data; extend these into selected lookup facts rather than reparsing the root source.
- `font_cmap_subtable_facts`, `font_validate_cmap_subtable`, `font_cmap_declared_work`, and `font_preflight_admission_work` already provide checked envelopes, semantic validation, and pre-loop resource accounting.
- `Font::require_revision`, `Font::glyph_id`, and `Font::horizontal_metrics` provide the exact guard/revalidate/read/guard/publication pattern for both new queries.
- `font_table_window` provides checked table-local windows; optional `kern` discovery can use the same directory without creating a public raw-table API.
- Existing generated cmap builders already produce format 4, two-segment format 4, shared/aliased records, and format 12 groups suitable for Phase 98 extensions.

### Established Patterns
- `Font::open` publishes exactly once after directory/profile/checksum/table/cross-cardinality admission and a final source-revision check.
- Attacker-declared loops receive semantic `max_work` and authoritative budget preflights before iteration, then one aggregate atomic charge.
- Unsupported profiles use capability errors; malformed admitted TrueType bytes use data errors; caller mistakes use invalid-input errors.
- Queries return opaque immutable semantic values and expose no parser offsets, tags, checksums, or cached mutable state.

### Integration Points
- Extend `RequiredTableFacts` with a selected cmap lookup descriptor and optional admitted kern descriptor.
- Add the public query methods beside existing `Font` queries and reuse `GlyphId` rather than adding a parallel glyph representation.
- Extend `FontLimits`, generated fixtures, public/white-box tests, module documentation, and the exact public-interface policy allowlist.
- Keep `moon.pkg` dependencies unchanged: `mb-font` remains portable and depends only on `mb-core`.

</code_context>

<specifics>
## Specific Ideas

- Treat OpenType 1.9.1 and Unicode 17.0.0 as the normative baselines inherited from Phase 97.
- Prefer one canonical mapping and one canonical kern profile so results cannot depend on target, record order, or host font behavior.
- Use signed integer font units for kerning; scaling and positioned text sequences remain caller/text-layer policy.

</specifics>

<deferred>
## Deferred Ideas

- Phase 99 owns simple/composite outline extraction and `Path2`-compatible geometry.
- Phase 100 owns licensed real-font provenance, public end-to-end workflow, and four-target hostile qualification.
- GPOS/GSUB shaping, vertical or cross-stream kerning, minimum values, multiple-subtable accumulation/override, format 2, Apple kern extensions, variable-font behavior, normalization, bidi, discovery, and rasterization remain outside v0.32.

</deferred>

---

*Phase: 98-unicode-mapping-and-kerning*
*Context gathered: 2026-07-27*
